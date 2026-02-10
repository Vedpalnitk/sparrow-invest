import { Injectable, HttpException, HttpStatus, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import {
  AnalyzePortfolioDto,
  AnalyzeHoldingDto,
  PortfolioAnalysisResponseDto,
  HoldingAnalysisDto,
  StatusConfigDto,
  FundHealthStatus,
} from './dto/portfolio-analysis.dto';

/**
 * Service for portfolio health analysis
 * Acts as a gateway to the Python analysis engine
 */
@Injectable()
export class PortfolioAnalysisService {
  private readonly logger = new Logger(PortfolioAnalysisService.name);
  private readonly pythonApiUrl: string;

  // In-memory cache for analysis results (consider Redis for production)
  private analysisCache: Map<string, { data: PortfolioAnalysisResponseDto; timestamp: number }> =
    new Map();
  private readonly CACHE_TTL_MS = 5 * 60 * 1000; // 5 minutes

  constructor(private configService: ConfigService) {
    this.pythonApiUrl =
      this.configService.get<string>('PYTHON_API_URL') || 'http://localhost:8001';
  }

  /**
   * Analyze a portfolio and return health classifications
   */
  async analyzePortfolio(dto: AnalyzePortfolioDto): Promise<PortfolioAnalysisResponseDto> {
    const cacheKey = this.getCacheKey(dto.clientId, dto.holdings);

    // Check cache
    const cached = this.analysisCache.get(cacheKey);
    if (cached && Date.now() - cached.timestamp < this.CACHE_TTL_MS) {
      this.logger.debug(`Returning cached analysis for client ${dto.clientId}`);
      return cached.data;
    }

    try {
      // Transform DTO to Python API format
      const pythonRequest = this.transformToPythonRequest(dto);

      // Call Python analysis API
      const response = await fetch(`${this.pythonApiUrl}/api/v1/portfolio-analysis/analyze`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(pythonRequest),
      });

      if (!response.ok) {
        const errorText = await response.text();
        this.logger.error(`Python API error: ${response.status} - ${errorText}`);
        throw new HttpException(
          `Analysis service unavailable: ${errorText}`,
          HttpStatus.SERVICE_UNAVAILABLE,
        );
      }

      const pythonResponse = await response.json();

      // Transform response to NestJS format
      const result = this.transformFromPythonResponse(pythonResponse);

      // Cache the result
      this.analysisCache.set(cacheKey, { data: result, timestamp: Date.now() });

      return result;
    } catch (error) {
      if (error instanceof HttpException) {
        throw error;
      }

      this.logger.error(`Failed to analyze portfolio: ${error.message}`);
      throw new HttpException(
        'Portfolio analysis failed. Please try again later.',
        HttpStatus.INTERNAL_SERVER_ERROR,
      );
    }
  }

  /**
   * Analyze a single holding
   */
  async analyzeHolding(dto: AnalyzeHoldingDto): Promise<HoldingAnalysisDto> {
    try {
      const pythonRequest = this.transformHoldingToPythonRequest(dto);

      const response = await fetch(
        `${this.pythonApiUrl}/api/v1/portfolio-analysis/analyze-holding`,
        {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
          },
          body: JSON.stringify(pythonRequest),
        },
      );

      if (!response.ok) {
        const errorText = await response.text();
        throw new HttpException(
          `Analysis failed: ${errorText}`,
          HttpStatus.SERVICE_UNAVAILABLE,
        );
      }

      const pythonResponse = await response.json();
      return this.transformHoldingFromPythonResponse(pythonResponse);
    } catch (error) {
      if (error instanceof HttpException) {
        throw error;
      }

      this.logger.error(`Failed to analyze holding: ${error.message}`);
      throw new HttpException(
        'Holding analysis failed',
        HttpStatus.INTERNAL_SERVER_ERROR,
      );
    }
  }

  /**
   * Get status configuration for UI display
   */
  async getStatusConfig(): Promise<StatusConfigDto[]> {
    try {
      const response = await fetch(
        `${this.pythonApiUrl}/api/v1/portfolio-analysis/status-config`,
      );

      if (!response.ok) {
        // Return hardcoded fallback
        return this.getDefaultStatusConfig();
      }

      return await response.json();
    } catch (error) {
      this.logger.warn(`Could not fetch status config from Python API, using defaults`);
      return this.getDefaultStatusConfig();
    }
  }

  /**
   * Analyze portfolio for a specific client (fetches holdings from DB)
   */
  async analyzeClientPortfolio(clientId: string, advisorId: string): Promise<PortfolioAnalysisResponseDto> {
    // This would be implemented if we want to fetch holdings directly
    // For now, the iOS app passes holdings directly
    throw new HttpException('Not implemented', HttpStatus.NOT_IMPLEMENTED);
  }

  /**
   * Clear analysis cache for a client
   */
  clearCache(clientId: string): void {
    for (const key of this.analysisCache.keys()) {
      if (key.startsWith(clientId)) {
        this.analysisCache.delete(key);
      }
    }
  }

  // ============================================
  // PRIVATE HELPER METHODS
  // ============================================

  private getCacheKey(clientId: string, holdings: AnalyzeHoldingDto[]): string {
    // Simple hash based on client ID and holding IDs
    const holdingIds = holdings.map((h) => h.holdingId).sort().join(',');
    return `${clientId}:${holdingIds}`;
  }

  private transformToPythonRequest(dto: AnalyzePortfolioDto): any {
    return {
      client_id: dto.clientId,
      holdings: dto.holdings.map((h) => this.transformHoldingToPythonRequest(h)),
    };
  }

  private transformHoldingToPythonRequest(h: AnalyzeHoldingDto): any {
    return {
      holding_id: h.holdingId,
      fund_scheme_code: h.fundSchemeCode,
      fund_name: h.fundName,
      fund_category: h.fundCategory,
      asset_class: h.assetClass,
      units: h.units,
      avg_nav: h.avgNav,
      current_nav: h.currentNav,
      invested_value: h.investedValue,
      current_value: h.currentValue,
      fund_return_1y: h.fundReturn1y ?? null,
      fund_return_3y: h.fundReturn3y ?? null,
      fund_return_6m: h.fundReturn6m ?? null,
      fund_return_3m: h.fundReturn3m ?? null,
      category_avg_return_1y: h.categoryAvgReturn1y ?? null,
      fund_volatility: h.fundVolatility ?? null,
      fund_sharpe_ratio: h.fundSharpeRatio ?? null,
      expense_ratio: h.expenseRatio ?? null,
    };
  }

  private transformFromPythonResponse(response: any): PortfolioAnalysisResponseDto {
    return {
      clientId: response.client_id,
      analysisDate: response.analysis_date,
      summary: {
        totalHoldings: response.summary.total_holdings,
        inFormCount: response.summary.in_form_count,
        onTrackCount: response.summary.on_track_count,
        offTrackCount: response.summary.off_track_count,
        outOfFormCount: response.summary.out_of_form_count,
        portfolioHealthScore: response.summary.portfolio_health_score,
        healthTrend: response.summary.health_trend,
        topPerformer: response.summary.top_performer,
        worstPerformer: response.summary.worst_performer,
        actionRequiredCount: response.summary.action_required_count,
      },
      holdings: response.holdings.map((h: any) => this.transformHoldingFromPythonResponse(h)),
      recommendations: response.recommendations,
      dataQuality: response.data_quality,
      poweredBy: response.powered_by,
    };
  }

  private transformHoldingFromPythonResponse(h: any): HoldingAnalysisDto {
    return {
      holdingId: h.holding_id,
      fundSchemeCode: h.fund_scheme_code,
      fundName: h.fund_name,
      fundCategory: h.fund_category,
      assetClass: h.asset_class,
      status: h.status as FundHealthStatus,
      statusLabel: h.status_label,
      statusDescription: h.status_description,
      actionHint: h.action_hint,
      scores: {
        returnsScore: h.scores.returns_score,
        riskScore: h.scores.risk_score,
        consistencyScore: h.scores.consistency_score,
        momentumScore: h.scores.momentum_score,
        overallScore: h.scores.overall_score,
      },
      insights: h.insights,
      investedValue: h.invested_value,
      currentValue: h.current_value,
      absoluteGain: h.absolute_gain,
      absoluteGainPercent: h.absolute_gain_percent,
      rankInPortfolio: h.rank_in_portfolio,
    };
  }

  private getDefaultStatusConfig(): StatusConfigDto[] {
    return [
      {
        status: FundHealthStatus.IN_FORM,
        label: 'In-form',
        description: 'Performing great',
        actionHint: 'Continue investing',
        icon: 'double_up',
        color: 'green',
      },
      {
        status: FundHealthStatus.ON_TRACK,
        label: 'On-track',
        description: 'Performing good',
        actionHint: 'Hold / invest more',
        icon: 'up',
        color: 'light_green',
      },
      {
        status: FundHealthStatus.OFF_TRACK,
        label: 'Off-track',
        description: "Don't invest further",
        actionHint: 'Review and monitor',
        icon: 'down',
        color: 'light_red',
      },
      {
        status: FundHealthStatus.OUT_OF_FORM,
        label: 'Out-of-form',
        description: 'Exit now',
        actionHint: 'Consider exiting',
        icon: 'double_down',
        color: 'red',
      },
    ];
  }
}
