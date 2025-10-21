# Requirements Document

## Introduction

This feature integrates 0G Compute Network's secure inference capability into the Pakt contract creation flow. When the information collection phase is complete, the system will transition from the conversational chat interface to execute secure AI inference using 0G's TEE (Trusted Execution Environment) or ZKP (Zero-Knowledge Proof) verification modes. This ensures that contract generation happens in a verifiable, secure manner without exposing the underlying AI model.

## Requirements

### Requirement 1: Signal Detection for Information Collection Completion

**User Story:** As a system, I want to detect when the information collection phase is complete, so that I can trigger the secure inference process.

#### Acceptance Criteria

1. WHEN the agent returns a graph state with a completion signal THEN the system SHALL capture this signal in the CreateChat component
2. WHEN the completion signal is detected THEN the system SHALL extract all collected contract data from the graph state
3. IF the signal property is named `inferenceReady` with value `true` THEN the system SHALL proceed to secure inference
4. WHEN the signal is detected THEN the system SHALL store the collected data including: projectName, clientName, email, paymentAmount, projectDescription, deadline, and walletAddress

### Requirement 2: 0G Compute SDK Integration

**User Story:** As a developer, I want to integrate the 0G Compute SDK, so that I can execute secure inference operations.

#### Acceptance Criteria

1. WHEN the application initializes THEN the system SHALL import and configure the 0G Compute SDK
2. WHEN configuring the SDK THEN the system SHALL provide necessary credentials (tokenId, executor address)
3. WHEN the SDK is initialized THEN the system SHALL support both TEE and ZKP verification modes
4. IF the SDK initialization fails THEN the system SHALL display an error message and allow retry

### Requirement 3: Secure Inference Execution

**User Story:** As a user, I want my contract to be generated using secure inference, so that my data remains private and the execution is verifiable.

#### Acceptance Criteria

1. WHEN information collection is complete THEN the system SHALL call `ogCompute.executeSecure()` with collected data
2. WHEN calling executeSecure THEN the system SHALL pass: tokenId, executor, input (user data), and verificationMode
3. WHEN inference executes THEN the system SHALL display a loading state with progress indication
4. WHEN inference completes THEN the system SHALL receive both the output and verification proof
5. IF inference fails THEN the system SHALL display an error and allow the user to retry or return to chat

### Requirement 4: UI Transition and Component Replacement

**User Story:** As a user, I want to see a smooth transition from chat to contract generation, so that I understand the process flow.

#### Acceptance Criteria

1. WHEN the completion signal is detected THEN the system SHALL hide the CreateChat component
2. WHEN transitioning THEN the system SHALL display a new InferenceView component
3. WHEN in InferenceView THEN the system SHALL show: loading state, progress indicator, and status messages
4. WHEN inference completes THEN the system SHALL display the generated contract with verification proof
5. WHEN displaying results THEN the system SHALL provide options to: review contract, edit details, or proceed to signing

### Requirement 5: State Management and Data Flow

**User Story:** As a system, I want to properly manage state transitions, so that data flows correctly between components.

#### Acceptance Criteria

1. WHEN the page loads THEN the system SHALL initialize with `showInference` state as false
2. WHEN completion signal is detected THEN the system SHALL set `showInference` to true
3. WHEN transitioning THEN the system SHALL preserve all collected data in page state
4. WHEN inference completes THEN the system SHALL update state with: inferenceResult, verificationProof, and generatedContract
5. WHEN user navigates back THEN the system SHALL allow returning to chat with preserved history

### Requirement 6: Error Handling and Recovery

**User Story:** As a user, I want clear error messages and recovery options, so that I can resolve issues without losing my progress.

#### Acceptance Criteria

1. WHEN any error occurs THEN the system SHALL display a user-friendly error message
2. WHEN SDK initialization fails THEN the system SHALL provide a "Retry" button
3. WHEN inference fails THEN the system SHALL preserve collected data and allow retry
4. WHEN network errors occur THEN the system SHALL detect and display appropriate messages
5. IF critical errors occur THEN the system SHALL provide an option to return to chat

### Requirement 7: Verification Proof Display

**User Story:** As a user, I want to see the verification proof, so that I can trust the contract generation process.

#### Acceptance Criteria

1. WHEN inference completes THEN the system SHALL display the verification proof
2. WHEN displaying proof THEN the system SHALL show: proof type (TEE/ZKP), timestamp, and proof hash
3. WHEN user clicks on proof THEN the system SHALL expand to show full proof details
4. WHEN proof is displayed THEN the system SHALL provide a "Copy" button for the proof data
5. WHEN proof is verified THEN the system SHALL display a visual indicator (checkmark, badge)

### Requirement 8: Integration with Existing Graph State

**User Story:** As a system, I want to integrate with the existing graph state management, so that the flow remains consistent.

#### Acceptance Criteria

1. WHEN graph state updates THEN the system SHALL check for the `inferenceReady` signal
2. WHEN signal is present THEN the system SHALL extract `collectedData` from graph state
3. WHEN transitioning THEN the system SHALL update `flowType` to "execution"
4. WHEN in execution mode THEN the system SHALL update progress indicators accordingly
5. WHEN inference completes THEN the system SHALL update graph state with results
