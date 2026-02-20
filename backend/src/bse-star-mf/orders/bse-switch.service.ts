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
import { PlaceSwitchDto } from './dto/place-order.dto'

@Injectable()
export class BseSwitchService {
  private readonly logger = new Logger(BseSwitchService.name)
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
   * Place a switch order via SOAP switchOrderEntryParam
   */
  async placeSwitch(advisorId: string, dto: PlaceSwitchDto) {
    if (!dto.amount && !dto.units) {
      throw new BadRequestException('Either amount or units is required for switch')
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
        orderType: BseOrderType.SWITCH,
        status: BseOrderStatus.CREATED,
        transCode: 'NEW',
        schemeCode: dto.fromSchemeCode,
        switchSchemeCode: dto.toSchemeCode,
        buySell: 'P',
        amount: dto.amount || null,
        units: dto.units || null,
        folioNumber: dto.folioNumber || null,
        referenceNumber,
      },
    })

    try {
      if (this.isMockMode) {
        return this.handleMockSwitchResponse(order.id)
      }

      const token = await this.authService.getOrderEntryToken(advisorId)

      // Build pipe-separated switch params per BSE specification
      const pipeParams = this.soapBuilder.buildPipeParams([
        'NEW',                              // TransCode
        referenceNumber,                    // UniqueRefNo
        '',                                 // OrderId (empty for new)
        credentials.memberId,               // MemberId
        dto.clientId,                       // ClientCode
        dto.fromSchemeCode,                 // FromSchemeCd
        dto.toSchemeCode,                   // ToSchemeCd
        dto.buySellType || '',              // BuySellType
        dto.amount?.toString() || '',       // Amount
        dto.units?.toString() || '',        // Qty
        '',                                 // AllUnits
        dto.folioNumber || '',              // FolioNo
        '',                                 // Remarks
        '',                                 // KYCStatus
        '',                                 // SubBrCode
        credentials.euin || '',             // EUIN
        credentials.euin ? 'Y' : 'N',      // EUINVal
        '',                                 // MinRedeem
        '',                                 // IPAdd
        token,                              // Password
        '',                                 // Param1
        '',                                 // Param2
        '',                                 // Param3
      ])

      const soapBody = this.soapBuilder.buildSwitchOrderEntryBody('NEW', pipeParams)

      const response = await this.httpClient.soapRequest(
        BSE_ENDPOINTS.ORDER_ENTRY,
        BSE_SOAP_ACTIONS.SWITCH_ORDER,
        soapBody,
        advisorId,
        'SwitchOrderEntry',
      )

      const responseValue = this.parseSwitchOrderResponse(response.body)
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

  private async handleMockSwitchResponse(orderId: string) {
    const mockResponse = this.mockService.mockOrderEntryResponse('SWITCH')
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
   * Parse SOAP XML response to extract switchOrderEntryParamResult value
   */
  private parseSwitchOrderResponse(xml: string): string {
    const parsed = this.xmlParser.parse(xml)
    const envelope = parsed['soap:Envelope'] || parsed['s:Envelope']
    const body = envelope?.['soap:Body'] || envelope?.['s:Body']
    const result = body?.switchOrderEntryParamResponse?.switchOrderEntryParamResult

    if (!result) {
      throw new Error('Failed to parse BSE switch order response')
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
