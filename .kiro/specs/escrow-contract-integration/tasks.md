# Implementation Plan

- [x] 1. Set up contract ABI and configuration infrastructure


  - Create centralized contract ABI file with TypeScript types
  - Define OrderState enum and Order interface
  - Create configuration file for contract addresses and network settings
  - Add environment variables for contract address and RPC URL
  - _Requirements: 9.1, 9.2, 9.3, 9.4, 9.5, 9.6_




- [x] 2. Implement order hash generation utility

  - Create generateOrderHash function with timestamp and random value
  - Implement bytes32 formatting (64 hex characters with 0x prefix)
  - Add validation to ensure uniqueness
  - Create helper function to validate order hash format
  - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5, 2.6_

- [x] 3. Build frontend Viem client module for contract interactions






- [ ] 3.1 Implement createAndDepositOrder function
  - Accept WalletClient and CreateOrderParams
  - Generate unique orderHash using utility function
  - Convert INR amounts to 0G tokens using parseEther
  - Calculate total deposit (escrowAmount + storageFee)
  - Call smart contract's createAndDeposit with value parameter
  - Return transaction hash and orderHash

  - _Requirements: 1.1, 1.2, 1.3, 1.7_


- [ ] 3.2 Implement getOrderDetails function
  - Accept PublicClient and orderHash
  - Call smart contract's getOrder function
  - Parse and return Order object with proper types

  - Handle non-existent orders gracefully

  - _Requirements: 2.4, 7.1, 7.2, 7.3, 7.4_

- [ ] 3.3 Implement approvePayment function
  - Accept WalletClient and orderHash
  - Call smart contract's approvePayment function

  - Return transaction hash

  - Handle state validation errors
  - _Requirements: 5.1, 5.2, 5.3, 5.7_

- [ ] 3.4 Implement withdrawFunds function
  - Accept WalletClient and orderHash

  - Call smart contract's withdrawFunds function

  - Return transaction hash
  - Handle state validation errors
  - _Requirements: 6.1, 6.2, 6.3, 6.8_

- [ ] 3.5 Implement waitForTransaction utility
  - Accept PublicClient and transaction hash

  - Use waitForTransactionReceipt from Viem
  - Return transaction receipt
  - Handle timeout scenarios
  - _Requirements: 1.4, 8.7_

- [ ] 4. Create error handling utilities
  - Define EscrowError class with code and details
  - Create ERROR_CODES constant object
  - Implement handleContractError function to parse Viem errors
  - Add user-friendly error messages for common scenarios
  - Implement retry logic with exponential backoff
  - _Requirements: 8.1, 8.2, 8.3, 8.4, 8.5, 8.6, 8.7_

- [ ] 5. Build backend agent verification module with Ethers.js
- [ ] 5.1 Set up agent wallet and signer
  - Create getAgentSigner function loading private key from env
  - Initialize JsonRpcProvider with 0G RPC URL
  - Create Wallet instance with provider
  - Add validation for missing private key
  - _Requirements: 10.1, 10.2, 10.3, 10.4, 10.5, 10.6_

- [ ] 5.2 Implement verifyDeliverableOnChain function
  - Accept orderHash and VerificationResult
  - Get agent signer and contract instance
  - Format verification details as JSON string
  - Call contract's verifyDeliverable with isValid flag
  - Wait for transaction confirmation
  - Return transaction hash
  - _Requirements: 4.7, 4.8, 4.9, 4.10_

- [ ] 5.3 Implement performVerificationChecks function
  - Accept orderHash, githubUrl, and optional deploymentUrl
  - Verify GitHub repository exists and is accessible
  - Verify repository ownership matches freelancer
  - Check deployment URL is live (if provided)
  - Verify deployment connects to latest commit
  - Compile VerificationResult with all checks
  - Handle errors gracefully and return failed result
  - _Requirements: 4.2, 4.3, 4.4, 4.5, 4.11_

- [ ] 5.4 Create verifyAndApproveDeliverable workflow function
  - Call performVerificationChecks to run all checks
  - Call verifyDeliverableOnChain with results
  - Return both transaction hash and verification result
  - Log verification status for monitoring
  - _Requirements: 4.1, 4.6_

- [ ] 6. Implement LangGraph verification agent
  - Create VerificationState interface with orderHash, URLs, and checks
  - Define VerificationCheck interface with name, status, details
  - Build LangGraph workflow with verification nodes
  - Implement GitHub API integration for repo checks
  - Implement deployment URL accessibility check
  - Implement commit verification logic
  - Create runVerificationWorkflow function as entry point
  - _Requirements: 4.2, 4.3, 4.4, 4.5_

- [ ] 7. Create database schema and migrations
- [ ] 7.1 Extend contracts table with escrow fields
  - Add orderHash field to escrow.deposit object
  - Update TypeScript interface for ContractEscrowData
  - Create migration to add new fields
  - _Requirements: 12.1, 12.2, 12.5_

- [ ] 7.2 Create escrow_orders table
  - Define table schema with all order fields
  - Add foreign key to contracts table
  - Create indexes on order_hash, contract_id, current_state
  - Add timestamps for created_at and updated_at
  - Create migration file
  - _Requirements: 7.1, 7.2, 7.6_

- [ ] 8. Build API routes for escrow operations
- [ ] 8.1 Create POST /api/escrow/create endpoint
  - Accept contractId, freelancerAddress, escrowAmount, storageFee


  - Fetch contract data from database
  - Validate contract exists and is signed
  - Return orderHash and instructions for client
  - Handle errors and return appropriate status codes
  - _Requirements: 1.1, 1.4, 12.1_

- [ ] 8.2 Create POST /api/escrow/submit-deliverable endpoint
  - Accept orderHash, contractId, githubUrl, deploymentUrl
  - Validate URLs are properly formatted
  - Store submission in database
  - Trigger agent verification workflow asynchronously
  - Return success response immediately
  - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5, 3.6, 3.7_

- [ ] 8.3 Create POST /api/escrow/verify endpoint (internal)
  - Accept orderHash, githubUrl, deploymentUrl
  - Call verifyAndApproveDeliverable from agent module
  - Update database with verification result
  - Return transaction hash and verification status
  - Handle agent errors gracefully
  - _Requirements: 4.10, 4.11_

- [ ] 8.4 Create GET /api/escrow/order/[orderHash] endpoint
  - Fetch order details from smart contract
  - Fetch additional data from database
  - Merge on-chain and off-chain data
  - Return complete order information
  - _Requirements: 7.3, 7.4, 12.5_

- [ ] 9. Implement state synchronization logic
  - Create syncOrderState function to fetch from blockchain
  - Update database record with latest on-chain state
  - Add stageHistory entry for state changes
  - Handle discrepancies (blockchain is authoritative)
  - Create background job to periodically sync all active orders
  - _Requirements: 7.1, 7.2, 7.3, 7.4, 7.5, 7.6_

- [ ] 10. Build event monitoring system
- [ ] 10.1 Set up event listeners for contract events
  - Listen for OrderCreatedAndFunded events
  - Listen for DeliverableVerified events
  - Listen for VerificationFailed events
  - Listen for PaymentApproved events
  - Listen for WithdrawalCompleted events
  - _Requirements: 11.1, 11.2, 11.3, 11.4, 11.5_

- [ ] 10.2 Implement event processing handlers
  - Process each event type and update database

  - Send notifications to relevant parties
  - Update contract stageHistory
  - Handle blockchain reorganizations
  - _Requirements: 11.6, 11.7_

- [ ] 11. Create frontend UI components for escrow workflow
- [x] 11.1 Build CreateEscrowButton component

  - Display button when contract is signed
  - Show loading state during transaction
  - Call createAndDepositOrder on click
  - Display transaction hash and orderHash on success
  - Show error messages on failure
  - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.6, 1.7_


- [ ] 11.2 Build SubmitDeliverableForm component
  - Display form for freelancer when order is ACTIVE
  - Input fields for GitHub URL and deployment URL
  - Validate URLs before submission
  - Call submit-deliverable API endpoint
  - Show success message and verification status
  - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5, 3.6_


- [ ] 11.3 Build ApprovePaymentButton component
  - Display button when order is VERIFIED
  - Disable when order is not in VERIFIED state
  - Call approvePayment function on click
  - Show transaction confirmation
  - Update UI to show APPROVED state

  - _Requirements: 5.1, 5.2, 5.3, 5.4, 5.5, 5.7_

- [ ] 11.4 Build WithdrawFundsButton component
  - Display button when order is APPROVED
  - Disable when order is not in APPROVED state
  - Call withdrawFunds function on click
  - Show transaction confirmation
  - Update UI to show COMPLETED state
  - _Requirements: 6.1, 6.2, 6.3, 6.4, 6.5, 6.6, 6.8_

- [ ] 11.5 Build OrderStatusDisplay component
  - Fetch and display current order state
  - Show state-specific information and actions
  - Display verification details when available
  - Show transaction hashes for transparency
  - Auto-refresh state periodically
  - _Requirements: 7.3, 7.4, 12.5_

- [ ] 12. Implement currency conversion utilities
  - Create convertINRto0G function with exchange rate
  - Create calculateEscrowAmounts function for fees
  - Add validation for amount ranges
  - Display amounts in both INR and 0G in UI
  - _Requirements: 12.3, 12.4_

- [ ] 13. Add comprehensive error handling to UI
  - Display user-friendly error messages
  - Show specific guidance for insufficient funds
  - Show specific guidance for wrong order state
  - Provide retry buttons for failed transactions
  - Show loading states during pending transactions
  - Suggest support contact after multiple failures
  - _Requirements: 8.1, 8.2, 8.3, 8.4, 8.5, 8.6, 8.7_

- [ ] 14. Create integration tests for complete workflows
  - Test order creation flow end-to-end
  - Test deliverable submission and verification
  - Test payment approval flow
  - Test fund withdrawal flow
  - Test state synchronization
  - Test error scenarios and recovery
  - _Requirements: All requirements_

- [ ] 15. Set up environment configuration and deployment
  - Add all required environment variables to .env.example
  - Document configuration in README
  - Create deployment guide with step-by-step instructions
  - Set up agent wallet and fund with 0G tokens
  - Deploy and verify smart contract (if needed)
  - Configure database migrations
  - Deploy backend services
  - Deploy frontend application
  - _Requirements: 10.1, 10.2, 10.3, 10.4, 10.5_

- [ ] 16. Add monitoring and logging
  - Log all contract interactions with transaction hashes
  - Log verification workflow steps and results
  - Monitor agent wallet balance
  - Set up alerts for failed verifications
  - Track gas usage and costs
  - Create dashboard for system health
  - _Requirements: 4.11, 11.6_

- [ ] 17. Create user documentation
  - Write guide for clients on creating escrow orders
  - Write guide for freelancers on submitting deliverables
  - Document the verification process
  - Create FAQ for common issues
  - Document error messages and solutions
  - _Requirements: 8.1, 8.2, 8.3_
