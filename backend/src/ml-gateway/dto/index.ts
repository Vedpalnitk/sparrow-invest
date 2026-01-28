export * from './classify.dto';
export * from './recommend.dto';
export * from './optimize.dto';
export * from './risk.dto';
export * from './portfolio-analysis.dto';

// Re-export specific DTOs for easier imports
export {
  AllocationBreakdownDto,
  PersonaDistributionItemDto,
  BlendedClassifyResponseDto,
} from './classify.dto';

export {
  AllocationTargetDto,
  BlendedRecommendRequestDto,
  BlendedRecommendResponseDto,
  BlendedFundRecommendationDto,
  AssetClassBreakdownDto,
} from './recommend.dto';

export {
  PortfolioHoldingDto,
  PortfolioAllocationTargetDto,
  PortfolioAnalysisRequestDto,
  PortfolioAnalysisResponseDto,
  EnrichedHoldingDto,
  RebalancingActionDto,
  CurrentMetricsDto,
  AnalysisSummaryDto,
} from './portfolio-analysis.dto';
