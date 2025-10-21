import { ethers } from "ethers";
import { StateGraph } from "@langchain/langgraph";
import { BaseMessage, AIMessage, HumanMessage } from "@langchain/core/messages";
import { START, END } from "@langchain/langgraph";
import { ChatPromptTemplate, MessagesPlaceholder } from "@langchain/core/prompts";
import { ChatGroq } from "@langchain/groq";
import { systemPrompt } from "./contractTemplate";
import { ChatOpenAI } from "@langchain/openai";
import { UserInputExtractionSchema, safeParseUserInput } from './zodSchemas';

import fs from 'fs/promises';
import path from 'path';


const model = new ChatGroq({
    modelName: "llama-3.3-70b-versatile",
    temperature: 0.7,
    apiKey: process.env.NEXT_PUBLIC_GROQ_API_KEY,
});

type guildState = {
    input: string,
    contractData?: string | null,
    chatHistory?: BaseMessage[],
    messages?: any[] | null,
    operation?: string,
    result?: string,
    walletAddress?: string, // Add wallet address to state
    // Stage management for conversation flow
    stage?: 'initial' | 'information_collection' | 'contract_creation' | 'payment_collection' | 'completed',
    information_collection?: boolean,
    // Project information for freelance website development
    projectInfo?: {
        projectName?: string,
        projectDescription?: string,
        deliverables?: string[], // e.g., ["GitHub repository", "Live deployment", "Documentation"]
        timeline?: string,
        requirements?: string,
        revisions?: number,
    },
    clientInfo?: {
        clientName?: string,
        walletAddress?: string,
    },
    financialInfo?: {
        paymentAmount?: number, // Payment to freelancer in USD
        platformFees?: number, // Pakt platform fees
        escrowFee?: number, // Escrow service fee (0.2% of payment amount)
        totalEscrowAmount?: number, // Total amount client needs to deposit
        currency?: string, // Currency for the payment (default: USD)
    },
    contractReady?: boolean,
}

export default function nodegraph() {
    const graph = new StateGraph<guildState>({
        channels: {
            messages: { value: (x: any[], y: any[]) => x.concat(y) },
            input: { value: null },
            result: { value: null },
            contractData: { value: null },
            chatHistory: { value: null },
            operation: { value: null },
            walletAddress: { value: null },
            projectInfo: { value: null },
            clientInfo: { value: null },
            financialInfo: { value: null },
            contractReady: { value: null }
        }
    });

    // Initial Node: Provides comprehensive project information and routes user requests
    graph.addNode("initial_node", async (state: guildState) => {
        const INITIAL_SYSTEM_TEMPLATE = `You are Pakt AI, an intelligent assistant for Pakt Wave 1 - a secure escrow system for freelance website development.

## About Pakt Wave 1
Pakt Wave 1 is a **trustless escrow platform** that enables secure transactions between clients and freelancers for website development projects. Built on:

🔗 **Secure Escrow System** - Protected payment holding
⚡ **Legal Contract Integration** - Professional contract generation  
💰 **USD payments** - Secure escrow payments
🤖 **Automated verification** - Payment release system

## Key Features & Benefits
✅ **Trustless Security** - Payments held in escrow until work completion
📋 **Milestone Tracking** - Automated verification and progress monitoring  
📁 **Secure Delivery** - Protected file delivery and project management
🛡️ **Dual Protection** - Guards against non-payment AND non-delivery
🌐 **Website Types** - Portfolios, business sites, e-commerce, web apps, landing pages, etc.

## How It Works
1. **Client deposits** payment into secure escrow
2. **Freelancer builds** the website according to specifications
3. **Automated verification** checks deliverables against requirements
4. **Payment releases** automatically when milestones are met
5. **Dispute resolution** available if needed

## Classification Guidelines
**For GREETINGS & GENERAL QUESTIONS**: Provide detailed, helpful information about Pakt, how it works, benefits, and encourage them to explore our escrow services. Be warm, informative, and educational.

**For ESCROW INTEREST**: If user wants to create an escrow, hire a freelancer, or start a website project - guide them to information collection.

Current conversation stage: {stage}

**Response Style**: Be warm, professional, and comprehensive. For general questions, provide detailed explanations about our platform, benefits, and how we solve common freelancing problems. Use markdown formatting and emojis for better readability.

Always end your response with one of these hidden classification tags (the user won't see this):
- [INTENT:ESCROW] - if user shows clear interest in creating escrow transactions or hiring freelancers
- [INTENT:GENERAL] - for greetings, general conversation, or information requests about the platform

For [INTENT:GENERAL], provide comprehensive, helpful information to educate users about Pakt's benefits and encourage exploration.`;

        const prompt = ChatPromptTemplate.fromMessages([
            ["system", INITIAL_SYSTEM_TEMPLATE],
            new MessagesPlaceholder({ variableName: "chat_history", optional: true }),
            ["human", "{input}"]
        ]);

        const response = await prompt.pipe(model).invoke({ 
            input: state.input, 
            chat_history: state.chatHistory,
            stage: state.stage || 'initial'
        });

        console.log(response.content, "Initial Node Response");

        const content = response.content as string;
        
        // Extract the intent classification from the response
        let operation = "end";  // Default to end
        if (content.includes("[INTENT:ESCROW]")) {
            operation = "escrow_info";
        }
        // If no specific intent, operation stays "end"

        // Clean the response by removing the intent tag before returning to user
        const cleanedContent = content.replace(/\[INTENT:(ESCROW|GENERAL)\]/g, '').trim();

        return { 
            result: cleanedContent,
            messages: [cleanedContent], 
            operation: operation,
            stage: operation === "escrow_info" ? 'information_collection' : 'initial',
            information_collection: operation === "escrow_info"
        };
    });

    // Escrow Information Collection Node: Gathers detailed requirements for website verification escrow transactions
    graph.addNode("escrow_info_node", async (state: guildState) => {
        const systemTemplate = `You are Pakt's Information Collection Agent for freelance website development escrows. 

## STREAMLINED COLLECTION PROCESS
Instead of asking questions individually, present ALL missing information requests in ONE organized message to speed up the process for hackathon testing.

## REQUIRED INFORMATION (4 items only):
1. **Company/Client Name** - Who is hiring for this project?
2. **Project Name** - What should the website be called?  
3. **Project Description** - Brief description of what website needs to be built
4. **Payment Amount** - How much will you pay the freelancer (in USD)?

## CURRENT STATE:
Project Info: {projectInfo}
Client Info: {clientInfo}
Financial Info: {financialInfo}

## RESPONSE STRATEGY:
**If MISSING multiple items**: Ask for ALL missing information in ONE well-organized message like:
"To set up your legal contract, I need the following information:
1. Company/Client name
2. Project name  
3. Brief project description
4. Payment amount in USD

Please provide all of these details in your next message."

**If MISSING 1-2 items**: Ask for the specific missing items clearly.

**If ALL collected**: Proceed to contract creation.

## RESPONSE ENDINGS:
- [READY_FOR_CONTRACT] - when you have all 4 required items
- [CONTINUE_INFO] - if you need more information

Keep responses professional, organized, and efficient. No unnecessary questions about delivery time, communication channels, or technical details.`;

        const prompt = ChatPromptTemplate.fromMessages([
            ["system", systemTemplate],
            new MessagesPlaceholder({ variableName: "chat_history", optional: true }),
            ["human", "{input}"]
        ]);

        const response = await prompt.pipe(model).invoke({
            input: state.input,
            chat_history: state.chatHistory || [],
            projectInfo: JSON.stringify(state.projectInfo || {}),
            clientInfo: JSON.stringify(state.clientInfo || {}),
            financialInfo: JSON.stringify(state.financialInfo || {}),
            stage: state.stage || 'information_collection'
        });

        console.log(response.content, "Escrow Info Node Response");

        // ZOD-BASED STRUCTURED INFORMATION EXTRACTION
        const extractionSystemTemplate = `You are an expert information extraction agent. Analyze the user's input and extract structured information for a freelance contract.

## EXTRACTION TASK:
Extract the following information from the user's message:
1. Project name (what the website/project should be called)
2. Project description (what needs to be built/developed)
3. Client/company name (who is hiring)
4. Payment amount (in USD, extract numbers only)
5. Any additional relevant details

## CURRENT CONTEXT:
User Input: {userInput}
Existing Project Info: {existingProjectInfo}
Existing Client Info: {existingClientInfo}
Existing Financial Info: {existingFinancialInfo}

## EXTRACTION RULES:
- Only extract information that is explicitly mentioned in the user's input
- If information is already collected, don't override unless new information is clearly provided
- For payment amounts, extract numeric values only (remove currency symbols)
- Be conservative - only extract what you're confident about
- Set fields to null if not found in the input

## OUTPUT FORMAT:
Return a structured JSON object with the extracted information and completion status.`;

        const extractionPrompt = ChatPromptTemplate.fromMessages([
            ["system", extractionSystemTemplate],
            ["human", "Extract information from: {userInput}"]
        ]);

        // Create structured LLM for information extraction using Zod
        const structuredLLM = model.withStructuredOutput(UserInputExtractionSchema, {
            name: "information_extraction",
            method: "function_calling"
        });

        const extractionChain = extractionPrompt.pipe(structuredLLM);

        try {
            // Extract structured information using Zod validation
            const extractedData = await extractionChain.invoke({
                userInput: state.input,
                existingProjectInfo: JSON.stringify(state.projectInfo || {}),
                existingClientInfo: JSON.stringify(state.clientInfo || {}),
                existingFinancialInfo: JSON.stringify(state.financialInfo || {})
            });

            console.log("Zod Extracted Data:", JSON.stringify(extractedData, null, 2));

            // Update state with extracted information
            const updatedProjectInfo = { ...state.projectInfo };
            const updatedClientInfo = { ...state.clientInfo };
            const updatedFinancialInfo = { ...state.financialInfo };

            // Apply extracted information with validation
            if (extractedData.extractedInfo.projectName && !updatedProjectInfo.projectName) {
                updatedProjectInfo.projectName = extractedData.extractedInfo.projectName;
            }

            if (extractedData.extractedInfo.projectDescription && !updatedProjectInfo.projectDescription) {
                updatedProjectInfo.projectDescription = extractedData.extractedInfo.projectDescription;
                // Set default deliverables based on project description
                updatedProjectInfo.deliverables = [
                    `Website development for ${extractedData.extractedInfo.projectName || 'the project'}`,
                    "Source code delivery",
                    "Documentation"
                ];
                updatedProjectInfo.timeline = "To be determined by freelancer";
                updatedProjectInfo.requirements = extractedData.extractedInfo.projectDescription;
                updatedProjectInfo.revisions = 2;
            }

            if (extractedData.extractedInfo.clientName && !updatedClientInfo.clientName) {
                updatedClientInfo.clientName = extractedData.extractedInfo.clientName;
                updatedClientInfo.walletAddress = null; // Will be set during signing
            }

            if (extractedData.extractedInfo.paymentAmount && !updatedFinancialInfo.paymentAmount) {
                const paymentAmount = extractedData.extractedInfo.paymentAmount;
                const escrowFee = Math.round((paymentAmount * 0.002) * 100) / 100; // 0.2%
                const platformFee = 0.5;
                const totalAmount = paymentAmount + escrowFee + platformFee;
                
                updatedFinancialInfo.paymentAmount = paymentAmount;
                updatedFinancialInfo.platformFees = platformFee;
                updatedFinancialInfo.escrowFee = escrowFee;
                updatedFinancialInfo.totalEscrowAmount = totalAmount;
                updatedFinancialInfo.currency = "USD";
            }

            // Check completion status using Zod extraction results
            const allInfoCollected = extractedData.completionStatus.isComplete || (
                extractedData.completionStatus.hasProjectName && 
                extractedData.completionStatus.hasProjectDescription && 
                extractedData.completionStatus.hasClientName && 
                extractedData.completionStatus.hasPaymentAmount
            );

            // Save collected information to file for persistence
            try {
                const collectedData = {
                    projectInfo: updatedProjectInfo,
                    clientInfo: updatedClientInfo,
                    financialInfo: updatedFinancialInfo,
                    extractionResult: extractedData,
                    timestamp: new Date().toISOString(),
                    stage: allInfoCollected ? 'contract_creation' : 'information_collection'
                };
                
                await fs.writeFile(
                    path.join(process.cwd(), 'collected_info.json'),
                    JSON.stringify(collectedData, null, 2)
                );
            } catch (error) {
                console.error('Error saving collected information:', error);
            }

            const content = response.content as string;
            
            // Extract the intent classification from the response
            let operation = "end";  // Default to end
            if (content.includes("[READY_FOR_CONTRACT]") || allInfoCollected) {
                operation = "contract_creation_node";
            }
            // If RETURN_TO_GENERAL or CONTINUE_INFO, operation stays "end"

            // Clean the response by removing the intent tag before returning to user
            const cleanedContent = content.replace(/\[(READY_FOR_CONTRACT|RETURN_TO_GENERAL|CONTINUE_INFO)\]/g, '').trim();

            return {
                ...state,
                result: cleanedContent,
                messages: [cleanedContent],
                operation: operation,
                projectInfo: updatedProjectInfo,
                clientInfo: updatedClientInfo,
                financialInfo: updatedFinancialInfo,
                information_collection: !allInfoCollected,
                stage: allInfoCollected ? 'contract_creation' : 'information_collection'
            };

        } catch (error) {
            console.error('Zod extraction error:', error);
            
            // Fallback to original regex-based extraction if Zod fails
            const input = state.input.toLowerCase();
            const originalInput = state.input;
            const updatedProjectInfo = { ...state.projectInfo };
            const updatedClientInfo = { ...state.clientInfo };
            const updatedFinancialInfo = { ...state.financialInfo };

            // Fallback extraction patterns (simplified)
            if (!updatedProjectInfo.projectName) {
                const nameMatch = originalInput.match(/(?:project name|website name|site name|called|project title)\s*:?\s*([^,.\n!?]+)/i);
                if (nameMatch && nameMatch[1].trim().length > 2) {
                    updatedProjectInfo.projectName = nameMatch[1].trim();
                }
            }

            if (!updatedProjectInfo.projectDescription) {
                const descMatch = originalInput.match(/(?:description|about|build|website|project)\s*:?\s*([^,.\n!?]{10,})/i);
                if (descMatch && descMatch[1].trim().length > 10) {
                    updatedProjectInfo.projectDescription = descMatch[1].trim();
                }
            }

            if (!updatedFinancialInfo.paymentAmount) {
                const paymentMatch = originalInput.match(/(?:payment|cost|price|pay|budget|amount)\s*:?\s*\$?(\d+(?:,\d{3})*(?:\.\d+)?)/i);
                if (paymentMatch) {
                    const amount = parseFloat(paymentMatch[1].replace(/,/g, ''));
                    if (amount > 0) {
                        updatedFinancialInfo.paymentAmount = amount;
                        const escrowFee = Math.round((amount * 0.002) * 100) / 100;
                        const platformFee = 0.5;
                        updatedFinancialInfo.platformFees = platformFee;
                        updatedFinancialInfo.escrowFee = escrowFee;
                        updatedFinancialInfo.totalEscrowAmount = amount + escrowFee + platformFee;
                    }
                }
            }

            if (!updatedClientInfo.clientName) {
                const clientMatch = originalInput.match(/(?:company|client|my name is|i'm|i am|name)\s*:?\s*([^,.\n!?]+)/i);
                if (clientMatch && clientMatch[1].trim().length > 1) {
                    updatedClientInfo.clientName = clientMatch[1].trim();
                }
            }

            const allInfoCollected = updatedProjectInfo.projectName && 
                                   updatedProjectInfo.projectDescription && 
                                   updatedClientInfo.clientName && 
                                   updatedFinancialInfo.paymentAmount;

            const content = response.content as string;
            let operation = "end";
            if (content.includes("[READY_FOR_CONTRACT]") || allInfoCollected) {
                operation = "contract_creation_node";
            }

            const cleanedContent = content.replace(/\[(READY_FOR_CONTRACT|RETURN_TO_GENERAL|CONTINUE_INFO)\]/g, '').trim();

            return {
                ...state,
                result: cleanedContent,
                messages: [cleanedContent],
                operation: operation,
                projectInfo: updatedProjectInfo,
                clientInfo: updatedClientInfo,
                financialInfo: updatedFinancialInfo,
                information_collection: !allInfoCollected,
                stage: allInfoCollected ? 'contract_creation' : 'information_collection'
            };
        }
    });

    // Contract Creation Node: Prepares contract for signing by both parties
    graph.addNode("contract_creation_node", async (state: guildState) => {
        const CONTRACT_CREATION_TEMPLATE = `You are Pakt's Contract Creation Agent. Your role is to prepare the final legal contract based on the collected information and guide users through the signing process.

## Your Current Task:
Based on the information collected in the previous conversation, you should:

1. **Summarize the collected information** in a clear, structured format
2. **Present the fee breakdown** with exact calculations
3. **Explain the next steps** for contract signing and escrow deposit
4. **Provide a preview** of what the legal contract will contain

## Contract Summary Format:
**Website Development Legal Agreement**

**Project Details:**
- Site Name: {projectName}
- Description: {projectDescription}
- Client: {clientName}

**Financial Terms:**
- Payment Amount: {paymentAmount} USD
- Basic Platform Fee: 0.5 USD
- Escrow Fee (0.2%): {escrowFee} USD
- **Total Escrow Deposit Required: {totalAmount} USD**

**Next Steps:**
1. Both parties will review and digitally sign the legal contract
2. Client deposits the total escrow amount
3. Service provider begins work
4. Upon completion and verification, payment is released

## Your Response:
- Create a professional contract summary using the collected information
- Show all fee calculations clearly
- Explain the signing and deposit process
- Ask for final confirmation before proceeding to legal contract generation

End your response with:
- [PROCEED_TO_CONTRACT] - if user confirms and wants to proceed to final legal contract generation
- [MODIFY_TERMS] - if user wants to change something
- [RETURN_TO_INFO] - if user wants to go back to information collection`;

        // Calculate fees based on collected information
        const paymentAmount = state.financialInfo?.paymentAmount || 0;
        const escrowFee = Math.round((paymentAmount * 0.002) * 100) / 100; // 0.2% rounded to 2 decimals
        const platformFee = 0.5;
        const totalAmount = paymentAmount + escrowFee + platformFee;

        const prompt = ChatPromptTemplate.fromMessages([
            ["system", CONTRACT_CREATION_TEMPLATE],
            new MessagesPlaceholder({ variableName: "chat_history", optional: true }),
            ["human", "{input}"]
        ]);

        const response = await prompt.pipe(model).invoke({ 
            input: state.input, 
            chat_history: state.chatHistory,
            projectName: state.projectInfo?.projectName || "Not specified",
            projectDescription: state.projectInfo?.projectDescription || "Not specified",
            clientName: state.clientInfo?.clientName || "Not specified",
            paymentAmount: paymentAmount,
            escrowFee: escrowFee,
            totalAmount: totalAmount
        });

        console.log(response.content, "Contract Creation Node Response");

        const content = response.content as string;
        
        // Extract the intent classification from the response
        let operation = "contract_creation_node";
        if (content.includes("[PROCEED_TO_CONTRACT]")) {
            operation = "escrow"; // Route to final legal contract generation
        } else if (content.includes("[MODIFY_TERMS]")) {
            operation = "contract_creation_node";
        } else if (content.includes("[RETURN_TO_INFO]")) {
            operation = "escrow_info";
        }

        // Clean the response by removing the intent tag before returning to user
        const cleanedContent = content.replace(/\[(PROCEED_TO_CONTRACT|MODIFY_TERMS|RETURN_TO_INFO)\]/g, '').trim();

        // Update financial info with calculated fees
        const updatedFinancialInfo = {
            ...state.financialInfo,
            paymentAmount: paymentAmount,
            platformFees: platformFee,
            escrowFee: escrowFee,
            totalEscrowAmount: totalAmount
        };

        return { 
            ...state,
            result: cleanedContent,
            messages: [cleanedContent], 
            operation: operation,
            financialInfo: updatedFinancialInfo,
            stage: operation === "escrow" ? 'contract_creation' : 'information_collection'
        };
    });
    //@ts-ignore

    // Stage-based routing function for efficient conversation flow
    const routeByStage = (state: guildState) => {
        console.log("Routing based on stage:", state.stage, "Operation:", state.operation);
        
        // Direct routing based on current stage
        if (state.stage === 'information_collection' || state.information_collection) {
            return "escrow_info_node";
        }
        
        if (state.stage === 'contract_creation') {
            return "contract_creation_node";
        }
        
        // Operation-based routing (legacy support)
        if (state.operation === "escrow_info") {
            return "escrow_info_node";
        }
        
        if (state.operation === "contract_creation_node") {
            return "contract_creation_node";
        }
        
        if (state.operation === "escrow") {
            return "escrow_node";
        }
        
        // Default routing for initial conversations
        return "initial_node";
    };

    // Add conditional edges for stage-based routing
    graph.addConditionalEdges(START, routeByStage, {
        //@ts-ignore
        "initial_node": "initial_node",
        //@ts-ignore
        "escrow_info_node": "escrow_info_node",
        //@ts-ignore
        "contract_creation_node": "contract_creation_node",
        //@ts-ignore
        "escrow_node": "escrow_node"
    });

    // Add routing from initial_node based on user intent
    //@ts-ignore
    graph.addConditionalEdges("initial_node", (state: guildState) => {
        if (state.operation === "escrow_info") {
            return "escrow_info_node";
        }
        // Default to "end" string for all other cases (including "end" operation)
        return "end";
    }, {
        "escrow_info_node": "escrow_info_node",
        "end": END
    });

    // Add routing from escrow_info_node based on completion status
    //@ts-ignore
    graph.addConditionalEdges("escrow_info_node", (state: guildState) => {
        if (state.operation === "contract_creation_node") {
            return "contract_creation_node";
        }
        // Default to "end" string for all other cases (including "end" operation)
        return "end";
    }, {
        "contract_creation_node": "contract_creation_node",
        "end": END
    });

    // Add routing from contract_creation_node
    //@ts-ignore
    graph.addConditionalEdges("contract_creation_node", (state: guildState) => {
        if (state.operation === "escrow_info") {
            return "escrow_info_node";
        }
        if (state.operation === "escrow") {
            return "escrow_node";
        }
        return END;
    }, {
        "escrow_info_node": "escrow_info_node",
        "escrow_node": "escrow_node",
        end: END,
    });

    // Add the Escrow_Node - Final legal contract generation node
    graph.addNode("escrow_node", async (state: guildState) => {
        console.log("Generating legal contract with all collected information");

        try {
            // Extract actual data from state
            const clientName = state.clientInfo?.clientName || "Not specified";
            const projectName = state.projectInfo?.projectName || "Not specified";
            const projectDescription = state.projectInfo?.projectDescription || "Not specified";
            const paymentAmount = state.financialInfo?.paymentAmount || 0;
            const platformFee = state.financialInfo?.platformFees || 0.5;
            const escrowFee = state.financialInfo?.escrowFee || 0;
            const totalAmount = state.financialInfo?.totalEscrowAmount || 0.5;

            // Generate contract with AI but with specific instructions to use actual data
            const LEGAL_CONTRACT_TEMPLATE = `You are Pakt's Legal Contract Generator. Create a professional, clear legal contract document using the EXACT information provided below.

## IMPORTANT: Use these EXACT values in the contract:
- Client Name: ${clientName}
- Project Name: ${projectName}
- Project Description: ${projectDescription}
- Payment Amount: $${paymentAmount} USD
- Platform Fee: $${platformFee} USD
- Escrow Fee: $${escrowFee} USD
- Total Escrow Amount: $${totalAmount} USD

## Your Task:
Generate a professional legal contract document that includes:

1. **Contract Title and Parties** - Use the exact client name provided
2. **Project Scope and Deliverables** - Use the exact project name and description
3. **Payment Terms and Schedule** - Use the exact financial amounts provided
4. **Timeline and Milestones** - Include standard freelance milestones
5. **Terms and Conditions** - Standard legal clauses
6. **Signatures Section** - Professional signature blocks

## Format Requirements:
- Replace ALL placeholders with the actual data provided above
- Use clear, professional language
- Make it legally sound but readable
- Structure it as a formal contract document
- DO NOT leave any [PLACEHOLDER] text - use the actual values

Create a complete, professional legal contract document using the exact information provided.`;

            const prompt = ChatPromptTemplate.fromMessages([
                ["system", LEGAL_CONTRACT_TEMPLATE],
                ["human", "Please generate the legal contract using the exact information provided in the system message."]
            ]);

            const response = await prompt.pipe(model).invoke({
                input: "Generate legal contract with exact data"
            });

            console.log(response.content, "Legal Contract Generated");

            let contractContent = response.content as string;

            // Manual replacement as backup to ensure all data is properly inserted
            contractContent = contractContent
                .replace(/\[CLIENT NAME\]/g, clientName)
                .replace(/\[PROJECT NAME\]/g, projectName)
                .replace(/\[PROJECT DESCRIPTION\]/g, projectDescription)
                .replace(/\$0 USD/g, `$${paymentAmount} USD`)
                .replace(/\$0\.5 USD/g, `$${platformFee} USD`)
                .replace(/\[FREELANCER NAME\]/g, "[FREELANCER NAME]") // Keep as placeholder for freelancer
                .replace(/\[CLIENT ADDRESS\]/g, "[CLIENT ADDRESS]") // Keep as placeholder
                .replace(/\[FREELANCER ADDRESS\]/g, "[FREELANCER ADDRESS]") // Keep as placeholder
                .replace(/\[FREELANCER PROFESSION\]/g, "[FREELANCER PROFESSION]") // Keep as placeholder
                .replace(/\[CLIENT PROFESSION\/COMPANY\]/g, clientName)
                .replace(/\[LIST OF SPECIFIC SERVICES OR DELIVERABLES\]/g, `Website development for ${projectName}: ${projectDescription}`)
                .replace(/\[START DATE\]/g, "[START DATE]") // Keep as placeholder
                .replace(/\[END DATE\]/g, "[END DATE]") // Keep as placeholder
                .replace(/\[CURRENT DATE\]/g, new Date().toLocaleDateString());

            // Create properly structured response object with actual data
            const structuredResponse = {
                success: true,
                contractType: "legal_document",
                legalContract: contractContent,
                projectInfo: {
                    projectName: projectName,
                    projectDescription: projectDescription,
                    deliverables: [`Website development for ${projectName}`, "Source code delivery", "Documentation"],
                    timeline: "To be determined by freelancer",
                    requirements: projectDescription,
                    revisions: 2
                },
                clientInfo: {
                    clientName: clientName,
                    walletAddress: state.walletAddress || null // Use wallet address from state
                },
                financialInfo: {
                    paymentAmount: paymentAmount,
                    platformFees: platformFee,
                    escrowFee: escrowFee,
                    totalEscrowAmount: totalAmount
                },
                contractDetails: {
                    createdAt: new Date().toISOString(),
                    status: 'ready_for_signing',
                    type: 'freelance_legal_contract'
                },
                message: `Legal contract has been generated successfully for ${projectName}. Client: ${clientName}, Payment: $${paymentAmount} USD. Please review the terms and conditions.`
            };

            return { 
                ...state,
                contractData: structuredResponse,
                result: "", // Empty result to prevent text message display
                messages: [] // Empty messages array
            };
        } catch (error) {
            console.error("Error in escrow_node:", error);
            
            // Return structured error response with available data
            const errorResponse = {
                success: false,
                error: "Failed to generate legal contract",
                projectInfo: state.projectInfo || {},
                clientInfo: state.clientInfo || {},
                financialInfo: state.financialInfo || {},
                contractDetails: {
                    createdAt: new Date().toISOString(),
                    status: 'error',
                    type: 'freelance_legal_contract'
                },
                message: "I apologize, but there was an error generating the legal contract. Please try again or provide more information about your requirements."
            };
            
            return { 
                ...state,
                result: "", // Empty result to prevent text message display
                messages: [] // Empty messages array
            };
        }
    });

//@ts-ignore
graph.addEdge("escrow_node", END);

const data = graph.compile();
return data;
}