import { Injectable, Logger } from '@nestjs/common'
import { Cron } from '@nestjs/schedule'
import { PrismaService } from '../../prisma/prisma.service'
import { BseHttpClient } from '../core/bse-http.client'
import { BseCredentialsService } from '../credentials/bse-credentials.service'
import { ConfigService } from '@nestjs/config'
import { BSE_ENDPOINTS } from '../core/bse-config'
import { BseMandateStatus } from '@prisma/client'

@Injectable()
export class BseMandateStatusPollJob {
  private readonly logger = new Logger(BseMandateStatusPollJob.name)
  private readonly isMockMode: boolean

  constructor(
    private prisma: PrismaService,
    private httpClient: BseHttpClient,
    private credentialsService: BseCredentialsService,
    private config: ConfigService,
  ) {
    this.isMockMode = this.config.get<boolean>('bse.mockMode') === true
  }

  @Cron('*/30 * * * *') // Every 30 minutes
  async pollPendingMandates() {
    if (this.isMockMode) return

    const pendingMandates = await this.prisma.bseMandate.findMany({
      where: {
        status: { in: [BseMandateStatus.SUBMITTED, BseMandateStatus.CREATED] },
        mandateId: { not: null },
      },
      take: 50,
    })

    for (const mandate of pendingMandates) {
      try {
        const credentials = await this.credentialsService.getDecryptedCredentials(mandate.advisorId)

        const response = await this.httpClient.jsonRequest(
          BSE_ENDPOINTS.MANDATE_DETAILS,
          'POST',
          {
            MemberCode: credentials.memberId,
            MandateId: mandate.mandateId,
          },
          mandate.advisorId,
          'MandateStatusPoll',
        )

        if (response.parsed?.Status) {
          const newStatus = this.mapBseStatus(response.parsed.Status)
          if (newStatus && newStatus !== mandate.status) {
            await this.prisma.bseMandate.update({
              where: { id: mandate.id },
              data: {
                status: newStatus,
                umrn: response.parsed.UMRN || mandate.umrn,
              },
            })
            this.logger.log(`Mandate ${mandate.mandateId} status updated: ${mandate.status} → ${newStatus}`)
          }
        }
      } catch (error) {
        this.logger.warn(`Failed to poll mandate ${mandate.mandateId}`, error)
      }
    }
  }

  private mapBseStatus(bseStatus: string): BseMandateStatus | null {
    const map: Record<string, BseMandateStatus> = {
      APPROVED: BseMandateStatus.APPROVED,
      REJECTED: BseMandateStatus.REJECTED,
      CANCELLED: BseMandateStatus.CANCELLED,
      EXPIRED: BseMandateStatus.EXPIRED,
    }
    return map[bseStatus?.toUpperCase()] || null
  }
}
