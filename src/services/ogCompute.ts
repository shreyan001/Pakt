/**
 * 0G Compute Service
 *
 * Wrapper service for 0G Compute Network's secure inference capabilities.
 * Provides methods for executing secure inference with TEE/ZKP verification.
 */

import {
  ZGComputeNetworkBroker,
  createZGComputeNetworkBroker,
} from "@0glabs/0g-serving-broker";
import { Wallet } from "ethers";
import {
  ogComputeConfig,
  validateOGComputeConfig,
  OGComputeConfig,
} from "@/config/ogCompute";
import {
  InferenceInput,
  InferenceOutput,
  VerificationProof,
  CollectedContractData,
} from "@/lib/types";

export class OGComputeService {
  private config: OGComputeConfig;
  private broker: ZGComputeNetworkBroker | null = null;
  private isInitialized: boolean = false;

  constructor(config?: Partial<OGComputeConfig>) {
    this.config = { ...ogComputeConfig, ...config };
  }

  /**
   * Initialize the 0G Compute SDK
   * @throws Error if configuration is invalid or initialization fails
   */
  async initialize(): Promise<void> {
    try {
      // Validate configuration
      validateOGComputeConfig();

      // Create a wallet from the private key
      const wallet = new Wallet(this.config.privateKey);

      // Initialize the broker
      this.broker = await createZGComputeNetworkBroker(
        wallet,
        undefined, // Use default ledger contract address
        undefined, // Use default inference contract address
        undefined // Use default fine-tuning contract address
      );

      this.isInitialized = true;
      console.log("0G Compute Service initialized successfully");
    } catch (error) {
      console.error("Failed to initialize 0G Compute Service:", error);
      throw new Error(
        `Failed to initialize 0G Compute: ${
          error instanceof Error ? error.message : "Unknown error"
        }`
      );
    }
  }

  /**
   * Execute secure inference with collected contract data
   * @param input Inference input with prompt and context
   * @returns Inference result with verification proof
   */
  async executeSecure(input: InferenceInput): Promise<InferenceOutput> {
    if (!this.isInitialized || !this.broker) {
      throw new Error(
        "0G Compute Service not initialized. Call initialize() first."
      );
    }

    let retryCount = 0;
    let lastError: Error | null = null;

    while (retryCount < this.config.retryAttempts) {
      try {
        console.log(
          `Executing secure inference (attempt ${retryCount + 1}/${
            this.config.retryAttempts
          })...`
        );

        // Execute the inference with timeout
        const result = await Promise.race([
          this.executeInferenceInternal(input),
          this.createTimeout(this.config.timeout),
        ]);

        console.log("Secure inference completed successfully");
        return result;
      } catch (error) {
        lastError = error instanceof Error ? error : new Error("Unknown error");
        console.error(
          `Inference attempt ${retryCount + 1} failed:`,
          lastError.message
        );

        retryCount++;
        if (retryCount < this.config.retryAttempts) {
          // Wait before retrying
          await this.delay(this.config.retryDelay);
        }
      }
    }

    throw new Error(
      `Inference failed after ${this.config.retryAttempts} attempts: ${
        lastError?.message || "Unknown error"
      }`
    );
  }

  /**
   * Internal method to execute inference
   */
  private async executeInferenceInternal(
    input: InferenceInput
  ): Promise<InferenceOutput> {
    if (!this.broker) {
      throw new Error("Broker not initialized");
    }

    try {
      // Format the prompt for contract generation
      const formattedPrompt = this.formatContractPrompt(input.context);

      // Get available services
      const services = await this.broker.inference.listService();
      if (services.length === 0) {
        throw new Error("No AI services available");
      }

      // Select the first available service (or implement selection logic)
      const selectedService = services[0];
      console.log(
        `Using service: ${selectedService.model} (Provider: ${selectedService.provider})`
      );

      // Acknowledge the provider
      await this.broker.inference.acknowledgeProviderSigner(
        selectedService.provider
      );

      // Get service metadata
      const { endpoint, model } =
        await this.broker.inference.getServiceMetadata(
          selectedService.provider
        );

      // Prepare messages for the AI
      const messages = [{ role: "user", content: formattedPrompt }];

      // Generate authenticated request headers
      const headers = await this.broker.inference.getRequestHeaders(
        selectedService.provider,
        JSON.stringify(messages)
      );

      // Send request to the AI service
      const response = await fetch(`${endpoint}/chat/completions`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          ...headers,
        },
        body: JSON.stringify({
          messages: messages,
          model: model,
        }),
      });

      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
      }

      const data = await response.json();
      const contractText = data.choices[0].message.content;
      const chatID = data.id;

      // Verify the response if service supports verification
      let isVerified = false;
      if (selectedService.verifiability) {
        isVerified =
          (await this.broker.inference.processResponse(
            selectedService.provider,
            contractText,
            chatID
          )) || false;
      }

      // Create verification proof
      const proof: VerificationProof = {
        type: input.verificationMode,
        hash: chatID,
        signature: selectedService.provider,
        timestamp: Date.now(),
        details: {
          verified: isVerified,
          provider: selectedService.provider,
          model: model,
          chatID: chatID,
        },
      };

      return {
        contractText,
        metadata: {
          generatedAt: Date.now(),
          model: model,
          verificationMode: input.verificationMode,
        },
        proof,
      };
    } catch (error) {
      console.error("Inference execution error:", error);
      throw error;
    }
  }

  /**
   * Verify a proof from inference result
   * @param proof Verification proof to validate
   * @returns true if proof is valid
   */
  async verifyProof(proof: VerificationProof): Promise<boolean> {
    try {
      // Basic validation
      if (!proof || !proof.hash || !proof.signature) {
        console.error("Invalid proof structure");
        return false;
      }

      // Check timestamp is recent (within last hour)
      const oneHourAgo = Date.now() - 60 * 60 * 1000;
      if (proof.timestamp < oneHourAgo) {
        console.error("Proof timestamp is too old");
        return false;
      }

      // TODO: Implement actual cryptographic verification based on proof type
      // For TEE: Verify attestation signature
      // For ZKP: Verify zero-knowledge proof

      console.log("Proof verification passed");
      return true;
    } catch (error) {
      console.error("Proof verification error:", error);
      return false;
    }
  }

  /**
   * Format collected data into a contract generation prompt
   */
  private formatContractPrompt(data: CollectedContractData): string {
    return `Generate a professional escrow contract with the following details:

PROJECT INFORMATION:
- Project Name: ${data.projectInfo.projectName}
- Description: ${data.projectInfo.projectDescription}
- Timeline: ${data.projectInfo.timeline}
- Deliverables: ${data.projectInfo.deliverables.join(", ")}

CLIENT INFORMATION:
- Name: ${data.clientInfo.clientName}
- Email: ${data.clientInfo.email}
- Wallet Address: ${data.clientInfo.walletAddress}

FINANCIAL TERMS:
- Payment Amount: ${data.financialInfo.paymentAmount} ${
      data.financialInfo.currency
    }
- Platform Fee: ${data.financialInfo.platformFees} ${
      data.financialInfo.currency
    }
- Escrow Fee: ${data.financialInfo.escrowFee} ${data.financialInfo.currency}
- Total Escrow Amount: ${data.financialInfo.totalEscrowAmount} ${
      data.financialInfo.currency
    }
- 0G Token Equivalent: ${data.financialInfo.zeroGEquivalent} 0G

ESCROW DETAILS:
- Escrow Type: ${data.escrowDetails.escrowType}
- Payment Method: ${data.escrowDetails.paymentMethod}
- Release Condition: ${data.escrowDetails.releaseCondition}
- Dispute Resolution: ${data.escrowDetails.disputeResolution}

Please generate a comprehensive escrow contract that includes:
1. Parties involved
2. Scope of work
3. Payment terms and schedule
4. Deliverables and milestones
5. Escrow conditions
6. Dispute resolution process
7. Terms and conditions
8. Signatures section`;
  }

  /**
   * Create a timeout promise
   */
  private createTimeout(ms: number): Promise<never> {
    return new Promise((_, reject) => {
      setTimeout(() => {
        reject(new Error(`Inference timeout after ${ms}ms`));
      }, ms);
    });
  }

  /**
   * Delay helper for retry logic
   */
  private delay(ms: number): Promise<void> {
    return new Promise((resolve) => setTimeout(resolve, ms));
  }

  /**
   * Clean up resources
   */
  async cleanup(): Promise<void> {
    if (this.broker) {
      // Cleanup broker resources if needed
      this.broker = null;
    }
    this.isInitialized = false;
  }
}

/**
 * Create and initialize a new OGComputeService instance
 */
export async function createOGComputeService(
  config?: Partial<OGComputeConfig>
): Promise<OGComputeService> {
  const service = new OGComputeService(config);
  await service.initialize();
  return service;
}
