import { Injectable, Logger, BadRequestException } from '@nestjs/common'
import { BseHttpClient } from '../core/bse-http.client'
import { BseAuthService } from '../auth/bse-auth.service'
import { BseCredentialsService } from '../credentials/bse-credentials.service'
import { BseMockService } from '../mocks/bse-mock.service'
import { ConfigService } from '@nestjs/config'
import { BSE_ENDPOINTS, BSE_TIMEOUTS } from '../core/bse-config'

@Injectable()
export class BseUploadService {
  private readonly logger = new Logger(BseUploadService.name)
  private readonly isMockMode: boolean
  private readonly MAX_AOF_SIZE = 30 * 1024 // 30KB

  constructor(
    private httpClient: BseHttpClient,
    private authService: BseAuthService,
    private credentialsService: BseCredentialsService,
    private mockService: BseMockService,
    private config: ConfigService,
  ) {
    this.isMockMode = this.config.get<boolean>('bse.mockMode') === true
  }

  async uploadAof(advisorId: string, clientCode: string, fileBuffer: Buffer, fileName: string) {
    if (fileBuffer.length > this.MAX_AOF_SIZE) {
      throw new BadRequestException('AOF file size exceeds 30KB limit')
    }

    if (this.isMockMode) {
      return { success: true, message: 'AOF uploaded (mock)' }
    }

    const credentials = await this.credentialsService.getDecryptedCredentials(advisorId)
    const base64Data = fileBuffer.toString('base64')

    const response = await this.httpClient.jsonRequest(
      BSE_ENDPOINTS.IMAGE_UPLOAD_BASE64,
      'POST',
      {
        MemberCode: credentials.memberId,
        ClientCode: clientCode,
        FileName: fileName,
        FileData: base64Data,
        FileType: 'AOF',
      },
      advisorId,
      'AOF_Upload',
      {},
      BSE_TIMEOUTS.UPLOAD,
    )

    return {
      success: response.parsed?.Status === '100',
      message: response.parsed?.Message || 'Upload complete',
    }
  }

  async uploadMandateScan(advisorId: string, mandateId: string, fileBuffer: Buffer) {
    if (this.isMockMode) {
      return { success: true, message: 'Mandate scan uploaded (mock)' }
    }

    const credentials = await this.credentialsService.getDecryptedCredentials(advisorId)
    const base64Data = fileBuffer.toString('base64')

    const response = await this.httpClient.jsonRequest(
      BSE_ENDPOINTS.MANDATE_SCAN_UPLOAD,
      'POST',
      {
        MemberCode: credentials.memberId,
        MandateId: mandateId,
        FileData: base64Data,
      },
      advisorId,
      'MandateScan_Upload',
      {},
      BSE_TIMEOUTS.UPLOAD,
    )

    return {
      success: response.parsed?.Status === '100',
      message: response.parsed?.Message || 'Upload complete',
    }
  }

  async uploadChequeImage(advisorId: string, clientCode: string, fileBuffer: Buffer) {
    if (this.isMockMode) {
      return { success: true, message: 'Cheque image uploaded (mock)' }
    }

    const credentials = await this.credentialsService.getDecryptedCredentials(advisorId)
    const base64Data = fileBuffer.toString('base64')

    const response = await this.httpClient.jsonRequest(
      BSE_ENDPOINTS.IMAGE_UPLOAD_BASE64,
      'POST',
      {
        MemberCode: credentials.memberId,
        ClientCode: clientCode,
        FileData: base64Data,
        FileType: 'CHEQUE',
      },
      advisorId,
      'Cheque_Upload',
      {},
      BSE_TIMEOUTS.UPLOAD,
    )

    return {
      success: response.parsed?.Status === '100',
      message: response.parsed?.Message || 'Upload complete',
    }
  }
}
