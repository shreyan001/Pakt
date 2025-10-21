# Design Document

## Overview

This design consolidates all contract creation functionality into the `CreateChat.tsx` component, eliminating separate pages and creating a seamless, inline contract generation experience. The solution integrates contract generation, 0G Compute processing, and contract preview directly into the chat interface, maintaining conversational context throughout the entire flow.

The key architectural change is moving from a redirect-based flow (chat → `/contract/create` page → `/contract/[id]` page) to an inline flow where everything happens within the chat component itself.

## Architecture

### Current Flow (To Be Replaced)
```
CreateChat → sessionStorage → /contract/create page → Backend API → /contract/[id] page
```

### New Flow (Consolidated)
```
CreateChat → Inline Generation → Inline Preview → /contract/[id] page (on user action)
```

### Component Hierarchy

```
CreateChat.tsx
├── Chat Messages (existing)
├── Contract Generation Message (new)
│   ├── Loading State
│   ├── Progress Indicators
│   └── Status Updates
├── Contract Preview Message (new)
│   ├── Verification Proof Display
│   ├── Contract Text Preview
│   └── Action Buttons
└── Input Area (existing)
```

## Components and Interfaces

### 1. CreateChat.tsx Enhancements

#### New State Variables

```typescript
// Contract generation state
const [isGeneratingContract, setIsGeneratingContract] = useState(false);
const [generationProgress, setGenerationProgress] = useState<{
  stage: string;
  message: string;
  percentage: number;
} | null>(null);

// Contract result state
const [generatedContract, setGeneratedContract] = useState<{
  contractId: string;
  contractText: string;
  contractHash: string;
  verificationProof: VerificationProof | null;
} | null>(null);

// Error handling
const [contractError, setContractError] = useState<string | null>(null);
```

#### New Functions

```typescript
/**
 * Triggered when AI graph signals data collection is complete
 * Initiates inline contract generation
 */
const handleContractGeneration = async (collectedData: CollectedContractData) => {
  setIsGeneratingContract(true);
  setContractError(null);
  
  // Add loading message to chat
  addGenerationMessageToChat();
  
  try {
    // Step 1: Generate contract
    setGenerationProgress({
      stage: 'generating',
      message: 'Generating legal contract...',
      percentage: 25
    });
    
    // Step 2: Process with 0G Compute
    setGenerationProgress({
      stage: 'processing',
      message: 'Processing with 0G Compute Network...',
      percentage: 50
    });
    
    // Step 3: Upload to storage
    setGenerationProgress({
      stage: 'uploading',
      message: 'Uploading to secure storage...',
      percentage: 75
    });
    
    // Call contract service
    const result = await createContract(collectedData);
    
    if (result.success) {
      setGenerationProgress({
        stage: 'complete',
        message: 'Contract created successfully!',
        percentage: 100
      });
      
      setGeneratedContract({
        contractId: result.contractId,
        contractText: result.contractText,
        contractHash: result.contractHash,
        verificationProof: result.verificationProof
      });
      
      // Add success message with preview to chat
      addContractPreviewToChat(result);
    } else {
      throw new Error(result.error || 'Contract generation failed');
    }
  } catch (error) {
    setContractError(error.message);
    addErrorMessageToChat(error.message);
  } finally {
    setIsGeneratingContract(false);
  }
};

/**
 * Retry contract generation on error
 */
const handleRetryGeneration = () => {
  if (collectedData) {
    handleContractGeneration(collectedData);
  }
};

/**
 * Navigate to full contract page
 */
const handleViewFullContract = () => {
  if (generatedContract?.contractId) {
    router.push(`/contract/${generatedContract.contractId}`);
  }
};
```

### 2. Chat Message Components

#### ContractGenerationMessage Component

```typescript
interface ContractGenerationMessageProps {
  progress: {
    stage: string;
    message: string;
    percentage: number;
  };
}

const ContractGenerationMessage: React.FC<ContractGenerationMessageProps> = ({ progress }) => {
  return (
    <div className="bg-slate-700/80 text-slate-100 px-3.5 py-2.5 rounded-lg border border-slate-600/30 max-w-[85%]">
      <div className="flex items-center gap-3 mb-3">
        <div className="w-10 h-10 border-4 border-slate-600 border-t-emerald-500 rounded-full animate-spin"></div>
        <div>
          <h3 className="text-sm font-mono font-medium">Creating Your Contract</h3>
          <p className="text-xs text-slate-400">{progress.message}</p>
        </div>
      </div>
      
      {/* Progress bar */}
      <div className="w-full bg-slate-600/50 rounded-full h-2 mb-2">
        <div 
          className="bg-gradient-to-r from-emerald-500 to-teal-600 h-2 rounded-full transition-all duration-500"
          style={{ width: `${progress.percentage}%` }}
        />
      </div>
      
      {/* Status indicators */}
      <div className="space-y-1 text-xs font-mono">
        <div className={progress.stage === 'generating' ? 'text-emerald-400 animate-pulse' : 'text-slate-400'}>
          {progress.percentage >= 25 ? '✓' : '⟳'} Generating legal contract...
        </div>
        <div className={progress.stage === 'processing' ? 'text-emerald-400 animate-pulse' : 'text-slate-400'}>
          {progress.percentage >= 50 ? '✓' : '⟳'} Processing with 0G Compute Network...
        </div>
        <div className={progress.stage === 'uploading' ? 'text-emerald-400 animate-pulse' : 'text-slate-400'}>
          {progress.percentage >= 75 ? '✓' : '⟳'} Uploading to secure storage...
        </div>
      </div>
    </div>
  );
};
```

#### ContractPreviewMessage Component

```typescript
interface ContractPreviewMessageProps {
  contractId: string;
  contractText: string;
  contractHash: string;
  verificationProof: VerificationProof | null;
  onViewFull: () => void;
  onEdit: () => void;
}

const ContractPreviewMessage: React.FC<ContractPreviewMessageProps> = ({
  contractId,
  contractText,
  contractHash,
  verificationProof,
  onViewFull,
  onEdit
}) => {
  const [showProofDetails, setShowProofDetails] = useState(false);
  
  return (
    <div className="bg-slate-700/80 text-slate-100 px-3.5 py-2.5 rounded-lg border border-slate-600/30 max-w-[85%]">
      {/* Success banner */}
      <div className="bg-emerald-500/20 border border-emerald-500/50 rounded-lg p-3 mb-3">
        <div className="flex items-center gap-2">
          <span className="text-xl">✓</span>
          <div>
            <h3 className="text-emerald-400 font-mono font-medium text-sm">
              Contract Generated Successfully
            </h3>
            <p className="text-xs text-slate-300 mt-1">
              Your contract has been created and verified
            </p>
          </div>
        </div>
      </div>
      
      {/* Verification proof */}
      {verificationProof && (
        <div className="bg-slate-800/50 rounded-lg p-3 mb-3">
          <div className="flex items-center justify-between mb-2">
            <h4 className="text-xs font-mono font-medium flex items-center gap-1">
              <span>🔐</span>
              <span>Verification Proof</span>
            </h4>
            <button
              onClick={() => setShowProofDetails(!showProofDetails)}
              className="text-emerald-400 text-xs hover:text-emerald-300"
            >
              {showProofDetails ? 'Hide' : 'Show'} Details
            </button>
          </div>
          
          <div className="space-y-1 text-xs">
            <div className="flex justify-between">
              <span className="text-slate-400">Type:</span>
              <span className="text-white bg-emerald-500/20 px-2 py-0.5 rounded">
                {verificationProof.type}
              </span>
            </div>
            <div className="flex justify-between">
              <span className="text-slate-400">Timestamp:</span>
              <span className="text-white">
                {new Date(verificationProof.timestamp).toLocaleString()}
              </span>
            </div>
            
            {showProofDetails && (
              <div className="mt-2 p-2 bg-slate-900/50 rounded text-xs font-mono">
                <div className="text-slate-400 mb-1">Hash:</div>
                <div className="text-white break-all">{verificationProof.hash}</div>
              </div>
            )}
          </div>
        </div>
      )}
      
      {/* Contract preview */}
      <div className="bg-white rounded-lg p-3 mb-3 max-h-48 overflow-y-auto">
        <pre className="text-xs font-mono text-slate-800 whitespace-pre-wrap">
          {contractText.substring(0, 500)}...
        </pre>
      </div>
      
      {/* Action buttons */}
      <div className="flex gap-2">
        <button
          onClick={onViewFull}
          className="flex-1 bg-gradient-to-r from-emerald-500 to-teal-600 text-white px-3 py-2 rounded-lg text-xs font-mono hover:opacity-90 transition-opacity"
        >
          View Full Contract →
        </button>
        <button
          onClick={onEdit}
          className="px-3 py-2 bg-slate-600 hover:bg-slate-500 text-white rounded-lg text-xs font-mono transition-colors"
        >
          Edit Details
        </button>
      </div>
    </div>
  );
};
```

#### ContractErrorMessage Component

```typescript
interface ContractErrorMessageProps {
  error: string;
  onRetry: () => void;
}

const ContractErrorMessage: React.FC<ContractErrorMessageProps> = ({ error, onRetry }) => {
  return (
    <div className="bg-slate-700/80 text-slate-100 px-3.5 py-2.5 rounded-lg border border-red-500/30 max-w-[85%]">
      <div className="flex items-center gap-3 mb-3">
        <div className="w-10 h-10 bg-red-500/20 rounded-full flex items-center justify-center">
          <span className="text-xl">⚠️</span>
        </div>
        <div>
          <h3 className="text-sm font-mono font-medium text-red-400">
            Contract Generation Failed
          </h3>
          <p className="text-xs text-slate-300 mt-1">{error}</p>
        </div>
      </div>
      
      <button
        onClick={onRetry}
        className="w-full bg-emerald-500 hover:bg-emerald-600 text-white px-3 py-2 rounded-lg text-xs font-mono transition-colors"
      >
        Retry Generation
      </button>
    </div>
  );
};
```

## Data Models

### Enhanced GraphState

The existing `GraphState` interface already supports the necessary fields. We'll utilize:

```typescript
interface GraphState {
  // Existing fields...
  inferenceReady?: boolean;
  collectedData?: CollectedContractData;
  
  // These will trigger contract generation
  stage?: string; // When 'completed'
  progress?: number; // When 100
}
```

### Contract Generation Flow Data

```typescript
interface ContractGenerationState {
  isGenerating: boolean;
  progress: {
    stage: 'generating' | 'processing' | 'uploading' | 'complete';
    message: string;
    percentage: number;
  } | null;
  result: {
    contractId: string;
    contractText: string;
    contractHash: string;
    verificationProof: VerificationProof | null;
  } | null;
  error: string | null;
}
```

## Error Handling

### Error Types

1. **Network Errors**: Connection issues with backend or 0G Compute
2. **Validation Errors**: Invalid collected data
3. **Generation Errors**: Contract template or generation failures
4. **Storage Errors**: Failed upload to backend or 0G storage
5. **Timeout Errors**: Generation takes too long

### Error Recovery Strategy

```typescript
const handleContractError = (error: Error, context: string) => {
  console.error(`Contract error in ${context}:`, error);
  
  let userMessage = 'An error occurred during contract generation.';
  let canRetry = true;
  
  if (error.message.includes('network')) {
    userMessage = 'Network connection lost. Please check your connection and try again.';
  } else if (error.message.includes('validation')) {
    userMessage = 'Some information is invalid. Please review and correct your details.';
    canRetry = false;
  } else if (error.message.includes('timeout')) {
    userMessage = 'Contract generation is taking longer than expected. Please try again.';
  } else if (error.message.includes('0G')) {
    userMessage = '0G Compute Network is temporarily unavailable. Retrying...';
  }
  
  setContractError(userMessage);
  addErrorMessageToChat(userMessage, canRetry);
};
```

## Testing Strategy

### Unit Tests

1. **Contract Generation Flow**
   - Test `handleContractGeneration` with valid data
   - Test error handling for each error type
   - Test retry mechanism
   - Test state updates during generation

2. **Message Components**
   - Test `ContractGenerationMessage` renders correctly
   - Test `ContractPreviewMessage` displays all data
   - Test `ContractErrorMessage` shows error and retry button
   - Test button interactions

3. **State Management**
   - Test state transitions during generation
   - Test cleanup on unmount
   - Test concurrent generation prevention

### Integration Tests

1. **End-to-End Flow**
   - Complete information collection
   - Trigger contract generation
   - Verify inline display
   - Navigate to full contract page

2. **Error Scenarios**
   - Network failure during generation
   - Invalid data handling
   - Timeout handling
   - Retry after error

3. **UI/UX Tests**
   - Progress indicators update correctly
   - Messages scroll into view
   - Action buttons work as expected
   - Chat history preserved

### Manual Testing Checklist

- [ ] Complete information collection flow
- [ ] Contract generation starts automatically
- [ ] Progress indicators show correct stages
- [ ] Contract preview displays correctly
- [ ] Verification proof shows when available
- [ ] "View Full Contract" navigates correctly
- [ ] "Edit Details" allows conversation continuation
- [ ] Error messages display clearly
- [ ] Retry button works after errors
- [ ] Chat history preserved through generation
- [ ] Scroll behavior works smoothly
- [ ] No redirect to `/contract/create` page
- [ ] InferenceView component not used

## Migration Plan

### Phase 1: Add Inline Generation (Non-Breaking)
1. Add new state variables to `CreateChat.tsx`
2. Implement message components
3. Add contract generation logic
4. Keep existing redirect as fallback

### Phase 2: Switch to Inline Flow
1. Update graph state handling to trigger inline generation
2. Remove sessionStorage usage
3. Test thoroughly

### Phase 3: Cleanup
1. Delete `/contract/create/page.tsx`
2. Delete `InferenceView.tsx` component
3. Remove unused imports and dependencies
4. Update documentation

## Files to Modify

1. **src/components/create/CreateChat.tsx** - Main changes
2. **src/app/create/page.tsx** - Remove redirect logic
3. **src/ai/graph.ts** - Ensure proper state signaling

## Files to Delete

1. **src/app/contract/create/page.tsx**
2. **src/components/create/InferenceView.tsx**

## Dependencies

- Existing: `contractService.ts` for contract generation
- Existing: `types.ts` for type definitions
- Existing: AI graph for state management
- No new dependencies required
