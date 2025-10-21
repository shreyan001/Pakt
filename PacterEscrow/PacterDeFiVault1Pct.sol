// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/**
 * @title PaktDeFiVault1Pct
 * @notice Minimal DeFi vault mock that stores ETH per-caller and pays a 1% bonus on every withdrawal.
 * - deposit() : deposit ETH credited to msg.sender (typically the escrow contract)
 * - withdraw(amount) : withdraw `amount` + 1% bonus to caller (if vault balance allows)
 * - simulateYield / topUpBonusPool : helpers for hackathon/demo
 *
 * Security notes:
 * - Bonus is funded from the vault's ETH balance. Keep the vault topped up.
 * - Integer math truncates; bonus = amount / 100.
 * - Use reentrancy guard when integrating into complex flows (escrow contract already should).
 */
contract PaktDeFiVault1Pct {
    mapping(address => uint256) private balances; // depositor (escrow contract) => deposited ETH
    address public owner;

    event Deposited(address indexed depositor, uint256 amount);
    event Withdrawn(address indexed depositor, uint256 amount, uint256 bonus);
    event SimulatedYield(address indexed escrow, uint256 amount);
    event ToppedUp(address indexed by, uint256 amount);
    event OwnerChanged(address indexed oldOwner, address indexed newOwner);

    modifier onlyOwner() {
        require(msg.sender == owner, "PaktVault: only owner");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    // accept direct ETH deposits (credited to msg.sender)
    receive() external payable {
        balances[msg.sender] += msg.value;
        emit Deposited(msg.sender, msg.value);
    }

    /// @notice deposit ETH and credit to caller's vault balance
    function deposit() external payable {
        require(msg.value > 0, "no eth");
        balances[msg.sender] += msg.value;
        emit Deposited(msg.sender, msg.value);
    }

    /**
     * @notice Withdraw `amount` plus 1% bonus to caller.
     * bonus = amount / 100 (integer division)
     * Requirements:
     *  - caller must have `balances[caller] >= amount` (their deposited principal)
     *  - vault (this contract) must have enough total ETH to pay amount+bonus
     */
    function withdraw(uint256 amount) external {
        require(amount > 0, "zero");
        uint256 depositorBalance = balances[msg.sender];
        require(depositorBalance >= amount, "insufficient depositor balance");

        uint256 bonus = amount / 100; // 1%
        uint256 totalOut = amount + bonus;

        // Check vault has enough ETH overall to pay totalOut
        require(address(this).balance >= totalOut, "vault: insufficient total balance for bonus");

        // Effects: reduce depositor principal by `amount` (bonus is paid from vault pool)
        balances[msg.sender] = depositorBalance - amount;

        // Interaction: send totalOut to caller
        (bool ok, ) = payable(msg.sender).call{value: totalOut}("");
        require(ok, "transfer failed");

        emit Withdrawn(msg.sender, amount, bonus);
    }

    /// @notice view balance credited to a depositor (escrow contract)
    function balanceOf(address depositor) external view returns (uint256) {
        return balances[depositor];
    }

    /// @notice Owner can top-up the vault to ensure bonus coverage. Funds are not tied to any depositor.
    function topUpBonusPool() external payable onlyOwner {
        require(msg.value > 0, "no eth");
        emit ToppedUp(msg.sender, msg.value);
    }

    /// @notice For demo: simulate yield credited to a specific escrow's deposited balance
    /// (owner only). This increases that escrow's `balances[escrow]`.
    function simulateYield(address escrow, uint256 amount) external onlyOwner {
        require(escrow != address(0), "zero escrow");
        require(amount > 0, "zero");
        // owner must send ETH along with call to actually fund vault balance,
        // OR owner can call this after topping up; here we just credit the mapping
        // and expect owner to ensure vault has enough ETH on-chain separately.
        balances[escrow] += amount;
        emit SimulatedYield(escrow, amount);
    }

    /// @notice Emergency withdraw of excess funds by owner (for hackathon/cleanup)
    function ownerWithdraw(uint256 amount) external onlyOwner {
        require(amount <= address(this).balance, "insufficient vault");
        (bool ok, ) = payable(owner).call{value: amount}("");
        require(ok, "owner withdraw failed");
    }

    function changeOwner(address newOwner) external onlyOwner {
        require(newOwner != address(0), "zero");
        address old = owner;
        owner = newOwner;
        emit OwnerChanged(old, newOwner);
    }

    /// @notice return full vault ETH balance
    function vaultBalance() external view returns (uint256) {
        return address(this).balance;
    }
}
