'use server';
import * as fs from 'fs';
import * as path from 'path';
import archiver from 'archiver';

/**
 * Filecoin Storage Service using web3.storage
 * 
 * This service provides decentralized storage functionality on Filecoin/IPFS
 * via the web3.storage gateway.
 */

export interface UploadResult {
    success: boolean;
    cid?: string; // Content Identifier (IPFS hash)
    url?: string; // Gateway URL to access the file
    error?: string;
}

export interface FolderUploadResult {
    success: boolean;
    cid?: string;
    url?: string;
    error?: string;
}

export interface DownloadResult {
    success: boolean;
    filePath?: string;
    error?: string;
}

export interface FileInfo {
    cid: string;
    size?: number;
    created?: string;
}

/**
 * FilecoinStorageService
 * 
 * Provides upload/download functionality using web3.storage (Filecoin + IPFS)
 * 
 * Environment variables required:
 * - WEB3_STORAGE_TOKEN: API token from https://web3.storage
 */
export class FilecoinStorageService {
    private token: string;
    private gatewayUrl: string;

    constructor() {
        const token = process.env.WEB3_STORAGE_TOKEN;
        if (!token) {
            console.warn('WEB3_STORAGE_TOKEN not set - storage features will be disabled');
        }
        this.token = token || '';
        this.gatewayUrl = process.env.FILECOIN_GATEWAY_URL || 'https://w3s.link/ipfs';
    }

    /**
     * Check if the service is properly configured
     */
    isConfigured(): boolean {
        return !!this.token;
    }

    /**
     * Upload a file to Filecoin/IPFS via web3.storage
     */
    async uploadFile(filePath: string): Promise<UploadResult> {
        if (!this.isConfigured()) {
            return { success: false, error: 'Storage service not configured - missing WEB3_STORAGE_TOKEN' };
        }

        try {
            // Read file
            if (!fs.existsSync(filePath)) {
                return { success: false, error: `File not found: ${filePath}` };
            }

            const fileContent = fs.readFileSync(filePath);
            const fileName = path.basename(filePath);

            // Create form data for upload
            const formData = new FormData();
            const blob = new Blob([new Uint8Array(fileContent)]);
            formData.append('file', blob, fileName);

            // Upload to web3.storage
            const response = await fetch('https://api.web3.storage/upload', {
                method: 'POST',
                headers: {
                    'Authorization': `Bearer ${this.token}`,
                },
                body: formData,
            });

            if (!response.ok) {
                const errorText = await response.text();
                return { success: false, error: `Upload failed: ${errorText}` };
            }

            const result = await response.json();
            const cid = result.cid;

            return {
                success: true,
                cid,
                url: `${this.gatewayUrl}/${cid}`,
            };
        } catch (error) {
            console.error('Upload error:', error);
            return { success: false, error: `Upload failed: ${error}` };
        }
    }

    /**
     * Upload a folder to Filecoin/IPFS by first archiving it
     */
    async uploadFolder(folderPath: string): Promise<FolderUploadResult> {
        if (!this.isConfigured()) {
            return { success: false, error: 'Storage service not configured - missing WEB3_STORAGE_TOKEN' };
        }

        try {
            // Check if folder exists
            if (!fs.existsSync(folderPath) || !fs.statSync(folderPath).isDirectory()) {
                return { success: false, error: `Folder not found: ${folderPath}` };
            }

            // Create a temporary zip file
            const tempZipPath = path.join(process.cwd(), 'temp', `upload_${Date.now()}.zip`);

            // Ensure temp directory exists
            const tempDir = path.dirname(tempZipPath);
            if (!fs.existsSync(tempDir)) {
                fs.mkdirSync(tempDir, { recursive: true });
            }

            // Create zip archive
            await this.createZipArchive(folderPath, tempZipPath);

            // Upload the zip file
            const uploadResult = await this.uploadFile(tempZipPath);

            // Clean up temp file
            if (fs.existsSync(tempZipPath)) {
                fs.unlinkSync(tempZipPath);
            }

            return uploadResult;
        } catch (error) {
            console.error('Folder upload error:', error);
            return { success: false, error: `Folder upload failed: ${error}` };
        }
    }

    /**
     * Download a file from IPFS using CID
     */
    async downloadFile(cid: string, outputPath: string): Promise<DownloadResult> {
        try {
            const url = `${this.gatewayUrl}/${cid}`;

            const response = await fetch(url);
            if (!response.ok) {
                return { success: false, error: `Download failed: ${response.statusText}` };
            }

            const arrayBuffer = await response.arrayBuffer();
            const buffer = Buffer.from(arrayBuffer);

            // Ensure output directory exists
            const outputDir = path.dirname(outputPath);
            if (!fs.existsSync(outputDir)) {
                fs.mkdirSync(outputDir, { recursive: true });
            }

            fs.writeFileSync(outputPath, buffer);

            return { success: true, filePath: outputPath };
        } catch (error) {
            console.error('Download error:', error);
            return { success: false, error: `Download failed: ${error}` };
        }
    }

    /**
     * Get the gateway URL for a CID
     */
    getGatewayUrl(cid: string): string {
        return `${this.gatewayUrl}/${cid}`;
    }

    /**
     * Create a zip archive from a folder
     */
    private createZipArchive(folderPath: string, outputPath: string): Promise<void> {
        return new Promise((resolve, reject) => {
            const output = fs.createWriteStream(outputPath);
            const archive = archiver('zip', { zlib: { level: 9 } });

            output.on('close', () => resolve());
            archive.on('error', (err) => reject(err));

            archive.pipe(output);
            archive.directory(folderPath, false);
            archive.finalize();
        });
    }
}

// Export singleton instance
export const filecoinStorage = new FilecoinStorageService();
