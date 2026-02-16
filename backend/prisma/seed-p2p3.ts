import { PrismaClient } from '@prisma/client';
import * as bcrypt from 'bcrypt';

const prisma = new PrismaClient();

async function main() {
  console.log('Seeding P2/P3 data...');

  // Find demo users
  const demoUsers = await prisma.user.findMany({
    where: {
      email: {
        in: ['amit.verma@demo.com', 'priya.patel@demo.com', 'rajesh.sharma@demo.com'],
      },
    },
  });

  console.log(`Found ${demoUsers.length} demo users`);

  for (const user of demoUsers) {
    // Create tax summary for current FY
    const currentFY = '2025-26';
    const existingTax = await prisma.userTaxSummary.findUnique({
      where: { userId_financialYear: { userId: user.id, financialYear: currentFY } },
    });

    if (!existingTax) {
      await prisma.userTaxSummary.create({
        data: {
          userId: user.id,
          financialYear: currentFY,
          ltcgRealized: 85000 + Math.floor(Math.random() * 50000),
          stcgRealized: 25000 + Math.floor(Math.random() * 30000),
          ltcgUnrealized: 120000 + Math.floor(Math.random() * 80000),
          stcgUnrealized: 15000 + Math.floor(Math.random() * 20000),
          elssInvested: 50000 + Math.floor(Math.random() * 100000),
          dividendReceived: 5000 + Math.floor(Math.random() * 10000),
          taxHarvestingDone: Math.floor(Math.random() * 50000),
        },
      });
      console.log(`Created tax summary for ${user.email}`);
    }

    // Create user actions
    const existingActions = await prisma.userAction.findFirst({
      where: { userId: user.id },
    });

    if (!existingActions) {
      const actions = [
        { type: 'SIP_DUE' as const, priority: 'HIGH' as const, title: 'SIP Due: HDFC Flexi Cap Fund', description: 'Monthly SIP of ₹10,000 is due on the 5th', dueDate: new Date(Date.now() + 3 * 24 * 60 * 60 * 1000) },
        { type: 'REBALANCE_RECOMMENDED' as const, priority: 'MEDIUM' as const, title: 'Portfolio Rebalancing Recommended', description: 'Your equity allocation has drifted 8% above target', dueDate: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000) },
        { type: 'TAX_HARVESTING' as const, priority: 'MEDIUM' as const, title: 'Tax Harvesting Opportunity', description: 'Book ₹15,000 LTCG before March 31', dueDate: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000) },
        { type: 'GOAL_REVIEW' as const, priority: 'LOW' as const, title: 'Goal Review: Emergency Fund', description: "You're 85% towards your goal", dueDate: new Date(Date.now() + 14 * 24 * 60 * 60 * 1000) },
        { type: 'KYC_EXPIRY' as const, priority: 'LOW' as const, title: 'KYC Update Required', description: 'Your KYC will expire in 45 days', dueDate: new Date(Date.now() + 45 * 24 * 60 * 60 * 1000) },
      ];

      for (const action of actions) {
        await prisma.userAction.create({ data: { userId: user.id, ...action } });
      }
      console.log(`Created ${actions.length} actions for ${user.email}`);
    }
  }

  // Seed advisor profiles
  const advisorUser = await prisma.user.findUnique({ where: { email: 'advisor@sparrow-invest.com' } });

  if (advisorUser) {
    const existingProfile = await prisma.advisorProfile.findUnique({ where: { userId: advisorUser.id } });

    if (!existingProfile) {
      await prisma.advisorProfile.create({
        data: {
          userId: advisorUser.id,
          displayName: 'Rahul Sharma, CFP',
          bio: 'Certified Financial Planner with 12+ years of experience in wealth management.',
          specializations: ['Retirement Planning', 'Tax Planning', 'ELSS'],
          experienceYears: 12,
          sebiRegNo: 'INH000012345',
          arnNo: 'ARN-123456',
          rating: 4.5,
          totalReviews: 48,
          totalClients: 156,
          aumManaged: 85000000,
          isAcceptingNew: true,
          minInvestment: 100000,
          feeStructure: '0.5% AUM annually',
          city: 'Mumbai',
          languages: ['English', 'Hindi', 'Marathi'],
          isVerified: true,
        },
      });
      console.log('Created advisor profile: Rahul Sharma, CFP');
    }
  }

  // Create additional advisor
  const existingNeha = await prisma.user.findUnique({ where: { email: 'neha.mehta@sparrow-invest.com' } });
  if (!existingNeha) {
    const hashedPassword = await bcrypt.hash('Advisor@123', 10);
    const user = await prisma.user.create({
      data: {
        email: 'neha.mehta@sparrow-invest.com',
        passwordHash: hashedPassword,
        role: 'advisor',
        isActive: true,
        isVerified: true,
        profile: { create: { name: 'Neha Mehta', city: 'Bengaluru' } },
      },
    });
    await prisma.advisorProfile.create({
      data: {
        userId: user.id,
        displayName: 'Neha Mehta, CFA',
        bio: 'CFA charterholder with expertise in equity markets and systematic investing.',
        specializations: ['Equity Investing', 'SIP Planning', 'Goal-based Investing'],
        experienceYears: 8,
        sebiRegNo: 'INH000023456',
        arnNo: 'ARN-234567',
        rating: 4.7,
        totalReviews: 32,
        totalClients: 89,
        aumManaged: 45000000,
        isAcceptingNew: true,
        minInvestment: 50000,
        feeStructure: '0.5% AUM annually',
        city: 'Bengaluru',
        languages: ['English', 'Hindi', 'Kannada'],
        isVerified: true,
      },
    });
    console.log('Created advisor: Neha Mehta, CFA');
  }

  console.log('P2/P3 data seeded successfully!');
}

main()
  .catch(console.error)
  .finally(() => prisma.$disconnect());
