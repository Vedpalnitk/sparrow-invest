import { Injectable, Logger, NotFoundException } from '@nestjs/common'
import { PrismaService } from '../../prisma/prisma.service'
import { BseHttpClient } from '../core/bse-http.client'
import { BseSoapBuilder } from '../core/bse-soap.builder'
import { BseAuthService } from '../auth/bse-auth.service'
import { BseErrorMapper } from '../core/bse-error.mapper'
import { BseCredentialsService } from '../credentials/bse-credentials.service'
import { BseMockService } from '../mocks/bse-mock.service'
import { ConfigService } from '@nestjs/config'
import { BSE_ENDPOINTS, BSE_SOAP_ACTIONS } from '../core/bse-config'
import { UploadCkycDto } from './dto/register-ucc.dto'

@Injectable()
export class BseCkycService {
  private readonly logger = new Logger(BseCkycService.name)
  private readonly isMockMode: boolean

  constructor(
    private prisma: PrismaService,
    private httpClient: BseHttpClient,
    private soapBuilder: BseSoapBuilder,
    private authService: BseAuthService,
    private errorMapper: BseErrorMapper,
    private credentialsService: BseCredentialsService,
    private mockService: BseMockService,
    private config: ConfigService,
  ) {
    this.isMockMode = this.config.get<boolean>('bse.mockMode') === true
  }

  async uploadCkyc(clientId: string, advisorId: string, dto: UploadCkycDto) {
    const client = await this.prisma.fAClient.findUnique({
      where: { id: clientId },
      select: { advisorId: true },
    })

    if (!client || client.advisorId !== advisorId) {
      throw new NotFoundException('Client not found')
    }

    if (this.isMockMode) {
      const mockResult = this.mockService.mockCkycUploadResponse()
      const parsed = this.errorMapper.parsePipeResponse(mockResult)

      await this.updateCkycStatus(clientId, parsed.success ? 'UPLOADED' : 'FAILED')

      return { success: parsed.success, message: parsed.message }
    }

    const credentials = await this.credentialsService.getDecryptedCredentials(advisorId)
    const token = await this.authService.getAdditionalServicesToken(advisorId)

    const ckycParams = this.soapBuilder.buildPipeParams([
      dto.pan,
      dto.ckycNumber,
    ])

    const body = this.soapBuilder.buildAdditionalServicesBody(
      '13', // CKYC flag
      credentials.userIdBse,
      credentials.memberId,
      token,
      ckycParams,
    )

    const response = await this.httpClient.soapRequest(
      BSE_ENDPOINTS.ADDITIONAL_SERVICES,
      BSE_SOAP_ACTIONS.ADDITIONAL_RESPONSE,
      body,
      advisorId,
      'CKYC_Upload',
    )

    const result = this.errorMapper.parsePipeResponse(response.body)
    await this.updateCkycStatus(clientId, result.success ? 'UPLOADED' : 'FAILED')

    return { success: result.success, message: result.message }
  }

  private async updateCkycStatus(clientId: string, status: string) {
    await this.prisma.bseUccRegistration.updateMany({
      where: { clientId },
      data: { ckycStatus: status },
    })
  }
}
