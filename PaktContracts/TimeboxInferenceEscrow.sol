// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./DeFiVault1Pct.sol";

/**
 * @title TimeboxInferenceEscrow
 * @notice Time-locked inference-service escrow integrated with 1%-bonus DeFi vault.
 * Parties:
 *  - client: funds the service
 *  - provider: runs inference endpoint
 *  - agent: monitors health & can pause/resume
 *
 * Flow:
 *  1. Client deploys contract with provider & agent addresses and funds it.
 *  2. Client starts service.
 *  3. Provider periodically calls claim() to receive pro-rata payment.
 *  4. Agent can pause/resume service if endpoint down/up.
 *  5. Funds live inside the vault (earning +1% bonus each time withdrawn).
 */

contract TimeboxInferenceEscrow {
    // Parties
    address public client;
    address payable public provider;
    address public agent;
    address public arbitrationContract;

    // Service parameters
    uint256 public startTimestamp;
    uint256 public durationSeconds;
    uint256 public fundedAmount;
    uint256 public lastClaimedTimestamp;

    bool public paused;
    uint256 public pausedAt;
    uint256 public accumulatedPausedSeconds;

    // Vault integration (1% bonus on each withdraw)
    DeFiVault1Pct public vault;

    // Reentrancy guard
    uint256 private _locked = 1;
    modifier nonReentrant() {
        require(_locked == 1, "reentrant");
        _locked = 2;
        _;
        _locked = 1;
    }

    modifier onlyClient() { require(msg.sender == client, "only client"); _; }
    modifier onlyAgent() { require(msg.sender == agent, "only agent"); _; }
    modifier onlyProvider() { require(msg.sender == provider, "only provider"); _; }

    event Funded(address indexed by, uint256 amount);
    event Started(uint256 start, uint256 duration);
    event Paused(address indexed by, uint256 at);
    event Resumed(address indexed by, uint256 at);
    event Claimed(uint256 amount, uint256 at);
    event Renewed(uint256 addAmount, uint256 newDuration);
    event SentToArbitration(address arbitration, uint256 amount);

    constructor(
        address _client,
        address payable _provider,
        address _agent,
        address _arbitrationContract,
        address payable _vault,
        uint256 _durationSeconds
    ) payable {
        require(_client != address(0) && _provider != address(0) && _agent != address(0), "invalid parties");
        client = _client;
        provider = _provider;
        agent = _agent;
        arbitrationContract = _arbitrationContract;
        durationSeconds = _durationSeconds;
        vault = DeFiVault1Pct(_vault);
        fundedAmount = msg.value;

        if (msg.value > 0) {
            // deposit initial funds into vault immediately
            vault.deposit{value: msg.value}();
            emit Funded(msg.sender, msg.value);
        }
    }

    receive() external payable {
        fund();
    }

    /// @notice Client adds more funds; automatically deposited into vault.
    function fund() public payable onlyClient {
        require(msg.value > 0, "no eth");
        fundedAmount += msg.value;
        vault.deposit{value: msg.value}();
        emit Funded(msg.sender, msg.value);
    }

    /// @notice Client starts the service timeline.
    function startService() external onlyClient {
        require(startTimestamp == 0, "already started");
        startTimestamp = block.timestamp;
        lastClaimedTimestamp = startTimestamp;
        emit Started(startTimestamp, durationSeconds);
    }

    /// @notice Agent pauses service (endpoint down).
    function pauseService() external onlyAgent {
        require(!paused, "already paused");
        paused = true;
        pausedAt = block.timestamp;
        emit Paused(msg.sender, pausedAt);
    }

    /// @notice Agent resumes service (endpoint back).
    function resumeService() external onlyAgent {
        require(paused, "not paused");
        accumulatedPausedSeconds += (block.timestamp - pausedAt);
        paused = false;
        pausedAt = 0;
        emit Resumed(msg.sender, block.timestamp);
    }

    /// @notice Provider claims pro-rata payment; pulls from vault (includes +1% bonus automatically).
    function claim() external onlyProvider nonReentrant {
        require(startTimestamp != 0, "not started");
        uint256 nowTs = block.timestamp;
        uint256 effectiveNow = paused ? pausedAt : nowTs;

        uint256 endTime = startTimestamp + durationSeconds + accumulatedPausedSeconds;
        if (effectiveNow > endTime) effectiveNow = endTime;
        require(effectiveNow > lastClaimedTimestamp, "nothing to claim");

        uint256 elapsed = effectiveNow - lastClaimedTimestamp;
        uint256 claimAmount = (fundedAmount * elapsed) / durationSeconds;
        uint256 currentVaultBalance = vault.balanceOf(address(this));
        if (claimAmount > currentVaultBalance) claimAmount = currentVaultBalance;


        lastClaimedTimestamp = effectiveNow;

        // Withdraw from vault directly to this escrow (vault adds 1% bonus)
        vault.withdraw(claimAmount);

        // Transfer full amount (with 1% bonus included) to provider
        uint256 payout = address(this).balance;
        (bool ok, ) = provider.call{value: payout}("");
        require(ok, "transfer failed");

        emit Claimed(payout, effectiveNow);
    }

    /// @notice Client renews (extend time + add funds)
    function renew(uint256 extraSeconds) external payable onlyClient {
        require(msg.value > 0, "no funds");
        fundedAmount += msg.value;
        durationSeconds += extraSeconds;
        vault.deposit{value: msg.value}();
        emit Renewed(msg.value, durationSeconds);
    }

    /// @notice Any party may open arbitration, sending all funds from vault.
    function openArbitration() external {
        require(msg.sender == client || msg.sender == provider || msg.sender == agent, "not party");
        uint256 bal = vault.balanceOf(address(this));
        if (bal > 0) {
            vault.withdraw(bal);
        }
        uint256 escrowBal = address(this).balance;
        if (escrowBal > 0 && arbitrationContract != address(0)) {
            (bool ok, ) = payable(arbitrationContract).call{value: escrowBal}("");
            require(ok, "send arbitration failed");
            emit SentToArbitration(arbitrationContract, escrowBal);
        }
    }

    /// @notice set or update arbitration contract (client or agent)
    function setArbitrationContract(address _arb) external {
        require(msg.sender == client || msg.sender == agent, "not permitted");
        arbitrationContract = _arb;
    }

    /// @notice emergency: view vault balance of this escrow
    function vaultBalance() external view returns (uint256) {
        return vault.balanceOf(address(this));
    }

    /// @notice contract's ETH balance (after vault withdraw, before payout)
    function escrowBalance() external view returns (uint256) {
        return address(this).balance;
    }
}
