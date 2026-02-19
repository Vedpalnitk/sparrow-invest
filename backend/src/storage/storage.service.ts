import {
  Injectable,
  BadRequestException,
  OnModuleInit,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import * as Minio from 'minio';

const BUCKET = 'insurance-documents';
const ADVISOR_BUCKET = 'advisor-assets';

const ALLOWED_MIME_TYPES = [
  'application/pdf',
  'image/jpeg',
  'image/png',
];

const MAX_FILE_SIZE = 10 * 1024 * 1024; // 10 MB

@Injectable()
export class StorageService implements OnModuleInit {
  private client: Minio.Client;

  constructor(private config: ConfigService) {
    this.client = new Minio.Client({
      endPoint: this.config.get<string>('minio.endpoint', 'localhost'),
      port: this.config.get<number>('minio.port', 9000),
      useSSL: false,
      accessKey: this.config.get<string>('minio.accessKey', 'minioadmin'),
      secretKey: this.config.get<string>('minio.secretKey', 'minioadmin'),
    });
  }

  async onModuleInit() {
    for (const bucket of [BUCKET, ADVISOR_BUCKET]) {
      try {
        const exists = await this.client.bucketExists(bucket);
        if (!exists) {
          await this.client.makeBucket(bucket);
        }
      } catch {
        console.warn(`[StorageService] Could not initialise bucket "${bucket}". Is MinIO running?`);
      }
    }
  }

  validateFile(file: { mimetype?: string; size?: number }) {
    if (!file.mimetype || !ALLOWED_MIME_TYPES.includes(file.mimetype)) {
      throw new BadRequestException(
        'Invalid file type. Only PDF, JPG, and PNG files are allowed.',
      );
    }
    if (file.size && file.size > MAX_FILE_SIZE) {
      throw new BadRequestException(
        'File too large. Maximum size is 10 MB.',
      );
    }
  }

  async uploadDocument(
    fileKey: string,
    buffer: Buffer,
    mimeType: string,
  ): Promise<void> {
    await this.client.putObject(BUCKET, fileKey, buffer, buffer.length, {
      'Content-Type': mimeType,
    });
  }

  async getSignedUrl(fileKey: string, expiry = 3600): Promise<string> {
    return this.client.presignedGetObject(BUCKET, fileKey, expiry);
  }

  async deleteDocument(fileKey: string): Promise<void> {
    await this.client.removeObject(BUCKET, fileKey);
  }

  async uploadAdvisorAsset(
    fileKey: string,
    buffer: Buffer,
    mimeType: string,
  ): Promise<void> {
    await this.client.putObject(ADVISOR_BUCKET, fileKey, buffer, buffer.length, {
      'Content-Type': mimeType,
    });
  }

  async getAdvisorAssetUrl(fileKey: string, expiry = 86400): Promise<string> {
    return this.client.presignedGetObject(ADVISOR_BUCKET, fileKey, expiry);
  }
}
