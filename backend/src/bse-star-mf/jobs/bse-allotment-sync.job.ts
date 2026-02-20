import { Injectable, Logger } from '@nestjs/common'
import { Cron } from '@nestjs/schedule'
import { PrismaService } from '../../prisma/prisma.service'
import { BseReportsService } from '../reports/bse-reports.service'
import { ConfigService } from '@nestjs/config'
import { BseOrderStatus } from '@prisma/client'

@Injectable()
export class BseAllotmentSyncJob {
  private readonly logger = new Logger(BseAllotmentSyncJob.name)
  private readonly isMockMode: boolean

  constructor(
    private prisma: PrismaService,
    private reportsService: BseReportsService,
    private config: ConfigService,
  ) {
    this.isMockMode = this.config.get<boolean>('bse.mockMode') === true
  }

  // Nightly allotment reconciliation (weekdays 9pm)
  @Cron('0 21 * * 1-5')
  async syncAllotments() {
    if (this.isMockMode) return

    this.logger.log('Starting nightly allotment reconciliation')

    const activeAdvisors = await this.prisma.bsePartnerCredential.findMany({
      where: { isActive: true },
      select: { userId: true },
    })

    const today = new Date()
    const fromDate = new Date(today)
    fromDate.setDate(fromDate.getDate() - 7) // Look back 7 days

    for (const advisor of activeAdvisors) {
      try {
        const result = await this.reportsService.queryAllotmentStatement(advisor.userId, {
          fromDate: fromDate.toISOString().split('T')[0],
          toDate: today.toISOString().split('T')[0],
        })

        if (result?.Allotments?.length) {
          for (const allotment of result.Allotments) {
            const order = await this.prisma.bseOrder.findFirst({
              where: {
                bseOrderNumber: allotment.OrderNumber,
                advisorId: advisor.userId,
              },
            })

            if (order && order.status !== BseOrderStatus.ALLOTTED) {
              await this.prisma.bseOrder.update({
                where: { id: order.id },
                data: {
                  status: BseOrderStatus.ALLOTTED,
                  allottedUnits: allotment.Units ? parseFloat(allotment.Units) : null,
                  allottedNav: allotment.NAV ? parseFloat(allotment.NAV) : null,
                  allottedAmount: allotment.Amount ? parseFloat(allotment.Amount) : null,
                  allottedAt: new Date(),
                },
              })

              this.logger.log(`Allotment synced for order ${allotment.OrderNumber}`)
            }
          }
        }
      } catch (error) {
        this.logger.warn(`Allotment sync failed for advisor ${advisor.userId}`, error)
      }
    }

    this.logger.log('Nightly allotment reconciliation complete')
  }
}
