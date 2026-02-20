import { Injectable, Logger, NotFoundException } from '@nestjs/common'
import { PrismaService } from '../../prisma/prisma.service'
import { BseHttpClient } from '../core/bse-http.client'
import { BseCredentialsService } from '../credentials/bse-credentials.service'
import { BseMockService } from '../mocks/bse-mock.service'
import { ConfigService } from '@nestjs/config'
import { BSE_ENDPOINTS } from '../core/bse-config'

@Injectable()
export class BseChildOrdersService {
  private readonly logger = new Logger(BseChildOrdersService.name)
  private readonly isMockMode: boolean

  constructor(
    private prisma: PrismaService,
    private httpClient: BseHttpClient,
    private credentialsService: BseCredentialsService,
    private mockService: BseMockService,
    private config: ConfigService,
  ) {
    this.isMockMode = this.config.get<boolean>('bse.mockMode') === true
  }

  async getChildOrderDetails(advisorId: string, registrationNo: string) {
    if (this.isMockMode) {
      return this.mockService.mockChildOrderDetailsResponse()
    }

    const credentials = await this.credentialsService.getDecryptedCredentials(advisorId)

    const response = await this.httpClient.jsonRequest(
      BSE_ENDPOINTS.CHILD_ORDER_DETAILS,
      'POST',
      {
        MemberCode: credentials.memberId,
        RegistrationNo: registrationNo,
      },
      advisorId,
      'ChildOrderDetails',
    )

    // Sync child orders to DB
    if (response.parsed?.ChildOrders?.length) {
      const order = await this.prisma.bseOrder.findFirst({
        where: { bseRegistrationNo: registrationNo, advisorId },
      })

      if (order) {
        for (const child of response.parsed.ChildOrders) {
          await this.prisma.bseChildOrder.upsert({
            where: {
              orderId_installmentNo: {
                orderId: order.id,
                installmentNo: parseInt(child.InstallmentNo) || 0,
              },
            },
            update: {
              orderNumber: child.OrderNumber,
              amount: child.Amount ? parseFloat(child.Amount) : null,
              units: child.Units ? parseFloat(child.Units) : null,
              nav: child.NAV ? parseFloat(child.NAV) : null,
              status: child.Status,
            },
            create: {
              orderId: order.id,
              installmentNo: parseInt(child.InstallmentNo) || 0,
              orderDate: new Date(child.OrderDate || Date.now()),
              orderNumber: child.OrderNumber,
              amount: child.Amount ? parseFloat(child.Amount) : null,
              units: child.Units ? parseFloat(child.Units) : null,
              nav: child.NAV ? parseFloat(child.NAV) : null,
              status: child.Status,
            },
          })
        }
      }
    }

    return response.parsed
  }
}
