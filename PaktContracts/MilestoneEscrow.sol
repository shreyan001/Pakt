// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./DeFiVault1Pct.sol";

/**
 * @title MilestoneEscrow
 * @notice Individualized escrow with AI-agent verification, milestone payments,
 *         arbitration routing, and integrated 1%-bonus DeFi vault.
 */
contract MilestoneEscrow {
    /*──────────────────────────────
      ░  STRUCTS  &  STATE
    ──────────────────────────────*/
    struct Milestone {
        uint256 amount;          // agreed payment for this milestone
        string description;      // optional short text
        bool verifiedByAgent;    // agent validated work
        bool clientApproved;     // client accepted milestone
        bool paid;               // already withdrawn
        string verificationHash; // IPFS / storage proof
    }

    address public client;
    address payable public freelancer;
    address public agent;
    address public arbitrationContract;

    DeFiVault1Pct public vault; // +1 % yield vault
    uint256 public storageFee;        // optional extra fee bucket
    Milestone[] public milestones;

    enum State { CREATED, FUNDED, DISPUTED, CLOSED }
    State public state;

    /*──────────────────────────────
      ░  EVENTS
    ──────────────────────────────*/
    event Funded(address indexed by, uint256 amount);
    event MilestoneAdded(uint256 indexed id, uint256 amount, string desc);
    event MilestoneVerified(uint256 indexed id, address agent, string hash, bool passed);
    event MilestoneApproved(uint256 indexed id, address client);
    event MilestonePaid(uint256 indexed id, address freelancer, uint256 amount);
    event SentToArbitration(address arbitration, uint256 amount);
    event ContractStateChanged(State newState);

    /*──────────────────────────────
      ░  MODIFIERS
    ──────────────────────────────*/
    modifier onlyClient() { require(msg.sender == client, "only client"); _; }
    modifier onlyAgent() { require(msg.sender == agent, "only agent"); _; }
    modifier onlyFreelancer() { require(msg.sender == freelancer, "only freelancer"); _; }
    modifier nonReentrant() { require(_locked == 1, "reentrant"); _locked = 2; _; _locked = 1; }
    uint256 private _locked = 1;

    /*──────────────────────────────
      ░  CONSTRUCTOR
    ──────────────────────────────*/
    constructor(
        address _client,
        address payable _freelancer,
        address _agent,
        address _arbitration,
        address payable _vault,
        uint256 _storageFee
    ) payable {
        require(_client != address(0) && _freelancer != address(0) && _agent != address(0), "invalid parties");
        client = _client;
        freelancer = _freelancer;
        agent = _agent;
        arbitrationContract = _arbitration;
        vault = DeFiVault1Pct(_vault);
        storageFee = _storageFee;
        state = State.CREATED;

        if (msg.value > 0) {
            vault.deposit{value: msg.value}();
            emit Funded(msg.sender, msg.value);
            state = State.FUNDED;
        }
    }

    receive() external payable { fund(); }

    /*──────────────────────────────
      ░  CORE  FLOW
    ──────────────────────────────*/

    /// client adds more funds; all deposits go straight into the vault
    function fund() public payable onlyClient {
        require(msg.value > 0, "no eth");
        vault.deposit{value: msg.value}();
        emit Funded(msg.sender, msg.value);
        if (state == State.CREATED) state = State.FUNDED;
    }

    /// add a milestone (before work starts)
    function addMilestone(uint256 amount, string calldata desc) external onlyClient {
        require(state == State.CREATED || state == State.FUNDED, "cannot add now");
        milestones.push(Milestone({
            amount: amount,
            description: desc,
            verifiedByAgent: false,
            clientApproved: false,
            paid: false,
            verificationHash: ""
        }));
        emit MilestoneAdded(milestones.length - 1, amount, desc);
    }

    /// agent verifies deliverable
    function verifyMilestone(uint256 id, string calldata proof, bool passed) external onlyAgent {
        require(id < milestones.length, "bad id");
        Milestone storage m = milestones[id];
        require(!m.paid, "already paid");
        m.verifiedByAgent = passed;
        m.verificationHash = proof;
        emit MilestoneVerified(id, msg.sender, proof, passed);
    }

    /// client approves payment after verification
    function approveMilestone(uint256 id) external onlyClient {
        Milestone storage m = milestones[id];
        require(m.verifiedByAgent, "not verified");
        require(!m.clientApproved, "already approved");
        m.clientApproved = true;
        emit MilestoneApproved(id, msg.sender);
    }

    /// freelancer claims approved milestone; withdraws from vault (+1%)
    function claimMilestone(uint256 id) external onlyFreelancer nonReentrant {
        require(state != State.DISPUTED, "disputed");
        Milestone storage m = milestones[id];
        require(m.clientApproved && m.verifiedByAgent, "not approved");
        require(!m.paid, "paid");

        uint256 currentVaultBalance = vault.balanceOf(address(this));
        require(currentVaultBalance >= m.amount, "vault low");

        m.paid = true;

        // pull funds (adds +1 %) from vault to escrow
        vault.withdraw(m.amount);

        uint256 payout = address(this).balance;
        (bool ok, ) = freelancer.call{value: payout}("");
        require(ok, "transfer failed");

        emit MilestonePaid(id, freelancer, payout);

        if (_allPaid()) {
            state = State.CLOSED;
            emit ContractStateChanged(state);
        }
    }

    /*──────────────────────────────
      ░  UTILITIES
    ──────────────────────────────*/

    function _allPaid() internal view returns (bool) {
        for (uint i; i < milestones.length; i++) if (!milestones[i].paid) return false;
        return true;
    }

    /*──────────────────────────────
      ░  ARBITRATION
    ──────────────────────────────*/

    function openDispute() external {
        require(msg.sender == client || msg.sender == freelancer || msg.sender == agent, "not party");
        state = State.DISPUTED;
        emit ContractStateChanged(state);
    }

    function sendToArbitration() external nonReentrant {
        require(state == State.DISPUTED, "not disputed");
        uint256 bal = vault.balanceOf(address(this));
        if (bal > 0) vault.withdraw(bal);
        uint256 escrowBal = address(this).balance;
        if (escrowBal > 0 && arbitrationContract != address(0)) {
            (bool ok, ) = payable(arbitrationContract).call{value: escrowBal}("");
            require(ok, "send failed");
            emit SentToArbitration(arbitrationContract, escrowBal);
        }
    }

    /*──────────────────────────────
      ░  VIEWS
    ──────────────────────────────*/

    function milestoneCount() external view returns (uint256) { return milestones.length; }

    function vaultBalanceOfEscrow() external view returns (uint256) {
        return vault.balanceOf(address(this));
    }

    function contractBalance() external view returns (uint256) {
        return address(this).balance;
    }
}
