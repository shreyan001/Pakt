// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/**
 * @title PaktV1
 * @dev A decentralized escrow contract with AI agent verification.
 * Uses native tokens (POL on Polygon) for payments.
 * Implements three-party escrow: Initiator, Freelancer, and Verification Agent.
 */
contract PaktV1 {
    // --- State Variables ---

    address public owner; // For emergency functions and configuration
    address public verificationAgent; // AI agent that verifies deliverables

    enum OrderState { PENDING, ACTIVE, VERIFIED, APPROVED, COMPLETED, DISPUTED, VERIFICATION_FAILED }

    struct Order {
        bytes32 orderHash;
        address initiator;
        address payable freelancer;
        uint256 escrowAmount;
        string projectName;
        OrderState currentState;
        uint256 createdTimestamp;
        uint256 verifiedTimestamp;
        uint256 completedTimestamp;
        string verificationDetails; // Hash/URL containing verification results
    }

    mapping(bytes32 => Order) public orders;

    // --- Events ---

    event OrderCreatedAndFunded(bytes32 indexed orderHash, address indexed initiator, address indexed freelancer, uint256 totalAmount);
    event DeliverableVerified(bytes32 indexed orderHash, address verificationAgent, uint256 timestamp, string verificationDetails);
    event VerificationFailed(bytes32 indexed orderHash, address verificationAgent, uint256 timestamp, string reason);
    event PaymentApproved(bytes32 indexed orderHash, address approver, uint256 timestamp);
    event WithdrawalCompleted(bytes32 indexed orderHash, address freelancer, uint256 amount);
    event OrderStateChanged(bytes32 indexed orderHash, OrderState newState);
    event VerificationAgentUpdated(address indexed oldAgent, address indexed newAgent);

    // --- Modifiers ---

    modifier onlyOwner() {
        require(msg.sender == owner, "Pakt: Caller is not the owner");
        _;
    }

    modifier onlyVerificationAgent() {
        require(msg.sender == verificationAgent, "Pakt: Caller is not the verification agent");
        _;
    }

    modifier onlyInitiator(bytes32 orderHash) {
        require(msg.sender == orders[orderHash].initiator, "Pakt: Caller is not the initiator");
        _;
    }

    modifier onlyFreelancer(bytes32 orderHash) {
        require(msg.sender == orders[orderHash].freelancer, "Pakt: Caller is not the freelancer");
        _;
    }
    
    modifier validateOrderExists(bytes32 orderHash) {
        require(orders[orderHash].createdTimestamp != 0, "Pakt: Order does not exist");
        _;
    }

    // --- Constructor ---

    constructor(address _verificationAgent) {
        owner = msg.sender;
        verificationAgent = _verificationAgent;
    }

    // --- Core Decentralized Function ---

    /**
     * @dev Allows the initiator to create and fund an escrow order in a single transaction.
     * Payment is made in native tokens (POL on Polygon).
     * @param orderHash A unique hash representing the order (can be generated client-side).
     * @param freelancer The address of the freelancer.
     * @param escrowAmount The amount for the freelancer in native tokens.
     * @param projectName A string to identify the project.
     */
    function createAndDeposit(
        bytes32 orderHash,
        address payable freelancer,
        uint256 escrowAmount,
        string memory projectName
    ) external payable {
        require(orderHash != 0, "Pakt: Invalid order hash");
        require(orders[orderHash].createdTimestamp == 0, "Pakt: Order already exists");
        require(freelancer != address(0), "Pakt: Invalid freelancer address");
        require(msg.value == escrowAmount, "Pakt: Incorrect token amount sent");

        orders[orderHash] = Order({
            orderHash: orderHash,
            initiator: msg.sender,
            freelancer: freelancer,
            escrowAmount: escrowAmount,
            projectName: projectName,
            currentState: OrderState.ACTIVE,
            createdTimestamp: block.timestamp,
            verifiedTimestamp: 0,
            completedTimestamp: 0,
            verificationDetails: ""
        });

        emit OrderCreatedAndFunded(orderHash, msg.sender, freelancer, escrowAmount);
        emit OrderStateChanged(orderHash, OrderState.ACTIVE);
    }
    
    // --- Agent Verification Function ---

    /**
     * @dev Allows the verification agent to verify deliverables and unlock payment approval window.
     * This function validates that the freelancer has provided genuine output (e.g., GitHub deployment).
     * Only after successful verification can the client approve payment.
     * @param orderHash The unique order identifier.
     * @param verificationDetails Storage hash/URL containing verification results and proof.
     * @param isValid Whether the deliverable passed verification checks.
     */
    function verifyDeliverable(
        bytes32 orderHash,
        string memory verificationDetails,
        bool isValid
    ) external validateOrderExists(orderHash) onlyVerificationAgent {
        Order storage order = orders[orderHash];
        require(order.currentState == OrderState.ACTIVE, "Pakt: Order not in active state for verification");

        order.verificationDetails = verificationDetails;
        order.verifiedTimestamp = block.timestamp;

        if (isValid) {
            order.currentState = OrderState.VERIFIED;
            emit DeliverableVerified(orderHash, msg.sender, block.timestamp, verificationDetails);
            emit OrderStateChanged(orderHash, OrderState.VERIFIED);
        } else {
            order.currentState = OrderState.VERIFICATION_FAILED;
            emit VerificationFailed(orderHash, msg.sender, block.timestamp, verificationDetails);
            emit OrderStateChanged(orderHash, OrderState.VERIFICATION_FAILED);
        }
    }

    // --- Other Core Functions ---

    /**
     * @dev Allows the initiator to approve payment after agent verification.
     * Payment window only opens after successful verification by the agent.
     * @param orderHash The unique order identifier.
     */
    function approvePayment(bytes32 orderHash) external validateOrderExists(orderHash) onlyInitiator(orderHash) {
        Order storage order = orders[orderHash];
        require(order.currentState == OrderState.VERIFIED, "Pakt: Order must be verified before approval");

        order.currentState = OrderState.APPROVED;

        emit PaymentApproved(orderHash, msg.sender, block.timestamp);
        emit OrderStateChanged(orderHash, OrderState.APPROVED);
    }

    /**
     * @dev Allows freelancer to withdraw funds after payment approval.
     * Uses native token transfer (POL on Polygon).
     * @param orderHash The unique order identifier.
     */
    function withdrawFunds(bytes32 orderHash) external validateOrderExists(orderHash) onlyFreelancer(orderHash) {
        Order storage order = orders[orderHash];
        require(order.currentState == OrderState.APPROVED, "Pakt: Payment not approved for withdrawal");

        uint256 amount = order.escrowAmount;
        
        order.currentState = OrderState.COMPLETED;
        order.completedTimestamp = block.timestamp;
        
        // Use call for native token transfer (safer than transfer)
        (bool success, ) = order.freelancer.call{value: amount}("");
        require(success, "Pakt: Token transfer to freelancer failed");

        emit WithdrawalCompleted(orderHash, msg.sender, amount);
        emit OrderStateChanged(orderHash, OrderState.COMPLETED);
    }

    // --- Administrative Functions ---

    /**
     * @dev Allows owner to update the verification agent address.
     * @param newAgent The new verification agent address.
     */
    function updateVerificationAgent(address newAgent) external onlyOwner {
        require(newAgent != address(0), "Pakt: Invalid agent address");
        address oldAgent = verificationAgent;
        verificationAgent = newAgent;
        emit VerificationAgentUpdated(oldAgent, newAgent);
    }

    // --- View Functions ---

    function getOrder(bytes32 orderHash) external view returns (Order memory) {
        return orders[orderHash];
    }

    function getVerificationDetails(bytes32 orderHash) external view returns (string memory) {
        return orders[orderHash].verificationDetails;
    }

    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }

    // --- Fallback Functions ---

    /**
     * @dev Reject direct token transfers to contract.
     * All deposits must go through createAndDeposit function.
     */
    receive() external payable {
        revert("Pakt: Use createAndDeposit function");
    }

    fallback() external payable {
        revert("Pakt: Use createAndDeposit function");
    }
}
