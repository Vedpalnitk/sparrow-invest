import { Controller, Get, Post, Query, Param, ParseIntPipe } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiQuery, ApiParam } from '@nestjs/swagger';
import { Public } from '../common/decorators/public.decorator';
import { MfApiService, FundWithMetrics, MFScheme } from './mfapi.service';
import { FundSyncService } from './fund-sync.service';
import { PrismaService } from '../prisma/prisma.service';

@ApiTags('Funds (Live Data)')
@Controller('api/v1/funds/live')
export class FundsController {
  constructor(
    private readonly mfApiService: MfApiService,
    private readonly fundSyncService: FundSyncService,
    private readonly prisma: PrismaService,
  ) {}

  @Public()
  @Get('search')
  @ApiOperation({ summary: 'Search mutual funds by name (Live from MFAPI.in)' })
  @ApiQuery({ name: 'q', required: true, description: 'Search query (min 2 characters)' })
  @ApiQuery({ name: 'direct_only', required: false, type: Boolean, description: 'Filter for Direct plans only' })
  @ApiQuery({ name: 'growth_only', required: false, type: Boolean, description: 'Filter for Growth plans only' })
  async searchFunds(
    @Query('q') query: string,
    @Query('direct_only') directOnly?: string,
    @Query('growth_only') growthOnly?: string,
  ): Promise<MFScheme[]> {
    let results = await this.mfApiService.searchFunds(query);

    // Apply filters
    if (directOnly === 'true') {
      results = results.filter(fund => fund.schemeName.includes('Direct'));
    }
    if (growthOnly === 'true') {
      results = results.filter(fund => fund.schemeName.includes('Growth'));
    }

    return results.slice(0, 50); // Limit results
  }

  @Public()
  @Get('popular')
  @ApiOperation({ summary: 'Get popular mutual funds with metrics (Live from MFAPI.in)' })
  async getPopularFunds(): Promise<FundWithMetrics[]> {
    return this.mfApiService.getPopularFunds();
  }

  @Public()
  @Get('category/:category')
  @ApiOperation({ summary: 'Get funds by category with full metrics (Live from MFAPI.in + Kuvera)' })
  @ApiParam({
    name: 'category',
    description: 'Fund category: large_cap, mid_cap, small_cap, flexi_cap, elss, hybrid, debt, liquid, index, sectoral, international, gold'
  })
  @ApiQuery({ name: 'limit', required: false, type: Number, description: 'Max results (default 20)' })
  async getFundsByCategory(
    @Param('category') category: string,
    @Query('limit') limit?: string,
  ): Promise<FundWithMetrics[]> {
    return this.mfApiService.getFundsByCategory(category, limit ? parseInt(limit) : 20);
  }

  @Public()
  @Get('search-category/:category')
  @ApiOperation({ summary: 'Search funds by category name (Live from MFAPI.in)' })
  @ApiParam({ name: 'category', description: 'Fund category name (e.g., "Large Cap", "Mid Cap")' })
  @ApiQuery({ name: 'limit', required: false, type: Number, description: 'Max results (default 10)' })
  async searchByCategory(
    @Param('category') category: string,
    @Query('limit') limit?: string,
  ): Promise<MFScheme[]> {
    return this.mfApiService.searchByCategory(category, limit ? parseInt(limit) : 10);
  }

  @Public()
  @Get(':schemeCode')
  @ApiOperation({ summary: 'Get fund details with metrics (Live from MFAPI.in)' })
  @ApiParam({ name: 'schemeCode', description: 'AMFI Scheme Code' })
  async getFundDetails(
    @Param('schemeCode', ParseIntPipe) schemeCode: number,
  ): Promise<FundWithMetrics> {
    return this.mfApiService.getFundWithMetrics(schemeCode);
  }

  @Public()
  @Get('batch/details')
  @ApiOperation({ summary: 'Get multiple funds by scheme codes (Live from MFAPI.in)' })
  @ApiQuery({ name: 'codes', required: true, description: 'Comma-separated scheme codes' })
  async getBatchDetails(
    @Query('codes') codes: string,
  ): Promise<FundWithMetrics[]> {
    const schemeCodes = codes.split(',').map(c => parseInt(c.trim())).filter(c => !isNaN(c));

    if (schemeCodes.length === 0) {
      return [];
    }

    if (schemeCodes.length > 20) {
      throw new Error('Maximum 20 funds per request');
    }

    return this.mfApiService.getMultipleFunds(schemeCodes);
  }

  // ============= Sync & Database Endpoints =============

  @Public()
  @Post('sync/popular')
  @ApiOperation({ summary: 'Sync popular funds to database (ONDC schema)' })
  async syncPopularFunds() {
    return this.fundSyncService.syncPopularFunds();
  }

  @Public()
  @Post('sync/category/:category')
  @ApiOperation({ summary: 'Sync funds by category to database' })
  @ApiParam({ name: 'category', description: 'Category: large_cap, mid_cap, small_cap, flexi_cap, elss, hybrid, debt, liquid, index' })
  @ApiQuery({ name: 'limit', required: false, type: Number, description: 'Max funds to sync (default 30)' })
  async syncByCategory(
    @Param('category') category: string,
    @Query('limit') limit?: string,
  ) {
    return this.fundSyncService.syncByCategory(category, limit ? parseInt(limit) : 30);
  }

  @Public()
  @Post('sync/fund/:schemeCode')
  @ApiOperation({ summary: 'Sync single fund with full NAV history' })
  @ApiParam({ name: 'schemeCode', description: 'AMFI Scheme Code' })
  async syncFundWithHistory(
    @Param('schemeCode', ParseIntPipe) schemeCode: number,
  ) {
    await this.fundSyncService.syncFundWithHistory(schemeCode);
    return { success: true, schemeCode };
  }

  @Public()
  @Post('sync/nav-update')
  @ApiOperation({ summary: 'Update NAV for all synced funds' })
  async updateAllNavs() {
    return this.fundSyncService.updateAllNavs();
  }

  @Public()
  @Get('sync/status')
  @ApiOperation({ summary: 'Get sync status and database counts' })
  async getSyncStatus() {
    return this.fundSyncService.getSyncStatus();
  }

  // ============= Database Endpoints (ONDC Schema) =============

  @Public()
  @Get('db/funds')
  @ApiOperation({ summary: 'Get all synced funds from database with metrics' })
  @ApiQuery({ name: 'category', required: false, description: 'Filter by category ID (e.g., L3-LARGE_CAP)' })
  @ApiQuery({ name: 'provider', required: false, description: 'Filter by provider/fund house slug' })
  @ApiQuery({ name: 'plan', required: false, description: 'Filter by plan type: direct, regular' })
  @ApiQuery({ name: 'limit', required: false, type: Number, description: 'Max results (default 50)' })
  @ApiQuery({ name: 'offset', required: false, type: Number, description: 'Offset for pagination' })
  async getDbFunds(
    @Query('category') category?: string,
    @Query('provider') provider?: string,
    @Query('plan') plan?: string,
    @Query('limit') limit?: string,
    @Query('offset') offset?: string,
  ) {
    const where: any = {};

    if (category) {
      where.scheme = { categoryId: category };
    }
    if (provider) {
      where.scheme = { ...where.scheme, providerId: provider };
    }
    if (plan) {
      where.plan = plan;
    }

    const schemePlans = await this.prisma.schemePlan.findMany({
      where,
      include: {
        scheme: {
          include: {
            provider: true,
            category: {
              include: {
                parent: true,
              },
            },
          },
        },
        nav: true,
        metrics: true,
      },
      take: limit ? parseInt(limit) : 50,
      skip: offset ? parseInt(offset) : 0,
      orderBy: { name: 'asc' },
    });

    return schemePlans.map(plan => ({
      id: plan.id,
      schemeCode: plan.mfapiSchemeCode,
      name: plan.name,
      isin: plan.isin,
      planType: plan.plan,
      optionType: plan.option,
      fundHouse: plan.scheme.provider.name,
      fundHouseId: plan.scheme.providerId,
      category: plan.scheme.category.name,
      categoryId: plan.scheme.categoryId,
      assetClass: plan.scheme.category.parent?.name,
      currentNav: plan.nav?.nav ? Number(plan.nav.nav) : null,
      dayChange: plan.nav?.dayChange ? Number(plan.nav.dayChange) : null,
      dayChangePercent: plan.nav?.dayChangePct ? Number(plan.nav.dayChangePct) : null,
      navDate: plan.nav?.navDate,
      return1Y: plan.metrics?.return1y ? Number(plan.metrics.return1y) : null,
      return3Y: plan.metrics?.return3y ? Number(plan.metrics.return3y) : null,
      return5Y: plan.metrics?.return5y ? Number(plan.metrics.return5y) : null,
      riskRating: plan.metrics?.riskRating,
      crisilRating: plan.metrics?.crisilRating,
      fundRating: plan.metrics?.fundRating,
      expenseRatio: plan.metrics?.expenseRatio ? Number(plan.metrics.expenseRatio) : null,
      aum: plan.metrics?.aum ? Number(plan.metrics.aum) : null,
      fundManager: plan.scheme.fundManager,
    }));
  }

  @Public()
  @Get('db/fund/:id')
  @ApiOperation({ summary: 'Get single fund details from database' })
  @ApiParam({ name: 'id', description: 'Scheme Plan ID or MFAPI scheme code' })
  async getDbFundDetails(@Param('id') id: string) {
    // Try to find by ID first, then by scheme code
    let schemePlan = await this.prisma.schemePlan.findUnique({
      where: { id },
      include: {
        scheme: {
          include: {
            provider: true,
            category: {
              include: {
                parent: {
                  include: { parent: true },
                },
              },
            },
          },
        },
        nav: true,
        metrics: true,
        navHistory: {
          orderBy: { navDate: 'desc' },
          take: 365, // Last 1 year
        },
      },
    });

    if (!schemePlan) {
      // Try by scheme code
      const schemeCode = parseInt(id);
      if (!isNaN(schemeCode)) {
        schemePlan = await this.prisma.schemePlan.findFirst({
          where: { mfapiSchemeCode: schemeCode },
          include: {
            scheme: {
              include: {
                provider: true,
                category: {
                  include: {
                    parent: {
                      include: { parent: true },
                    },
                  },
                },
              },
            },
            nav: true,
            metrics: true,
            navHistory: {
              orderBy: { navDate: 'desc' },
              take: 365,
            },
          },
        });
      }
    }

    if (!schemePlan) {
      return null;
    }

    return {
      id: schemePlan.id,
      schemeCode: schemePlan.mfapiSchemeCode,
      name: schemePlan.name,
      isin: schemePlan.isin,
      planType: schemePlan.plan,
      optionType: schemePlan.option,
      scheme: {
        id: schemePlan.scheme.id,
        name: schemePlan.scheme.name,
        fundManager: schemePlan.scheme.fundManager,
        exitLoad: schemePlan.scheme.exitLoad,
        benchmark: schemePlan.scheme.benchmark,
      },
      provider: {
        id: schemePlan.scheme.provider.id,
        name: schemePlan.scheme.provider.name,
        shortName: schemePlan.scheme.provider.shortName,
      },
      category: {
        id: schemePlan.scheme.category.id,
        name: schemePlan.scheme.category.name,
        parent: schemePlan.scheme.category.parent?.name,
        l1: schemePlan.scheme.category.parent?.parent?.name,
      },
      nav: schemePlan.nav ? {
        value: Number(schemePlan.nav.nav),
        date: schemePlan.nav.navDate,
        dayChange: Number(schemePlan.nav.dayChange),
        dayChangePercent: Number(schemePlan.nav.dayChangePct),
      } : null,
      metrics: schemePlan.metrics ? {
        return1Y: schemePlan.metrics.return1y ? Number(schemePlan.metrics.return1y) : null,
        return3Y: schemePlan.metrics.return3y ? Number(schemePlan.metrics.return3y) : null,
        return5Y: schemePlan.metrics.return5y ? Number(schemePlan.metrics.return5y) : null,
        riskRating: schemePlan.metrics.riskRating,
        crisilRating: schemePlan.metrics.crisilRating,
        fundRating: schemePlan.metrics.fundRating,
        volatility: schemePlan.metrics.volatility ? Number(schemePlan.metrics.volatility) : null,
        expenseRatio: schemePlan.metrics.expenseRatio ? Number(schemePlan.metrics.expenseRatio) : null,
        aum: schemePlan.metrics.aum ? Number(schemePlan.metrics.aum) : null,
      } : null,
      navHistory: schemePlan.navHistory.map(h => ({
        date: h.navDate,
        nav: Number(h.nav),
      })),
    };
  }

  @Public()
  @Get('db/providers')
  @ApiOperation({ summary: 'Get all fund providers (AMCs) from database' })
  async getDbProviders() {
    const providers = await this.prisma.provider.findMany({
      include: {
        _count: {
          select: { schemes: true },
        },
      },
      orderBy: { name: 'asc' },
    });

    return providers.map(p => ({
      id: p.id,
      name: p.name,
      shortName: p.shortName,
      schemeCount: p._count.schemes,
    }));
  }

  @Public()
  @Get('db/categories')
  @ApiOperation({ summary: 'Get all ONDC categories from database' })
  async getDbCategories() {
    const categories = await this.prisma.category.findMany({
      include: {
        parent: true,
        _count: {
          select: { schemes: true },
        },
      },
      orderBy: [{ level: 'asc' }, { name: 'asc' }],
    });

    return categories.map(c => ({
      id: c.id,
      code: c.code,
      name: c.name,
      level: c.level,
      parentId: c.parentId,
      parentName: c.parent?.name,
      schemeCount: c._count.schemes,
    }));
  }

  // ============= ML Service Compatible Endpoints =============

  @Public()
  @Get('ml/funds')
  @ApiOperation({ summary: 'Get all synced funds in ML-compatible format (for ML Service)' })
  @ApiQuery({ name: 'asset_class', required: false, description: 'Filter by asset class (equity, debt, hybrid, gold, international, liquid)' })
  @ApiQuery({ name: 'category', required: false, description: 'Filter by fund category' })
  async getMlFunds(
    @Query('asset_class') assetClass?: string,
    @Query('category') category?: string,
  ) {
    const where: any = {
      plan: 'direct',
      option: 'growth',
      status: 'active',
    };

    if (category) {
      where.scheme = { category: { name: { contains: category, mode: 'insensitive' } } };
    }

    const schemePlans = await this.prisma.schemePlan.findMany({
      where,
      include: {
        scheme: {
          include: {
            provider: true,
            category: {
              include: {
                parent: true,
              },
            },
          },
        },
        nav: true,
        metrics: true,
      },
      orderBy: { name: 'asc' },
    });

    // Map to ML-compatible format
    let funds = schemePlans.map(plan => {
      // Determine asset class from category hierarchy
      const categoryName = plan.scheme.category.name.toLowerCase();
      const parentName = plan.scheme.category.parent?.name?.toLowerCase() || '';

      let fundAssetClass = 'equity'; // default
      if (categoryName.includes('liquid') || categoryName.includes('overnight') || categoryName.includes('money market')) {
        fundAssetClass = 'liquid';
      } else if (categoryName.includes('gilt') || categoryName.includes('bond') || categoryName.includes('debt') ||
                 categoryName.includes('duration') || parentName.includes('debt')) {
        fundAssetClass = 'debt';
      } else if (categoryName.includes('hybrid') || categoryName.includes('balanced') || categoryName.includes('arbitrage') ||
                 categoryName.includes('multi asset') || parentName.includes('hybrid')) {
        fundAssetClass = 'hybrid';
      } else if (categoryName.includes('gold') || categoryName.includes('silver')) {
        fundAssetClass = 'gold';
      } else if (categoryName.includes('international') || categoryName.includes('global') || categoryName.includes('overseas')) {
        fundAssetClass = 'international';
      }

      return {
        scheme_code: plan.mfapiSchemeCode || 0,
        scheme_name: plan.name,
        fund_house: plan.scheme.provider.name,
        category: plan.scheme.category.name,
        asset_class: fundAssetClass,
        return_1y: plan.metrics?.return1y ? Number(plan.metrics.return1y) : 0,
        return_3y: plan.metrics?.return3y ? Number(plan.metrics.return3y) : 0,
        return_5y: plan.metrics?.return5y ? Number(plan.metrics.return5y) : 0,
        volatility: plan.metrics?.volatility ? Number(plan.metrics.volatility) : 15,
        sharpe_ratio: plan.metrics?.sharpeRatio ? Number(plan.metrics.sharpeRatio) : 0.8,
        expense_ratio: plan.metrics?.expenseRatio ? Number(plan.metrics.expenseRatio) : 0.5,
        nav: plan.nav?.nav ? Number(plan.nav.nav) : 0,
        last_updated: plan.nav?.updatedAt || plan.updatedAt,
      };
    });

    // Filter by asset class if specified
    if (assetClass) {
      funds = funds.filter(f => f.asset_class === assetClass.toLowerCase());
    }

    // Get unique categories and asset classes for filters
    const categories = [...new Set(funds.map(f => f.category))].sort();
    const assetClasses = [...new Set(funds.map(f => f.asset_class))].sort();

    return {
      funds,
      total: funds.length,
      filters: {
        categories,
        asset_classes: assetClasses,
      },
    };
  }

  @Public()
  @Get('ml/funds/stats')
  @ApiOperation({ summary: 'Get fund statistics in ML-compatible format' })
  async getMlFundsStats() {
    const result = await this.getMlFunds();
    const funds = result.funds;

    // Calculate stats
    const byAssetClass: Record<string, number> = {};
    const byCategory: Record<string, number> = {};
    let totalReturn1y = 0;
    let totalReturn3y = 0;
    let totalExpense = 0;
    let countWithReturn1y = 0;
    let countWithReturn3y = 0;
    let countWithExpense = 0;

    for (const fund of funds) {
      // Count by asset class
      byAssetClass[fund.asset_class] = (byAssetClass[fund.asset_class] || 0) + 1;

      // Count by category
      byCategory[fund.category] = (byCategory[fund.category] || 0) + 1;

      // Sum for averages
      if (fund.return_1y) {
        totalReturn1y += fund.return_1y;
        countWithReturn1y++;
      }
      if (fund.return_3y) {
        totalReturn3y += fund.return_3y;
        countWithReturn3y++;
      }
      if (fund.expense_ratio) {
        totalExpense += fund.expense_ratio;
        countWithExpense++;
      }
    }

    return {
      total_funds: funds.length,
      by_asset_class: byAssetClass,
      by_category: byCategory,
      averages: {
        return_1y: countWithReturn1y > 0 ? totalReturn1y / countWithReturn1y : 0,
        return_3y: countWithReturn3y > 0 ? totalReturn3y / countWithReturn3y : 0,
        expense_ratio: countWithExpense > 0 ? totalExpense / countWithExpense : 0,
      },
    };
  }
}
