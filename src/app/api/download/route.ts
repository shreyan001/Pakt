import { NextRequest, NextResponse } from 'next/server';
import { ZeroGStorageService } from '@/lib/0gStorageService';
import * as fs from 'fs';
import * as path from 'path';
import { v4 as uuidv4 } from 'uuid';
import os from 'os';

export async function POST(request: NextRequest) {
  try {
    const { rootHash } = await request.json();

    if (!rootHash) {
      return NextResponse.json(
        { error: 'Root hash is required' },
        { status: 400 }
      );
    }

    // Create a temporary directory for the download
    const tempDir = path.join(os.tmpdir(), 'Pakt-downloads');
    if (!fs.existsSync(tempDir)) {
      fs.mkdirSync(tempDir, { recursive: true });
    }

    // Generate a unique filename
    const uniqueId = uuidv4();
    const outputPath = path.join(tempDir, `${uniqueId}.zip`);

    // Initialize 0G Storage service
    const storageService = new ZeroGStorageService();

    // Download the file
    const downloadResult = await storageService.downloadFile(rootHash, outputPath);

    if (!downloadResult.success) {
      return NextResponse.json(
        { error: downloadResult.error || 'Download failed' },
        { status: 500 }
      );
    }

    // Read the file as a buffer
    const fileBuffer = fs.readFileSync(outputPath);

    // Clean up the temporary file
    fs.unlinkSync(outputPath);

    // Return the file as a response
    return new NextResponse(fileBuffer, {
      headers: {
        'Content-Type': 'application/octet-stream',
        'Content-Disposition': 'attachment; filename="project-files.zip"',
      },
    });
  } catch (error: any) {
    console.error('Download API error:', error);
    return NextResponse.json(
      { error: error.message || 'An unexpected error occurred' },
      { status: 500 }
    );
  }
}