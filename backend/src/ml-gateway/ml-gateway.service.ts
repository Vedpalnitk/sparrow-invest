import { Injectable, Inject, OnModuleInit, Logger } from '@nestjs/common';
import type { ClientGrpc } from '@nestjs/microservices';
import { Observable, lastValueFrom, timeout, catchError, of } from 'rxjs';
import { ConfigService } from '@nestjs/config';
import {
  ClassifyRequestDto,
  ClassifyResponseDto,
  BlendedClassifyResponseDto,
  RecommendRequestDto,
  RecommendResponseDto,
  BlendedRecommendRequestDto,
  BlendedRecommendResponseDto,
  OptimizeRequestDto,
  OptimizeResponseDto,
  RiskRequestDto,
  RiskResponseDto,
  PortfolioAnalysisRequestDto,
  PortfolioAnalysisResponseDto,
} from './dto';

interface MLServiceClient {
  ClassifyProfile(request: any): Observable<any>;
  GetRecommendations(request: any): Observable<any>;
  OptimizePortfolio(request: any): Observable<any>;
  AssessRisk(request: any): Observable<any>;
  HealthCheck(request: any): Observable<any>;
}

@Injectable()
export class MlGatewayService implements OnModuleInit {
  private readonly logger = new Logger(MlGatewayService.name);
  private mlService: MLServiceClient;
  private readonly TIMEOUT_MS = 30000; // 30 seconds
  private readonly mlServiceHttpUrl: string;

  constructor(
    @Inject('ML_SERVICE') private readonly client: ClientGrpc,
    private readonly configService: ConfigService,
  ) {
    this.mlServiceHttpUrl =
      this.configService.get<string>('mlService.httpUrl') || 'http://localhost:8000';
  }

  onModuleInit() {
    this.mlService = this.client.getService<MLServiceClient>('MLService');
    this.logger.log('ML Gateway service initialized');
  }

  /**
   * Classify a user profile into an investment persona.
   */
  async classifyProfile(request: ClassifyRequestDto): Promise<ClassifyResponseDto> {
    try {
      const grpcRequest = this.toGrpcClassifyRequest(request);

      const response = await lastValueFrom(
        this.mlService.ClassifyProfile(grpcRequest).pipe(
          timeout(this.TIMEOUT_MS),
          catchError((error) => {
            this.logger.error(`ClassifyProfile gRPC error: ${error.message}`);
            throw error;
          }),
        ),
      );

      return this.fromGrpcClassifyResponse(response);
    } catch (error) {
      this.logger.error(`ClassifyProfile failed: ${error.message}`);
      throw error;
    }
  }

  /**
   * Classify a user profile with blended persona distribution.
   * Returns weighted distribution across all personas and blended allocation.
   */
  async classifyProfileBlended(request: ClassifyRequestDto): Promise<BlendedClassifyResponseDto> {
    try {
      const httpRequest = {
        request_id: request.request_id || '',
        profile: {
          age: request.profile.age,
          goal: request.profile.goal || '',
          target_amount: request.profile.target_amount || 0,
          target_year: request.profile.target_year || 0,
          monthly_sip: request.profile.monthly_sip || 0,
          lump_sum: request.profile.lump_sum || 0,
          liquidity: request.profile.liquidity,
          risk_tolerance: request.profile.risk_tolerance,
          knowledge: request.profile.knowledge,
          volatility: request.profile.volatility,
          horizon_years: request.profile.horizon_years,
        },
      };

      const response = await fetch(`${this.mlServiceHttpUrl}/api/v1/classify/blended`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(httpRequest),
      });

      if (!response.ok) {
        const error = await response.json().catch(() => ({ detail: 'Unknown error' }));
        throw new Error(error.detail || `HTTP ${response.status}`);
      }

      const data = await response.json();
      return this.fromHttpBlendedClassifyResponse(data);
    } catch (error) {
      this.logger.error(`ClassifyProfileBlended failed: ${error.message}`);
      throw error;
    }
  }

  private fromHttpBlendedClassifyResponse(response: any): BlendedClassifyResponseDto {
    return {
      request_id: response.request_id,
      primary_persona: {
        id: response.primary_persona.id,
        name: response.primary_persona.name,
        slug: response.primary_persona.slug,
        risk_band: response.primary_persona.risk_band,
        description: response.primary_persona.description,
      },
      distribution: (response.distribution || []).map((item: any) => ({
        persona: {
          id: item.persona.id,
          name: item.persona.name,
          slug: item.persona.slug,
          risk_band: item.persona.risk_band,
          description: item.persona.description,
        },
        weight: item.weight,
        allocation: {
          equity: item.allocation.equity,
          debt: item.allocation.debt,
          hybrid: item.allocation.hybrid,
          gold: item.allocation.gold,
          international: item.allocation.international,
          liquid: item.allocation.liquid,
        },
      })),
      blended_allocation: {
        equity: response.blended_allocation.equity,
        debt: response.blended_allocation.debt,
        hybrid: response.blended_allocation.hybrid,
        gold: response.blended_allocation.gold,
        international: response.blended_allocation.international,
        liquid: response.blended_allocation.liquid,
      },
      confidence: response.confidence,
      model_version: response.model_version,
      latency_ms: response.latency_ms,
    };
  }

  /**
   * Get fund recommendations based on persona.
   */
  async getRecommendations(request: RecommendRequestDto): Promise<RecommendResponseDto> {
    try {
      const grpcRequest = this.toGrpcRecommendRequest(request);

      const response = await lastValueFrom(
        this.mlService.GetRecommendations(grpcRequest).pipe(
          timeout(this.TIMEOUT_MS),
          catchError((error) => {
            this.logger.error(`GetRecommendations gRPC error: ${error.message}`);
            throw error;
          }),
        ),
      );

      return this.fromGrpcRecommendResponse(response);
    } catch (error) {
      this.logger.error(`GetRecommendations failed: ${error.message}`);
      throw error;
    }
  }

  /**
   * Get fund recommendations based on blended allocation targets.
   * Uses HTTP instead of gRPC for this newer endpoint.
   */
  async getRecommendationsBlended(request: BlendedRecommendRequestDto): Promise<BlendedRecommendResponseDto> {
    try {
      // Convert percentages to decimals if needed (values > 1 are assumed to be percentages)
      const toDecimal = (value: number) => value > 1 ? value / 100 : value;

      const httpRequest = {
        request_id: request.request_id || '',
        blended_allocation: {
          equity: toDecimal(request.blended_allocation.equity || 0),
          debt: toDecimal(request.blended_allocation.debt || 0),
          hybrid: toDecimal(request.blended_allocation.hybrid || 0),
          gold: toDecimal(request.blended_allocation.gold || 0),
          international: toDecimal(request.blended_allocation.international || 0),
          liquid: toDecimal(request.blended_allocation.liquid || 0),
        },
        persona_distribution: request.persona_distribution || {},
        profile: request.profile,
        top_n: request.top_n || 6,
        investment_amount: request.investment_amount,
        category_filters: request.category_filters || [],
        exclude_funds: request.exclude_funds || [],
      };

      const response = await fetch(`${this.mlServiceHttpUrl}/api/v1/recommend/blended`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(httpRequest),
      });

      if (!response.ok) {
        const error = await response.json().catch(() => ({ detail: 'Unknown error' }));
        throw new Error(error.detail || `HTTP ${response.status}`);
      }

      const data = await response.json();
      return this.fromHttpBlendedRecommendResponse(data);
    } catch (error) {
      this.logger.error(`GetRecommendationsBlended failed: ${error.message}`);
      throw error;
    }
  }

  private fromHttpBlendedRecommendResponse(response: any): BlendedRecommendResponseDto {
    return {
      request_id: response.request_id,
      recommendations: (response.recommendations || []).map((r: any) => ({
        scheme_code: r.scheme_code,
        scheme_name: r.scheme_name,
        fund_house: r.fund_house,
        category: r.category,
        asset_class: r.asset_class,
        score: r.score,
        suggested_allocation: r.suggested_allocation,
        suggested_amount: r.suggested_amount,
        reasoning: r.reasoning,
        metrics: r.metrics || {},
      })),
      asset_class_breakdown: (response.asset_class_breakdown || []).map((b: any) => ({
        asset_class: b.asset_class,
        target_allocation: b.target_allocation,
        actual_allocation: b.actual_allocation,
        fund_count: b.fund_count,
        total_amount: b.total_amount,
      })),
      target_allocation: {
        equity: response.target_allocation?.equity || 0,
        debt: response.target_allocation?.debt || 0,
        hybrid: response.target_allocation?.hybrid || 0,
        gold: response.target_allocation?.gold || 0,
        international: response.target_allocation?.international || 0,
        liquid: response.target_allocation?.liquid || 0,
      },
      alignment_score: response.alignment_score,
      alignment_message: response.alignment_message,
      model_version: response.model_version,
      latency_ms: response.latency_ms,
    };
  }

  /**
   * Optimize portfolio allocation.
   */
  async optimizePortfolio(request: OptimizeRequestDto): Promise<OptimizeResponseDto> {
    try {
      const grpcRequest = this.toGrpcOptimizeRequest(request);

      const response = await lastValueFrom(
        this.mlService.OptimizePortfolio(grpcRequest).pipe(
          timeout(this.TIMEOUT_MS),
          catchError((error) => {
            this.logger.error(`OptimizePortfolio gRPC error: ${error.message}`);
            throw error;
          }),
        ),
      );

      return this.fromGrpcOptimizeResponse(response);
    } catch (error) {
      this.logger.error(`OptimizePortfolio failed: ${error.message}`);
      throw error;
    }
  }

  /**
   * Assess portfolio risk.
   */
  async assessRisk(request: RiskRequestDto): Promise<RiskResponseDto> {
    try {
      const grpcRequest = this.toGrpcRiskRequest(request);

      const response = await lastValueFrom(
        this.mlService.AssessRisk(grpcRequest).pipe(
          timeout(this.TIMEOUT_MS),
          catchError((error) => {
            this.logger.error(`AssessRisk gRPC error: ${error.message}`);
            throw error;
          }),
        ),
      );

      return this.fromGrpcRiskResponse(response);
    } catch (error) {
      this.logger.error(`AssessRisk failed: ${error.message}`);
      throw error;
    }
  }

  /**
   * Health check for ML service.
   */
  async healthCheck(): Promise<{ status: string; services: any[] }> {
    try {
      const response = await lastValueFrom(
        this.mlService.HealthCheck({}).pipe(
          timeout(5000),
          catchError((error) => {
            this.logger.error(`HealthCheck gRPC error: ${error.message}`);
            return of({ status: 'unhealthy', services: [] });
          }),
        ),
      );

      return response;
    } catch (error) {
      this.logger.error(`HealthCheck failed: ${error.message}`);
      return { status: 'unhealthy', services: [] };
    }
  }

  /**
   * Get fund universe from database (SchemePlan table).
   * This is now served directly from the backend's database instead of ML service.
   */
  async getFunds(assetClass?: string, category?: string): Promise<any> {
    try {
      // Call the backend's own ML funds endpoint
      const params = new URLSearchParams();
      if (assetClass) params.append('asset_class', assetClass);
      if (category) params.append('category', category);

      const queryString = params.toString();
      const url = `http://localhost:3501/api/v1/funds/live/ml/funds${queryString ? `?${queryString}` : ''}`;

      const response = await fetch(url);
      if (!response.ok) {
        throw new Error(`Funds endpoint returned ${response.status}`);
      }

      return response.json();
    } catch (error) {
      this.logger.error(`GetFunds failed: ${error.message}`);
      throw error;
    }
  }

  /**
   * Get fund universe statistics from database.
   */
  async getFundsStats(): Promise<any> {
    try {
      const url = `http://localhost:3501/api/v1/funds/live/ml/funds/stats`;

      const response = await fetch(url);
      if (!response.ok) {
        throw new Error(`Funds stats endpoint returned ${response.status}`);
      }

      return response.json();
    } catch (error) {
      this.logger.error(`GetFundsStats failed: ${error.message}`);
      throw error;
    }
  }

  /**
   * Analyze portfolio against target allocation and generate rebalancing roadmap.
   * Uses HTTP to call the ML service endpoint.
   */
  async analyzePortfolio(
    request: PortfolioAnalysisRequestDto,
  ): Promise<PortfolioAnalysisResponseDto> {
    try {
      const httpRequest = {
        request_id: request.request_id || '',
        holdings: request.holdings.map((h) => ({
          scheme_code: h.scheme_code,
          scheme_name: h.scheme_name,
          amount: h.amount,
          units: h.units,
          purchase_date: h.purchase_date,
          purchase_price: h.purchase_price,
          purchase_amount: h.purchase_amount,
        })),
        target_allocation: {
          equity: request.target_allocation.equity || 0,
          debt: request.target_allocation.debt || 0,
          hybrid: request.target_allocation.hybrid || 0,
          gold: request.target_allocation.gold || 0,
          international: request.target_allocation.international || 0,
          liquid: request.target_allocation.liquid || 0,
        },
        profile: request.profile,
      };

      const response = await fetch(
        `${this.mlServiceHttpUrl}/api/v1/analyze/portfolio`,
        {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify(httpRequest),
        },
      );

      if (!response.ok) {
        const error = await response
          .json()
          .catch(() => ({ detail: 'Unknown error' }));
        throw new Error(error.detail || `HTTP ${response.status}`);
      }

      const data = await response.json();
      return this.fromHttpPortfolioAnalysisResponse(data);
    } catch (error) {
      this.logger.error(`AnalyzePortfolio failed: ${error.message}`);
      throw error;
    }
  }

  private fromHttpPortfolioAnalysisResponse(
    response: any,
  ): PortfolioAnalysisResponseDto {
    return {
      request_id: response.request_id,
      current_allocation: {
        equity: response.current_allocation?.equity || 0,
        debt: response.current_allocation?.debt || 0,
        hybrid: response.current_allocation?.hybrid || 0,
        gold: response.current_allocation?.gold || 0,
        international: response.current_allocation?.international || 0,
        liquid: response.current_allocation?.liquid || 0,
      },
      target_allocation: {
        equity: response.target_allocation?.equity || 0,
        debt: response.target_allocation?.debt || 0,
        hybrid: response.target_allocation?.hybrid || 0,
        gold: response.target_allocation?.gold || 0,
        international: response.target_allocation?.international || 0,
        liquid: response.target_allocation?.liquid || 0,
      },
      allocation_gaps: response.allocation_gaps || {},
      current_metrics: {
        total_value: response.current_metrics?.total_value || 0,
        total_holdings: response.current_metrics?.total_holdings || 0,
        weighted_return_1y: response.current_metrics?.weighted_return_1y,
        weighted_return_3y: response.current_metrics?.weighted_return_3y,
        weighted_volatility: response.current_metrics?.weighted_volatility,
        weighted_sharpe: response.current_metrics?.weighted_sharpe,
        category_breakdown: response.current_metrics?.category_breakdown || {},
      },
      holdings: (response.holdings || []).map((h: any) => ({
        scheme_code: h.scheme_code,
        scheme_name: h.scheme_name,
        category: h.category,
        asset_class: h.asset_class,
        current_value: h.current_value,
        weight: h.weight,
        units: h.units,
        nav: h.nav,
        return_1y: h.return_1y,
        return_3y: h.return_3y,
        volatility: h.volatility,
        sharpe_ratio: h.sharpe_ratio,
        holding_period_days: h.holding_period_days,
        tax_status: h.tax_status,
        purchase_amount: h.purchase_amount,
        unrealized_gain: h.unrealized_gain,
      })),
      rebalancing_actions: (response.rebalancing_actions || []).map(
        (a: any) => ({
          action: a.action,
          priority: a.priority,
          scheme_code: a.scheme_code,
          scheme_name: a.scheme_name,
          category: a.category,
          asset_class: a.asset_class,
          current_value: a.current_value,
          current_weight: a.current_weight,
          current_units: a.current_units,
          target_value: a.target_value,
          target_weight: a.target_weight,
          transaction_amount: a.transaction_amount,
          transaction_units: a.transaction_units,
          tax_status: a.tax_status,
          holding_period_days: a.holding_period_days,
          estimated_gain: a.estimated_gain,
          tax_note: a.tax_note,
          reason: a.reason,
        }),
      ),
      summary: {
        is_aligned: response.summary?.is_aligned || false,
        alignment_score: response.summary?.alignment_score || 0,
        primary_issues: response.summary?.primary_issues || [],
        total_sell_amount: response.summary?.total_sell_amount || 0,
        total_buy_amount: response.summary?.total_buy_amount || 0,
        net_transaction: response.summary?.net_transaction || 0,
        tax_impact_summary: response.summary?.tax_impact_summary || '',
      },
      model_version: response.model_version,
      latency_ms: response.latency_ms,
    };
  }

  // ============= Request/Response Transformers =============

  private toGrpcClassifyRequest(dto: ClassifyRequestDto): any {
    return {
      request_id: dto.request_id || '',
      profile: {
        age: dto.profile.age,
        goal: dto.profile.goal || '',
        target_amount: dto.profile.target_amount || 0,
        target_year: dto.profile.target_year || 0,
        monthly_sip: dto.profile.monthly_sip || 0,
        lump_sum: dto.profile.lump_sum || 0,
        liquidity: dto.profile.liquidity,
        risk_tolerance: dto.profile.risk_tolerance,
        knowledge: dto.profile.knowledge,
        volatility: dto.profile.volatility,
        horizon_years: dto.profile.horizon_years,
      },
      model_version: dto.model_version || '',
    };
  }

  private fromGrpcClassifyResponse(response: any): ClassifyResponseDto {
    return {
      request_id: response.request_id,
      persona: {
        id: response.persona.id,
        name: response.persona.name,
        slug: response.persona.slug,
        risk_band: response.persona.risk_band,
        description: response.persona.description,
      },
      confidence: response.confidence,
      probabilities: response.probabilities || {},
      model_version: response.model_version,
      latency_ms: response.latency_ms,
    };
  }

  private toGrpcRecommendRequest(dto: RecommendRequestDto): any {
    return {
      request_id: dto.request_id || '',
      persona_id: dto.persona_id,
      profile: dto.profile,
      top_n: dto.top_n,
      category_filters: dto.category_filters || [],
      exclude_funds: dto.exclude_funds || [],
    };
  }

  private fromGrpcRecommendResponse(response: any): RecommendResponseDto {
    return {
      request_id: response.request_id,
      recommendations: (response.recommendations || []).map((r: any) => ({
        scheme_code: r.scheme_code,
        scheme_name: r.scheme_name,
        fund_house: r.fund_house,
        category: r.category,
        score: r.score,
        suggested_allocation: r.suggested_allocation,
        reasoning: r.reasoning,
        metrics: r.metrics || {},
      })),
      persona_alignment: response.persona_alignment,
      model_version: response.model_version,
      latency_ms: response.latency_ms,
    };
  }

  private toGrpcOptimizeRequest(dto: OptimizeRequestDto): any {
    return {
      request_id: dto.request_id || '',
      persona_id: dto.persona_id,
      profile: dto.profile,
      available_funds: dto.available_funds.map((f) => ({
        scheme_code: f.scheme_code,
        scheme_name: f.scheme_name,
        category: f.category,
        return_1y: f.return_1y || 0,
        return_3y: f.return_3y || 0,
        return_5y: f.return_5y || 0,
        volatility: f.volatility || 0,
        sharpe_ratio: f.sharpe_ratio || 0,
        expense_ratio: f.expense_ratio || 0,
      })),
      constraints: dto.constraints
        ? {
            max_equity_pct: dto.constraints.max_equity_pct,
            min_debt_pct: dto.constraints.min_debt_pct,
            max_single_fund_pct: dto.constraints.max_single_fund_pct,
            min_funds: dto.constraints.min_funds,
            max_funds: dto.constraints.max_funds,
            target_return: dto.constraints.target_return || 0,
            max_volatility: dto.constraints.max_volatility || 0,
          }
        : undefined,
    };
  }

  private fromGrpcOptimizeResponse(response: any): OptimizeResponseDto {
    return {
      request_id: response.request_id,
      allocations: (response.allocations || []).map((a: any) => ({
        scheme_code: a.scheme_code,
        scheme_name: a.scheme_name,
        category: a.category,
        weight: a.weight,
        monthly_sip: a.monthly_sip,
      })),
      expected_metrics: {
        expected_return: response.expected_metrics?.expected_return || 0,
        expected_volatility: response.expected_metrics?.expected_volatility || 0,
        sharpe_ratio: response.expected_metrics?.sharpe_ratio || 0,
        max_drawdown: response.expected_metrics?.max_drawdown,
        projected_value: response.expected_metrics?.projected_value,
      },
      model_version: response.model_version,
      latency_ms: response.latency_ms,
    };
  }

  private toGrpcRiskRequest(dto: RiskRequestDto): any {
    const mapFund = (f: any) => ({
      scheme_code: f.scheme_code,
      scheme_name: f.scheme_name,
      category: f.category,
      volatility: f.volatility || 0,
      weight: f.weight || 0,
    });

    return {
      request_id: dto.request_id || '',
      profile: dto.profile,
      current_portfolio: (dto.current_portfolio || []).map(mapFund),
      proposed_portfolio: (dto.proposed_portfolio || []).map(mapFund),
    };
  }

  private fromGrpcRiskResponse(response: any): RiskResponseDto {
    return {
      request_id: response.request_id,
      risk_level: response.risk_level,
      risk_score: response.risk_score,
      risk_factors: (response.risk_factors || []).map((f: any) => ({
        name: f.name,
        contribution: f.contribution,
        severity: f.severity,
        description: f.description,
      })),
      recommendations: response.recommendations || [],
      persona_alignment: response.persona_alignment,
      model_version: response.model_version,
      latency_ms: response.latency_ms,
    };
  }
}
