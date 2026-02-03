import { useState, useEffect } from 'react';
import AdvisorLayout from '@/components/layout/AdvisorLayout';
import { useFATheme, formatCurrency, formatCurrencyCompact } from '@/utils/fa';
import {
  clientsApi,
  portfolioApi,
  mlApi,
  PortfolioAnalysisResponse,
  RebalancingAction,
  EnrichedHolding,
  PortfolioAllocationTarget,
} from '@/services/api';

interface ClientOption {
  id: string;
  name: string;
  aum: number;
}

// AI Analysis types
const analysisTypes = [
  { id: 'portfolio-health', name: 'Portfolio Health Check', description: 'Comprehensive analysis of portfolio diversification, risk, and performance', icon: 'M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z' },
  { id: 'rebalance', name: 'Rebalancing Recommendations', description: 'AI-powered suggestions to optimize asset allocation with tax awareness', icon: 'M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15' },
  { id: 'risk-analysis', name: 'Risk Assessment', description: 'Deep dive into portfolio risk factors and stress testing', icon: 'M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z' },
  { id: 'tax-harvest', name: 'Tax Loss Harvesting', description: 'Identify opportunities to offset gains with strategic losses', icon: 'M9 14l6-6m-5.5.5h.01m4.99 5h.01M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16l3.5-2 3.5 2 3.5-2 3.5 2z' },
];

// Default target allocation for Moderate risk profile
const DEFAULT_TARGET_ALLOCATION: PortfolioAllocationTarget = {
  equity: 0.60,
  debt: 0.25,
  hybrid: 0.05,
  gold: 0.05,
  international: 0.05,
  liquid: 0.00,
};

const AnalysisPage = () => {
  const { colors, isDark } = useFATheme();
  const [clients, setClients] = useState<ClientOption[]>([]);
  const [selectedClient, setSelectedClient] = useState<string>('');
  const [selectedAnalysis, setSelectedAnalysis] = useState<string>('portfolio-health');
  const [isAnalyzing, setIsAnalyzing] = useState(false);
  const [analysisResult, setAnalysisResult] = useState<PortfolioAnalysisResponse | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [loadingClients, setLoadingClients] = useState(true);

  // Fetch clients on mount
  useEffect(() => {
    const fetchClients = async () => {
      try {
        setLoadingClients(true);
        const response = await clientsApi.list<ClientOption>({});
        setClients(response.data || []);
      } catch {
        // Fallback to mock data
        setClients([
          { id: '1', name: 'Rajesh Sharma', aum: 4500000 },
          { id: '2', name: 'Priya Patel', aum: 2800000 },
          { id: '3', name: 'Amit Kumar', aum: 1200000 },
        ]);
      } finally {
        setLoadingClients(false);
      }
    };
    fetchClients();
  }, []);

  const runAnalysis = async () => {
    if (!selectedClient || !selectedAnalysis) return;

    setIsAnalyzing(true);
    setError(null);
    setAnalysisResult(null);

    try {
      // Fetch client holdings
      const holdings = await portfolioApi.getClientHoldings(selectedClient);

      if (!holdings || holdings.length === 0) {
        setError('No holdings found for this client. Please add holdings first.');
        setIsAnalyzing(false);
        return;
      }

      // Transform holdings to ML service format
      const portfolioHoldings = holdings.map((h: any) => ({
        scheme_code: parseInt(h.fundSchemeCode, 10),
        scheme_name: h.fundName,
        amount: Number(h.currentValue) || Number(h.investedValue),
        units: Number(h.units),
        purchase_date: h.purchaseDate || h.createdAt?.split('T')[0],
        purchase_amount: Number(h.investedValue),
      }));

      // Call ML service for portfolio analysis
      const result = await mlApi.analyzePortfolio({
        holdings: portfolioHoldings,
        target_allocation: DEFAULT_TARGET_ALLOCATION,
        profile: {
          client_id: selectedClient,
          risk_profile: 'Moderate',
        },
      });

      setAnalysisResult(result);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Analysis failed. Please try again.');
    } finally {
      setIsAnalyzing(false);
    }
  };

  const getActionColor = (action: string) => {
    switch (action) {
      case 'SELL': return colors.error;
      case 'BUY': return colors.success;
      case 'ADD_NEW': return colors.primary;
      case 'HOLD': return colors.warning;
      default: return colors.textSecondary;
    }
  };

  const getPriorityBadge = (priority: string) => {
    const bgColors: Record<string, string> = {
      HIGH: colors.error,
      MEDIUM: colors.warning,
      LOW: colors.success,
    };
    return bgColors[priority] || colors.textSecondary;
  };

  const formatPercent = (value: number) => `${(value * 100).toFixed(1)}%`;

  return (
    <AdvisorLayout title="AI Portfolio Analysis">
      <div style={{ background: colors.background, minHeight: '100%', margin: '-2rem', padding: '2rem' }}>
        {/* Header */}
        <div className="mb-6">
          <p className="text-sm" style={{ color: colors.textSecondary }}>
            Analyze client portfolios with AI-powered insights, rebalancing recommendations, and tax optimization
          </p>
        </div>

        <div className="grid grid-cols-3 gap-6">
          {/* Left Column - Analysis Tools */}
          <div className="col-span-2 space-y-6">
            {/* Analysis Selector */}
            <div
              className="p-5 rounded-2xl"
              style={{
                background: colors.cardBackground,
                backdropFilter: 'blur(20px)',
                border: `1px solid ${colors.cardBorder}`,
                boxShadow: `0 4px 20px ${colors.glassShadow}`
              }}
            >
              <h2 className="text-sm font-semibold uppercase tracking-wider mb-4" style={{ color: colors.primary }}>
                Run Portfolio Analysis
              </h2>

              <div className="grid grid-cols-2 gap-4 mb-4">
                <div>
                  <label className="block text-xs font-medium mb-2" style={{ color: colors.textSecondary }}>Select Client</label>
                  <select
                    value={selectedClient}
                    onChange={(e) => {
                      setSelectedClient(e.target.value);
                      setAnalysisResult(null);
                    }}
                    disabled={loadingClients}
                    className="w-full px-4 py-2.5 rounded-xl text-sm"
                    style={{
                      background: isDark ? colors.inputBg : '#FFFFFF',
                      border: `1px solid ${colors.inputBorder}`,
                      color: colors.textPrimary
                    }}
                  >
                    <option value="">Choose a client...</option>
                    {clients.map(client => (
                      <option key={client.id} value={client.id}>
                        {client.name} ({formatCurrency(client.aum)})
                      </option>
                    ))}
                  </select>
                </div>
                <div>
                  <label className="block text-xs font-medium mb-2" style={{ color: colors.textSecondary }}>Analysis Type</label>
                  <select
                    value={selectedAnalysis}
                    onChange={(e) => setSelectedAnalysis(e.target.value)}
                    className="w-full px-4 py-2.5 rounded-xl text-sm"
                    style={{
                      background: isDark ? colors.inputBg : '#FFFFFF',
                      border: `1px solid ${colors.inputBorder}`,
                      color: colors.textPrimary
                    }}
                  >
                    {analysisTypes.map(type => (
                      <option key={type.id} value={type.id}>{type.name}</option>
                    ))}
                  </select>
                </div>
              </div>

              <button
                onClick={runAnalysis}
                disabled={!selectedClient || isAnalyzing}
                className="w-full py-3 rounded-full text-sm font-semibold text-white transition-all hover:shadow-lg disabled:opacity-50 disabled:cursor-not-allowed flex items-center justify-center gap-2"
                style={{
                  background: `linear-gradient(135deg, ${colors.primary} 0%, ${colors.primaryDark} 100%)`,
                  boxShadow: `0 4px 14px ${colors.glassShadow}`
                }}
              >
                {isAnalyzing ? (
                  <>
                    <svg className="w-4 h-4 animate-spin" fill="none" viewBox="0 0 24 24">
                      <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"></circle>
                      <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                    </svg>
                    Analyzing Portfolio...
                  </>
                ) : (
                  <>
                    <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
                      <path strokeLinecap="round" strokeLinejoin="round" d="M9.663 17h4.673M12 3v1m6.364 1.636l-.707.707M21 12h-1M4 12H3m3.343-5.657l-.707-.707m2.828 9.9a5 5 0 117.072 0l-.548.547A3.374 3.374 0 0014 18.469V19a2 2 0 11-4 0v-.531c0-.895-.356-1.754-.988-2.386l-.548-.547z" />
                    </svg>
                    Run AI Analysis
                  </>
                )}
              </button>

              {error && (
                <div className="mt-4 p-3 rounded-xl text-sm" style={{ background: `${colors.error}15`, color: colors.error }}>
                  {error}
                </div>
              )}
            </div>

            {/* Analysis Result */}
            {analysisResult && (
              <>
                {/* Summary Card */}
                <div
                  className="p-5 rounded-2xl"
                  style={{
                    background: colors.cardBackground,
                    backdropFilter: 'blur(20px)',
                    border: `1px solid ${colors.cardBorder}`,
                    boxShadow: `0 4px 20px ${colors.glassShadow}`
                  }}
                >
                  <div className="flex items-center justify-between mb-4">
                    <h2 className="text-sm font-semibold uppercase tracking-wider" style={{ color: colors.primary }}>
                      Portfolio Analysis Summary
                    </h2>
                    <div className="flex items-center gap-2">
                      <span className="text-xs" style={{ color: colors.textSecondary }}>Alignment Score</span>
                      <span
                        className="text-2xl font-bold"
                        style={{ color: analysisResult.summary.alignment_score >= 0.8 ? colors.success : analysisResult.summary.alignment_score >= 0.6 ? colors.warning : colors.error }}
                      >
                        {(analysisResult.summary.alignment_score * 100).toFixed(0)}%
                      </span>
                    </div>
                  </div>

                  {/* Key Metrics */}
                  <div className="grid grid-cols-4 gap-3 mb-6">
                    <div className="p-3 rounded-xl" style={{ background: colors.chipBg }}>
                      <p className="text-xs" style={{ color: colors.textSecondary }}>Total Value</p>
                      <p className="text-lg font-bold" style={{ color: colors.textPrimary }}>
                        {formatCurrency(analysisResult.current_metrics.total_value)}
                      </p>
                    </div>
                    <div className="p-3 rounded-xl" style={{ background: colors.chipBg }}>
                      <p className="text-xs" style={{ color: colors.textSecondary }}>Holdings</p>
                      <p className="text-lg font-bold" style={{ color: colors.textPrimary }}>
                        {analysisResult.current_metrics.total_holdings}
                      </p>
                    </div>
                    <div className="p-3 rounded-xl" style={{ background: colors.chipBg }}>
                      <p className="text-xs" style={{ color: colors.textSecondary }}>1Y Return</p>
                      <p className="text-lg font-bold" style={{ color: (analysisResult.current_metrics.weighted_return_1y || 0) >= 0 ? colors.success : colors.error }}>
                        {analysisResult.current_metrics.weighted_return_1y?.toFixed(1) || 'N/A'}%
                      </p>
                    </div>
                    <div className="p-3 rounded-xl" style={{ background: colors.chipBg }}>
                      <p className="text-xs" style={{ color: colors.textSecondary }}>Volatility</p>
                      <p className="text-lg font-bold" style={{ color: colors.textPrimary }}>
                        {analysisResult.current_metrics.weighted_volatility?.toFixed(1) || 'N/A'}%
                      </p>
                    </div>
                  </div>

                  {/* Issues */}
                  {analysisResult.summary.primary_issues.length > 0 && (
                    <div className="mb-4">
                      <h3 className="text-xs font-semibold uppercase tracking-wider mb-2" style={{ color: colors.textTertiary }}>
                        Issues Identified
                      </h3>
                      <div className="space-y-2">
                        {analysisResult.summary.primary_issues.map((issue, i) => (
                          <div key={i} className="flex items-start gap-2 p-2 rounded-lg" style={{ background: `${colors.warning}10` }}>
                            <svg className="w-4 h-4 flex-shrink-0 mt-0.5" style={{ color: colors.warning }} fill="none" viewBox="0 0 24 24" stroke="currentColor">
                              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z" />
                            </svg>
                            <p className="text-sm" style={{ color: colors.textPrimary }}>{issue}</p>
                          </div>
                        ))}
                      </div>
                    </div>
                  )}

                  {/* Tax Impact */}
                  {analysisResult.summary.tax_impact_summary && (
                    <div className="p-3 rounded-xl" style={{ background: `${colors.primary}10`, border: `1px solid ${colors.primary}20` }}>
                      <p className="text-xs font-medium" style={{ color: colors.primary }}>Tax Impact</p>
                      <p className="text-sm mt-1" style={{ color: colors.textPrimary }}>{analysisResult.summary.tax_impact_summary}</p>
                    </div>
                  )}
                </div>

                {/* Allocation Comparison */}
                <div
                  className="p-5 rounded-2xl"
                  style={{
                    background: colors.cardBackground,
                    backdropFilter: 'blur(20px)',
                    border: `1px solid ${colors.cardBorder}`,
                    boxShadow: `0 4px 20px ${colors.glassShadow}`
                  }}
                >
                  <h2 className="text-sm font-semibold uppercase tracking-wider mb-4" style={{ color: colors.primary }}>
                    Asset Allocation Comparison
                  </h2>
                  <div className="space-y-4">
                    {Object.keys(analysisResult.target_allocation).map((asset) => {
                      const current = (analysisResult.current_allocation as any)[asset] || 0;
                      const target = (analysisResult.target_allocation as any)[asset] || 0;
                      const gap = (analysisResult.allocation_gaps as any)[asset] || 0;
                      const isOver = gap > 0;

                      return (
                        <div key={asset}>
                          <div className="flex items-center justify-between mb-1">
                            <span className="text-sm font-medium capitalize" style={{ color: colors.textPrimary }}>{asset}</span>
                            <div className="flex items-center gap-3">
                              <span className="text-xs" style={{ color: colors.textSecondary }}>
                                Current: {formatPercent(current)}
                              </span>
                              <span className="text-xs" style={{ color: colors.textTertiary }}>→</span>
                              <span className="text-xs" style={{ color: colors.primary }}>
                                Target: {formatPercent(target)}
                              </span>
                              {gap !== 0 && (
                                <span
                                  className="text-xs px-2 py-0.5 rounded-full"
                                  style={{ background: `${isOver ? colors.error : colors.success}15`, color: isOver ? colors.error : colors.success }}
                                >
                                  {isOver ? '+' : ''}{formatPercent(gap)}
                                </span>
                              )}
                            </div>
                          </div>
                          <div className="relative h-2 rounded-full overflow-hidden" style={{ background: colors.progressBg }}>
                            <div
                              className="absolute h-full rounded-full transition-all"
                              style={{
                                width: `${Math.min(current * 100, 100)}%`,
                                background: current > target ? colors.warning : colors.primary,
                              }}
                            />
                            <div
                              className="absolute top-0 h-full w-0.5"
                              style={{
                                left: `${Math.min(target * 100, 100)}%`,
                                background: colors.textPrimary,
                              }}
                            />
                          </div>
                        </div>
                      );
                    })}
                  </div>
                </div>

                {/* Rebalancing Actions */}
                {analysisResult.rebalancing_actions.length > 0 && (
                  <div
                    className="p-5 rounded-2xl"
                    style={{
                      background: colors.cardBackground,
                      backdropFilter: 'blur(20px)',
                      border: `1px solid ${colors.cardBorder}`,
                      boxShadow: `0 4px 20px ${colors.glassShadow}`
                    }}
                  >
                    <div className="flex items-center justify-between mb-4">
                      <h2 className="text-sm font-semibold uppercase tracking-wider" style={{ color: colors.primary }}>
                        Recommended Actions
                      </h2>
                      <div className="flex items-center gap-4 text-xs" style={{ color: colors.textSecondary }}>
                        <span>Sell: {formatCurrencyCompact(analysisResult.summary.total_sell_amount)}</span>
                        <span>Buy: {formatCurrencyCompact(analysisResult.summary.total_buy_amount)}</span>
                      </div>
                    </div>
                    <div className="space-y-3">
                      {analysisResult.rebalancing_actions.map((action: RebalancingAction, i: number) => (
                        <div
                          key={i}
                          className="p-4 rounded-xl"
                          style={{
                            background: isDark ? 'rgba(147, 197, 253, 0.05)' : 'rgba(59, 130, 246, 0.03)',
                            border: `1px solid ${colors.cardBorder}`,
                          }}
                        >
                          <div className="flex items-start justify-between mb-2">
                            <div className="flex items-center gap-2">
                              <span
                                className="px-2 py-1 rounded text-xs font-bold text-white"
                                style={{ background: getActionColor(action.action) }}
                              >
                                {action.action}
                              </span>
                              <span
                                className="px-2 py-0.5 rounded text-xs"
                                style={{ background: `${getPriorityBadge(action.priority)}20`, color: getPriorityBadge(action.priority) }}
                              >
                                {action.priority}
                              </span>
                              {action.tax_status && (
                                <span
                                  className="px-2 py-0.5 rounded text-xs"
                                  style={{ background: colors.chipBg, color: colors.textSecondary }}
                                >
                                  {action.tax_status}
                                </span>
                              )}
                            </div>
                            <span
                              className="text-lg font-bold"
                              style={{ color: action.transaction_amount < 0 ? colors.error : colors.success }}
                            >
                              {action.transaction_amount < 0 ? '-' : '+'}
                              {formatCurrency(Math.abs(action.transaction_amount))}
                            </span>
                          </div>
                          <p className="font-medium text-sm" style={{ color: colors.textPrimary }}>{action.scheme_name}</p>
                          <p className="text-xs mt-1" style={{ color: colors.textSecondary }}>
                            {action.category} • {action.asset_class}
                          </p>
                          <p className="text-xs mt-2" style={{ color: colors.textTertiary }}>{action.reason}</p>
                          {action.tax_note && (
                            <p className="text-xs mt-1 italic" style={{ color: colors.warning }}>{action.tax_note}</p>
                          )}
                        </div>
                      ))}
                    </div>
                  </div>
                )}

                {/* Holdings Detail */}
                <div
                  className="p-5 rounded-2xl"
                  style={{
                    background: colors.cardBackground,
                    backdropFilter: 'blur(20px)',
                    border: `1px solid ${colors.cardBorder}`,
                    boxShadow: `0 4px 20px ${colors.glassShadow}`
                  }}
                >
                  <h2 className="text-sm font-semibold uppercase tracking-wider mb-4" style={{ color: colors.primary }}>
                    Portfolio Holdings
                  </h2>
                  <div className="overflow-x-auto">
                    <table className="w-full text-sm">
                      <thead>
                        <tr style={{ color: colors.textSecondary }}>
                          <th className="text-left py-2 font-medium">Fund</th>
                          <th className="text-right py-2 font-medium">Value</th>
                          <th className="text-right py-2 font-medium">Weight</th>
                          <th className="text-right py-2 font-medium">1Y Return</th>
                          <th className="text-right py-2 font-medium">Tax Status</th>
                        </tr>
                      </thead>
                      <tbody>
                        {analysisResult.holdings.map((holding: EnrichedHolding, i: number) => (
                          <tr key={i} style={{ borderTop: `1px solid ${colors.cardBorder}` }}>
                            <td className="py-3">
                              <p className="font-medium" style={{ color: colors.textPrimary }}>{holding.scheme_name}</p>
                              <p className="text-xs" style={{ color: colors.textTertiary }}>{holding.category}</p>
                            </td>
                            <td className="text-right py-3" style={{ color: colors.textPrimary }}>
                              {formatCurrency(holding.current_value)}
                            </td>
                            <td className="text-right py-3" style={{ color: colors.textSecondary }}>
                              {(holding.weight * 100).toFixed(1)}%
                            </td>
                            <td className="text-right py-3" style={{ color: (holding.return_1y || 0) >= 0 ? colors.success : colors.error }}>
                              {holding.return_1y?.toFixed(1) || 'N/A'}%
                            </td>
                            <td className="text-right py-3">
                              {holding.tax_status && (
                                <span
                                  className="px-2 py-0.5 rounded text-xs"
                                  style={{
                                    background: holding.tax_status === 'LTCG' ? `${colors.success}15` : `${colors.warning}15`,
                                    color: holding.tax_status === 'LTCG' ? colors.success : colors.warning,
                                  }}
                                >
                                  {holding.tax_status}
                                </span>
                              )}
                            </td>
                          </tr>
                        ))}
                      </tbody>
                    </table>
                  </div>
                </div>
              </>
            )}

            {/* Analysis Types Grid - Show when no result */}
            {!analysisResult && (
              <div>
                <h2 className="text-sm font-semibold uppercase tracking-wider mb-4" style={{ color: colors.primary }}>
                  Available Analysis Types
                </h2>
                <div className="grid grid-cols-2 gap-3">
                  {analysisTypes.map(type => (
                    <div
                      key={type.id}
                      className="p-4 rounded-xl cursor-pointer transition-all hover:-translate-y-0.5"
                      style={{
                        background: isDark
                          ? 'linear-gradient(135deg, rgba(147, 197, 253, 0.08) 0%, rgba(125, 211, 252, 0.04) 100%)'
                          : 'linear-gradient(135deg, rgba(59, 130, 246, 0.04) 0%, rgba(56, 189, 248, 0.02) 100%)',
                        border: `1px solid ${selectedAnalysis === type.id ? colors.primary : colors.cardBorder}`,
                        boxShadow: `0 2px 10px ${colors.glassShadow}`
                      }}
                      onClick={() => setSelectedAnalysis(type.id)}
                    >
                      <div className="flex items-start gap-3">
                        <div
                          className="w-10 h-10 rounded-lg flex items-center justify-center flex-shrink-0"
                          style={{ background: colors.chipBg }}
                        >
                          <svg className="w-5 h-5" style={{ color: colors.primary }} fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.5}>
                            <path strokeLinecap="round" strokeLinejoin="round" d={type.icon} />
                          </svg>
                        </div>
                        <div>
                          <h3 className="font-medium text-sm" style={{ color: colors.textPrimary }}>{type.name}</h3>
                          <p className="text-xs mt-1" style={{ color: colors.textSecondary }}>{type.description}</p>
                        </div>
                      </div>
                    </div>
                  ))}
                </div>
              </div>
            )}
          </div>

          {/* Right Column - Model Info */}
          <div>
            <div
              className="p-5 rounded-2xl sticky top-24"
              style={{
                background: colors.cardBackground,
                backdropFilter: 'blur(20px)',
                border: `1px solid ${colors.cardBorder}`,
                boxShadow: `0 4px 20px ${colors.glassShadow}`
              }}
            >
              <h2 className="text-sm font-semibold uppercase tracking-wider mb-4" style={{ color: colors.primary }}>
                AI Model Info
              </h2>
              <div className="space-y-4">
                <div className="p-3 rounded-xl" style={{ background: colors.chipBg }}>
                  <p className="text-xs font-medium" style={{ color: colors.textSecondary }}>Model Version</p>
                  <p className="text-sm font-bold" style={{ color: colors.textPrimary }}>
                    {analysisResult?.model_version || 'portfolio-analyzer-v1.0'}
                  </p>
                </div>
                {analysisResult?.latency_ms && (
                  <div className="p-3 rounded-xl" style={{ background: colors.chipBg }}>
                    <p className="text-xs font-medium" style={{ color: colors.textSecondary }}>Analysis Time</p>
                    <p className="text-sm font-bold" style={{ color: colors.textPrimary }}>
                      {analysisResult.latency_ms.toFixed(0)}ms
                    </p>
                  </div>
                )}
                <div className="p-3 rounded-xl" style={{ background: colors.chipBg }}>
                  <p className="text-xs font-medium mb-2" style={{ color: colors.textSecondary }}>Features</p>
                  <ul className="space-y-1">
                    {['Tax-aware rebalancing', 'LTCG/STCG classification', 'Priority-based actions', 'Gap analysis'].map((feature, i) => (
                      <li key={i} className="flex items-center gap-2 text-xs" style={{ color: colors.textPrimary }}>
                        <svg className="w-3 h-3" style={{ color: colors.success }} fill="currentColor" viewBox="0 0 20 20">
                          <path fillRule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clipRule="evenodd" />
                        </svg>
                        {feature}
                      </li>
                    ))}
                  </ul>
                </div>

                <div className="pt-4 border-t" style={{ borderColor: colors.cardBorder }}>
                  <p className="text-xs" style={{ color: colors.textTertiary }}>
                    The AI analysis considers your client&apos;s current holdings, target allocation based on risk profile,
                    and tax implications to provide optimal rebalancing recommendations.
                  </p>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </AdvisorLayout>
  );
};

export default AnalysisPage;
