import { Injectable, Logger, OnModuleInit, Inject } from '@nestjs/common';
import { Cron } from '@nestjs/schedule';
import { Queue } from 'bullmq';
import { PrismaService } from '../prisma/prisma.service';
import { AmfiService, AmfiNavRecord } from './amfi.service';
import { MetricsCalculatorService } from './metrics-calculator.service';
import { BULLMQ_CONNECTION } from '../common/queue/queue.module';
import { Prisma } from '@prisma/client';

/**
 * Fund Sync Service — AMFI-based
 *
 * Synchronizes ALL fund data from the AMFI daily NAV file to the ONDC-compliant database.
 * Supports Direct + Regular plans, Growth + IDCW options (~18K active fund plans).
 *
 * Tables populated:
 * - providers (AMC/Fund Houses)
 * - schemes (Parent fund items)
 * - scheme_plans (Individual plans with ISIN)
 * - scheme_plan_nav (Current NAV)
 * - scheme_plan_nav_history (Historical NAV for charts)
 * - data_sync_logs (Sync tracking)
 */

// Map AMFI/MFAPI categories to ONDC L3 category IDs
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
  'Sector Allocation': 'L3-SECTORAL',
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
  'Fund of Funds': 'L3-FOF_DOMESTIC',
  'Gold': 'L3-GOLD',
  'Gold ETF': 'L3-GOLD',
};

function extractPlanType(schemeName: string): 'direct' | 'regular' {
  return schemeName.toLowerCase().includes('direct') ? 'direct' : 'regular';
}

function extractOptionType(schemeName: string): 'growth' | 'idcw' {
  const name = schemeName.toLowerCase();
  if (name.includes('dividend') || name.includes('idcw') || name.includes('payout')) return 'idcw';
  return 'growth';
}

function slugify(text: string): string {
  return text
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-|-$/g, '');
}

@Injectable()
export class FundSyncService implements OnModuleInit {
  private readonly logger = new Logger(FundSyncService.name);
  private isSyncing = false;

  private metricsQueue!: Queue;

  constructor(
    private readonly prisma: PrismaService,
    private readonly amfiService: AmfiService,
    private readonly metricsCalculator: MetricsCalculatorService,
    @Inject(BULLMQ_CONNECTION) private readonly bullmqConnection: any,
  ) {}

  async onModuleInit() {
    this.metricsQueue = new Queue('metrics-recalc', { connection: this.bullmqConnection });

    const schemeCount = await this.prisma.scheme.count();
    if (schemeCount === 0) {
      this.logger.log('No schemes found, starting initial AMFI sync in background...');
      this.syncFromAmfi().catch(err => {
        this.logger.error(`Initial AMFI sync failed: ${err.message}`);
      });
    }
  }

  /**
   * Daily NAV update cron — runs Mon-Fri at 00:30 IST (AMFI file updates ~23:30 IST).
   */
  @Cron('0 30 0 * * 1-5', { timeZone: 'Asia/Kolkata' })
  async dailyNavUpdate(): Promise<void> {
    this.logger.log('Daily NAV update cron triggered');

    const maxRetries = 3;
    for (let attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        await this.syncFromAmfi();
        return;
      } catch (error) {
        this.logger.error(`Daily NAV update attempt ${attempt}/${maxRetries} failed: ${error.message}`);
        if (attempt < maxRetries) {
          await new Promise(resolve => setTimeout(resolve, 5 * 60 * 1000)); // 5 min backoff
        }
      }
    }

    this.logger.error('Daily NAV update failed after all retries');
  }

  /**
   * Full AMFI ingest: download NAVAll.txt, sync all funds with valid ISINs.
   */
  async syncFromAmfi(): Promise<{ synced: number; failed: number; total: number }> {
    if (this.isSyncing) {
      this.logger.warn('Sync already in progress');
      return { synced: 0, failed: 0, total: 0 };
    }

    this.isSyncing = true;
    const syncLog = await this.startSyncLog('amfi_nav');

    try {
      // 1. Fetch and parse the AMFI file
      const allRecords = await this.amfiService.fetchAndParseNavAll();

      // 2. Filter: open-ended, valid ISIN, no segregated, no ETFs
      const validRecords = allRecords.filter(r => {
        // Must have valid ISIN
        if (!r.isinGrowth && !r.isinReinvestment) return false
        // Open-ended only (drop Close Ended + Interval)
        if (r.schemeType !== 'Open Ended Schemes') return false
        const nameLower = r.schemeName.toLowerCase()
        // No segregated portfolios
        if (nameLower.includes('segregat')) return false
        // No ETFs
        if (nameLower.includes(' etf')) return false
        if (r.schemeCategory === 'Other  ETFs' || r.schemeCategory === 'Gold ETF') return false
        return true
      })
      this.logger.log(`AMFI: ${allRecords.length} total → ${validRecords.length} after filtering (open-ended, no segregated, no ETFs)`);

      // 3. Check if AMFI NAV date is same as last synced NAV date (holiday/weekend skip)
      if (validRecords.length > 0) {
        const latestNav = await this.prisma.schemePlanNav.findFirst({
          orderBy: { navDate: 'desc' },
          select: { navDate: true },
        });

        if (latestNav?.navDate) {
          const lastNavDate = latestNav.navDate.toISOString().slice(0, 10);
          const amfiDate = validRecords[0].navDate.toISOString().slice(0, 10);
          if (lastNavDate === amfiDate) {
            this.logger.log(`AMFI NAV date ${amfiDate} matches DB — skipping (holiday/weekend)`);
            await this.completeSyncLog(syncLog.id, validRecords.length, 0, 0);
            return { synced: 0, failed: 0, total: validRecords.length };
          }
        }
      }

      // 4. Pre-load existing data for performance optimization
      const existingData = await this.preloadExistingData();
      this.logger.log(`Pre-loaded: ${existingData.providerIds.size} providers, ${existingData.schemeIds.size} schemes, ${existingData.schemePlanIds.size} plans`);

      // 5. Sync records sequentially (shared state requires sequential access)
      let synced = 0;
      let failed = 0;
      const navHistoryBatch: { schemePlanId: string; navDate: Date; nav: Prisma.Decimal }[] = [];

      for (let i = 0; i < validRecords.length; i++) {
        try {
          await this.syncAmfiRecord(validRecords[i], existingData, navHistoryBatch);
          synced++;
        } catch (error) {
          this.logger.debug(`Failed to sync ${validRecords[i].schemeCode}: ${error.message}`);
          failed++;
        }

        // Log progress every 1000 records
        if ((i + 1) % 1000 === 0) {
          this.logger.log(`Sync progress: ${i + 1}/${validRecords.length} (${synced} ok, ${failed} failed)`);
        }

        // Flush NAV history batch every 1000 records to limit memory
        if (navHistoryBatch.length >= 1000) {
          await this.prisma.schemePlanNavHistory.createMany({
            data: navHistoryBatch.splice(0),
            skipDuplicates: true,
          });
        }
      }

      // 6. Bulk insert NAV history rows
      if (navHistoryBatch.length > 0) {
        const chunkSize = 500;
        for (let i = 0; i < navHistoryBatch.length; i += chunkSize) {
          const chunk = navHistoryBatch.slice(i, i + chunkSize);
          await this.prisma.schemePlanNavHistory.createMany({
            data: chunk,
            skipDuplicates: true,
          });
        }
        this.logger.log(`Inserted ${navHistoryBatch.length} NAV history rows`);
      }

      await this.completeSyncLog(syncLog.id, validRecords.length, synced, failed);
      this.logger.log(`AMFI sync completed: ${synced} synced, ${failed} failed out of ${validRecords.length}`);

      // 7. Queue metrics recalculation (async, non-blocking)
      await this.metricsQueue.add('recalculate', {}, {
        jobId: `metrics-after-sync-${Date.now()}`,
      });
      this.logger.log('Metrics recalculation queued (will run in background)');

      return { synced, failed, total: validRecords.length };
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
    counts: { providers: number; schemes: number; schemePlans: number; navHistoryRows: number };
  }> {
    const lastSync = await this.prisma.dataSyncLog.findFirst({
      orderBy: { startedAt: 'desc' },
    });

    const [providers, schemes, schemePlans, navHistoryRows] = await Promise.all([
      this.prisma.provider.count(),
      this.prisma.scheme.count(),
      this.prisma.schemePlan.count(),
      this.prisma.schemePlanNavHistory.count(),
    ]);

    return {
      isSyncing: this.isSyncing,
      lastSync,
      counts: { providers, schemes, schemePlans, navHistoryRows },
    };
  }

  // ============= Private Methods =============

  /**
   * Pre-load existing provider, scheme, and schemePlan IDs plus latest NAVs
   * to avoid redundant upserts for entities that already exist.
   */
  private async preloadExistingData() {
    const [providers, schemes, schemePlans, latestNavs] = await Promise.all([
      this.prisma.provider.findMany({ select: { id: true } }),
      this.prisma.scheme.findMany({ select: { id: true } }),
      this.prisma.schemePlan.findMany({ select: { id: true, isin: true } }),
      this.prisma.schemePlanNav.findMany({ select: { schemePlanId: true, nav: true } }),
    ]);

    return {
      providerIds: new Set(providers.map(p => p.id)),
      schemeIds: new Set(schemes.map(s => s.id)),
      schemePlanIds: new Set(schemePlans.map(sp => sp.id)),
      schemePlanIsins: new Set(schemePlans.map(sp => sp.isin)),
      latestNavMap: new Map(latestNavs.map(n => [n.schemePlanId, Number(n.nav)])),
    };
  }

  /**
   * Sync a single AMFI NAV record to the database.
   * Uses pre-loaded data to skip redundant upserts for existing entities.
   */
  private async syncAmfiRecord(
    record: AmfiNavRecord,
    existing: Awaited<ReturnType<typeof this.preloadExistingData>>,
    navHistoryBatch: { schemePlanId: string; navDate: Date; nav: Prisma.Decimal }[],
  ): Promise<void> {
    // 1. Upsert Provider (Fund House) — skip if already exists
    const providerId = slugify(record.fundHouse);
    if (!existing.providerIds.has(providerId)) {
      await this.prisma.provider.upsert({
        where: { id: providerId },
        update: { name: record.fundHouse },
        create: {
          id: providerId,
          name: record.fundHouse,
          shortName: this.extractShortName(record.fundHouse),
        },
      });
      existing.providerIds.add(providerId);
    }

    // 2. Map category to ONDC L3
    const categoryId = this.mapCategoryToOndcL3(record.schemeCategory);

    // 3. Create base scheme name (without plan/option)
    const baseSchemeName = this.extractBaseSchemeName(record.schemeName);
    const schemeId = `${providerId}-${slugify(baseSchemeName)}`;

    // 4. Upsert Scheme — skip if already exists
    if (!existing.schemeIds.has(schemeId)) {
      await this.prisma.scheme.upsert({
        where: { id: schemeId },
        update: {
          name: baseSchemeName,
          categoryId,
          mfapiSchemeCode: record.schemeCode,
        },
        create: {
          id: schemeId,
          providerId,
          name: baseSchemeName,
          categoryId,
          mfapiSchemeCode: record.schemeCode,
        },
      });
      existing.schemeIds.add(schemeId);
    }

    // 5. Upsert Scheme Plan
    const planType = extractPlanType(record.schemeName);
    const optionType = extractOptionType(record.schemeName);
    const isin = record.isinGrowth || record.isinReinvestment || `TEMP-${record.schemeCode}`;
    const schemePlanId = `${schemeId}-${planType}-${optionType}`;

    if (!existing.schemePlanIds.has(schemePlanId)) {
      // Handle potential ISIN uniqueness conflicts — use schemeCode suffix as fallback
      const effectiveIsin = existing.schemePlanIsins.has(isin) ? `${isin}-${record.schemeCode}` : isin;
      try {
        await this.prisma.schemePlan.upsert({
          where: { id: schemePlanId },
          update: {
            name: record.schemeName,
            isin: effectiveIsin,
            mfapiSchemeCode: record.schemeCode,
          },
          create: {
            id: schemePlanId,
            schemeId,
            name: record.schemeName,
            isin: effectiveIsin,
            rtaIdentifier: `AMFI-${record.schemeCode}`,
            plan: planType,
            option: optionType,
            mfapiSchemeCode: record.schemeCode,
          },
        });
        existing.schemePlanIds.add(schemePlanId);
        existing.schemePlanIsins.add(effectiveIsin);
      } catch (error) {
        // If ISIN unique constraint still fails, try with full unique suffix
        if (error.code === 'P2002') {
          const fallbackIsin = `${isin}-${schemePlanId}`;
          await this.prisma.schemePlan.upsert({
            where: { id: schemePlanId },
            update: {
              name: record.schemeName,
              isin: fallbackIsin,
              mfapiSchemeCode: record.schemeCode,
            },
            create: {
              id: schemePlanId,
              schemeId,
              name: record.schemeName,
              isin: fallbackIsin,
              rtaIdentifier: `AMFI-${record.schemeCode}`,
              plan: planType,
              option: optionType,
              mfapiSchemeCode: record.schemeCode,
            },
          });
          existing.schemePlanIds.add(schemePlanId);
          existing.schemePlanIsins.add(fallbackIsin);
        } else {
          throw error;
        }
      }
    } else {
      // Plan already exists — update name and MFAPI code
      await this.prisma.schemePlan.update({
        where: { id: schemePlanId },
        data: {
          name: record.schemeName,
          mfapiSchemeCode: record.schemeCode,
        },
      });
    }

    // 6. Compute day change from pre-loaded latest NAV
    const prevNavValue = existing.latestNavMap.get(schemePlanId) ?? record.nav;
    const dayChange = record.nav - prevNavValue;
    const dayChangePct = prevNavValue > 0 ? (dayChange / prevNavValue) * 100 : 0;

    // 7. Upsert current NAV
    await this.prisma.schemePlanNav.upsert({
      where: { schemePlanId },
      update: {
        nav: new Prisma.Decimal(record.nav),
        navDate: record.navDate,
        dayChange: new Prisma.Decimal(dayChange),
        dayChangePct: new Prisma.Decimal(dayChangePct),
      },
      create: {
        schemePlanId,
        nav: new Prisma.Decimal(record.nav),
        navDate: record.navDate,
        dayChange: new Prisma.Decimal(dayChange),
        dayChangePct: new Prisma.Decimal(dayChangePct),
      },
    });

    // 8. Add NAV history row to batch (bulk inserted later)
    navHistoryBatch.push({
      schemePlanId,
      navDate: record.navDate,
      nav: new Prisma.Decimal(record.nav),
    });
  }

  /**
   * Map AMFI category to ONDC L3 category ID
   */
  private mapCategoryToOndcL3(category: string): string {
    if (CATEGORY_TO_ONDC_L3[category]) {
      return CATEGORY_TO_ONDC_L3[category];
    }

    for (const [key, value] of Object.entries(CATEGORY_TO_ONDC_L3)) {
      if (category.toLowerCase().includes(key.toLowerCase())) {
        return value;
      }
    }

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
    if (lower.includes('gold') || lower.includes('silver')) return 'L3-GOLD';
    if (lower.includes('fund of funds') || lower.includes('fof')) return 'L3-FOF_DOMESTIC';
    if (lower.includes('sector')) return 'L3-SECTORAL';
    if (lower.includes('close ended') || lower.includes('interval')) return 'L3-OTHER';

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
    const patterns = [
      /^(.+?)\s+Mutual\s+Fund$/i,
      /^(.+?)\s+Asset\s+Management$/i,
      /^(.+?)\s+AMC$/i,
    ];

    for (const pattern of patterns) {
      const match = fundHouse.match(pattern);
      if (match) return match[1];
    }

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
