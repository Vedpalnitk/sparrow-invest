import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { PointsTier, PointsTransactionType } from '@prisma/client';

@Injectable()
export class PointsService {
  constructor(private prisma: PrismaService) {}

  // Tier thresholds
  private readonly tierThresholds = {
    BRONZE: 0,
    SILVER: 1000,
    GOLD: 3000,
    PLATINUM: 7500,
  };

  async getUserPoints(userId: string) {
    let userPoints = await this.prisma.userPoints.findUnique({
      where: { userId },
    });

    // If no points record exists, create one
    if (!userPoints) {
      userPoints = await this.prisma.userPoints.create({
        data: {
          userId,
          currentPoints: 0,
          lifetimePoints: 0,
          redeemedPoints: 0,
          tier: PointsTier.BRONZE,
          pointsToNextTier: this.tierThresholds.SILVER,
          sipStreak: 0,
        },
      });
    }

    const nextTier = this.getNextTier(userPoints.tier);
    const pointsToNextTier = nextTier
      ? this.tierThresholds[nextTier] - userPoints.lifetimePoints
      : 0;

    return {
      currentPoints: userPoints.currentPoints,
      lifetimePoints: userPoints.lifetimePoints,
      redeemedPoints: userPoints.redeemedPoints,
      tier: userPoints.tier,
      tierName: this.getTierDisplayName(userPoints.tier),
      pointsToNextTier: Math.max(0, pointsToNextTier),
      nextTier: nextTier,
      sipStreak: userPoints.sipStreak,
      tierUpdatedAt: userPoints.tierUpdatedAt?.toISOString() || null,
    };
  }

  async getPointsTransactions(userId: string, limit: number = 20, offset: number = 0) {
    const userPoints = await this.prisma.userPoints.findUnique({
      where: { userId },
    });

    if (!userPoints) {
      return { transactions: [], total: 0 };
    }

    const [transactions, total] = await Promise.all([
      this.prisma.pointsTransaction.findMany({
        where: { userPointsId: userPoints.id },
        orderBy: { createdAt: 'desc' },
        take: limit,
        skip: offset,
      }),
      this.prisma.pointsTransaction.count({
        where: { userPointsId: userPoints.id },
      }),
    ]);

    return {
      transactions: transactions.map((t) => ({
        id: t.id,
        type: t.type,
        typeName: this.getTransactionTypeName(t.type),
        points: t.points,
        description: t.description,
        referenceId: t.referenceId,
        expiresAt: t.expiresAt?.toISOString() || null,
        createdAt: t.createdAt.toISOString(),
      })),
      total,
    };
  }

  async awardPoints(
    userId: string,
    type: PointsTransactionType,
    points: number,
    description: string,
    referenceId?: string,
  ) {
    let userPoints = await this.prisma.userPoints.findUnique({
      where: { userId },
    });

    if (!userPoints) {
      userPoints = await this.prisma.userPoints.create({
        data: {
          userId,
          currentPoints: 0,
          lifetimePoints: 0,
          redeemedPoints: 0,
          tier: PointsTier.BRONZE,
          pointsToNextTier: this.tierThresholds.SILVER,
          sipStreak: 0,
        },
      });
    }

    // Create transaction and update points
    await this.prisma.$transaction([
      this.prisma.pointsTransaction.create({
        data: {
          userPointsId: userPoints.id,
          type,
          points,
          description,
          referenceId,
        },
      }),
      this.prisma.userPoints.update({
        where: { id: userPoints.id },
        data: {
          currentPoints: { increment: points },
          lifetimePoints: { increment: points },
        },
      }),
    ]);

    // Check for tier upgrade
    const updatedPoints = await this.prisma.userPoints.findUnique({
      where: { id: userPoints.id },
    });

    if (updatedPoints) {
      const newTier = this.calculateTier(updatedPoints.lifetimePoints);
      if (newTier !== updatedPoints.tier) {
        await this.prisma.userPoints.update({
          where: { id: userPoints.id },
          data: {
            tier: newTier,
            tierUpdatedAt: new Date(),
          },
        });
      }
    }

    return this.getUserPoints(userId);
  }

  async incrementSipStreak(userId: string) {
    const userPoints = await this.prisma.userPoints.findUnique({
      where: { userId },
    });

    if (userPoints) {
      const newStreak = userPoints.sipStreak + 1;
      await this.prisma.userPoints.update({
        where: { id: userPoints.id },
        data: { sipStreak: newStreak },
      });

      // Award streak bonus points at milestones
      if (newStreak % 3 === 0) {
        // Every 3 months
        const bonusPoints = newStreak >= 12 ? 500 : newStreak >= 6 ? 300 : 150;
        await this.awardPoints(
          userId,
          PointsTransactionType.EARNED_STREAK,
          bonusPoints,
          `SIP streak bonus - ${newStreak} months`,
        );
      }
    }
  }

  private calculateTier(lifetimePoints: number): PointsTier {
    if (lifetimePoints >= this.tierThresholds.PLATINUM) return PointsTier.PLATINUM;
    if (lifetimePoints >= this.tierThresholds.GOLD) return PointsTier.GOLD;
    if (lifetimePoints >= this.tierThresholds.SILVER) return PointsTier.SILVER;
    return PointsTier.BRONZE;
  }

  private getNextTier(currentTier: PointsTier): PointsTier | null {
    const tiers = [PointsTier.BRONZE, PointsTier.SILVER, PointsTier.GOLD, PointsTier.PLATINUM];
    const currentIndex = tiers.indexOf(currentTier);
    return currentIndex < tiers.length - 1 ? tiers[currentIndex + 1] : null;
  }

  private getTierDisplayName(tier: PointsTier): string {
    return tier.charAt(0) + tier.slice(1).toLowerCase();
  }

  private getTransactionTypeName(type: PointsTransactionType): string {
    const names: Record<PointsTransactionType, string> = {
      EARNED_SIP: 'SIP Completion',
      EARNED_LUMPSUM: 'Lumpsum Investment',
      EARNED_REFERRAL: 'Referral Bonus',
      EARNED_KYC: 'KYC Verification',
      EARNED_GOAL: 'Goal Achievement',
      EARNED_STREAK: 'SIP Streak Bonus',
      REDEEMED: 'Points Redeemed',
      EXPIRED: 'Points Expired',
    };
    return names[type] || type;
  }
}
