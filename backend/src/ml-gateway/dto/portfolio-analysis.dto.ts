import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsNumber,
  IsString,
  IsOptional,
  IsArray,
  IsObject,
  ValidateNested,
  Min,
  Max,
  IsDateString,
} from 'class-validator';
import { Type } from 'class-transformer';

// ============= Request DTOs =============

export class PortfolioHoldingDto {
  @ApiProperty({ description: 'Fund scheme code', example: 120503 })
  @IsNumber()
  scheme_code: number;

  @ApiPropertyOptional({ description: 'Fund name (auto-fetched if missing)' })
  @IsOptional()
  @IsString()
  scheme_name?: string;

  @ApiPropertyOptional({ description: 'Current value in INR', example: 500000 })
  @IsOptional()
  @IsNumber()
  @Min(0)
  amount?: number;

  @ApiPropertyOptional({ description: 'Number of units held', example: 1000 })
  @IsOptional()
  @IsNumber()
  @Min(0)
  units?: number;

  @ApiPropertyOptional({
    description: 'Purchase date (ISO format)',
    example: '2024-01-15',
  })
  @IsOptional()
  @IsDateString()
  purchase_date?: string;

  @ApiPropertyOptional({ description: 'Cost basis per unit', example: 400 })
  @IsOptional()
  @IsNumber()
  @Min(0)
  purchase_price?: number;

  @ApiPropertyOptional({
    description: 'Original investment amount',
    example: 400000,
  })
  @IsOptional()
  @IsNumber()
  @Min(0)
  purchase_amount?: number;
}

export class PortfolioAllocationTargetDto {
  @ApiProperty({ description: 'Target equity allocation (0-1)', example: 0.4 })
  @IsNumber()
  @Min(0)
  @Max(1)
  equity: number = 0;

  @ApiProperty({ description: 'Target debt allocation (0-1)', example: 0.35 })
  @IsNumber()
  @Min(0)
  @Max(1)
  debt: number = 0;

  @ApiProperty({ description: 'Target hybrid allocation (0-1)', example: 0.15 })
  @IsNumber()
  @Min(0)
  @Max(1)
  hybrid: number = 0;

  @ApiProperty({ description: 'Target gold allocation (0-1)', example: 0.05 })
  @IsNumber()
  @Min(0)
  @Max(1)
  gold: number = 0;

  @ApiProperty({
    description: 'Target international allocation (0-1)',
    example: 0.05,
  })
  @IsNumber()
  @Min(0)
  @Max(1)
  international: number = 0;

  @ApiProperty({ description: 'Target liquid allocation (0-1)', example: 0 })
  @IsNumber()
  @Min(0)
  @Max(1)
  liquid: number = 0;
}

export class PortfolioAnalysisRequestDto {
  @ApiPropertyOptional({ description: 'Request ID for tracking' })
  @IsOptional()
  @IsString()
  request_id?: string;

  @ApiProperty({
    type: [PortfolioHoldingDto],
    description: 'Current portfolio holdings',
  })
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => PortfolioHoldingDto)
  holdings: PortfolioHoldingDto[];

  @ApiProperty({
    type: PortfolioAllocationTargetDto,
    description: 'Target allocation from persona classification',
  })
  @ValidateNested()
  @Type(() => PortfolioAllocationTargetDto)
  target_allocation: PortfolioAllocationTargetDto;

  @ApiProperty({ description: 'User profile data' })
  @IsObject()
  profile: Record<string, any>;
}

// ============= Response DTOs =============

export class EnrichedHoldingDto {
  @ApiProperty({ description: 'Scheme code' })
  scheme_code: number;

  @ApiProperty({ description: 'Scheme name' })
  scheme_name: string;

  @ApiProperty({ description: 'Fund category' })
  category: string;

  @ApiProperty({ description: 'Asset class' })
  asset_class: string;

  @ApiProperty({ description: 'Current value in INR' })
  current_value: number;

  @ApiProperty({ description: 'Weight in portfolio (0-1)' })
  weight: number;

  @ApiPropertyOptional({ description: 'Number of units' })
  units?: number;

  @ApiPropertyOptional({ description: 'Current NAV' })
  nav?: number;

  @ApiPropertyOptional({ description: '1-year return %' })
  return_1y?: number;

  @ApiPropertyOptional({ description: '3-year return %' })
  return_3y?: number;

  @ApiPropertyOptional({ description: 'Volatility %' })
  volatility?: number;

  @ApiPropertyOptional({ description: 'Sharpe ratio' })
  sharpe_ratio?: number;

  @ApiPropertyOptional({ description: 'Days since purchase' })
  holding_period_days?: number;

  @ApiPropertyOptional({
    description: 'Tax status based on holding period',
    enum: ['LTCG', 'STCG'],
  })
  tax_status?: 'LTCG' | 'STCG';

  @ApiPropertyOptional({ description: 'Original purchase amount' })
  purchase_amount?: number;

  @ApiPropertyOptional({ description: 'Unrealized gain/loss' })
  unrealized_gain?: number;
}

export class RebalancingActionDto {
  @ApiProperty({
    description: 'Action type',
    enum: ['SELL', 'BUY', 'HOLD', 'ADD_NEW'],
  })
  action: 'SELL' | 'BUY' | 'HOLD' | 'ADD_NEW';

  @ApiProperty({
    description: 'Action priority',
    enum: ['HIGH', 'MEDIUM', 'LOW'],
  })
  priority: 'HIGH' | 'MEDIUM' | 'LOW';

  @ApiProperty({ description: 'Scheme code' })
  scheme_code: number;

  @ApiProperty({ description: 'Scheme name' })
  scheme_name: string;

  @ApiProperty({ description: 'Fund category' })
  category: string;

  @ApiProperty({ description: 'Asset class' })
  asset_class: string;

  @ApiPropertyOptional({ description: 'Current value in INR' })
  current_value?: number;

  @ApiPropertyOptional({ description: 'Current weight in portfolio (0-1)' })
  current_weight?: number;

  @ApiPropertyOptional({ description: 'Current units held' })
  current_units?: number;

  @ApiProperty({ description: 'Target value after rebalancing' })
  target_value: number;

  @ApiProperty({ description: 'Target weight after rebalancing (0-1)' })
  target_weight: number;

  @ApiProperty({
    description: 'Amount to transact (negative for SELL)',
    example: -300000,
  })
  transaction_amount: number;

  @ApiPropertyOptional({ description: 'Units to transact' })
  transaction_units?: number;

  @ApiPropertyOptional({
    description: 'Tax status for SELL actions',
    enum: ['LTCG', 'STCG'],
  })
  tax_status?: 'LTCG' | 'STCG';

  @ApiPropertyOptional({ description: 'Days held' })
  holding_period_days?: number;

  @ApiPropertyOptional({ description: 'Estimated capital gain/loss' })
  estimated_gain?: number;

  @ApiPropertyOptional({
    description: 'Tax note explaining implications',
    example: 'LTCG: 10% tax on gains above INR 1 lakh',
  })
  tax_note?: string;

  @ApiProperty({ description: 'Reasoning for this action' })
  reason: string;
}

export class CurrentMetricsDto {
  @ApiProperty({ description: 'Total portfolio value in INR' })
  total_value: number;

  @ApiProperty({ description: 'Number of holdings' })
  total_holdings: number;

  @ApiPropertyOptional({ description: 'Weighted 1-year return %' })
  weighted_return_1y?: number;

  @ApiPropertyOptional({ description: 'Weighted 3-year return %' })
  weighted_return_3y?: number;

  @ApiPropertyOptional({ description: 'Weighted volatility %' })
  weighted_volatility?: number;

  @ApiPropertyOptional({ description: 'Weighted Sharpe ratio' })
  weighted_sharpe?: number;

  @ApiProperty({
    description: 'Breakdown by category',
    type: 'object',
    additionalProperties: {
      type: 'object',
      properties: {
        allocation: { type: 'number' },
        count: { type: 'number' },
        value: { type: 'number' },
      },
    },
  })
  category_breakdown: Record<
    string,
    { allocation: number; count: number; value: number }
  >;
}

export class AnalysisSummaryDto {
  @ApiProperty({ description: 'Whether portfolio is aligned with target' })
  is_aligned: boolean;

  @ApiProperty({ description: 'Alignment score (0-1)' })
  alignment_score: number;

  @ApiProperty({
    description: 'Primary issues identified',
    type: [String],
  })
  primary_issues: string[];

  @ApiProperty({ description: 'Total amount to sell' })
  total_sell_amount: number;

  @ApiProperty({ description: 'Total amount to buy' })
  total_buy_amount: number;

  @ApiProperty({
    description: 'Net cash flow (negative = additional investment needed)',
  })
  net_transaction: number;

  @ApiProperty({ description: 'Summary of tax implications' })
  tax_impact_summary: string;
}

export class PortfolioAnalysisResponseDto {
  @ApiPropertyOptional({ description: 'Request ID' })
  request_id?: string;

  @ApiProperty({
    type: PortfolioAllocationTargetDto,
    description: 'Current allocation by asset class',
  })
  current_allocation: PortfolioAllocationTargetDto;

  @ApiProperty({
    type: PortfolioAllocationTargetDto,
    description: 'Target allocation by asset class',
  })
  target_allocation: PortfolioAllocationTargetDto;

  @ApiProperty({
    description: 'Gap by asset class (positive = overweight)',
    type: 'object',
    additionalProperties: { type: 'number' },
  })
  allocation_gaps: Record<string, number>;

  @ApiProperty({
    type: CurrentMetricsDto,
    description: 'Current portfolio metrics',
  })
  current_metrics: CurrentMetricsDto;

  @ApiProperty({
    type: [EnrichedHoldingDto],
    description: 'Enriched holdings with current data',
  })
  holdings: EnrichedHoldingDto[];

  @ApiProperty({
    type: [RebalancingActionDto],
    description: 'Rebalancing actions to achieve target allocation',
  })
  rebalancing_actions: RebalancingActionDto[];

  @ApiProperty({
    type: AnalysisSummaryDto,
    description: 'Analysis summary',
  })
  summary: AnalysisSummaryDto;

  @ApiProperty({ description: 'Model version used' })
  model_version: string;

  @ApiProperty({ description: 'Processing time in milliseconds' })
  latency_ms: number;
}
