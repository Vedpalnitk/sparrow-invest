import { Injectable, Logger } from '@nestjs/common'
import { Cron, CronExpression } from '@nestjs/schedule'
import { BseMastersService } from '../masters/bse-masters.service'
import { PrismaService } from '../../prisma/prisma.service'
import { ConfigService } from '@nestjs/config'

@Injectable()
export class BseSchemeMasterSyncJob {
  private readonly logger = new Logger(BseSchemeMasterSyncJob.name)
  private readonly isMockMode: boolean

  constructor(
    private mastersService: BseMastersService,
    private prisma: PrismaService,
    private config: ConfigService,
  ) {
    this.isMockMode = this.config.get<boolean>('bse.mockMode') === true
  }

  // Weekly scheme master sync (Sunday at 2am)
  @Cron('0 2 * * 0')
  async syncSchemeMaster() {
    if (this.isMockMode) return

    this.logger.log('Starting weekly BSE scheme master sync')

    const activeAdvisors = await this.prisma.bsePartnerCredential.findMany({
      where: { isActive: true },
      select: { userId: true },
      take: 1, // Only need one credential for scheme master
    })

    if (activeAdvisors.length === 0) {
      this.logger.warn('No active BSE credentials found, skipping scheme master sync')
      return
    }

    try {
      const result = await this.mastersService.syncSchemeMaster(activeAdvisors[0].userId)
      this.logger.log(`Scheme master sync complete: ${result.synced} schemes synced`)
    } catch (error) {
      this.logger.error('Scheme master sync failed', error)
    }
  }
}
