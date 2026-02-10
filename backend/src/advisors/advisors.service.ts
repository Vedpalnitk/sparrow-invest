import { Injectable, NotFoundException, BadRequestException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { Decimal } from '@prisma/client/runtime/library';
import { AdvisorFilterDto, CreateReviewDto } from './dto/advisor.dto';

@Injectable()
export class AdvisorsService {
  constructor(private prisma: PrismaService) {}

  async getAdvisors(filters: AdvisorFilterDto, limit: number = 20, offset: number = 0) {
    const where: any = {};

    if (filters.city) {
      where.city = { contains: filters.city, mode: 'insensitive' };
    }

    if (filters.specialization) {
      where.specializations = { has: filters.specialization };
    }

    if (filters.minRating) {
      where.rating = { gte: filters.minRating };
    }

    if (filters.verifiedOnly) {
      where.isVerified = true;
    }

    if (filters.acceptingNew) {
      where.isAcceptingNew = true;
    }

    if (filters.search) {
      where.OR = [
        { displayName: { contains: filters.search, mode: 'insensitive' } },
        { bio: { contains: filters.search, mode: 'insensitive' } },
      ];
    }

    const [advisors, total] = await Promise.all([
      this.prisma.advisorProfile.findMany({
        where,
        include: {
          user: {
            select: { email: true },
          },
        },
        orderBy: [{ rating: 'desc' }, { totalClients: 'desc' }],
        take: limit,
        skip: offset,
      }),
      this.prisma.advisorProfile.count({ where }),
    ]);

    return {
      advisors: advisors.map((a) => this.formatAdvisor(a)),
      total,
      page: Math.floor(offset / limit) + 1,
      totalPages: Math.ceil(total / limit),
    };
  }

  async getAdvisorById(advisorId: string) {
    const advisor = await this.prisma.advisorProfile.findUnique({
      where: { id: advisorId },
      include: {
        user: {
          select: { email: true },
        },
      },
    });

    if (!advisor) {
      throw new NotFoundException('Advisor not found');
    }

    return this.formatAdvisor(advisor);
  }

  async getAdvisorReviews(advisorId: string, limit: number = 20, offset: number = 0) {
    const advisor = await this.prisma.advisorProfile.findUnique({
      where: { id: advisorId },
    });

    if (!advisor) {
      throw new NotFoundException('Advisor not found');
    }

    const [reviews, total] = await Promise.all([
      this.prisma.advisorReview.findMany({
        where: { advisorProfileId: advisorId },
        include: {
          reviewer: {
            select: {
              id: true,
              profile: {
                select: { name: true },
              },
            },
          },
        },
        orderBy: { createdAt: 'desc' },
        take: limit,
        skip: offset,
      }),
      this.prisma.advisorReview.count({
        where: { advisorProfileId: advisorId },
      }),
    ]);

    return {
      reviews: reviews.map((r) => ({
        id: r.id,
        rating: r.rating,
        comment: r.comment,
        isAnonymous: r.isAnonymous,
        reviewerName: r.isAnonymous ? null : r.reviewer.profile?.name || 'Anonymous',
        createdAt: r.createdAt.toISOString(),
      })),
      total,
      averageRating: this.toNumber(advisor.rating),
    };
  }

  async createReview(userId: string, advisorId: string, dto: CreateReviewDto) {
    const advisor = await this.prisma.advisorProfile.findUnique({
      where: { id: advisorId },
    });

    if (!advisor) {
      throw new NotFoundException('Advisor not found');
    }

    // Check if user already reviewed this advisor
    const existingReview = await this.prisma.advisorReview.findUnique({
      where: {
        advisorProfileId_reviewerId: {
          advisorProfileId: advisorId,
          reviewerId: userId,
        },
      },
    });

    if (existingReview) {
      throw new BadRequestException('You have already reviewed this advisor');
    }

    // Create review
    const review = await this.prisma.advisorReview.create({
      data: {
        advisorProfileId: advisorId,
        reviewerId: userId,
        rating: dto.rating,
        comment: dto.comment,
        isAnonymous: dto.isAnonymous ?? false,
      },
      include: {
        reviewer: {
          select: {
            profile: {
              select: { name: true },
            },
          },
        },
      },
    });

    // Update advisor's average rating
    const allReviews = await this.prisma.advisorReview.findMany({
      where: { advisorProfileId: advisorId },
      select: { rating: true },
    });

    const averageRating =
      allReviews.reduce((sum, r) => sum + r.rating, 0) / allReviews.length;

    await this.prisma.advisorProfile.update({
      where: { id: advisorId },
      data: {
        rating: averageRating,
        totalReviews: allReviews.length,
      },
    });

    return {
      id: review.id,
      rating: review.rating,
      comment: review.comment,
      isAnonymous: review.isAnonymous,
      reviewerName: review.isAnonymous ? null : review.reviewer.profile?.name || 'Anonymous',
      createdAt: review.createdAt.toISOString(),
    };
  }

  async getSpecializations() {
    const advisors = await this.prisma.advisorProfile.findMany({
      select: { specializations: true },
    });

    const allSpecializations = advisors.flatMap((a) => a.specializations);
    const uniqueSpecializations = [...new Set(allSpecializations)].sort();

    return { specializations: uniqueSpecializations };
  }

  private formatAdvisor(advisor: any) {
    return {
      id: advisor.id,
      displayName: advisor.displayName,
      bio: advisor.bio,
      email: advisor.user?.email,
      specializations: advisor.specializations,
      experienceYears: advisor.experienceYears,
      sebiRegNo: advisor.sebiRegNo,
      arnNo: advisor.arnNo,
      rating: this.toNumber(advisor.rating),
      totalReviews: advisor.totalReviews,
      totalClients: advisor.totalClients,
      aumManaged: this.toNumber(advisor.aumManaged),
      isAcceptingNew: advisor.isAcceptingNew,
      minInvestment: advisor.minInvestment ? this.toNumber(advisor.minInvestment) : null,
      feeStructure: advisor.feeStructure,
      avatarUrl: advisor.avatarUrl,
      city: advisor.city,
      languages: advisor.languages,
      isVerified: advisor.isVerified,
    };
  }

  private toNumber(value: Decimal | number | null): number {
    if (value === null) return 0;
    if (typeof value === 'number') return value;
    return Number(value);
  }
}
