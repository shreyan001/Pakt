# Implementation Plan

- [x] 1. Add contract generation state management to CreateChat.tsx


  - Add state variables for contract generation tracking (isGeneratingContract, generationProgress, generatedContract, contractError)
  - Add state variable to store collected data from AI graph
  - Initialize all states with appropriate default values
  - _Requirements: 1.1, 4.1, 4.3_



- [ ] 2. Create inline message components for contract generation
  - [ ] 2.1 Create ContractGenerationMessage component
    - Implement loading spinner and progress bar
    - Display stage-specific status messages
    - Show progress indicators for each generation step

    - _Requirements: 1.2, 1.3_
  
  - [ ] 2.2 Create ContractPreviewMessage component
    - Display success banner with checkmark
    - Show verification proof details with toggle
    - Render contract text preview with scroll

    - Add "View Full Contract" and "Edit Details" buttons
    - _Requirements: 1.4, 2.1, 2.2, 2.3, 2.6_
  
  - [x] 2.3 Create ContractErrorMessage component

    - Display error icon and message

    - Show user-friendly error text
    - Add retry button
    - _Requirements: 1.5, 5.1, 5.2_

- [x] 3. Implement contract generation handler function

  - [ ] 3.1 Create handleContractGeneration function
    - Accept CollectedContractData as parameter
    - Set isGeneratingContract to true
    - Add generation loading message to chat elements
    - _Requirements: 1.1, 1.2_
  

  - [ ] 3.2 Implement progress tracking
    - Update progress state for "Generating legal contract" (25%)
    - Update progress state for "Processing with 0G Compute" (50%)
    - Update progress state for "Uploading to secure storage" (75%)
    - Update progress state for "Complete" (100%)

    - _Requirements: 1.3_
  
  - [ ] 3.3 Integrate with contractService
    - Call createContract function with collected data
    - Handle success response and store contract result
    - Add contract preview message to chat on success

    - Handle error response and display error message

    - _Requirements: 1.4, 1.5, 3.3_

- [ ] 4. Implement helper functions for chat message management
  - Create addGenerationMessageToChat function to add loading message
  - Create addContractPreviewToChat function to add preview message

  - Create addErrorMessageToChat function to add error message
  - Ensure messages scroll into view automatically
  - _Requirements: 1.2, 1.4, 1.5, 2.6_


- [ ] 5. Add contract generation trigger logic
  - [ ] 5.1 Monitor graphState changes in useEffect
    - Check for stage === 'completed' and progress === 100
    - Check for collectedData presence in graphState
    - Extract collectedData from graphState
    - _Requirements: 1.1, 4.1, 4.2_

  
  - [ ] 5.2 Trigger contract generation automatically
    - Call handleContractGeneration when data is complete
    - Prevent duplicate generation calls
    - Store collected data in component state
    - _Requirements: 1.1, 4.2_


- [ ] 6. Implement action button handlers
  - Create handleViewFullContract function to navigate to /contract/[contractId]
  - Create handleEditDetails function to allow conversation continuation
  - Create handleRetryGeneration function to retry on error
  - Wire up buttons in ContractPreviewMessage and ContractErrorMessage
  - _Requirements: 2.3, 2.4, 2.5, 5.3_



- [ ] 7. Add error handling and recovery
  - Implement error type detection (network, validation, timeout, 0G)
  - Create user-friendly error messages for each type


  - Add error state cleanup on retry
  - Implement timeout handling for long-running generation
  - _Requirements: 5.1, 5.2, 5.3, 5.4, 5.5_


- [ ] 8. Update graph state integration
  - Remove sessionStorage usage for pendingContractData
  - Ensure graphState properly signals completion
  - Verify collectedData structure matches CollectedContractData type
  - Test state synchronization between graph and component
  - _Requirements: 3.4, 4.1, 4.2_



- [ ] 9. Remove redirect logic from create page
  - Remove redirect to /contract/create from src/app/create/page.tsx
  - Remove sessionStorage.setItem for pendingContractData
  - Keep only the graphState update logic
  - _Requirements: 3.1, 3.4_

- [ ] 10. Clean up unused files and components
  - Delete src/app/contract/create/page.tsx
  - Delete src/components/create/InferenceView.tsx
  - Remove unused imports from CreateChat.tsx
  - Remove InferenceView import from any files
  - _Requirements: 3.1, 3.2, 3.5_

- [ ] 11. Add TypeScript type safety
  - Ensure all new state variables have proper types
  - Add types for message component props
  - Verify CollectedContractData type usage
  - Add type guards where necessary
  - _Requirements: 3.3, 4.3_

- [ ] 12. Test and verify the complete flow
  - Test information collection completion triggers generation
  - Verify progress indicators update correctly
  - Test contract preview displays all information
  - Verify "View Full Contract" navigation works
  - Test "Edit Details" allows conversation continuation
  - Test error handling and retry functionality
  - Verify no redirect to /contract/create occurs
  - Confirm chat history is preserved throughout
  - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5, 2.1, 2.2, 2.3, 2.4, 2.5, 2.6, 3.1, 3.2, 3.3, 3.4, 3.5, 4.1, 4.2, 4.3, 4.4, 5.1, 5.2, 5.3, 5.4, 5.5_
