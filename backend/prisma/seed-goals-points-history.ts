import { PrismaClient, GoalCategory, GoalStatus, PointsTier, PointsTransactionType } from '@prisma/client';

const prisma = new PrismaClient();

async function main() {
  console.log('🌱 Seeding goals, points, portfolio history, market indices, and dividends...');

  // Find demo users
  const amitUser = await prisma.user.findUnique({ where: { email: 'amit.verma@demo.com' } });
  const priyaUser = await prisma.user.findUnique({ where: { email: 'priya.patel@demo.com' } });
  const rajeshUser = await prisma.user.findUnique({ where: { email: 'rajesh.sharma@demo.com' } });

  if (!amitUser || !priyaUser || !rajeshUser) {
    console.log('⚠️ Demo users not found. Run seed-advisors-and-self-clients.ts first.');
    return;
  }

  // Get FAClient IDs for managed users
  const priyaClient = await prisma.fAClient.findFirst({ where: { userId: priyaUser.id } });
  const rajeshClient = await prisma.fAClient.findFirst({ where: { userId: rajeshUser.id } });

  // =============================================
  // SEED MARKET INDICES
  // =============================================
  console.log('📊 Seeding market indices...');

  const marketIndices = [
    {
      symbol: 'NIFTY50',
      name: 'NIFTY 50',
      currentValue: 24856.75,
      change: 142.35,
      changePercent: 0.58,
      previousClose: 24714.40,
      dayHigh: 24912.50,
      dayLow: 24698.20,
    },
    {
      symbol: 'SENSEX',
      name: 'S&P BSE SENSEX',
      currentValue: 81652.45,
      change: 412.80,
      changePercent: 0.51,
      previousClose: 81239.65,
      dayHigh: 81820.30,
      dayLow: 81105.50,
    },
    {
      symbol: 'NIFTYBANK',
      name: 'NIFTY Bank',
      currentValue: 51234.20,
      change: -221.45,
      changePercent: -0.43,
      previousClose: 51455.65,
      dayHigh: 51580.00,
      dayLow: 51050.25,
    },
    {
      symbol: 'NIFTYMIDCAP100',
      name: 'NIFTY Midcap 100',
      currentValue: 58432.15,
      change: 538.90,
      changePercent: 0.93,
      previousClose: 57893.25,
      dayHigh: 58650.00,
      dayLow: 57750.80,
    },
  ];

  for (const index of marketIndices) {
    await prisma.marketIndex.upsert({
      where: { symbol: index.symbol },
      update: {
        ...index,
        lastUpdated: new Date(),
      },
      create: {
        ...index,
        lastUpdated: new Date(),
        isActive: true,
      },
    });
  }

  // =============================================
  // SEED USER GOALS
  // =============================================
  console.log('🎯 Seeding user goals...');

  const now = new Date();
  const twoYearsFromNow = new Date(now.getFullYear() + 2, now.getMonth(), now.getDate());
  const twentyFiveYearsFromNow = new Date(now.getFullYear() + 25, now.getMonth(), now.getDate());
  const oneYearFromNow = new Date(now.getFullYear() + 1, now.getMonth(), now.getDate());

  // Goals for Amit (self-service user)
  const amitGoals = [
    {
      userId: amitUser.id,
      name: 'Home Down Payment',
      category: GoalCategory.HOME,
      icon: 'house.fill',
      targetAmount: 500000,
      currentAmount: 310000,
      targetDate: twoYearsFromNow,
      monthlySip: 12500,
      status: GoalStatus.ACTIVE,
      priority: 1,
      linkedFundCodes: ['119598', '120503'],
    },
    {
      userId: amitUser.id,
      name: 'Retirement Fund',
      category: GoalCategory.RETIREMENT,
      icon: 'beach.umbrella',
      targetAmount: 10000000,
      currentAmount: 850000,
      targetDate: twentyFiveYearsFromNow,
      monthlySip: 15000,
      status: GoalStatus.ACTIVE,
      priority: 2,
      linkedFundCodes: ['119598', '135781'],
    },
    {
      userId: amitUser.id,
      name: 'Emergency Fund',
      category: GoalCategory.EMERGENCY,
      icon: 'cross.case.fill',
      targetAmount: 300000,
      currentAmount: 300000,
      targetDate: now,
      monthlySip: 0,
      status: GoalStatus.COMPLETED,
      priority: 3,
      linkedFundCodes: ['119775'],
    },
  ];

  // Goals for Priya (managed user)
  const priyaGoals = [
    {
      userId: priyaUser.id,
      clientId: priyaClient?.id,
      name: 'Child Education',
      category: GoalCategory.EDUCATION,
      icon: 'graduationcap.fill',
      targetAmount: 2500000,
      currentAmount: 450000,
      targetDate: new Date(now.getFullYear() + 10, now.getMonth(), now.getDate()),
      monthlySip: 20000,
      status: GoalStatus.ACTIVE,
      priority: 1,
      linkedFundCodes: ['120503', '135781'],
    },
    {
      userId: priyaUser.id,
      clientId: priyaClient?.id,
      name: 'Family Vacation',
      category: GoalCategory.TRAVEL,
      icon: 'airplane',
      targetAmount: 200000,
      currentAmount: 85000,
      targetDate: oneYearFromNow,
      monthlySip: 10000,
      status: GoalStatus.ACTIVE,
      priority: 2,
      linkedFundCodes: ['119775'],
    },
  ];

  // Goals for Rajesh (managed user)
  const rajeshGoals = [
    {
      userId: rajeshUser.id,
      clientId: rajeshClient?.id,
      name: 'New Car',
      category: GoalCategory.CAR,
      icon: 'car.fill',
      targetAmount: 1500000,
      currentAmount: 620000,
      targetDate: new Date(now.getFullYear() + 3, now.getMonth(), now.getDate()),
      monthlySip: 25000,
      status: GoalStatus.ACTIVE,
      priority: 1,
      linkedFundCodes: ['119598', '120503'],
    },
    {
      userId: rajeshUser.id,
      clientId: rajeshClient?.id,
      name: 'Wealth Building',
      category: GoalCategory.WEALTH,
      icon: 'chart.line.uptrend.xyaxis',
      targetAmount: 50000000,
      currentAmount: 2500000,
      targetDate: new Date(now.getFullYear() + 20, now.getMonth(), now.getDate()),
      monthlySip: 50000,
      status: GoalStatus.ACTIVE,
      priority: 2,
      linkedFundCodes: ['119598', '135781', '140251'],
    },
  ];

  const allGoals = [...amitGoals, ...priyaGoals, ...rajeshGoals];

  for (const goal of allGoals) {
    await prisma.userGoal.create({
      data: goal,
    });
  }

  // =============================================
  // SEED USER POINTS
  // =============================================
  console.log('🏆 Seeding user points...');

  const userPointsData = [
    {
      userId: amitUser.id,
      currentPoints: 1250,
      lifetimePoints: 2100,
      redeemedPoints: 850,
      tier: PointsTier.SILVER,
      pointsToNextTier: 750,
      sipStreak: 8,
    },
    {
      userId: priyaUser.id,
      currentPoints: 3500,
      lifetimePoints: 4200,
      redeemedPoints: 700,
      tier: PointsTier.GOLD,
      pointsToNextTier: 1500,
      sipStreak: 14,
    },
    {
      userId: rajeshUser.id,
      currentPoints: 850,
      lifetimePoints: 1200,
      redeemedPoints: 350,
      tier: PointsTier.BRONZE,
      pointsToNextTier: 1150,
      sipStreak: 5,
    },
  ];

  for (const pointsData of userPointsData) {
    const userPoints = await prisma.userPoints.create({
      data: {
        ...pointsData,
        tierUpdatedAt: new Date(),
      },
    });

    // Add some points transactions
    const transactions = [
      {
        userPointsId: userPoints.id,
        type: PointsTransactionType.EARNED_SIP,
        points: 100,
        description: 'SIP completed - January 2026',
      },
      {
        userPointsId: userPoints.id,
        type: PointsTransactionType.EARNED_SIP,
        points: 100,
        description: 'SIP completed - December 2025',
      },
      {
        userPointsId: userPoints.id,
        type: PointsTransactionType.EARNED_STREAK,
        points: 250,
        description: 'SIP streak bonus - 5 months',
      },
      {
        userPointsId: userPoints.id,
        type: PointsTransactionType.EARNED_KYC,
        points: 500,
        description: 'KYC verification completed',
      },
    ];

    for (const txn of transactions) {
      await prisma.pointsTransaction.create({ data: txn });
    }
  }

  // =============================================
  // SEED PORTFOLIO HISTORY (Last 12 months)
  // =============================================
  console.log('📈 Seeding portfolio history...');

  const generatePortfolioHistory = async (userId: string, clientId: string | null, baseValue: number, baseInvested: number): Promise<Array<{
    userId: string;
    clientId: string | null;
    date: Date;
    totalValue: number;
    totalInvested: number;
    dayChange: number;
    dayChangePct: number;
  }>> => {
    const history: Array<{
      userId: string;
      clientId: string | null;
      date: Date;
      totalValue: number;
      totalInvested: number;
      dayChange: number;
      dayChangePct: number;
    }> = [];
    const today = new Date();

    for (let i = 365; i >= 0; i--) {
      const date = new Date(today);
      date.setDate(date.getDate() - i);

      // Skip weekends
      if (date.getDay() === 0 || date.getDay() === 6) continue;

      // Simulate gradual growth with some volatility
      const dayNumber = 365 - i;
      const growthFactor = 1 + (dayNumber * 0.0003); // ~11% annual growth
      const volatility = (Math.random() - 0.5) * 0.02; // ±1% daily volatility

      const totalValue = baseValue * growthFactor * (1 + volatility);
      const totalInvested = baseInvested + (dayNumber * (baseInvested * 0.001)); // Gradual SIP additions

      history.push({
        userId,
        clientId,
        date,
        totalValue,
        totalInvested,
        dayChange: totalValue * volatility,
        dayChangePct: volatility * 100,
      });
    }

    return history;
  };

  // Generate history for each user
  const amitHistory = await generatePortfolioHistory(amitUser.id, null, 992000, 850000);
  const priyaHistory = await generatePortfolioHistory(priyaUser.id, priyaClient?.id || null, 1250000, 1050000);
  const rajeshHistory = await generatePortfolioHistory(rajeshUser.id, rajeshClient?.id || null, 580000, 480000);

  // Insert in batches
  const allHistory = [...amitHistory, ...priyaHistory, ...rajeshHistory];

  // Use createMany for efficiency (batch insert)
  const batchSize = 100;
  for (let i = 0; i < allHistory.length; i += batchSize) {
    const batch = allHistory.slice(i, i + batchSize);
    await prisma.userPortfolioHistory.createMany({
      data: batch,
      skipDuplicates: true,
    });
  }

  // =============================================
  // SEED DIVIDENDS
  // =============================================
  console.log('💰 Seeding dividend records...');

  const dividends = [
    {
      userId: amitUser.id,
      fundName: 'HDFC Mid-Cap Opportunities Fund',
      fundSchemeCode: '120503',
      amount: 2500,
      dividendType: 'PAYOUT',
      recordDate: new Date(2025, 11, 15),
      paymentDate: new Date(2025, 11, 20),
      nav: 112.35,
    },
    {
      userId: amitUser.id,
      fundName: 'ICICI Prudential Corporate Bond Fund',
      fundSchemeCode: '119775',
      amount: 1800,
      dividendType: 'REINVESTED',
      recordDate: new Date(2025, 10, 10),
      paymentDate: new Date(2025, 10, 15),
      nav: 24.10,
      units: 74.69,
    },
    {
      userId: priyaUser.id,
      clientId: priyaClient?.id,
      fundName: 'Parag Parikh Flexi Cap Fund',
      fundSchemeCode: '119598',
      amount: 3200,
      dividendType: 'PAYOUT',
      recordDate: new Date(2025, 9, 5),
      paymentDate: new Date(2025, 9, 10),
      nav: 78.45,
    },
    {
      userId: rajeshUser.id,
      clientId: rajeshClient?.id,
      fundName: 'Mirae Asset Large Cap Fund',
      fundSchemeCode: '135781',
      amount: 1500,
      dividendType: 'PAYOUT',
      recordDate: new Date(2025, 8, 20),
      paymentDate: new Date(2025, 8, 25),
      nav: 89.25,
    },
  ];

  for (const dividend of dividends) {
    await prisma.dividendRecord.create({ data: dividend });
  }

  console.log('✅ Seeding completed successfully!');
  console.log('   - Market indices: 4');
  console.log('   - User goals: ' + allGoals.length);
  console.log('   - User points records: 3');
  console.log('   - Portfolio history records: ~' + allHistory.length);
  console.log('   - Dividend records: ' + dividends.length);
}

main()
  .catch((e) => {
    console.error('❌ Seeding failed:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
