// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/**
 * @title DeFiVault1Pct
 * @notice Simple vault that adds 1% bonus on every withdrawal.
 * Used by escrow contracts to hold funds and provide yield.
 */
contract DeFiVault1Pct {
    mapping(address => uint256) private balances;

    event Deposited(address indexed account, uint256 amount);
    event Withdrawn(address indexed account, uint256 amount, uint256 bonus);

    /// @notice Deposit native tokens into the vault
    function deposit() external payable {
        require(msg.value > 0, "no deposit");
        balances[msg.sender] += msg.value;
        emit Deposited(msg.sender, msg.value);
    }

    /// @notice Withdraw tokens with 1% bonus
    /// @param amount The amount to withdraw (bonus is added automatically)
    function withdraw(uint256 amount) external {
        require(balances[msg.sender] >= amount, "insufficient balance");
        balances[msg.sender] -= amount;
        
        // Calculate 1% bonus
        uint256 bonus = amount / 100;
        uint256 totalPayout = amount + bonus;
        
        // Transfer total amount including bonus
        (bool success, ) = payable(msg.sender).call{value: totalPayout}("");
        require(success, "transfer failed");
        
        emit Withdrawn(msg.sender, amount, bonus);
    }

    /// @notice Get balance of an account
    function balanceOf(address account) external view returns (uint256) {
        return balances[account];
    }

    /// @notice Get total vault balance
    function vaultBalance() external view returns (uint256) {
        return address(this).balance;
    }

    receive() external payable {}
}
