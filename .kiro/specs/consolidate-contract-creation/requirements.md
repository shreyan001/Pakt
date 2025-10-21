# Requirements Document

## Introduction

This feature consolidates all contract creation functionality into a single component (`CreateChat.tsx`), eliminating the need for separate pages (`/contract/create` and the InferenceView component). The goal is to streamline the user experience by handling the entire contract creation flow - from data collection through AI generation to final contract display - within the chat interface itself.

Currently, the application redirects users to separate pages during contract generation, breaking the conversational flow. This refactoring will keep users in the chat interface throughout the entire process, displaying loading states, generation progress, and final results inline within the chat conversation.

## Requirements

### Requirement 1: Inline Contract Generation

**User Story:** As a user completing the contract information collection, I want the contract generation to happen within the chat interface, so that I maintain context and don't lose my conversation history.

#### Acceptance Criteria

1. WHEN the AI agent determines that data collection is complete THEN the system SHALL initiate contract generation without redirecting to a separate page
2. WHEN contract generation begins THEN the system SHALL display an inline loading message in the chat with progress indicators
3. WHEN contract generation is in progress THEN the system SHALL show status updates (e.g., "Generating legal contract...", "Processing with 0G Compute Network...", "Uploading to secure storage...")
4. WHEN contract generation completes successfully THEN the system SHALL display the contract preview within the chat interface
5. WHEN contract generation fails THEN the system SHALL display an error message inline with a retry option

### Requirement 2: Contract Preview and Actions

**User Story:** As a user who has generated a contract, I want to preview and interact with the contract directly in the chat, so that I can review and proceed without navigation disruptions.

#### Acceptance Criteria

1. WHEN a contract is successfully generated THEN the system SHALL display a formatted preview of the contract text in the chat
2. WHEN the contract preview is displayed THEN the system SHALL show verification proof details (type, timestamp, hash) if available
3. WHEN the contract preview is displayed THEN the system SHALL provide action buttons for "View Full Contract" and "Edit Details"
4. WHEN the user clicks "View Full Contract" THEN the system SHALL navigate to `/contract/[contractId]` page
5. WHEN the user clicks "Edit Details" THEN the system SHALL allow the user to continue the conversation to modify information
6. WHEN the contract preview is shown THEN the system SHALL display it as a chat message that can be scrolled through in the conversation history

### Requirement 3: Remove Redundant Pages

**User Story:** As a developer maintaining the codebase, I want to remove unused pages and components, so that the application has a cleaner architecture with less code duplication.

#### Acceptance Criteria

1. WHEN the consolidation is complete THEN the system SHALL NOT have a `/contract/create` page
2. WHEN the consolidation is complete THEN the system SHALL NOT use the `InferenceView` component
3. WHEN the consolidation is complete THEN the system SHALL handle all contract creation logic within `CreateChat.tsx`
4. WHEN the consolidation is complete THEN the system SHALL remove sessionStorage usage for `pendingContractData`
5. WHEN the consolidation is complete THEN the system SHALL maintain all existing functionality (0G Compute integration, contract storage, verification)

### Requirement 4: State Management Integration

**User Story:** As a user interacting with the chat, I want the contract generation state to be managed seamlessly within the existing chat state, so that the experience feels natural and cohesive.

#### Acceptance Criteria

1. WHEN contract generation is triggered THEN the system SHALL update the existing `graphState` to reflect the generation status
2. WHEN contract generation progresses THEN the system SHALL update the `contractProgress` state to show percentage completion
3. WHEN a contract is generated THEN the system SHALL store the contract ID and content in the component state
4. WHEN the user scrolls through chat history THEN the system SHALL preserve all contract generation messages and previews
5. IF the user refreshes the page during generation THEN the system SHALL handle the state gracefully (either resume or show appropriate message)

### Requirement 5: Error Handling and Recovery

**User Story:** As a user experiencing an error during contract generation, I want clear feedback and recovery options within the chat, so that I can resolve issues without starting over.

#### Acceptance Criteria

1. WHEN contract generation fails THEN the system SHALL display a user-friendly error message in the chat
2. WHEN an error occurs THEN the system SHALL provide a "Retry" button inline in the chat
3. WHEN the user clicks "Retry" THEN the system SHALL attempt contract generation again using the same collected data
4. WHEN network errors occur THEN the system SHALL display specific error messages (e.g., "Network connection lost", "0G Compute unavailable")
5. WHEN generation times out THEN the system SHALL notify the user and offer to retry or edit details
