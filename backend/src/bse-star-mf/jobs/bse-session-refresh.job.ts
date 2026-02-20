import { Injectable, Logger } from '@nestjs/common'
import { Cron, CronExpression } from '@nestjs/schedule'
import { PrismaService } from '../../prisma/prisma.service'
import { BseSessionManager } from '../core/bse-session.manager'
import { BseSessionType } from '@prisma/client'

@Injectable()
export class BseSessionRefreshJob {
  private readonly logger = new Logger(BseSessionRefreshJob.name)

  constructor(
    private prisma: PrismaService,
    private sessionManager: BseSessionManager,
  ) {}

  // Refresh ORDER_ENTRY tokens 5 minutes before expiry
  @Cron('*/5 * * * *') // Every 5 minutes
  async refreshExpiringTokens() {
    const fiveMinutesFromNow = new Date(Date.now() + 5 * 60 * 1000)

    const expiringSessions = await this.prisma.bseSessionToken.findMany({
      where: {
        sessionType: BseSessionType.ORDER_ENTRY,
        expiresAt: { lte: fiveMinutesFromNow },
      },
    })

    for (const session of expiringSessions) {
      try {
        await this.sessionManager.getSessionToken(session.userId, BseSessionType.ORDER_ENTRY)
        this.logger.log(`Refreshed ORDER_ENTRY token for user ${session.userId}`)
      } catch (error) {
        this.logger.warn(`Failed to refresh token for user ${session.userId}`, error)
      }
    }
  }

  // Clean up expired tokens daily
  @Cron(CronExpression.EVERY_DAY_AT_MIDNIGHT)
  async cleanupExpiredTokens() {
    const result = await this.prisma.bseSessionToken.deleteMany({
      where: { expiresAt: { lt: new Date() } },
    })

    if (result.count > 0) {
      this.logger.log(`Cleaned up ${result.count} expired BSE session tokens`)
    }
  }
}
