import { Injectable, Logger } from '@nestjs/common'
import { Cron } from '@nestjs/schedule'
import { PrismaService } from '../../prisma/prisma.service'
import { BseHttpClient } from '../core/bse-http.client'
import { BseCredentialsService } from '../credentials/bse-credentials.service'
import { ConfigService } from '@nestjs/config'
import { BSE_ENDPOINTS } from '../core/bse-config'
import { BseOrderStatus } from '@prisma/client'

@Injectable()
export class BseOrderStatusPollJob {
  private readonly logger = new Logger(BseOrderStatusPollJob.name)
  private readonly isMockMode: boolean

  constructor(
    private prisma: PrismaService,
    private httpClient: BseHttpClient,
    private credentialsService: BseCredentialsService,
    private config: ConfigService,
  ) {
    this.isMockMode = this.config.get<boolean>('bse.mockMode') === true
  }

  @Cron('*/15 * * * *') // Every 15 minutes
  async pollPendingOrders() {
    if (this.isMockMode) return

    const pendingOrders = await this.prisma.bseOrder.findMany({
      where: {
        status: {
          in: [
            BseOrderStatus.SUBMITTED,
            BseOrderStatus.ACCEPTED,
            BseOrderStatus.PAYMENT_PENDING,
            BseOrderStatus.PAYMENT_SUCCESS,
          ],
        },
        bseOrderNumber: { not: null },
      },
      take: 100,
      orderBy: { updatedAt: 'asc' },
    })

    // Group by advisor for batch queries
    const byAdvisor = new Map<string, typeof pendingOrders>()
    for (const order of pendingOrders) {
      const existing = byAdvisor.get(order.advisorId) || []
      existing.push(order)
      byAdvisor.set(order.advisorId, existing)
    }

    for (const [advisorId, orders] of byAdvisor) {
      try {
        const credentials = await this.credentialsService.getDecryptedCredentials(advisorId)

        const response = await this.httpClient.jsonRequest(
          BSE_ENDPOINTS.ORDER_STATUS,
          'POST',
          {
            MemberCode: credentials.memberId,
            OrderNo: orders.map((o) => o.bseOrderNumber).join(','),
          },
          advisorId,
          'OrderStatusPoll',
        )

        if (response.parsed?.Orders?.length) {
          for (const bseOrder of response.parsed.Orders) {
            const order = orders.find((o) => o.bseOrderNumber === bseOrder.OrderNumber)
            if (!order) continue

            const newStatus = this.mapBseStatus(bseOrder.Status)
            if (!newStatus || newStatus === order.status) continue

            const updateData: any = { status: newStatus }

            if (bseOrder.AllottedUnits) {
              updateData.allottedUnits = parseFloat(bseOrder.AllottedUnits)
              updateData.allottedNav = bseOrder.AllottedNav ? parseFloat(bseOrder.AllottedNav) : null
              updateData.allottedAmount = bseOrder.AllottedAmount ? parseFloat(bseOrder.AllottedAmount) : null
              updateData.allottedAt = new Date()
            }

            await this.prisma.bseOrder.update({
              where: { id: order.id },
              data: updateData,
            })

            this.logger.log(`Order ${order.bseOrderNumber} status: ${order.status} → ${newStatus}`)
          }
        }
      } catch (error) {
        this.logger.warn(`Failed to poll orders for advisor ${advisorId}`, error)
      }
    }
  }

  private mapBseStatus(bseStatus: string): BseOrderStatus | null {
    const map: Record<string, BseOrderStatus> = {
      ACCEPTED: BseOrderStatus.ACCEPTED,
      REJECTED: BseOrderStatus.REJECTED,
      ALLOTTED: BseOrderStatus.ALLOTTED,
      CANCELLED: BseOrderStatus.CANCELLED,
      FAILED: BseOrderStatus.FAILED,
    }
    return map[bseStatus?.toUpperCase()] || null
  }
}
