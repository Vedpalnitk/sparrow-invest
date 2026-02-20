import { Injectable, Logger, NotFoundException } from '@nestjs/common'
import { PrismaService } from '../../prisma/prisma.service'
import { BseHttpClient } from '../core/bse-http.client'
import { BseErrorMapper } from '../core/bse-error.mapper'
import { BseCredentialsService } from '../credentials/bse-credentials.service'
import { BseReferenceNumberService } from '../core/bse-reference-number.service'
import { BseMockService } from '../mocks/bse-mock.service'
import { ConfigService } from '@nestjs/config'
import { BSE_ENDPOINTS } from '../core/bse-config'
import { RegisterStpDto } from './dto/register-sip.dto'
import { BseOrderType, BseOrderStatus } from '@prisma/client'

@Injectable()
export class BseStpService {
  private readonly logger = new Logger(BseStpService.name)
  private readonly isMockMode: boolean

  constructor(
    private prisma: PrismaService,
    private httpClient: BseHttpClient,
    private errorMapper: BseErrorMapper,
    private credentialsService: BseCredentialsService,
    private refNumberService: BseReferenceNumberService,
    private mockService: BseMockService,
    private config: ConfigService,
  ) {
    this.isMockMode = this.config.get<boolean>('bse.mockMode') === true
  }

  async registerStp(advisorId: string, dto: RegisterStpDto) {
    await this.verifyClientAccess(dto.clientId, advisorId)

    const credentials = await this.credentialsService.getDecryptedCredentials(advisorId)
    const ucc = await this.prisma.bseUccRegistration.findUnique({
      where: { clientId: dto.clientId },
    })

    if (!ucc?.clientCode) {
      throw new NotFoundException('Client not registered with BSE')
    }

    const refNumber = await this.refNumberService.generate(credentials.memberId)

    const order = await this.prisma.bseOrder.create({
      data: {
        clientId: dto.clientId,
        advisorId,
        orderType: BseOrderType.STP,
        status: BseOrderStatus.CREATED,
        referenceNumber: refNumber,
        schemeCode: dto.fromSchemeCode,
        switchSchemeCode: dto.toSchemeCode,
        amount: dto.amount,
        frequency: dto.frequency,
        sipStartDate: new Date(dto.startDate),
        sipEndDate: dto.endDate ? new Date(dto.endDate) : null,
        installments: dto.installments,
        folioNumber: dto.folioNumber,
      },
    })

    if (this.isMockMode) {
      const mockResult = this.mockService.mockStpRegistrationResponse()

      await this.prisma.bseOrder.update({
        where: { id: order.id },
        data: {
          status: mockResult.Status === '100' ? BseOrderStatus.ACCEPTED : BseOrderStatus.REJECTED,
          bseRegistrationNo: mockResult.RegistrationNo,
          bseResponseCode: mockResult.Status,
          bseResponseMsg: mockResult.Message,
          submittedAt: new Date(),
        },
      })

      return {
        orderId: order.id,
        registrationNo: mockResult.RegistrationNo,
        success: mockResult.Status === '100',
        message: mockResult.Message,
      }
    }

    // STP uses Enhanced REST API
    const requestBody = {
      ClientCode: ucc.clientCode,
      FromSchemeCode: dto.fromSchemeCode,
      ToSchemeCode: dto.toSchemeCode,
      TransactionType: 'NEW',
      Amount: dto.amount,
      Frequency: dto.frequency,
      StartDate: dto.startDate,
      EndDate: dto.endDate || '',
      NoOfTransfers: dto.installments || 999,
      FolioNo: dto.folioNumber || '',
      MemberCode: credentials.memberId,
      ARNCode: credentials.arn,
      EUIN: credentials.euin || '',
      STPType: dto.stpType || 'EXCHANGE',
    }

    const response = await this.httpClient.jsonRequest(
      BSE_ENDPOINTS.STP_REGISTRATION,
      'POST',
      requestBody,
      advisorId,
      'STP_Registration',
      { APIKey: credentials.passKey },
    )

    const success = response.parsed?.Status === '100'

    await this.prisma.bseOrder.update({
      where: { id: order.id },
      data: {
        status: success ? BseOrderStatus.ACCEPTED : BseOrderStatus.REJECTED,
        bseRegistrationNo: response.parsed?.RegistrationNo,
        bseResponseCode: response.parsed?.Status,
        bseResponseMsg: response.parsed?.Message,
        submittedAt: new Date(),
      },
    })

    return {
      orderId: order.id,
      registrationNo: response.parsed?.RegistrationNo,
      success,
      message: response.parsed?.Message,
    }
  }

  private async verifyClientAccess(clientId: string, advisorId: string) {
    const client = await this.prisma.fAClient.findUnique({
      where: { id: clientId },
      select: { advisorId: true },
    })
    if (!client || client.advisorId !== advisorId) {
      throw new NotFoundException('Client not found')
    }
  }
}
