import { Injectable, Logger } from '@nestjs/common'
import { BseHttpClient } from '../core/bse-http.client'
import { BseCredentialsService } from '../credentials/bse-credentials.service'
import { BseMockService } from '../mocks/bse-mock.service'
import { ConfigService } from '@nestjs/config'
import { BSE_ENDPOINTS } from '../core/bse-config'
import { OrderStatusQueryDto, AllotmentQueryDto, RedemptionQueryDto } from './dto/report-query.dto'

@Injectable()
export class BseReportsService {
  private readonly logger = new Logger(BseReportsService.name)
  private readonly isMockMode: boolean

  constructor(
    private httpClient: BseHttpClient,
    private credentialsService: BseCredentialsService,
    private mockService: BseMockService,
    private config: ConfigService,
  ) {
    this.isMockMode = this.config.get<boolean>('bse.mockMode') === true
  }

  async queryOrderStatus(advisorId: string, dto: OrderStatusQueryDto) {
    if (this.isMockMode) {
      return this.mockService.mockOrderStatusResponse()
    }

    const credentials = await this.credentialsService.getDecryptedCredentials(advisorId)

    const response = await this.httpClient.jsonRequest(
      BSE_ENDPOINTS.ORDER_STATUS,
      'POST',
      {
        MemberCode: credentials.memberId,
        ClientCode: dto.clientCode || '',
        FromDate: dto.fromDate || '',
        ToDate: dto.toDate || '',
        OrderType: dto.orderType || '',
        OrderNo: dto.orderNumber || '',
      },
      advisorId,
      'OrderStatus',
    )

    return response.parsed
  }

  async queryAllotmentStatement(advisorId: string, dto: AllotmentQueryDto) {
    if (this.isMockMode) {
      return this.mockService.mockAllotmentStatementResponse()
    }

    const credentials = await this.credentialsService.getDecryptedCredentials(advisorId)

    const response = await this.httpClient.jsonRequest(
      BSE_ENDPOINTS.ALLOTMENT_STATEMENT,
      'POST',
      {
        MemberCode: credentials.memberId,
        ClientCode: dto.clientCode || '',
        FromDate: dto.fromDate,
        ToDate: dto.toDate,
      },
      advisorId,
      'AllotmentStatement',
    )

    return response.parsed
  }

  async queryRedemptionStatement(advisorId: string, dto: RedemptionQueryDto) {
    if (this.isMockMode) {
      return { Status: '100', Redemptions: [] }
    }

    const credentials = await this.credentialsService.getDecryptedCredentials(advisorId)

    const response = await this.httpClient.jsonRequest(
      BSE_ENDPOINTS.REDEMPTION_STATEMENT,
      'POST',
      {
        MemberCode: credentials.memberId,
        ClientCode: dto.clientCode || '',
        FromDate: dto.fromDate,
        ToDate: dto.toDate,
      },
      advisorId,
      'RedemptionStatement',
    )

    return response.parsed
  }
}
