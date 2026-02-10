import { Injectable } from '@nestjs/common'
import { PrismaService } from '../prisma/prisma.service'
import {
  AdvisorDashboardDto,
  AdvisorInsightsDto,
  KpiGrowthDto,
  PortfolioHealthItemDto,
  RebalancingAlertDto,
  TaxHarvestingOpportunityDto,
  GoalAlertDto,
  MarketInsightDto,
} from './dto/dashboard.dto'

// Target allocations by risk profile (used for rebalancing alerts)
const TARGET_ALLOCATIONS: Record<string, Record<string, number>> = {
  Conservative: { Equity: 30, Debt: 50, Hybrid: 10, Gold: 5, Liquid: 5 },
  Moderate: { Equity: 50, Debt: 30, Hybrid: 10, Gold: 5, Liquid: 5 },
  Aggressive: { Equity: 70, Debt: 15, Hybrid: 10, Gold: 5, Liquid: 0 },
}

const RISK_PROFILE_MAP: Record<string, string> = {
  CONSERVATIVE: 'Conservative',
  MODERATE: 'Moderate',
  AGGRESSIVE: 'Aggressive',
}

const STATUS_MAP: Record<string, string> = {
  ACTIVE: 'Active',
  INACTIVE: 'Inactive',
  PENDING_KYC: 'Pending KYC',
}

const TYPE_MAP: Record<string, string> = {
  BUY: 'Buy',
  SELL: 'Sell',
  SIP: 'SIP',
  SWP: 'SWP',
  SWITCH: 'Switch',
  STP: 'STP',
}

const TXN_STATUS_MAP: Record<string, string> = {
  COMPLETED: 'Completed',
  PENDING: 'Pending',
  PROCESSING: 'Processing',
  FAILED: 'Failed',
  CANCELLED: 'Cancelled',
}

@Injectable()
export class AdvisorDashboardService {
  constructor(private prisma: PrismaService) {}

  async getDashboard(advisorId: string): Promise<AdvisorDashboardDto> {
    // Run all queries in parallel for performance
    const [
      clients,
      activeSipsCount,
      monthlySipValue,
      pendingActionsCount,
      pendingTransactions,
      upcomingSips,
      failedSips,
    ] = await Promise.all([
      // All clients with holdings and active SIPs
      this.prisma.fAClient.findMany({
        where: { advisorId },
        include: {
          holdings: true,
          sips: { where: { status: 'ACTIVE' } },
        },
        orderBy: { createdAt: 'desc' },
      }),
      // Active SIP count
      this.prisma.fASIP.count({
        where: { client: { advisorId }, status: 'ACTIVE' },
      }),
      // Total monthly SIP value
      this.prisma.fASIP.aggregate({
        where: { client: { advisorId }, status: 'ACTIVE', frequency: 'MONTHLY' },
        _sum: { amount: true },
      }),
      // Pending actions count
      this.prisma.userAction.count({
        where: {
          userId: advisorId,
          isCompleted: false,
          isDismissed: false,
          OR: [{ expiresAt: null }, { expiresAt: { gt: new Date() } }],
        },
      }),
      // Pending transactions
      this.prisma.fATransaction.findMany({
        where: {
          client: { advisorId },
          status: 'PENDING',
        },
        include: { client: { select: { id: true, name: true } } },
        orderBy: { date: 'desc' },
        take: 10,
      }),
      // Upcoming SIPs (next 7 days)
      this.prisma.fASIP.findMany({
        where: {
          client: { advisorId },
          status: 'ACTIVE',
          nextSipDate: {
            gte: new Date(),
            lte: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000),
          },
        },
        include: { client: { select: { id: true, name: true } } },
        orderBy: { nextSipDate: 'asc' },
        take: 10,
      }),
      // Failed SIPs
      this.prisma.fASIP.findMany({
        where: {
          client: { advisorId },
          status: 'FAILED',
        },
        include: { client: { select: { id: true, name: true } } },
        orderBy: { updatedAt: 'desc' },
        take: 10,
      }),
    ])

    // Compute client-level KPIs
    const clientData = clients.map((c) => {
      const holdings = c.holdings || []
      const sips = c.sips || []
      const aum = holdings.reduce((sum, h) => sum + Number(h.currentValue || 0), 0)
      const invested = holdings.reduce((sum, h) => sum + Number(h.investedValue || 0), 0)
      const returns = invested > 0 ? ((aum - invested) / invested) * 100 : 0

      return {
        id: c.id,
        name: c.name,
        email: c.email,
        aum,
        invested,
        returns: Math.round(returns * 100) / 100,
        riskProfile: RISK_PROFILE_MAP[c.riskProfile] || 'Moderate',
        status: STATUS_MAP[c.status] || 'Active',
        sipCount: sips.length,
        lastActive: this.formatLastActive(c.lastActiveAt),
        createdAt: c.createdAt,
      }
    })

    const totalAum = clientData.reduce((sum, c) => sum + c.aum, 0)
    const totalInvested = clientData.reduce((sum, c) => sum + c.invested, 0)
    const avgReturns = totalInvested > 0
      ? Math.round(((totalAum - totalInvested) / totalInvested) * 10000) / 100
      : 0

    // Top performers by returns
    const topPerformers = [...clientData]
      .filter((c) => c.aum > 0)
      .sort((a, b) => b.returns - a.returns)
      .slice(0, 5)
      .map(({ invested, createdAt, ...rest }) => rest)

    // Recent clients (last 5 added)
    const recentClients = clientData
      .slice(0, 5)
      .map(({ invested, createdAt, ...rest }) => rest)

    // Compute growth metrics
    const aumGrowth = await this.computeAumGrowth(advisorId, totalAum)
    const clientsGrowth = await this.computeClientsGrowth(advisorId, clients.length)
    const sipsGrowth = await this.computeSipsGrowth(advisorId, activeSipsCount)

    return {
      totalAum: Math.round(totalAum * 100) / 100,
      totalClients: clients.length,
      activeSips: activeSipsCount,
      pendingActions: pendingActionsCount,
      avgReturns,
      monthlySipValue: Number(monthlySipValue._sum.amount || 0),
      recentClients,
      pendingTransactions: pendingTransactions.map((t) => ({
        id: t.id,
        clientId: t.clientId,
        clientName: t.client?.name || '',
        fundName: t.fundName,
        type: TYPE_MAP[t.type] || t.type,
        amount: Number(t.amount),
        status: TXN_STATUS_MAP[t.status] || t.status,
        date: t.date.toISOString().split('T')[0],
      })),
      topPerformers,
      upcomingSips: upcomingSips.map((s) => ({
        id: s.id,
        clientId: s.clientId,
        clientName: s.client?.name || '',
        fundName: s.fundName,
        amount: Number(s.amount),
        nextDate: s.nextSipDate.toISOString().split('T')[0],
        status: s.status,
      })),
      failedSips: failedSips.map((s) => ({
        id: s.id,
        clientId: s.clientId,
        clientName: s.client?.name || '',
        fundName: s.fundName,
        amount: Number(s.amount),
        nextDate: s.nextSipDate.toISOString().split('T')[0],
        status: s.status,
      })),
      aumGrowth,
      clientsGrowth,
      sipsGrowth,
    }
  }

  async getInsights(advisorId: string): Promise<AdvisorInsightsDto> {
    const [
      portfolioHealth,
      rebalancingAlerts,
      taxHarvesting,
      goalAlerts,
    ] = await Promise.all([
      this.computePortfolioHealth(advisorId),
      this.computeRebalancingAlerts(advisorId),
      this.computeTaxHarvesting(advisorId),
      this.computeGoalAlerts(advisorId),
    ])

    const marketInsights = this.getMarketInsights()

    return {
      portfolioHealth,
      rebalancingAlerts,
      taxHarvesting,
      goalAlerts,
      marketInsights,
    }
  }

  // ============================================================
  // Private: Growth computations
  // ============================================================

  private async computeAumGrowth(advisorId: string, currentAum: number): Promise<KpiGrowthDto | null> {
    const now = new Date()
    const oneMonthAgo = new Date(now.getFullYear(), now.getMonth() - 1, now.getDate())
    const oneYearAgo = new Date(now.getFullYear() - 1, now.getMonth(), now.getDate())

    // Get historical AUM from portfolio history snapshots
    const [prevMonthSnap, prevYearSnap] = await Promise.all([
      this.prisma.userPortfolioHistory.findFirst({
        where: {
          client: { advisorId },
          date: { lte: oneMonthAgo },
        },
        orderBy: { date: 'desc' },
      }),
      this.prisma.userPortfolioHistory.findFirst({
        where: {
          client: { advisorId },
          date: { lte: oneYearAgo },
        },
        orderBy: { date: 'desc' },
      }),
    ])

    const prevMonthValue = prevMonthSnap ? Number(prevMonthSnap.totalValue) : currentAum * 0.97
    const prevYearValue = prevYearSnap ? Number(prevYearSnap.totalValue) : currentAum * 0.88

    const momAbsolute = currentAum - prevMonthValue
    const momChange = prevMonthValue > 0 ? (momAbsolute / prevMonthValue) * 100 : 0
    const yoyAbsolute = currentAum - prevYearValue
    const yoyChange = prevYearValue > 0 ? (yoyAbsolute / prevYearValue) * 100 : 0

    // Build trend (last 6 months)
    const trend = await this.buildAumTrend(advisorId, 6)

    return {
      momChange: Math.round(momChange * 100) / 100,
      momAbsolute: Math.round(momAbsolute * 100) / 100,
      yoyChange: Math.round(yoyChange * 100) / 100,
      yoyAbsolute: Math.round(yoyAbsolute * 100) / 100,
      prevMonthValue: Math.round(prevMonthValue * 100) / 100,
      prevYearValue: Math.round(prevYearValue * 100) / 100,
      trend,
    }
  }

  private async buildAumTrend(advisorId: string, months: number) {
    const trend: { date: string; value: number }[] = []
    const now = new Date()

    for (let i = months; i >= 0; i--) {
      const date = new Date(now.getFullYear(), now.getMonth() - i, 1)

      const snap = await this.prisma.userPortfolioHistory.findFirst({
        where: {
          client: { advisorId },
          date: { lte: date },
        },
        orderBy: { date: 'desc' },
      })

      if (snap) {
        trend.push({
          date: date.toISOString().split('T')[0],
          value: Number(snap.totalValue),
        })
      }
    }

    // If no history exists, return current AUM as single point
    if (trend.length === 0) {
      const currentAum = await this.prisma.fAHolding.aggregate({
        where: { client: { advisorId } },
        _sum: { currentValue: true },
      })
      trend.push({
        date: now.toISOString().split('T')[0],
        value: Number(currentAum._sum.currentValue || 0),
      })
    }

    return trend
  }

  private async computeClientsGrowth(advisorId: string, currentCount: number): Promise<KpiGrowthDto | null> {
    const now = new Date()
    const oneMonthAgo = new Date(now.getFullYear(), now.getMonth() - 1, now.getDate())
    const oneYearAgo = new Date(now.getFullYear() - 1, now.getMonth(), now.getDate())

    const [prevMonthCount, prevYearCount] = await Promise.all([
      this.prisma.fAClient.count({
        where: { advisorId, createdAt: { lte: oneMonthAgo } },
      }),
      this.prisma.fAClient.count({
        where: { advisorId, createdAt: { lte: oneYearAgo } },
      }),
    ])

    const momAbsolute = currentCount - prevMonthCount
    const momChange = prevMonthCount > 0 ? (momAbsolute / prevMonthCount) * 100 : 0
    const yoyAbsolute = currentCount - prevYearCount
    const yoyChange = prevYearCount > 0 ? (yoyAbsolute / prevYearCount) * 100 : 0

    return {
      momChange: Math.round(momChange * 100) / 100,
      momAbsolute,
      yoyChange: Math.round(yoyChange * 100) / 100,
      yoyAbsolute,
      prevMonthValue: prevMonthCount,
      prevYearValue: prevYearCount,
      trend: [],
    }
  }

  private async computeSipsGrowth(advisorId: string, currentCount: number): Promise<KpiGrowthDto | null> {
    const now = new Date()
    const oneMonthAgo = new Date(now.getFullYear(), now.getMonth() - 1, now.getDate())
    const oneYearAgo = new Date(now.getFullYear() - 1, now.getMonth(), now.getDate())

    const [prevMonthCount, prevYearCount] = await Promise.all([
      this.prisma.fASIP.count({
        where: { client: { advisorId }, status: 'ACTIVE', createdAt: { lte: oneMonthAgo } },
      }),
      this.prisma.fASIP.count({
        where: { client: { advisorId }, status: 'ACTIVE', createdAt: { lte: oneYearAgo } },
      }),
    ])

    const momAbsolute = currentCount - prevMonthCount
    const momChange = prevMonthCount > 0 ? (momAbsolute / prevMonthCount) * 100 : 0
    const yoyAbsolute = currentCount - prevYearCount
    const yoyChange = prevYearCount > 0 ? (yoyAbsolute / prevYearCount) * 100 : 0

    return {
      momChange: Math.round(momChange * 100) / 100,
      momAbsolute,
      yoyChange: Math.round(yoyChange * 100) / 100,
      yoyAbsolute,
      prevMonthValue: prevMonthCount,
      prevYearValue: prevYearCount,
      trend: [],
    }
  }

  // ============================================================
  // Private: Insights computations
  // ============================================================

  private async computePortfolioHealth(advisorId: string): Promise<PortfolioHealthItemDto[]> {
    const clients = await this.prisma.fAClient.findMany({
      where: { advisorId, status: 'ACTIVE' },
      include: {
        holdings: true,
        sips: { where: { status: 'ACTIVE' } },
      },
    })

    return clients.map((client) => {
      const holdings = client.holdings || []
      const sips = client.sips || []
      const aum = holdings.reduce((sum, h) => sum + Number(h.currentValue || 0), 0)
      const invested = holdings.reduce((sum, h) => sum + Number(h.investedValue || 0), 0)
      const returns = invested > 0 ? ((aum - invested) / invested) * 100 : 0

      const issues: string[] = []
      let score = 100

      // Diversification check
      const assetClasses = new Set(holdings.map((h) => h.assetClass))
      if (assetClasses.size <= 1 && holdings.length > 0) {
        issues.push('Low diversification — concentrated in single asset class')
        score -= 20
      }

      // No active SIPs
      if (sips.length === 0 && aum > 0) {
        issues.push('No active SIPs — no systematic investments')
        score -= 15
      }

      // Negative returns
      if (returns < 0) {
        issues.push(`Negative returns (${returns.toFixed(1)}%)`)
        score -= 25
      } else if (returns < 5) {
        issues.push(`Below benchmark returns (${returns.toFixed(1)}%)`)
        score -= 10
      }

      // Very small portfolio
      if (aum > 0 && aum < 50000) {
        issues.push('Portfolio value below ₹50,000')
        score -= 10
      }

      // High concentration in single fund
      if (holdings.length > 0) {
        const maxHolding = Math.max(...holdings.map((h) => Number(h.currentValue || 0)))
        if (aum > 0 && maxHolding / aum > 0.5) {
          issues.push('Over 50% concentrated in a single fund')
          score -= 15
        }
      }

      score = Math.max(0, Math.min(100, score))
      const status = score >= 70 ? 'healthy' : score >= 40 ? 'needs_attention' : 'critical'

      return {
        clientId: client.id,
        clientName: client.name,
        score,
        status,
        issues,
        aum: Math.round(aum * 100) / 100,
      }
    })
  }

  private async computeRebalancingAlerts(advisorId: string): Promise<RebalancingAlertDto[]> {
    const clients = await this.prisma.fAClient.findMany({
      where: { advisorId, status: 'ACTIVE' },
      include: { holdings: true },
    })

    const alerts: RebalancingAlertDto[] = []

    for (const client of clients) {
      const holdings = client.holdings || []
      const totalValue = holdings.reduce((sum, h) => sum + Number(h.currentValue || 0), 0)
      if (totalValue === 0) continue

      const riskProfile = RISK_PROFILE_MAP[client.riskProfile] || 'Moderate'
      const targets = TARGET_ALLOCATIONS[riskProfile] || TARGET_ALLOCATIONS.Moderate

      // Compute current allocation
      const currentAlloc: Record<string, number> = {}
      holdings.forEach((h) => {
        currentAlloc[h.assetClass] = (currentAlloc[h.assetClass] || 0) + Number(h.currentValue || 0)
      })

      // Check each target asset class for deviation > 5%
      for (const [assetClass, targetPct] of Object.entries(targets)) {
        const currentValue = currentAlloc[assetClass] || 0
        const currentPct = (currentValue / totalValue) * 100
        const deviation = currentPct - targetPct

        if (Math.abs(deviation) > 5) {
          alerts.push({
            clientId: client.id,
            clientName: client.name,
            assetClass,
            currentAllocation: Math.round(currentPct * 100) / 100,
            targetAllocation: targetPct,
            deviation: Math.round(deviation * 100) / 100,
            action: deviation > 0 ? 'decrease' : 'increase',
            amount: Math.abs(Math.round((deviation / 100) * totalValue * 100) / 100),
          })
        }
      }
    }

    return alerts.sort((a, b) => Math.abs(b.deviation) - Math.abs(a.deviation))
  }

  private async computeTaxHarvesting(advisorId: string): Promise<TaxHarvestingOpportunityDto[]> {
    const holdings = await this.prisma.fAHolding.findMany({
      where: {
        client: { advisorId },
        absoluteGain: { lt: 0 },
      },
      include: {
        client: { select: { id: true, name: true } },
      },
      orderBy: { absoluteGain: 'asc' },
      take: 20,
    })

    return holdings.map((h) => {
      const invested = Number(h.investedValue || 0)
      const current = Number(h.currentValue || 0)
      const unrealizedLoss = Math.abs(Number(h.absoluteGain || 0))

      // Determine holding period
      const daysSincePurchase = h.lastTxnDate
        ? Math.floor((Date.now() - h.lastTxnDate.getTime()) / (1000 * 60 * 60 * 24))
        : 0
      const holdingPeriod = daysSincePurchase > 365 ? 'long_term' : 'short_term'

      // Potential tax savings (approximate: 15% STCG, 10% LTCG for equity)
      const taxRate = holdingPeriod === 'short_term' ? 0.15 : 0.10
      const potentialSavings = Math.round(unrealizedLoss * taxRate * 100) / 100

      return {
        clientId: h.client.id,
        clientName: h.client.name,
        fundName: h.fundName,
        holdingId: h.id,
        investedValue: invested,
        currentValue: current,
        unrealizedLoss: Math.round(unrealizedLoss * 100) / 100,
        potentialSavings,
        holdingPeriod,
      }
    })
  }

  private async computeGoalAlerts(advisorId: string): Promise<GoalAlertDto[]> {
    const goals = await this.prisma.userGoal.findMany({
      where: {
        client: { advisorId },
        status: 'ACTIVE',
      },
      include: {
        client: { select: { id: true, name: true } },
      },
      orderBy: { targetDate: 'asc' },
    })

    return goals.map((goal) => {
      const targetAmount = Number(goal.targetAmount)
      const currentAmount = Number(goal.currentAmount)
      const progress = targetAmount > 0 ? (currentAmount / targetAmount) * 100 : 0

      const now = new Date()
      const targetDate = new Date(goal.targetDate)
      const totalDays = Math.max(1, Math.ceil((targetDate.getTime() - goal.createdAt.getTime()) / (1000 * 60 * 60 * 24)))
      const elapsedDays = Math.ceil((now.getTime() - goal.createdAt.getTime()) / (1000 * 60 * 60 * 24))
      const daysRemaining = Math.max(0, Math.ceil((targetDate.getTime() - now.getTime()) / (1000 * 60 * 60 * 24)))

      const expectedProgress = totalDays > 0 ? (elapsedDays / totalDays) * 100 : 0
      const progressRatio = expectedProgress > 0 ? progress / expectedProgress : 1

      let status: string
      if (progressRatio >= 0.9) {
        status = 'ON_TRACK'
      } else if (progressRatio >= 0.6) {
        status = 'AT_RISK'
      } else {
        status = 'OFF_TRACK'
      }

      return {
        clientId: goal.client?.id || '',
        clientName: goal.client?.name || '',
        goalId: goal.id,
        goalName: goal.name,
        status,
        progress: Math.round(progress * 100) / 100,
        targetAmount,
        currentAmount,
        daysRemaining,
      }
    })
  }

  private getMarketInsights(): MarketInsightDto[] {
    // Seeded market news items — in production this would come from a market data feed
    return [
      {
        id: 'mi-1',
        title: 'RBI Holds Repo Rate Steady at 6.5%',
        summary: 'The RBI maintained the repo rate at 6.5% for the eighth consecutive time, signaling continued focus on inflation control while supporting growth.',
        category: 'Monetary Policy',
        impact: 'neutral',
        date: new Date().toISOString().split('T')[0],
      },
      {
        id: 'mi-2',
        title: 'Equity Markets Hit All-Time High',
        summary: 'Nifty 50 crossed the 25,000 mark driven by strong FII inflows and robust Q3 earnings across IT and banking sectors.',
        category: 'Markets',
        impact: 'positive',
        date: new Date().toISOString().split('T')[0],
      },
      {
        id: 'mi-3',
        title: 'SEBI Tightens Small-Cap Fund Regulations',
        summary: 'New stress testing norms for small-cap and mid-cap funds may impact fund managers\' ability to deploy in smaller companies.',
        category: 'Regulation',
        impact: 'negative',
        date: new Date().toISOString().split('T')[0],
      },
      {
        id: 'mi-4',
        title: 'Gold ETFs See Record Inflows',
        summary: 'Amid global uncertainty, gold ETFs attracted ₹2,800 Cr in the last quarter, highest in 3 years.',
        category: 'Commodities',
        impact: 'positive',
        date: new Date().toISOString().split('T')[0],
      },
    ]
  }

  // ============================================================
  // Helpers
  // ============================================================

  private formatLastActive(date: Date | null): string {
    if (!date) return 'Never'

    const now = new Date()
    const diff = now.getTime() - date.getTime()
    const hours = Math.floor(diff / (1000 * 60 * 60))
    const days = Math.floor(hours / 24)

    if (hours < 1) return 'Just now'
    if (hours < 24) return `${hours} hour${hours > 1 ? 's' : ''} ago`
    if (days < 7) return `${days} day${days > 1 ? 's' : ''} ago`
    return date.toISOString().split('T')[0]
  }
}
