// Download files from 0G Storage
import { NextRequest, NextResponse } from 'next/server'
import { ZeroGStorageService } from '@/lib/0gStorageService'
import * as fs from 'fs'
import * as path from 'path'
import * as os from 'os'

export async function POST(request: NextRequest) {
  try {
    const { storageHash } = await request.json()
    
    if (!storageHash) {
      return NextResponse.json(
        { error: 'Storage hash is required' },
        { status: 400 }
      )
    }
    
    console.log('📥 Downloading from 0G Storage:', storageHash)
    
    // Initialize 0G Storage Service
    const storageService = new ZeroGStorageService()
    
    // Create temp download path
    const tempDir = os.tmpdir()
    const downloadPath = path.join(tempDir, `Pakt_download_${Date.now()}.json`)
    
    // Download file
    const downloadResult = await storageService.downloadFile(storageHash, downloadPath)
    
    if (!downloadResult.success) {
      return NextResponse.json(
        { error: downloadResult.error || 'Download failed' },
        { status: 500 }
      )
    }
    
    // Read the downloaded file
    const fileContent = fs.readFileSync(downloadPath, 'utf-8')
    const metadata = JSON.parse(fileContent)
    
    // Clean up temp file
    fs.unlinkSync(downloadPath)
    
    console.log('✅ Download successful!')
    
    return NextResponse.json({
      success: true,
      metadata,
      storageHash
    })
  } catch (error: any) {
    console.error('❌ Download error:', error)
    return NextResponse.json(
      { error: error.message || 'Download failed' },
      { status: 500 }
    )
  }
}
