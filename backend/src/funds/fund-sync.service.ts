import { Injectable, Logger, OnModuleInit } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { MfApiService, FundWithMetrics, MFDetails, MFScheme } from './mfapi.service';
import { Prisma } from '@prisma/client';

/**
 * Fund Sync Service
 *
 * Synchronizes fund data from MFAPI.in to the ONDC-compliant database schema.
 *
 * Tables populated:
 * - providers (AMC/Fund Houses)
 * - schemes (Parent fund items)
 * - scheme_plans (Individual plans with ISIN)
 * - scheme_plan_nav (Current NAV)
 * - scheme_plan_metrics (Returns, ratings, etc.)
 * - scheme_plan_nav_history (Historical NAV for charts)
 * - data_sync_logs (Sync tracking)
 */

// Map MFAPI categories to ONDC L3 category IDs
const CATEGORY_TO_ONDC_L3: Record<string, string> = {
  // Equity
  'Large Cap Fund': 'L3-LARGE_CAP',
  'Large & Mid Cap Fund': 'L3-LARGE_MID_CAP',
  'Mid Cap Fund': 'L3-MID_CAP',
  'Small Cap Fund': 'L3-SMALL_CAP',
  'Multi Cap Fund': 'L3-MULTI_CAP',
  'Flexi Cap Fund': 'L3-FLEXI_CAP',
  'Focused Fund': 'L3-FOCUSED',
  'ELSS': 'L3-ELSS',
  'Value Fund': 'L3-VALUE',
  'Value/Contra Fund': 'L3-VALUE',
  'Contra Fund': 'L3-CONTRA',
  'Dividend Yield Fund': 'L3-DIVIDEND_YIELD',
  'Sectoral/Thematic': 'L3-SECTORAL',
  'Sectoral Fund': 'L3-SECTORAL',
  'Thematic Fund': 'L3-SECTORAL',
  // Debt
  'Liquid Fund': 'L3-LIQUID',
  'Overnight Fund': 'L3-OVERNIGHT',
  'Ultra Short Duration Fund': 'L3-ULTRA_SHORT',
  'Low Duration Fund': 'L3-LOW_DURATION',
  'Money Market Fund': 'L3-MONEY_MARKET',
  'Short Duration Fund': 'L3-SHORT_DURATION',
  'Medium Duration Fund': 'L3-MEDIUM_DURATION',
  'Medium to Long Duration Fund': 'L3-MEDIUM_LONG_DURATION',
  'Long Duration Fund': 'L3-LONG_DURATION',
  'Dynamic Bond Fund': 'L3-DYNAMIC_BOND',
  'Corporate Bond Fund': 'L3-CORPORATE_BOND',
  'Credit Risk Fund': 'L3-CREDIT_RISK',
  'Banking and PSU Fund': 'L3-BANKING_PSU',
  'Gilt Fund': 'L3-GILT',
  'Gilt Fund with 10 year constant duration': 'L3-GILT_10Y',
  'Floater Fund': 'L3-FLOATER',
  // Hybrid
  'Aggressive Hybrid Fund': 'L3-AGGRESSIVE_HYBRID',
  'Conservative Hybrid Fund': 'L3-CONSERVATIVE_HYBRID',
  'Balanced Advantage Fund': 'L3-DYNAMIC_ALLOCATION',
  'Dynamic Asset Allocation': 'L3-DYNAMIC_ALLOCATION',
  'Multi Asset Allocation Fund': 'L3-MULTI_ASSET',
  'Arbitrage Fund': 'L3-ARBITRAGE',
  'Equity Savings Fund': 'L3-EQUITY_SAVINGS',
  // Solution Oriented
  'Retirement Fund': 'L3-RETIREMENT',
  "Children's Fund": 'L3-CHILDRENS',
  // Other
  'Index Fund': 'L3-INDEX',
  'ETF': 'L3-INDEX',
  'Index Funds': 'L3-INDEX',
  'Fund of Funds (Overseas)': 'L3-FOF_OVERSEAS',
  'Fund of Funds (Domestic)': 'L3-FOF_DOMESTIC',
  'Gold': 'L3-GOLD',
  'Gold ETF': 'L3-GOLD',
};

// Extract plan type from scheme name
function extractPlanType(schemeName: string): 'direct' | 'regular' {
  const name = schemeName.toLowerCase();
  if (name.includes('direct')) return 'direct';
  return 'regular';
}

// Extract option type from scheme name
function extractOptionType(schemeName: string): 'growth' | 'idcw' {
  const name = schemeName.toLowerCase();
  if (name.includes('dividend') || name.includes('idcw') || name.includes('payout')) return 'idcw';
  return 'growth';
}

// Generate a slug from fund house name
function slugify(text: string): string {
  return text
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-|-$/g, '');
}

// Parse NAV date from DD-MM-YYYY format
function parseNavDate(dateStr: string): Date {
  const [day, month, year] = dateStr.split('-').map(Number);
  return new Date(year, month - 1, day);
}

@Injectable()
export class FundSyncService implements OnModuleInit {
  private readonly logger = new Logger(FundSyncService.name);
  private isSyncing = false;

  constructor(
    private readonly prisma: PrismaService,
    private readonly mfApiService: MfApiService,
  ) {}

  async onModuleInit() {
    // Check if we need initial sync
    const schemeCount = await this.prisma.scheme.count();
    if (schemeCount === 0) {
      this.logger.log('No schemes found, starting initial sync...');
      // Don't await - run in background
      this.syncPopularFunds().catch(err => {
        this.logger.error(`Initial sync failed: ${err.message}`);
      });
    }
  }

  /**
   * Sync popular funds (curated list of ~150 top funds)
   * Good for initial setup and testing
   */
  async syncPopularFunds(): Promise<{ synced: number; failed: number }> {
    if (this.isSyncing) {
      this.logger.warn('Sync already in progress');
      return { synced: 0, failed: 0 };
    }

    this.isSyncing = true;
    const syncLog = await this.startSyncLog('mfapi_popular');

    try {
      this.logger.log('Starting popular funds sync...');
      const funds = await this.mfApiService.getPopularFunds();

      let synced = 0;
      let failed = 0;

      for (const fund of funds) {
        try {
          await this.syncFund(fund);
          synced++;
        } catch (error) {
          this.logger.error(`Failed to sync ${fund.schemeCode}: ${error.message}`);
          failed++;
        }
      }

      await this.completeSyncLog(syncLog.id, funds.length, synced, failed);
      this.logger.log(`Popular funds sync completed: ${synced} synced, ${failed} failed`);

      return { synced, failed };
    } catch (error) {
      await this.failSyncLog(syncLog.id, error.message);
      throw error;
    } finally {
      this.isSyncing = false;
    }
  }

  /**
   * Sync funds by category
   */
  async syncByCategory(category: string, limit: number = 30): Promise<{ synced: number; failed: number }> {
    if (this.isSyncing) {
      this.logger.warn('Sync already in progress');
      return { synced: 0, failed: 0 };
    }

    this.isSyncing = true;
    const syncLog = await this.startSyncLog(`mfapi_category_${category}`);

    try {
      this.logger.log(`Starting ${category} sync...`);
      const funds = await this.mfApiService.getFundsByCategory(category, limit);

      let synced = 0;
      let failed = 0;

      for (const fund of funds) {
        try {
          await this.syncFund(fund);
          synced++;
        } catch (error) {
          this.logger.error(`Failed to sync ${fund.schemeCode}: ${error.message}`);
          failed++;
        }
      }

      await this.completeSyncLog(syncLog.id, funds.length, synced, failed);
      this.logger.log(`Category ${category} sync completed: ${synced} synced, ${failed} failed`);

      return { synced, failed };
    } catch (error) {
      await this.failSyncLog(syncLog.id, error.message);
      throw error;
    } finally {
      this.isSyncing = false;
    }
  }

  /**
   * Sync a single fund with full NAV history
   */
  async syncFundWithHistory(schemeCode: number): Promise<void> {
    try {
      // Get fund details with full NAV history
      const details = await this.mfApiService.getFundDetails(schemeCode);
      const fundWithMetrics = await this.mfApiService.getFundWithMetrics(schemeCode);

      // Sync fund data
      await this.syncFund(fundWithMetrics);

      // Get the scheme plan
      const schemePlan = await this.prisma.schemePlan.findFirst({
        where: { mfapiSchemeCode: schemeCode },
      });

      if (schemePlan && details.data.length > 0) {
        // Sync NAV history (limit to last 5 years = ~1250 data points)
        const navHistory = details.data.slice(0, 1250).map(nav => ({
          schemePlanId: schemePlan.id,
          navDate: parseNavDate(nav.date),
          nav: new Prisma.Decimal(nav.nav),
        }));

        // Batch upsert NAV history
        for (const nav of navHistory) {
          await this.prisma.schemePlanNavHistory.upsert({
            where: {
              schemePlanId_navDate: {
                schemePlanId: nav.schemePlanId,
                navDate: nav.navDate,
              },
            },
            update: { nav: nav.nav },
            create: nav,
          });
        }

        this.logger.log(`Synced ${navHistory.length} NAV history points for ${schemeCode}`);
      }
    } catch (error) {
      this.logger.error(`Failed to sync fund ${schemeCode} with history: ${error.message}`);
      throw error;
    }
  }

  /**
   * Update NAV for all synced funds (daily job)
   */
  async updateAllNavs(): Promise<{ updated: number; failed: number }> {
    if (this.isSyncing) {
      this.logger.warn('Sync already in progress');
      return { updated: 0, failed: 0 };
    }

    this.isSyncing = true;
    const syncLog = await this.startSyncLog('mfapi_nav_update');

    try {
      // Get all scheme plans with MFAPI codes
      const schemePlans = await this.prisma.schemePlan.findMany({
        where: { mfapiSchemeCode: { not: null } },
        select: { id: true, mfapiSchemeCode: true },
      });

      let updated = 0;
      let failed = 0;

      // Process in batches
      const batchSize = 10;
      for (let i = 0; i < schemePlans.length; i += batchSize) {
        const batch = schemePlans.slice(i, i + batchSize);

        await Promise.allSettled(
          batch.map(async (plan) => {
            try {
              const details = await this.mfApiService.getFundDetails(plan.mfapiSchemeCode!);
              if (details.data.length > 0) {
                const currentNav = parseFloat(details.data[0].nav);
                const previousNav = details.data.length > 1 ? parseFloat(details.data[1].nav) : currentNav;
                const dayChange = currentNav - previousNav;
                const dayChangePct = previousNav > 0 ? (dayChange / previousNav) * 100 : 0;

                await this.prisma.schemePlanNav.upsert({
                  where: { schemePlanId: plan.id },
                  update: {
                    nav: new Prisma.Decimal(currentNav),
                    navDate: parseNavDate(details.data[0].date),
                    dayChange: new Prisma.Decimal(dayChange),
                    dayChangePct: new Prisma.Decimal(dayChangePct),
                  },
                  create: {
                    schemePlanId: plan.id,
                    nav: new Prisma.Decimal(currentNav),
                    navDate: parseNavDate(details.data[0].date),
                    dayChange: new Prisma.Decimal(dayChange),
                    dayChangePct: new Prisma.Decimal(dayChangePct),
                  },
                });
                updated++;
              }
            } catch (error) {
              this.logger.debug(`Failed to update NAV for ${plan.mfapiSchemeCode}: ${error.message}`);
              failed++;
            }
          })
        );

        // Small delay between batches
        await new Promise(resolve => setTimeout(resolve, 500));
      }

      await this.completeSyncLog(syncLog.id, schemePlans.length, updated, failed);
      this.logger.log(`NAV update completed: ${updated} updated, ${failed} failed`);

      return { updated, failed };
    } catch (error) {
      await this.failSyncLog(syncLog.id, error.message);
      throw error;
    } finally {
      this.isSyncing = false;
    }
  }

  /**
   * Get sync status
   */
  async getSyncStatus(): Promise<{
    isSyncing: boolean;
    lastSync: any;
    counts: { providers: number; schemes: number; schemePlans: number };
  }> {
    const lastSync = await this.prisma.dataSyncLog.findFirst({
      orderBy: { startedAt: 'desc' },
    });

    const [providers, schemes, schemePlans] = await Promise.all([
      this.prisma.provider.count(),
      this.prisma.scheme.count(),
      this.prisma.schemePlan.count(),
    ]);

    return {
      isSyncing: this.isSyncing,
      lastSync,
      counts: { providers, schemes, schemePlans },
    };
  }

  // ============= Private Methods =============

  /**
   * Sync a single fund to the database
   */
  private async syncFund(fund: FundWithMetrics): Promise<void> {
    // 1. Upsert Provider (Fund House)
    const providerId = slugify(fund.fundHouse);
    await this.prisma.provider.upsert({
      where: { id: providerId },
      update: { name: fund.fundHouse },
      create: {
        id: providerId,
        name: fund.fundHouse,
        shortName: this.extractShortName(fund.fundHouse),
      },
    });

    // 2. Map category to ONDC L3
    const categoryId = this.mapCategoryToOndcL3(fund.category);

    // 3. Create base scheme name (without plan/option)
    const baseSchemeName = this.extractBaseSchemeName(fund.schemeName);
    const schemeId = `${providerId}-${slugify(baseSchemeName)}`;

    // 4. Upsert Scheme
    await this.prisma.scheme.upsert({
      where: { id: schemeId },
      update: {
        name: baseSchemeName,
        categoryId,
        fundManager: fund.fundManager,
        mfapiSchemeCode: fund.schemeCode,
      },
      create: {
        id: schemeId,
        providerId,
        name: baseSchemeName,
        categoryId,
        fundManager: fund.fundManager,
        mfapiSchemeCode: fund.schemeCode,
      },
    });

    // 5. Upsert Scheme Plan
    const planType = extractPlanType(fund.schemeName);
    const optionType = extractOptionType(fund.schemeName);
    const schemePlanId = `${schemeId}-${planType}-${optionType}`;

    await this.prisma.schemePlan.upsert({
      where: { id: schemePlanId },
      update: {
        name: fund.schemeName,
        isin: fund.isin || `TEMP-${fund.schemeCode}`,
        mfapiSchemeCode: fund.schemeCode,
      },
      create: {
        id: schemePlanId,
        schemeId,
        name: fund.schemeName,
        isin: fund.isin || `TEMP-${fund.schemeCode}`,
        rtaIdentifier: `MFAPI-${fund.schemeCode}`,
        plan: planType,
        option: optionType,
        mfapiSchemeCode: fund.schemeCode,
      },
    });

    // 6. Upsert NAV
    await this.prisma.schemePlanNav.upsert({
      where: { schemePlanId: schemePlanId },
      update: {
        nav: new Prisma.Decimal(fund.currentNav),
        navDate: new Date(),
        dayChange: new Prisma.Decimal(fund.dayChange),
        dayChangePct: new Prisma.Decimal(fund.dayChangePercent),
      },
      create: {
        schemePlanId: schemePlanId,
        nav: new Prisma.Decimal(fund.currentNav),
        navDate: new Date(),
        dayChange: new Prisma.Decimal(fund.dayChange),
        dayChangePct: new Prisma.Decimal(fund.dayChangePercent),
      },
    });

    // 7. Upsert Metrics
    await this.prisma.schemePlanMetrics.upsert({
      where: { schemePlanId: schemePlanId },
      update: {
        return1y: fund.return1Y ? new Prisma.Decimal(fund.return1Y) : null,
        return3y: fund.return3Y ? new Prisma.Decimal(fund.return3Y) : null,
        return5y: fund.return5Y ? new Prisma.Decimal(fund.return5Y) : null,
        riskRating: fund.riskRating,
        crisilRating: fund.crisilRating,
        fundRating: fund.fundRating,
        volatility: fund.volatility ? new Prisma.Decimal(fund.volatility) : null,
        expenseRatio: fund.expenseRatio ? new Prisma.Decimal(fund.expenseRatio) : null,
        aum: fund.aum ? new Prisma.Decimal(fund.aum) : null,
      },
      create: {
        schemePlanId: schemePlanId,
        return1y: fund.return1Y ? new Prisma.Decimal(fund.return1Y) : null,
        return3y: fund.return3Y ? new Prisma.Decimal(fund.return3Y) : null,
        return5y: fund.return5Y ? new Prisma.Decimal(fund.return5Y) : null,
        riskRating: fund.riskRating,
        crisilRating: fund.crisilRating,
        fundRating: fund.fundRating,
        volatility: fund.volatility ? new Prisma.Decimal(fund.volatility) : null,
        expenseRatio: fund.expenseRatio ? new Prisma.Decimal(fund.expenseRatio) : null,
        aum: fund.aum ? new Prisma.Decimal(fund.aum) : null,
      },
    });
  }

  /**
   * Map MFAPI category to ONDC L3 category ID
   */
  private mapCategoryToOndcL3(category: string): string {
    // Try exact match
    if (CATEGORY_TO_ONDC_L3[category]) {
      return CATEGORY_TO_ONDC_L3[category];
    }

    // Try partial match
    for (const [key, value] of Object.entries(CATEGORY_TO_ONDC_L3)) {
      if (category.toLowerCase().includes(key.toLowerCase())) {
        return value;
      }
    }

    // Default mapping based on keywords
    const lower = category.toLowerCase();
    if (lower.includes('large') && lower.includes('mid')) return 'L3-LARGE_MID_CAP';
    if (lower.includes('large')) return 'L3-LARGE_CAP';
    if (lower.includes('mid')) return 'L3-MID_CAP';
    if (lower.includes('small')) return 'L3-SMALL_CAP';
    if (lower.includes('flexi')) return 'L3-FLEXI_CAP';
    if (lower.includes('multi')) return 'L3-MULTI_CAP';
    if (lower.includes('elss') || lower.includes('tax')) return 'L3-ELSS';
    if (lower.includes('liquid')) return 'L3-LIQUID';
    if (lower.includes('overnight')) return 'L3-OVERNIGHT';
    if (lower.includes('gilt')) return 'L3-GILT';
    if (lower.includes('hybrid') || lower.includes('balanced')) return 'L3-AGGRESSIVE_HYBRID';
    if (lower.includes('index') || lower.includes('etf')) return 'L3-INDEX';
    if (lower.includes('gold')) return 'L3-GOLD';

    // Default to Other
    return 'L3-OTHER';
  }

  /**
   * Extract base scheme name (without plan/option suffixes)
   */
  private extractBaseSchemeName(fullName: string): string {
    return fullName
      .replace(/\s*-?\s*(Direct|Regular)\s*(Plan)?/gi, '')
      .replace(/\s*-?\s*(Growth|Dividend|IDCW|Payout|Reinvestment)\s*(Option)?/gi, '')
      .replace(/\s*-?\s*Plan\s*$/gi, '')
      .replace(/\s+/g, ' ')
      .trim();
  }

  /**
   * Extract short name from fund house
   */
  private extractShortName(fundHouse: string): string {
    // Common patterns
    const patterns = [
      /^(\w+)\s+Mutual\s+Fund$/i,
      /^(\w+)\s+Asset\s+Management$/i,
      /^(\w+)\s+AMC$/i,
    ];

    for (const pattern of patterns) {
      const match = fundHouse.match(pattern);
      if (match) return match[1];
    }

    // Just take first word
    return fundHouse.split(' ')[0];
  }

  // ============= Sync Log Methods =============

  private async startSyncLog(syncType: string) {
    return this.prisma.dataSyncLog.create({
      data: {
        syncType,
        status: 'started',
      },
    });
  }

  private async completeSyncLog(id: number, total: number, synced: number, failed: number) {
    return this.prisma.dataSyncLog.update({
      where: { id },
      data: {
        status: 'completed',
        recordsTotal: total,
        recordsSynced: synced,
        recordsFailed: failed,
        completedAt: new Date(),
      },
    });
  }

  private async failSyncLog(id: number, errorMessage: string) {
    return this.prisma.dataSyncLog.update({
      where: { id },
      data: {
        status: 'failed',
        errorMessage,
        completedAt: new Date(),
      },
    });
  }
}
