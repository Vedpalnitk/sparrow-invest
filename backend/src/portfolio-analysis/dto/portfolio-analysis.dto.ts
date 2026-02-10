import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsString,
  IsNumber,
  IsOptional,
  IsArray,
  ValidateNested,
  IsEnum,
} from 'class-validator';
import { Type } from 'class-transformer';

/**
 * Fund health status classification
 */
export enum FundHealthStatus {
  IN_FORM = 'in_form',
  ON_TRACK = 'on_track',
  OFF_TRACK = 'off_track',
  OUT_OF_FORM = 'out_of_form',
}

/**
 * Input DTO for analyzing a holding
 */
export class AnalyzeHoldingDto {
  @ApiProperty({ description: 'Unique holding identifier' })
  @IsString()
  holdingId: string;

  @ApiProperty({ description: 'Fund scheme code (e.g., AMFI code)' })
  @IsString()
  fundSchemeCode: string;

  @ApiProperty({ description: 'Fund name' })
  @IsString()
  fundName: string;

  @ApiProperty({ description: 'Fund category (e.g., Large Cap, Mid Cap)' })
  @IsString()
  fundCategory: string;

  @ApiProperty({ description: 'Asset class (e.g., Equity, Debt, Hybrid)' })
  @IsString()
  assetClass: string;

  @ApiProperty({ description: 'Number of units held' })
  @IsNumber()
  units: number;

  @ApiProperty({ description: 'Average NAV at purchase' })
  @IsNumber()
  avgNav: number;

  @ApiProperty({ description: 'Current NAV' })
  @IsNumber()
  currentNav: number;

  @ApiProperty({ description: 'Total invested value' })
  @IsNumber()
  investedValue: number;

  @ApiProperty({ description: 'Current market value' })
  @IsNumber()
  currentValue: number;

  // Optional metrics for deeper analysis
  @ApiPropertyOptional({ description: '1-year return percentage' })
  @IsOptional()
  @IsNumber()
  fundReturn1y?: number;

  @ApiPropertyOptional({ description: '3-year return percentage' })
  @IsOptional()
  @IsNumber()
  fundReturn3y?: number;

  @ApiPropertyOptional({ description: '6-month return percentage' })
  @IsOptional()
  @IsNumber()
  fundReturn6m?: number;

  @ApiPropertyOptional({ description: '3-month return percentage' })
  @IsOptional()
  @IsNumber()
  fundReturn3m?: number;

  @ApiPropertyOptional({ description: 'Category average 1-year return' })
  @IsOptional()
  @IsNumber()
  categoryAvgReturn1y?: number;

  @ApiPropertyOptional({ description: 'Fund volatility (standard deviation)' })
  @IsOptional()
  @IsNumber()
  fundVolatility?: number;

  @ApiPropertyOptional({ description: 'Sharpe ratio' })
  @IsOptional()
  @IsNumber()
  fundSharpeRatio?: number;

  @ApiPropertyOptional({ description: 'Expense ratio percentage' })
  @IsOptional()
  @IsNumber()
  expenseRatio?: number;
}

/**
 * Request DTO for portfolio analysis
 */
export class AnalyzePortfolioDto {
  @ApiProperty({ description: 'Client identifier' })
  @IsString()
  clientId: string;

  @ApiProperty({ type: [AnalyzeHoldingDto], description: 'List of holdings to analyze' })
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => AnalyzeHoldingDto)
  holdings: AnalyzeHoldingDto[];
}

/**
 * Individual score components
 */
export class FundHealthScoreDto {
  @ApiProperty({ description: 'Returns vs category score (0-100)' })
  returnsScore: number;

  @ApiProperty({ description: 'Risk-adjusted returns score (0-100)' })
  riskScore: number;

  @ApiProperty({ description: 'Performance consistency score (0-100)' })
  consistencyScore: number;

  @ApiProperty({ description: 'Recent momentum score (0-100)' })
  momentumScore: number;

  @ApiProperty({ description: 'Overall weighted score (0-100)' })
  overallScore: number;
}

/**
 * Analysis result for a single holding
 */
export class HoldingAnalysisDto {
  @ApiProperty({ description: 'Holding identifier' })
  holdingId: string;

  @ApiProperty({ description: 'Fund scheme code' })
  fundSchemeCode: string;

  @ApiProperty({ description: 'Fund name' })
  fundName: string;

  @ApiProperty({ description: 'Fund category' })
  fundCategory: string;

  @ApiProperty({ description: 'Asset class' })
  assetClass: string;

  @ApiProperty({ enum: FundHealthStatus, description: 'Health status classification' })
  status: FundHealthStatus;

  @ApiProperty({ description: 'Human-readable status label (e.g., "In-form")' })
  statusLabel: string;

  @ApiProperty({ description: 'Status description (e.g., "Performing great")' })
  statusDescription: string;

  @ApiProperty({ description: 'Recommended action (e.g., "Continue investing")' })
  actionHint: string;

  @ApiProperty({ type: FundHealthScoreDto, description: 'Detailed scores' })
  scores: FundHealthScoreDto;

  @ApiProperty({ type: [String], description: 'Key insights about the fund' })
  insights: string[];

  @ApiProperty({ description: 'Total invested value' })
  investedValue: number;

  @ApiProperty({ description: 'Current market value' })
  currentValue: number;

  @ApiProperty({ description: 'Absolute gain/loss' })
  absoluteGain: number;

  @ApiProperty({ description: 'Gain/loss percentage' })
  absoluteGainPercent: number;

  @ApiPropertyOptional({ description: 'Rank within portfolio (1 = best)' })
  rankInPortfolio?: number;
}

/**
 * Portfolio health summary
 */
export class PortfolioHealthSummaryDto {
  @ApiProperty({ description: 'Total number of holdings' })
  totalHoldings: number;

  @ApiProperty({ description: 'Count of in-form funds' })
  inFormCount: number;

  @ApiProperty({ description: 'Count of on-track funds' })
  onTrackCount: number;

  @ApiProperty({ description: 'Count of off-track funds' })
  offTrackCount: number;

  @ApiProperty({ description: 'Count of out-of-form funds' })
  outOfFormCount: number;

  @ApiProperty({ description: 'Overall portfolio health score (0-100)' })
  portfolioHealthScore: number;

  @ApiProperty({ description: 'Health trend: improving, stable, or declining' })
  healthTrend: string;

  @ApiPropertyOptional({ description: 'Name of top performing fund' })
  topPerformer?: string;

  @ApiPropertyOptional({ description: 'Name of worst performing fund' })
  worstPerformer?: string;

  @ApiProperty({ description: 'Number of holdings requiring attention' })
  actionRequiredCount: number;
}

/**
 * Complete portfolio analysis response
 */
export class PortfolioAnalysisResponseDto {
  @ApiProperty({ description: 'Client identifier' })
  clientId: string;

  @ApiProperty({ description: 'Analysis timestamp' })
  analysisDate: string;

  @ApiProperty({ type: PortfolioHealthSummaryDto, description: 'Portfolio summary' })
  summary: PortfolioHealthSummaryDto;

  @ApiProperty({ type: [HoldingAnalysisDto], description: 'Analysis for each holding' })
  holdings: HoldingAnalysisDto[];

  @ApiProperty({ type: [String], description: 'Portfolio-level recommendations' })
  recommendations: string[];

  @ApiProperty({ description: 'Data quality: good, partial, or limited' })
  dataQuality: string;

  @ApiProperty({ description: 'Attribution text' })
  poweredBy: string;
}

/**
 * Status configuration for UI display
 */
export class StatusConfigDto {
  @ApiProperty({ enum: FundHealthStatus })
  status: FundHealthStatus;

  @ApiProperty({ description: 'Display label' })
  label: string;

  @ApiProperty({ description: 'Description text' })
  description: string;

  @ApiProperty({ description: 'Action hint text' })
  actionHint: string;

  @ApiProperty({ description: 'Icon identifier' })
  icon: string;

  @ApiProperty({ description: 'Color identifier' })
  color: string;
}
