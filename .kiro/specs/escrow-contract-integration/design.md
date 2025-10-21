# Design Document

## Overview

The Escrow Smart Contract Integration connects the Pakt platform with the PaktEscrowV2 smart contract deployed on the 0G blockchain. This integration enables a complete three-party escrow workflow where clients deposit funds, freelancers submit deliverables, an AI agent verifies authenticity, and payments are released upon approval.

The design follows a hybrid architecture combining:
- **Frontend (Viem)**: Client and freelancer wallet interactions
- **Backend Agent (Ethers.js)**: Automated verification service
- **LangGraph Agent**: GitHub and deployment verification logic
- **Database Sync**: Maintaining consistency between on-chain and off-chain data

## Architecture

### System Components

```
┌─────────────────────────────────────────────────────────────────┐
│                         Frontend (Next.js)                       │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐          │
│  │   Client     │  │  Freelancer  │  │   Contract   │          │
│  │   Dashboard  │  │   Dashboard  │  │   Details    │          │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘          │
│         │                  │                  │                   │
│         └──────────────────┴──────────────────┘                   │
│                            │                                      │
│                    ┌───────▼────────┐                            │
│                    │  Viem Client   │                            │
│                    │  (Web3 Layer)  │                            │
│                    └───────┬────────┘                            │
└────────────────────────────┼─────────────────────────────────────┘
                             │
                    ┌────────▼────────┐
                    │   0G Blockchain │
                    │  PaktEscrowV2 │
                    │     Contract    │
                    └────────┬────────┘
                             │
        ┌────────────────────┼────────────────────┐
        │                    │                    │
┌───────▼────────┐  ┌────────▼────────┐  ┌───────▼────────┐
│   Database     │  │  Backend Agent  │  │  Event Monitor │
│   (Postgres)   │  │  (Ethers.js)    │  │   (Webhooks)   │
│                │  │                 │  │                │
│  - Contracts   │  │  - Verification │  │  - State Sync  │
│  - Milestones  │  │  - LangGraph    │  │  - Notifications│
│  - Users       │  │  - GitHub Check │  │                │
└────────────────┘  └─────────────────┘  └────────────────┘
```

### Data Flow

#### 1. Order Creation Flow
```
Client → Frontend → Viem → Smart Contract → Database
  │                                            │
  └────────── Confirmation ←──────────────────┘
```

#### 2. Verification Flow
```
Freelancer → Submit Deliverable → Database
                                      │
                                      ▼
                            Backend Agent (LangGraph)
                                      │
                    ┌─────────────────┴─────────────────┐
                    │                                   │
              GitHub API                          Deployment Check
                    │                                   │
                    └─────────────────┬─────────────────┘
                                      ▼
                            Verification Result
                                      │
                                      ▼
                            Smart Contract (verifyDeliverable)
                                      │
                                      ▼
                                  Database Update
```

#### 3. Payment Release Flow
```
Client → Approve Payment → Smart Contract → APPROVED State
                                                    │
                                                    ▼
Freelancer → Withdraw Funds → Smart Contract → Transfer 0G Tokens
                                                    │
                                                    ▼
                                            COMPLETED State
```

## Components and Interfaces

### 1. Contract ABI Module

**Location**: `src/lib/contracts/PaktABI.ts`

```typescript
// Contract ABI with full type safety
export const Pakt_ABI = [...] as const;

// Order state enum matching Solidity
export enum OrderState {
  PENDING = 0,
  ACTIVE = 1,
  VERIFIED = 2,
  APPROVED = 3,
  COMPLETED = 4,
  DISPUTED = 5,
  VERIFICATION_FAILED = 6,
}

// TypeScript interfaces
export interface Order {
  orderHash: Hash;
  initiator: Address;
  freelancer: Address;
  escrowAmount: bigint;
  storageFee: bigint;
  projectName: string;
  currentState: OrderState;
  createdTimestamp: bigint;
  verifiedTimestamp: bigint;
  completedTimestamp: bigint;
  verificationDetails: string;
}

export interface CreateOrderParams {
  freelancerAddress: Address;
  escrowAmount: string; // in 0G tokens
  storageFee: string;
  projectName: string;
}
```

### 2. Frontend Client Module (Viem)

**Location**: `src/lib/contracts/PaktClient.ts`

```typescript
/**
 * Client-side contract interactions using Viem
 * Handles wallet connections and transaction signing
 */

// Core functions
export async function createAndDepositOrder(
  walletClient: WalletClient,
  params: CreateOrderParams
): Promise<{ txHash: Hash; orderHash: Hash }>;

export async function approvePayment(
  walletClient: WalletClient,
  orderHash: Hash
): Promise<Hash>;

export async function withdrawFunds(
  walletClient: WalletClient,
  orderHash: Hash
): Promise<Hash>;

export async function getOrderDetails(
  publicClient: PublicClient,
  orderHash: Hash
): Promise<Order>;

export async function waitForTransaction(
  publicClient: PublicClient,
  hash: Hash
): Promise<TransactionReceipt>;
```

**Key Design Decisions**:
- Uses Viem for modern, type-safe Web3 interactions
- Separates wallet client (write) from public client (read)
- Generates orderHash client-side for immediate reference
- Handles native 0G token transfers via `value` parameter
- Provides transaction waiting utilities

### 3. Backend Agent Module (Ethers.js)

**Location**: `src/lib/agents/verificationAgent.ts`

```typescript
/**
 * Backend verification agent using Ethers.js
 * Runs automated checks and updates contract state
 */

export interface VerificationResult {
  isValid: boolean;
  verificationDetails: string;
  githubUrl?: string;
  deploymentUrl?: string;
  checksPerformed: string[];
  timestamp: number;
}

// Core agent functions
export async function verifyDeliverableOnChain(
  orderHash: string,
  verificationResult: VerificationResult
): Promise<string>;

export async function performVerificationChecks(
  orderHash: string,
  githubUrl: string,
  deploymentUrl?: string
): Promise<VerificationResult>;

export async function verifyAndApproveDeliverable(
  orderHash: string,
  githubUrl: string,
  deploymentUrl?: string
): Promise<{ txHash: string; verificationResult: VerificationResult }>;
```

**Key Design Decisions**:
- Uses Ethers.js for backend Node.js environment
- Agent wallet managed via environment variables
- Integrates with LangGraph for intelligent verification
- Stores verification proofs on 0G storage (future enhancement)
- Provides comprehensive verification result objects

### 4. LangGraph Verification Integration

**Location**: `src/ai/verificationGraph.ts`

```typescript
/**
 * LangGraph agent for deliverable verification
 * Performs automated checks on GitHub and deployments
 */

export interface VerificationState {
  orderHash: string;
  githubUrl: string;
  deploymentUrl?: string;
  checks: VerificationCheck[];
  result: VerificationResult;
}

export interface VerificationCheck {
  name: string;
  status: 'pending' | 'passed' | 'failed';
  details: string;
}

// Verification workflow
export async function runVerificationWorkflow(
  orderHash: string,
  githubUrl: string,
  deploymentUrl?: string
): Promise<VerificationResult>;
```

**Verification Checks**:
1. **GitHub Repository Accessibility**: Verify repo exists and is public/accessible
2. **Repository Ownership**: Confirm repo belongs to freelancer's GitHub account
3. **Commit Activity**: Check for recent commits matching project timeline
4. **Deployment Accessibility**: Verify deployment URL is live (if provided)
5. **Deployment-Repo Connection**: Verify deployment matches latest commit
6. **Code Quality**: Basic checks for project structure and completeness

### 5. API Routes

**Location**: `src/app/api/escrow/`

#### Create Order Endpoint
```typescript
// POST /api/escrow/create
interface CreateOrderRequest {
  contractId: string;
  freelancerAddress: string;
  escrowAmount: string;
  storageFee: string;
}

interface CreateOrderResponse {
  success: boolean;
  orderHash: string;
  txHash: string;
  error?: string;
}
```

#### Submit Deliverable Endpoint
```typescript
// POST /api/escrow/submit-deliverable
interface SubmitDeliverableRequest {
  orderHash: string;
  contractId: string;
  githubUrl: string;
  deploymentUrl?: string;
}

interface SubmitDeliverableResponse {
  success: boolean;
  message: string;
  verificationTriggered: boolean;
}
```

#### Verify Deliverable Endpoint (Internal)
```typescript
// POST /api/escrow/verify (Called by agent)
interface VerifyDeliverableRequest {
  orderHash: string;
  githubUrl: string;
  deploymentUrl?: string;
}

interface VerifyDeliverableResponse {
  success: boolean;
  txHash: string;
  verificationStatus: 'APPROVED' | 'REJECTED';
  details: VerificationResult;
}
```

### 6. Database Schema Extensions

**Contract Table Updates**:
```typescript
interface ContractEscrowData {
  // Existing fields...
  escrow: {
    amounts: {
      inr: { totalAmount: string; currency: string; exchangeRate: string };
      "0G": { totalAmount: string; currency: string; network: string };
    };
    contractAddress: string;
    orderHash?: string; // NEW: Link to on-chain order
    deposit: {
      deposited: boolean;
      depositedAmount: string;
      depositedAt: string | null;
      transactionHash: string | null;
      orderHash?: string; // NEW: On-chain order reference
    };
    // ... rest of escrow fields
  };
}
```

**New Escrow Orders Table**:
```sql
CREATE TABLE escrow_orders (
  id SERIAL PRIMARY KEY,
  order_hash VARCHAR(66) UNIQUE NOT NULL,
  contract_id VARCHAR(255) NOT NULL,
  initiator_address VARCHAR(42) NOT NULL,
  freelancer_address VARCHAR(42) NOT NULL,
  escrow_amount DECIMAL(20, 8) NOT NULL,
  storage_fee DECIMAL(20, 8) NOT NULL,
  project_name VARCHAR(255) NOT NULL,
  current_state INTEGER NOT NULL,
  created_timestamp BIGINT NOT NULL,
  verified_timestamp BIGINT,
  completed_timestamp BIGINT,
  verification_details TEXT,
  github_url TEXT,
  deployment_url TEXT,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  FOREIGN KEY (contract_id) REFERENCES contracts(id)
);

CREATE INDEX idx_order_hash ON escrow_orders(order_hash);
CREATE INDEX idx_contract_id ON escrow_orders(contract_id);
CREATE INDEX idx_current_state ON escrow_orders(current_state);
```

## Data Models

### Order Hash Generation

```typescript
/**
 * Generates a unique bytes32 order hash
 * Format: keccak256(initiator + freelancer + timestamp + random)
 */
function generateOrderHash(
  initiatorAddress: Address,
  freelancerAddress: Address
): Hash {
  const timestamp = Date.now();
  const randomValue = Math.random().toString(36).substring(7);
  const hashString = `${initiatorAddress}-${freelancerAddress}-${timestamp}-${randomValue}`;
  
  // Convert to bytes32 format
  return `0x${Buffer.from(hashString)
    .toString('hex')
    .padStart(64, '0')}` as Hash;
}
```

### Currency Conversion

```typescript
/**
 * Converts INR to 0G tokens using stored exchange rate
 */
function convertINRto0G(
  amountINR: number,
  exchangeRate: number
): string {
  const zeroGAmount = amountINR / exchangeRate;
  return zeroGAmount.toFixed(8); // 8 decimal precision
}

/**
 * Calculates total escrow amount including fees
 */
function calculateEscrowAmounts(paymentAmount: number) {
  const platformFee = paymentAmount * 0.025; // 2.5%
  const storageFee = paymentAmount * 0.005; // 0.5%
  const totalINR = paymentAmount + platformFee + storageFee;
  
  return {
    escrowAmount: paymentAmount,
    platformFee,
    storageFee,
    totalINR,
    totalZeroG: convertINRto0G(totalINR, 85.0) // Example rate
  };
}
```

### State Machine

```typescript
/**
 * Order state transitions
 */
const STATE_TRANSITIONS = {
  PENDING: ['ACTIVE'],
  ACTIVE: ['VERIFIED', 'VERIFICATION_FAILED'],
  VERIFIED: ['APPROVED'],
  APPROVED: ['COMPLETED'],
  COMPLETED: [],
  DISPUTED: ['VERIFIED', 'VERIFICATION_FAILED'],
  VERIFICATION_FAILED: ['ACTIVE'] // Allow resubmission
};

function canTransition(
  currentState: OrderState,
  targetState: OrderState
): boolean {
  return STATE_TRANSITIONS[currentState].includes(targetState);
}
```

## Error Handling

### Frontend Error Handling

```typescript
/**
 * Standardized error handling for contract interactions
 */
class EscrowError extends Error {
  constructor(
    message: string,
    public code: string,
    public details?: any
  ) {
    super(message);
    this.name = 'EscrowError';
  }
}

// Error codes
export const ERROR_CODES = {
  INSUFFICIENT_FUNDS: 'INSUFFICIENT_FUNDS',
  INVALID_STATE: 'INVALID_STATE',
  TRANSACTION_FAILED: 'TRANSACTION_FAILED',
  WALLET_NOT_CONNECTED: 'WALLET_NOT_CONNECTED',
  INVALID_ORDER_HASH: 'INVALID_ORDER_HASH',
  VERIFICATION_FAILED: 'VERIFICATION_FAILED',
  NETWORK_ERROR: 'NETWORK_ERROR',
};

// Error handler
export function handleContractError(error: any): EscrowError {
  if (error.message.includes('insufficient funds')) {
    return new EscrowError(
      'Insufficient 0G tokens in wallet',
      ERROR_CODES.INSUFFICIENT_FUNDS,
      error
    );
  }
  
  if (error.message.includes('Order not in active state')) {
    return new EscrowError(
      'Order is not in the correct state for this action',
      ERROR_CODES.INVALID_STATE,
      error
    );
  }
  
  // Default error
  return new EscrowError(
    'Transaction failed. Please try again.',
    ERROR_CODES.TRANSACTION_FAILED,
    error
  );
}
```

### Backend Error Handling

```typescript
/**
 * Agent verification error handling
 */
export async function safeVerification(
  orderHash: string,
  githubUrl: string,
  deploymentUrl?: string
): Promise<VerificationResult> {
  try {
    return await performVerificationChecks(
      orderHash,
      githubUrl,
      deploymentUrl
    );
  } catch (error) {
    console.error('Verification error:', error);
    
    // Return failed verification instead of throwing
    return {
      isValid: false,
      verificationDetails: `Verification failed: ${error.message}`,
      githubUrl,
      deploymentUrl,
      checksPerformed: ['error_occurred'],
      timestamp: Date.now(),
    };
  }
}
```

### Transaction Retry Logic

```typescript
/**
 * Retry failed transactions with exponential backoff
 */
export async function retryTransaction<T>(
  fn: () => Promise<T>,
  maxRetries: number = 3,
  baseDelay: number = 1000
): Promise<T> {
  for (let attempt = 0; attempt < maxRetries; attempt++) {
    try {
      return await fn();
    } catch (error) {
      if (attempt === maxRetries - 1) throw error;
      
      const delay = baseDelay * Math.pow(2, attempt);
      console.log(`Retry attempt ${attempt + 1} after ${delay}ms`);
      await new Promise(resolve => setTimeout(resolve, delay));
    }
  }
  
  throw new Error('Max retries exceeded');
}
```

## Testing Strategy

### Unit Tests

**Contract Client Tests** (`PaktClient.test.ts`):
- Order hash generation uniqueness
- Currency conversion accuracy
- Parameter validation
- Error handling for invalid inputs

**Verification Agent Tests** (`verificationAgent.test.ts`):
- GitHub API mocking
- Deployment check logic
- Verification result formatting
- Error scenarios

### Integration Tests

**End-to-End Flow Tests**:
1. Create order → Verify on-chain state
2. Submit deliverable → Trigger verification
3. Agent verification → Update contract
4. Approve payment → Verify state change
5. Withdraw funds → Verify token transfer

**Database Sync Tests**:
- On-chain state matches database
- Event processing updates records
- Concurrent update handling

### Mock Data

```typescript
// Mock contract for testing
export const mockContract = {
  address: '0x1234567890123456789012345678901234567890',
  orderHash: '0xabcdef...',
  initiator: '0x742d35Cc6634C0532925a3b8D4C0C8b3C2e1e1e1',
  freelancer: '0x8ba1f109551bD432803012645Hac136c22C177e9',
  escrowAmount: parseEther('1.0'),
  storageFee: parseEther('0.1'),
};

// Mock verification result
export const mockVerificationSuccess = {
  isValid: true,
  verificationDetails: 'All checks passed',
  githubUrl: 'https://github.com/user/repo',
  deploymentUrl: 'https://app.example.com',
  checksPerformed: [
    'GitHub accessibility',
    'Repository ownership',
    'Deployment live',
    'Deployment-repo connection'
  ],
  timestamp: Date.now(),
};
```

## Security Considerations

### 1. Private Key Management
- Agent private key stored in environment variables only
- Never logged or exposed in responses
- Separate keys for testnet and mainnet
- Key rotation procedures documented

### 2. Transaction Validation
- All amounts validated before submission
- Order state checked before state transitions
- Wallet address validation (checksum)
- Prevent replay attacks with unique order hashes

### 3. Verification Security
- GitHub API rate limiting handled
- Deployment checks timeout after 30 seconds
- Malicious URL detection
- Verification results stored immutably

### 4. Frontend Security
- Wallet connection validation
- Transaction signing user confirmation
- Display amounts in both INR and 0G
- Clear error messages without exposing internals

## Performance Optimization

### 1. Caching Strategy
```typescript
// Cache order details to reduce RPC calls
const orderCache = new Map<Hash, { order: Order; timestamp: number }>();
const CACHE_TTL = 60000; // 1 minute

export async function getCachedOrder(
  publicClient: PublicClient,
  orderHash: Hash
): Promise<Order> {
  const cached = orderCache.get(orderHash);
  
  if (cached && Date.now() - cached.timestamp < CACHE_TTL) {
    return cached.order;
  }
  
  const order = await getOrderDetails(publicClient, orderHash);
  orderCache.set(orderHash, { order, timestamp: Date.now() });
  
  return order;
}
```

### 2. Batch Operations
- Fetch multiple orders in single RPC call
- Batch event processing
- Aggregate database updates

### 3. Async Processing
- Verification runs asynchronously
- Event monitoring in background worker
- Non-blocking UI updates

## Deployment Strategy

### Environment Configuration

```env
# Smart Contract
Pakt_CONTRACT_ADDRESS=0x...
ZEROG_RPC_URL=https://rpc.0g.network
ZEROG_CHAIN_ID=16600

# Agent Wallet
AGENT_PRIVATE_KEY=0x...
AGENT_ADDRESS=0x...

# Services
DATABASE_URL=postgresql://...
REDIS_URL=redis://...

# External APIs
GITHUB_API_TOKEN=ghp_...
```

### Deployment Steps

1. **Deploy Smart Contract** (if not deployed)
   - Deploy PaktEscrowV2 to 0G testnet
   - Verify contract on block explorer
   - Update contract address in config

2. **Setup Agent Wallet**
   - Generate new wallet for agent
   - Fund with 0G tokens for gas
   - Update agent address in contract

3. **Deploy Backend Services**
   - Deploy verification agent service
   - Setup event monitoring workers
   - Configure database migrations

4. **Deploy Frontend**
   - Build Next.js application
   - Configure environment variables
   - Deploy to Vercel/hosting platform

5. **Testing**
   - Run end-to-end tests on testnet
   - Verify all flows work correctly
   - Monitor for errors

## Future Enhancements

1. **0G Storage Integration**: Store verification proofs on 0G decentralized storage
2. **Multi-Milestone Support**: Handle multiple milestones per contract
3. **Dispute Resolution**: Implement on-chain dispute mechanism
4. **Gas Optimization**: Batch operations to reduce gas costs
5. **Event Webhooks**: Real-time notifications via webhooks
6. **Mobile Support**: React Native integration
7. **Multi-Chain**: Support other EVM chains beyond 0G
