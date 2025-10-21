# Requirements Document

## Introduction

This feature implements the complete integration between the Pakt platform and the PaktEscrowV2 smart contract deployed on the 0G network. The integration enables a three-party escrow system where clients can create and fund escrow orders, freelancers can submit deliverables, an AI agent verifies the authenticity of submissions, and payments are released upon client approval. The system uses native 0G tokens for payments and integrates with 0G decentralized storage for verification proofs.

The integration bridges the existing Pakt contract management system (with INR-based pricing and milestone tracking) with the on-chain escrow mechanism, providing a seamless experience for all parties while maintaining security and transparency through blockchain technology.

## Requirements

### Requirement 1: Client Order Creation and Funding

**User Story:** As a client, I want to create and fund an escrow order on the blockchain in a single transaction, so that my payment is securely held until the freelancer completes the work.

#### Acceptance Criteria

1. WHEN a client initiates escrow creation from a signed contract THEN the system SHALL generate a unique orderHash from the contract data
2. WHEN the client confirms the transaction THEN the system SHALL call the smart contract's createAndDeposit function with the correct parameters (orderHash, freelancer address, escrow amount, storage fee, project name)
3. WHEN the transaction is submitted THEN the system SHALL send the exact total amount (escrowAmount + storageFee) in native 0G tokens
4. WHEN the transaction is confirmed THEN the system SHALL update the contract record in the database with the orderHash, transaction hash, and deposit status
5. WHEN the order is created on-chain THEN the order state SHALL be ACTIVE
6. IF the transaction fails THEN the system SHALL display a clear error message and allow the client to retry
7. WHEN the order is successfully created THEN the system SHALL emit an OrderCreatedAndFunded event that can be tracked

### Requirement 2: Order Hash Generation and Management

**User Story:** As a developer, I want a reliable method to generate and manage unique order hashes, so that each escrow order can be uniquely identified both on-chain and off-chain.

#### Acceptance Criteria

1. WHEN generating an orderHash THEN the system SHALL use a combination of client address, freelancer address, timestamp, and random value
2. WHEN an orderHash is generated THEN it SHALL be a valid bytes32 value (64 hexadecimal characters)
3. WHEN an orderHash is created THEN the system SHALL store it in the contract database record for future reference
4. WHEN retrieving order details THEN the system SHALL use the stored orderHash to query the smart contract
5. IF an orderHash collision occurs THEN the system SHALL regenerate a new unique hash
6. WHEN displaying order information THEN the system SHALL show the orderHash to users for transparency

### Requirement 3: Freelancer Deliverable Submission

**User Story:** As a freelancer, I want to submit my completed work (GitHub repository and deployment URL) through the platform, so that it can be verified and I can receive payment.

#### Acceptance Criteria

1. WHEN a freelancer navigates to an active order THEN the system SHALL display a deliverable submission form
2. WHEN submitting deliverables THEN the freelancer SHALL provide a GitHub repository URL
3. WHEN submitting deliverables THEN the freelancer MAY optionally provide a deployment URL
4. WHEN the freelancer submits the form THEN the system SHALL validate that the URLs are properly formatted
5. WHEN submission is successful THEN the system SHALL store the submission data in the database
6. WHEN submission is successful THEN the system SHALL trigger the agent verification workflow
7. WHEN submission is recorded THEN the system SHALL update the milestone deliverable status to "submitted"

### Requirement 4: AI Agent Verification Workflow

**User Story:** As the system, I want an AI agent to automatically verify that submitted deliverables are authentic and belong to the freelancer, so that clients can trust the work before approving payment.

#### Acceptance Criteria

1. WHEN a deliverable is submitted THEN the system SHALL trigger the LangGraph agent verification workflow
2. WHEN the agent runs THEN it SHALL verify that the GitHub repository exists and is accessible
3. WHEN the agent runs THEN it SHALL verify that the repository belongs to the freelancer's GitHub account
4. WHEN a deployment URL is provided THEN the agent SHALL verify that the deployment is live and accessible
5. WHEN a deployment URL is provided THEN the agent SHALL verify that the deployment is connected to the latest commit in the provided repository
6. WHEN verification checks complete THEN the agent SHALL compile a verification result with all checks performed
7. WHEN verification is successful THEN the agent SHALL call the smart contract's verifyDeliverable function with isValid=true
8. WHEN verification fails THEN the agent SHALL call the smart contract's verifyDeliverable function with isValid=false
9. WHEN calling verifyDeliverable THEN the agent SHALL provide a verificationDetails string (0G storage CID or JSON)
10. WHEN the verification transaction is confirmed THEN the system SHALL update the database with the verification status and timestamp
11. IF the agent encounters an error THEN the system SHALL log the error and mark verification as failed

### Requirement 5: Client Payment Approval

**User Story:** As a client, I want to review verified deliverables and approve payment release, so that I can ensure the work meets my requirements before the freelancer receives funds.

#### Acceptance Criteria

1. WHEN an order is in VERIFIED state THEN the client SHALL see an option to approve payment
2. WHEN an order is not in VERIFIED state THEN the approve payment option SHALL be disabled
3. WHEN the client clicks approve payment THEN the system SHALL call the smart contract's approvePayment function
4. WHEN the approvePayment transaction is confirmed THEN the order state SHALL change to APPROVED
5. WHEN payment is approved THEN the system SHALL update the database with approval status and timestamp
6. WHEN payment is approved THEN the system SHALL notify the freelancer that funds are ready for withdrawal
7. IF the transaction fails THEN the system SHALL display an error and allow retry

### Requirement 6: Freelancer Fund Withdrawal

**User Story:** As a freelancer, I want to withdraw my earned funds after the client approves payment, so that I can receive compensation for my completed work.

#### Acceptance Criteria

1. WHEN an order is in APPROVED state THEN the freelancer SHALL see a withdraw funds button
2. WHEN an order is not in APPROVED state THEN the withdraw option SHALL be disabled
3. WHEN the freelancer clicks withdraw THEN the system SHALL call the smart contract's withdrawFunds function
4. WHEN the withdrawal transaction is confirmed THEN the escrow amount SHALL be transferred to the freelancer's wallet
5. WHEN withdrawal is successful THEN the order state SHALL change to COMPLETED
6. WHEN withdrawal is successful THEN the system SHALL update the database with completion status and timestamp
7. WHEN the order is completed THEN the system SHALL update the milestone payment status to "released"
8. IF the transaction fails THEN the system SHALL display an error and allow retry

### Requirement 7: Order State Synchronization

**User Story:** As a developer, I want the platform database to stay synchronized with the on-chain order state, so that users always see accurate and up-to-date information.

#### Acceptance Criteria

1. WHEN any state-changing transaction is confirmed THEN the system SHALL query the smart contract for the updated order state
2. WHEN the order state is retrieved THEN the system SHALL update the corresponding database record
3. WHEN displaying order information THEN the system SHALL show the current on-chain state
4. WHEN a user views an order THEN the system SHALL fetch the latest state from the blockchain
5. IF there is a discrepancy between database and blockchain THEN the blockchain state SHALL be considered authoritative
6. WHEN state changes occur THEN the system SHALL update the stageHistory in the contract record

### Requirement 8: Transaction Error Handling and Retry

**User Story:** As a user, I want clear error messages and the ability to retry failed transactions, so that temporary issues don't prevent me from completing my actions.

#### Acceptance Criteria

1. WHEN a transaction fails THEN the system SHALL display a user-friendly error message explaining the failure
2. WHEN a transaction fails due to insufficient funds THEN the error message SHALL indicate the required amount
3. WHEN a transaction fails due to wrong order state THEN the error message SHALL indicate the current state and required state
4. WHEN a transaction fails THEN the system SHALL provide a retry button
5. WHEN a user retries a transaction THEN the system SHALL use the same parameters as the original attempt
6. WHEN multiple retries fail THEN the system SHALL suggest contacting support
7. WHEN a transaction is pending THEN the system SHALL show a loading state with transaction hash

### Requirement 9: Contract ABI and Configuration Management

**User Story:** As a developer, I want centralized management of contract ABIs and addresses, so that the integration is maintainable and can be easily updated.

#### Acceptance Criteria

1. WHEN the application starts THEN it SHALL load the PaktEscrowV2 ABI from a centralized configuration file
2. WHEN making contract calls THEN the system SHALL use the configured contract address
3. WHEN the contract is redeployed THEN updating the address in configuration SHALL update all integrations
4. WHEN different networks are used THEN the system SHALL support network-specific contract addresses
5. WHEN contract functions are called THEN the system SHALL use TypeScript types derived from the ABI
6. WHEN the ABI changes THEN the system SHALL provide type-safe access to new functions

### Requirement 10: Agent Wallet and Private Key Management

**User Story:** As a system administrator, I want secure management of the verification agent's private key, so that automated verifications can occur without compromising security.

#### Acceptance Criteria

1. WHEN the agent service starts THEN it SHALL load the agent private key from environment variables
2. WHEN the agent private key is stored THEN it SHALL never be committed to version control
3. WHEN the agent makes transactions THEN it SHALL use the configured private key to sign
4. WHEN the agent address is needed THEN it SHALL be derived from the private key
5. IF the private key is missing THEN the agent service SHALL fail to start with a clear error message
6. WHEN the agent is updated in the contract THEN the system SHALL support updating the configured private key

### Requirement 11: Event Monitoring and Notifications

**User Story:** As a user, I want to receive notifications when important events occur in my escrow orders, so that I can take timely action.

#### Acceptance Criteria

1. WHEN an OrderCreatedAndFunded event is emitted THEN the system SHALL notify the freelancer
2. WHEN a DeliverableVerified event is emitted THEN the system SHALL notify the client
3. WHEN a VerificationFailed event is emitted THEN the system SHALL notify both parties
4. WHEN a PaymentApproved event is emitted THEN the system SHALL notify the freelancer
5. WHEN a WithdrawalCompleted event is emitted THEN the system SHALL notify the client
6. WHEN events are processed THEN the system SHALL update the database accordingly
7. WHEN monitoring events THEN the system SHALL handle blockchain reorganizations gracefully

### Requirement 12: Integration with Existing Contract Data Model

**User Story:** As a developer, I want the escrow integration to work seamlessly with the existing contract data model, so that all contract information remains consistent.

#### Acceptance Criteria

1. WHEN creating an escrow order THEN the system SHALL use data from the existing contract record (parties, amounts, project details)
2. WHEN storing escrow data THEN the system SHALL update the escrow section of the contract JSON
3. WHEN converting INR to 0G tokens THEN the system SHALL use the stored exchange rate
4. WHEN updating order status THEN the system SHALL update both the escrow object and milestone statuses
5. WHEN displaying contract information THEN the system SHALL show both off-chain and on-chain data
6. WHEN milestones are completed THEN the system SHALL track which milestone corresponds to which on-chain order
