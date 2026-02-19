import { Injectable, Logger } from '@nestjs/common';
import { Cron } from '@nestjs/schedule';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class ComplianceScheduler {
  private readonly logger = new Logger(ComplianceScheduler.name);

  constructor(private prisma: PrismaService) {}

  /**
   * Daily at 6 AM IST (00:30 UTC): check for expiring compliance records
   * and update their status.
   */
  @Cron('30 0 * * *')
  async checkExpiringRecords() {
    this.logger.log('Running daily compliance expiry check...');

    try {
      const now = new Date();
      const sixtyDays = new Date();
      sixtyDays.setDate(sixtyDays.getDate() + 60);

      // Mark records as EXPIRED
      const expired = await this.prisma.complianceRecord.updateMany({
        where: {
          expiryDate: { lt: now },
          status: { not: 'EXPIRED' },
        },
        data: { status: 'EXPIRED' },
      });

      // Mark records as EXPIRING_SOON (within 60 days)
      const expiringSoon = await this.prisma.complianceRecord.updateMany({
        where: {
          expiryDate: { gte: now, lte: sixtyDays },
          status: 'VALID',
        },
        data: { status: 'EXPIRING_SOON' },
      });

      this.logger.log(
        `Compliance check complete: ${expired.count} expired, ${expiringSoon.count} expiring soon`,
      );
    } catch (err) {
      this.logger.error('Compliance scheduler failed', err);
    }
  }
}
