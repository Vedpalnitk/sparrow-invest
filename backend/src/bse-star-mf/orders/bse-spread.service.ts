import { Injectable, Logger, NotFoundException, BadRequestException } from '@nestjs/common'
import { ConfigService } from '@nestjs/config'
import { XMLParser } from 'fast-xml-parser'
import { PrismaService } from '../../prisma/prisma.service'
import { BseHttpClient } from '../core/bse-http.client'
import { BseSoapBuilder } from '../core/bse-soap.builder'
import { BseErrorMapper } from '../core/bse-error.mapper'
import { BseReferenceNumberService } from '../core/bse-reference-number.service'
import { BseCredentialsService } from '../credentials/bse-credentials.service'
import { BseAuthService } from '../auth/bse-auth.service'
import { BseMockService } from '../mocks/bse-mock.service'
import { BSE_ENDPOINTS, BSE_SOAP_ACTIONS } from '../core/bse-config'
import { BseOrderType, BseOrderStatus } from '@prisma/client'
import { PlaceSpreadDto } from './dto/place-order.dto'

@Injectable()
export class BseSpreadService {
  private readonly logger = new Logger(BseSpreadService.name)
  private readonly xmlParser = new XMLParser()
  private readonly isMockMode: boolean

  constructor(
    private prisma: PrismaService,
    private httpClient: BseHttpClient,
    private soapBuilder: BseSoapBuilder,
    private errorMapper: BseErrorMapper,
    private refNumberService: BseReferenceNumberService,
    private credentialsService: BseCredentialsService,
    private authService: BseAuthService,
    private mockService: BseMockService,
    private config: ConfigService,
  ) {
    this.isMockMode = this.config.get<boolean>('bse.mockMode') === true
  }

  /**
   * Place a spread order via SOAP spreadOrderEntryParam
   */
  async placeSpread(advisorId: string, dto: PlaceSpreadDto) {
    if (!dto.amount || dto.amount <= 0) {
      throw new BadRequestException('Amount is required for spread orders')
    }

    await this.verifyClientAccess(dto.clientId, advisorId)

    const credentials = await this.credentialsService.getDecryptedCredentials(advisorId)
    const referenceNumber = await this.refNumberService.generate(credentials.memberId)

    // Create order record
    const order = await this.prisma.bseOrder.create({
      data: {
        clientId: dto.clientId,
        advisorId,
        transactionId: dto.transactionId || null,
        orderType: BseOrderType.SPREAD,
        status: BseOrderStatus.CREATED,
        transCode: 'NEW',
        schemeCode: dto.schemeCode,
        buySell: 'P',
        amount: dto.amount,
        folioNumber: dto.folioNumber || null,
        referenceNumber,
      },
    })

    try {
      if (this.isMockMode) {
        return this.handleMockSpreadResponse(order.id)
      }

      const token = await this.authService.getOrderEntryToken(advisorId)

      // Build pipe-separated spread params per BSE specification
      const pipeParams = this.soapBuilder.buildPipeParams([
        'NEW',                              // TransCode
        referenceNumber,                    // UniqueRefNo
        '',                                 // OrderId (empty for new)
        credentials.memberId,               // MemberId
        dto.clientId,                       // ClientCode
        dto.schemeCode,                     // SchemeCode
        dto.amount.toString(),              // Amount
        dto.folioNumber || '',              // FolioNo
        '',                                 // Remarks
        '',                                 // KYCStatus
        '',                                 // SubBrCode
        credentials.euin || '',             // EUIN
        credentials.euin ? 'Y' : 'N',      // EUINVal
        '',                                 // IPAdd
        token,                              // Password
        '',                                 // Param1
        '',                                 // Param2
        '',                                 // Param3
      ])

      const soapBody = this.soapBuilder.buildSpreadOrderEntryBody('NEW', pipeParams)

      const response = await this.httpClient.soapRequest(
        BSE_ENDPOINTS.ORDER_ENTRY,
        BSE_SOAP_ACTIONS.SPREAD_ORDER,
        soapBody,
        advisorId,
        'SpreadOrderEntry',
      )

      const responseValue = this.parseSpreadOrderResponse(response.body)
      const result = this.errorMapper.parsePipeResponse(responseValue)

      const bseOrderNumber = result.data?.[0] || null
      const newStatus = result.success ? BseOrderStatus.SUBMITTED : BseOrderStatus.REJECTED

      const updated = await this.prisma.bseOrder.update({
        where: { id: order.id },
        data: {
          status: newStatus,
          bseOrderNumber,
          bseResponseCode: result.code,
          bseResponseMsg: result.message,
          submittedAt: result.success ? new Date() : null,
        },
      })

      this.errorMapper.throwIfError(result)

      return {
        id: updated.id,
        bseOrderNumber: updated.bseOrderNumber,
        referenceNumber: updated.referenceNumber,
        status: updated.status,
        responseCode: result.code,
        message: result.message,
      }
    } catch (error) {
      await this.prisma.bseOrder.updateMany({
        where: { id: order.id, status: BseOrderStatus.CREATED },
        data: {
          status: BseOrderStatus.FAILED,
          bseResponseMsg: error instanceof Error ? error.message : 'Unknown error',
        },
      })
      throw error
    }
  }

  private async handleMockSpreadResponse(orderId: string) {
    const mockResponse = this.mockService.mockOrderEntryResponse('SPREAD')
    const result = this.errorMapper.parsePipeResponse(mockResponse)
    const bseOrderNumber = result.data?.[0] || null

    const updated = await this.prisma.bseOrder.update({
      where: { id: orderId },
      data: {
        status: BseOrderStatus.SUBMITTED,
        bseOrderNumber,
        bseResponseCode: result.code,
        bseResponseMsg: result.message,
        submittedAt: new Date(),
      },
    })

    return {
      id: updated.id,
      bseOrderNumber: updated.bseOrderNumber,
      referenceNumber: updated.referenceNumber,
      status: updated.status,
      responseCode: result.code,
      message: result.message,
    }
  }

  /**
   * Parse SOAP XML response to extract spreadOrderEntryParamResult value
   */
  private parseSpreadOrderResponse(xml: string): string {
    const parsed = this.xmlParser.parse(xml)
    const envelope = parsed['soap:Envelope'] || parsed['s:Envelope']
    const body = envelope?.['soap:Body'] || envelope?.['s:Body']
    const result = body?.spreadOrderEntryParamResponse?.spreadOrderEntryParamResult

    if (!result) {
      throw new Error('Failed to parse BSE spread order response')
    }

    return String(result)
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
