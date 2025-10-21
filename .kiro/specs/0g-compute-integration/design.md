# Design Document

## Overview

This design integrates 0G Compute Network's secure inference capability into the Pakt contract creation workflow. The system will detect when information collection is complete via a signal in the graph state, then transition from the chat interface to execute secure AI inference using 0G's SDK. The architecture ensures data privacy, verifiable execution, and a smooth user experience.

## Architecture

### High-Level Flow

```
User Chat → Information Collection → Signal Detection → 0G Secure Inference → Contract Display
     ↓              ↓                      ↓                    ↓                    ↓
CreateChat    Graph State          Page State Update    InferenceView      ContractReview
Component     Management           (showInference)       Component          Component
```

### Component Hierarchy

```
CreatePage (src/app/create/page.tsx)
├── State Management
│   ├── showInference: boolean
│   ├── collectedData: ContractData
│   ├── inferenceResult: string
│   └── verificationProof: string
├── Conditional Rendering
│   ├── If !showInference → CreateChat + CreateDiagram
│   └── If showInference → InferenceView
└── 0G Compute Integration
    └── executeSecureInference()
```

## Components and Interfaces

### 1. Modified CreatePage Component

**Location:** `src/app/create/page.tsx`

**New State Variables:**
```typescript
const [showInference, setShowInference] = useState(false);
const [collectedData, setCollectedData] = useState<any>(null);
const [inferenceResult, setInferenceResult] = useState<string | null>(null);
const [verificationProof, setVerificationProof] = useState<any>(null);
const [inferenceError, setInferenceError] = useState<string | null>(null);
const [isInferenceLoading, setIsInferenceLoading] = useState(false);
```

**New Handler:**
```typescript
const handleGraphStateUpdate = (newGraphState: GraphState, progress: number) => {
  setGraphState(newGraphState);
  setContractProgress(progress);
  
  // Check for inference ready signal
  if (newGraphState.inferenceReady && newGraphState.collectedData) {
    setCollectedData(newGraphState.collectedData);
    setShowInference(true);
    executeSecureInference(newGraphState.collectedData);
  }
};
```

**Conditional Rendering Logic:**
```typescript
{!showInference ? (
  // Existing chat + diagram layout
  <div className="flex w-full max-w-7xl gap-8">
    <CreateChat ... />
    <CreateDiagram ... />
  </div>
) : (
  // New inference view
  <InferenceView
    collectedData={collectedData}
    inferenceResult={inferenceResult}
    verificationProof={verificationProof}
    isLoading={isInferenceLoading}
    error={inferenceError}
    onRetry={() => executeSecureInference(collectedData)}
    onBack={() => setShowInference(false)}
  />
)}
```

### 2. 0G Compute Service

**Location:** `src/services/ogCompute.ts` (new file)

**Purpose:** Encapsulate all 0G Compute SDK interactions

**Interface:**
```typescript
export interface OGComputeConfig {
  tokenId: string;
  executor: string;
  verificationMode: 'TEE' | 'ZKP';
  rpcUrl?: string;
}

export interface InferenceResult {
  output: string;
  proof: any;
  timestamp: number;
  verificationMode: string;
}

export class OGComputeService {
  private config: OGComputeConfig;
  private client: any; // 0G Compute client instance
  
  constructor(config: OGComputeConfig);
  async initialize(): Promise<void>;
  async executeSecure(input: any): Promise<InferenceResult>;
  async verifyProof(proof: any): Promise<boolean>;
}
```

**Implementation Details:**
- Initialize SDK with environment variables for tokenId and executor
- Handle connection errors with retry logic
- Format input data for the inference model
- Parse and validate inference results
- Extract and format verification proofs

### 3. InferenceView Component

**Location:** `src/components/create/InferenceView.tsx` (new file)

**Props Interface:**
```typescript
interface InferenceViewProps {
  collectedData: any;
  inferenceResult: string | null;
  verificationProof: any;
  isLoading: boolean;
  error: string | null;
  onRetry: () => void;
  onBack: () => void;
}
```

**UI States:**
1. **Loading State:**
   - Animated spinner
   - Progress messages ("Initializing secure environment...", "Executing inference...", "Generating verification proof...")
   - Estimated time remaining

2. **Success State:**
   - Generated contract display
   - Verification proof badge
   - Proof details (expandable)
   - Action buttons: "Review Contract", "Edit Details", "Proceed to Signing"

3. **Error State:**
   - Error message display
   - Error details (expandable)
   - "Retry" button
   - "Back to Chat" button

**Layout:**
```
┌─────────────────────────────────────────┐
│  Secure Contract Generation             │
│  ─────────────────────────────────────  │
│                                         │
│  [Loading Spinner / Result Display]    │
│                                         │
│  Verification Proof: ✓ TEE Verified    │
│  [Proof Details]                        │
│                                         │
│  [Action Buttons]                       │
└─────────────────────────────────────────┘
```

### 4. Modified Graph State Interface

**Location:** `src/lib/types.ts`

**New Properties:**
```typescript
export interface GraphState {
  // ... existing properties
  inferenceReady?: boolean;
  collectedData?: {
    projectName: string;
    clientName: string;
    email: string;
    paymentAmount: number;
    projectDescription: string;
    deadline: string;
    walletAddress: string;
    [key: string]: any;
  };
}
```

### 5. Backend Graph Modification

**Location:** `src/ai/graph.ts`

**New Node:** `checkInferenceReadiness`

**Purpose:** Determine if all required information is collected and set the signal

**Logic:**
```typescript
const checkInferenceReadiness = (state: GraphState): GraphState => {
  const requiredFields = [
    'projectName',
    'clientName', 
    'email',
    'paymentAmount',
    'projectDescription',
    'deadline'
  ];
  
  const collectedFields = state.collectedFields || {};
  const allFieldsCollected = requiredFields.every(
    field => collectedFields[field] === true
  );
  
  if (allFieldsCollected) {
    return {
      ...state,
      inferenceReady: true,
      collectedData: extractCollectedData(state)
    };
  }
  
  return state;
};
```

**Integration Point:** Add this node after the information collection validation node

## Data Models

### CollectedData Model

```typescript
interface CollectedContractData {
  // Identity
  userType: 'client' | 'freelancer';
  clientName: string;
  email: string;
  walletAddress: string;
  
  // Project Details
  projectName: string;
  projectDescription: string;
  category?: string;
  
  // Payment Terms
  paymentAmount: number;
  currency: string;
  deadline: string;
  
  // Additional Context
  specialRequirements?: string;
  milestones?: Array<{
    title: string;
    amount: number;
    deadline: string;
  }>;
}
```

### InferenceInput Model

```typescript
interface InferenceInput {
  prompt: string; // Formatted prompt for contract generation
  context: CollectedContractData;
  template: string; // Contract template type
  verificationMode: 'TEE' | 'ZKP';
}
```

### InferenceOutput Model

```typescript
interface InferenceOutput {
  contractText: string;
  metadata: {
    generatedAt: number;
    model: string;
    verificationMode: string;
  };
  proof: {
    type: 'TEE' | 'ZKP';
    hash: string;
    signature: string;
    timestamp: number;
    details: any;
  };
}
```

## Error Handling

### Error Types

1. **SDK Initialization Errors**
   - Invalid credentials
   - Network connectivity issues
   - SDK version mismatch

2. **Inference Execution Errors**
   - Timeout errors
   - Invalid input format
   - Model unavailable
   - Insufficient resources

3. **Verification Errors**
   - Proof validation failure
   - Signature mismatch
   - Expired proof

### Error Handling Strategy

```typescript
async function executeSecureInference(data: any) {
  setIsInferenceLoading(true);
  setInferenceError(null);
  
  try {
    // Initialize service
    const ogService = new OGComputeService({
      tokenId: process.env.NEXT_PUBLIC_OG_TOKEN_ID!,
      executor: process.env.NEXT_PUBLIC_OG_EXECUTOR!,
      verificationMode: 'TEE'
    });
    
    await ogService.initialize();
    
    // Execute inference
    const result = await ogService.executeSecure({
      prompt: formatContractPrompt(data),
      context: data,
      template: 'escrow-contract'
    });
    
    // Verify proof
    const isValid = await ogService.verifyProof(result.proof);
    if (!isValid) {
      throw new Error('Proof verification failed');
    }
    
    setInferenceResult(result.output);
    setVerificationProof(result.proof);
    
  } catch (error) {
    console.error('Inference error:', error);
    setInferenceError(
      error instanceof Error 
        ? error.message 
        : 'An unexpected error occurred'
    );
  } finally {
    setIsInferenceLoading(false);
  }
}
```

### User-Facing Error Messages

- **SDK Init Failure:** "Unable to connect to secure inference service. Please check your connection and try again."
- **Inference Timeout:** "Contract generation is taking longer than expected. Please retry."
- **Proof Verification Failure:** "Unable to verify the generated contract. Please retry for a secure result."
- **Network Error:** "Network connection lost. Please check your internet and retry."

## Testing Strategy

### Unit Tests

1. **OGComputeService Tests**
   - Test SDK initialization with valid/invalid credentials
   - Test inference execution with mock data
   - Test proof verification logic
   - Test error handling for various failure scenarios

2. **InferenceView Component Tests**
   - Test rendering in loading state
   - Test rendering with successful result
   - Test rendering with error state
   - Test user interactions (retry, back buttons)

3. **State Management Tests**
   - Test signal detection logic
   - Test state transitions (chat → inference)
   - Test data preservation across transitions

### Integration Tests

1. **End-to-End Flow Test**
   - Complete information collection
   - Trigger inference
   - Verify contract generation
   - Validate proof display

2. **Error Recovery Test**
   - Simulate inference failure
   - Test retry functionality
   - Verify data persistence

3. **Graph State Integration Test**
   - Test signal propagation from graph to UI
   - Test data extraction from graph state
   - Test state synchronization

### Manual Testing Checklist

- [ ] Complete information collection and verify signal triggers
- [ ] Verify smooth UI transition from chat to inference view
- [ ] Test inference execution with real 0G Compute SDK
- [ ] Verify proof display and expandable details
- [ ] Test error scenarios (network failure, timeout, invalid proof)
- [ ] Test retry functionality
- [ ] Test back navigation to chat
- [ ] Verify data persistence across transitions
- [ ] Test with both TEE and ZKP verification modes
- [ ] Verify mobile responsiveness

## Environment Configuration

### Required Environment Variables

```env
# 0G Compute Configuration
NEXT_PUBLIC_OG_TOKEN_ID=your_token_id_here
NEXT_PUBLIC_OG_EXECUTOR=your_executor_address_here
NEXT_PUBLIC_OG_RPC_URL=https://rpc.0g.ai
NEXT_PUBLIC_OG_VERIFICATION_MODE=TEE # or ZKP
```

### Configuration File

**Location:** `src/config/ogCompute.ts`

```typescript
export const ogComputeConfig = {
  tokenId: process.env.NEXT_PUBLIC_OG_TOKEN_ID || '',
  executor: process.env.NEXT_PUBLIC_OG_EXECUTOR || '',
  rpcUrl: process.env.NEXT_PUBLIC_OG_RPC_URL || 'https://rpc.0g.ai',
  verificationMode: (process.env.NEXT_PUBLIC_OG_VERIFICATION_MODE || 'TEE') as 'TEE' | 'ZKP',
  timeout: 60000, // 60 seconds
  retryAttempts: 3,
  retryDelay: 2000 // 2 seconds
};
```

## Security Considerations

1. **Credential Management**
   - Store sensitive credentials in environment variables
   - Never expose tokenId or executor in client-side code
   - Use server-side API routes for sensitive operations

2. **Data Privacy**
   - Ensure collected data is encrypted in transit
   - Verify TEE/ZKP proofs before displaying results
   - Clear sensitive data from state when no longer needed

3. **Proof Validation**
   - Always verify proofs before accepting inference results
   - Display verification status prominently to users
   - Log verification failures for security monitoring

4. **Rate Limiting**
   - Implement client-side rate limiting for inference requests
   - Handle rate limit errors gracefully
   - Provide clear feedback to users

## Performance Considerations

1. **Lazy Loading**
   - Load 0G Compute SDK only when needed (after signal detection)
   - Use dynamic imports for InferenceView component

2. **Caching**
   - Cache SDK initialization to avoid repeated setup
   - Store inference results in session storage for recovery

3. **Timeout Handling**
   - Set reasonable timeout for inference operations (60s)
   - Provide progress updates during long-running operations
   - Allow users to cancel long-running operations

4. **Optimistic UI**
   - Show immediate feedback when inference starts
   - Display progress indicators
   - Preload success/error states for smooth transitions
