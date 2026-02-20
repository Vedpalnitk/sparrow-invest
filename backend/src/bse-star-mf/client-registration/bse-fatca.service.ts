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
import { UploadFatcaDto } from './dto/register-ucc.dto'

@Injectable()
export class BseFatcaService {
  private readonly logger = new Logger(BseFatcaService.name)
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

  async uploadFatca(clientId: string, advisorId: string, dto: UploadFatcaDto) {
    const client = await this.prisma.fAClient.findUnique({
      where: { id: clientId },
      select: { advisorId: true, name: true, pan: true, dateOfBirth: true, address: true, city: true, state: true, pincode: true },
    })

    if (!client || client.advisorId !== advisorId) {
      throw new NotFoundException('Client not found')
    }

    if (this.isMockMode) {
      const mockResult = this.mockService.mockFatcaUploadResponse()
      const parsed = this.errorMapper.parsePipeResponse(mockResult)

      await this.updateFatcaStatus(clientId, parsed.success ? 'UPLOADED' : 'FAILED')

      return { success: parsed.success, message: parsed.message }
    }

    const credentials = await this.credentialsService.getDecryptedCredentials(advisorId)
    const token = await this.authService.getAdditionalServicesToken(advisorId)

    // Build FATCA params (flag 01, 75 pipe-separated fields)
    const fatcaParams = this.soapBuilder.buildPipeParams([
      dto.pan,                    // PAN
      client.name,                // Name
      dto.taxStatus || '01',      // Tax Status (Individual)
      dto.sourceOfWealth || '02', // Source of Wealth
      dto.incomeSlab || '31',     // Income Slab
      dto.pepStatus || 'N',       // PEP
      dto.addressType || '1',     // Address Type
      client.address || '',       // Address
      client.city || '',          // City
      client.state || '',         // State
      client.pincode || '',       // Pincode
      'IN',                       // Country
      dto.countryOfBirth || 'IN', // Birth Country
      dto.citizenshipCountry || 'IN', // Citizenship
      dto.nationalityCountry || 'IN', // Nationality
    ])

    const body = this.soapBuilder.buildAdditionalServicesBody(
      '01', // FATCA flag
      credentials.userIdBse,
      credentials.memberId,
      token,
      fatcaParams,
    )

    const response = await this.httpClient.soapRequest(
      BSE_ENDPOINTS.ADDITIONAL_SERVICES,
      BSE_SOAP_ACTIONS.ADDITIONAL_RESPONSE,
      body,
      advisorId,
      'FATCA_Upload',
    )

    const result = this.errorMapper.parsePipeResponse(response.body)
    await this.updateFatcaStatus(clientId, result.success ? 'UPLOADED' : 'FAILED')

    return { success: result.success, message: result.message }
  }

  private async updateFatcaStatus(clientId: string, status: string) {
    await this.prisma.bseUccRegistration.updateMany({
      where: { clientId },
      data: { fatcaStatus: status },
    })
  }
}
