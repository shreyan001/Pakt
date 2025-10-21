/**
 * 0G Compute Network Configuration
 * 
 * This file contains configuration for integrating with 0G Compute Network's
 * secure inference capabilities using TEE (Trusted Execution Environment) or
 * ZKP (Zero-Knowledge Proof) verification modes.
 */

export interface OGComputeConfig {
  privateKey: string;
  rpcUrl: string;
  verificationMode: 'TEE' | 'ZKP';
  timeout: number;
  retryAttempts: number;
  retryDelay: number;
}

/**
 * Get 0G Compute configuration from environment variables
 */
export const ogComputeConfig: OGComputeConfig = {
  // Private key for 0G Compute wallet (server-side only)
  privateKey: process.env.OG_COMPUTE_PRIVATE_KEY || process.env.AGENT_PRIVATE_KEY || '',
  
  // RPC URL for 0G Network
  rpcUrl: process.env.NEXT_PUBLIC_ZEROG_RPC_URL || 'https://evmrpc-testnet.0g.ai',
  
  // Verification mode: TEE (Trusted Execution Environment) or ZKP (Zero-Knowledge Proof)
  verificationMode: (process.env.OG_COMPUTE_VERIFICATION_MODE || 'TEE') as 'TEE' | 'ZKP',
  
  // Timeout for inference operations (60 seconds)
  timeout: parseInt(process.env.OG_COMPUTE_TIMEOUT || '60000', 10),
  
  // Number of retry attempts for failed operations
  retryAttempts: parseInt(process.env.OG_COMPUTE_RETRY_ATTEMPTS || '3', 10),
  
  // Delay between retry attempts (2 seconds)
  retryDelay: parseInt(process.env.OG_COMPUTE_RETRY_DELAY || '2000', 10),
};

/**
 * Validate that all required configuration values are present
 * @throws Error if required configuration is missing
 */
export function validateOGComputeConfig(): void {
  const missingVars: string[] = [];
  
  if (!ogComputeConfig.privateKey) {
    missingVars.push('OG_COMPUTE_PRIVATE_KEY or AGENT_PRIVATE_KEY');
  }
  
  if (missingVars.length > 0) {
    throw new Error(
      `Missing required 0G Compute configuration: ${missingVars.join(', ')}. ` +
      'Please add these environment variables to your .env file.'
    );
  }
}

/**
 * Check if 0G Compute is properly configured
 * @returns true if all required configuration is present
 */
export function isOGComputeConfigured(): boolean {
  return !!ogComputeConfig.privateKey;
}
