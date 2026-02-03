import { useState, useEffect, useCallback } from 'react';
import { useRouter } from 'next/router';
import AdvisorLayout from '@/components/layout/AdvisorLayout';
import { dbFundsApi, DatabaseFund } from '@/services/api';
import { useFATheme, getAssetClassColor, getRiskRatingInfo, ASSET_CLASS_LABELS } from '@/utils/fa';

// Asset class values from backend (lowercase)
type AssetClass = 'equity' | 'debt' | 'hybrid' | 'liquid' | 'gold' | 'international';

const assetClasses: AssetClass[] = ['equity', 'debt', 'hybrid', 'liquid'];

const FundsPage = () => {
  const { colors, isDark } = useFATheme();
  const router = useRouter();

  const [funds, setFunds] = useState<DatabaseFund[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [searchTerm, setSearchTerm] = useState('');
  const [searchResults, setSearchResults] = useState<DatabaseFund[] | null>(null);
  const [searching, setSearching] = useState(false);
  const [filterAssetClass, setFilterAssetClass] = useState<string>('all');
  const [filterRisk, setFilterRisk] = useState<string>('all');
  const [sortBy, setSortBy] = useState<'returns' | 'nav' | 'rating' | 'dayChange'>('returns');
  const [viewMode, setViewMode] = useState<'list' | 'tile'>('list');

  // Load all funds from database on mount
  useEffect(() => {
    const loadFunds = async () => {
      try {
        setLoading(true);
        setError(null);
        const data = await dbFundsApi.getAllFunds();
        setFunds(data);
      } catch (err) {
        console.error('Failed to load funds:', err);
        const message = err instanceof Error ? err.message : 'Failed to load funds';
        if (message.includes('fetch') || message.includes('network')) {
          setError('Cannot connect to server. Make sure the backend is running on port 3501.');
        } else {
          setError(message);
        }
      } finally {
        setLoading(false);
      }
    };
    loadFunds();
  }, []);

  // Client-side search filtering (since all funds are already loaded)
  const searchFunds = useCallback((query: string) => {
    if (!query.trim()) {
      setSearchResults(null);
      return;
    }

    setSearching(true);
    const lowerQuery = query.toLowerCase();
    const results = funds.filter(fund =>
      fund.schemeName.toLowerCase().includes(lowerQuery) ||
      fund.fundHouse.toLowerCase().includes(lowerQuery) ||
      fund.category.toLowerCase().includes(lowerQuery) ||
      (fund.subCategory && fund.subCategory.toLowerCase().includes(lowerQuery))
    );
    setSearchResults(results);
    setSearching(false);
  }, [funds]);

  // Debounce search input
  useEffect(() => {
    const timer = setTimeout(() => {
      if (searchTerm.length >= 2) {
        searchFunds(searchTerm);
      } else {
        setSearchResults(null);
      }
    }, 150); // Faster since it's client-side filtering
    return () => clearTimeout(timer);
  }, [searchTerm, searchFunds]);

  // Use the shared getAssetClassColor from utils with colors
  const getCategoryColor = (assetClass: string) => getAssetClassColor(assetClass, colors);

  // Use search results if available, otherwise use popular funds
  const displayFunds = searchResults !== null ? searchResults : funds;

  const filteredFunds = displayFunds
    .filter(fund => {
      const matchesAssetClass = filterAssetClass === 'all' || fund.assetClass === filterAssetClass;
      const matchesRisk = filterRisk === 'all' || fund.riskRating?.toString() === filterRisk;
      return matchesAssetClass && matchesRisk;
    })
    .sort((a, b) => {
      if (sortBy === 'returns') return (b.return1Y ?? 0) - (a.return1Y ?? 0);
      if (sortBy === 'nav') return b.currentNav - a.currentNav;
      if (sortBy === 'rating') return (b.riskRating ?? 0) - (a.riskRating ?? 0);
      if (sortBy === 'dayChange') return b.dayChangePercent - a.dayChangePercent;
      return 0;
    });

  const handleFundClick = (fund: DatabaseFund) => {
    router.push(`/advisor/fund/${fund.schemeCode}`);
  };

  return (
    <AdvisorLayout title="Fund Universe">
      <div style={{ background: colors.background, minHeight: '100%', margin: '-2rem', padding: '2rem' }}>
        {/* Header */}
        <div className="flex items-center justify-between mb-8">
          <div>
            <p className="text-sm" style={{ color: colors.textSecondary }}>
              Browse and recommend funds to your clients
            </p>
          </div>
          <div className="flex items-center gap-3">
            <span className="text-sm" style={{ color: colors.textTertiary }}>
              {filteredFunds.length} funds
            </span>
            {/* View Toggle */}
            <div className="flex rounded-lg overflow-hidden" style={{ border: `1px solid ${colors.cardBorder}` }}>
              <button
                onClick={() => setViewMode('list')}
                className="p-2 transition-all"
                style={{
                  background: viewMode === 'list' ? colors.primary : colors.cardBackground,
                  color: viewMode === 'list' ? 'white' : colors.textSecondary
                }}
                title="List View"
              >
                <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
                  <path strokeLinecap="round" strokeLinejoin="round" d="M4 6h16M4 12h16M4 18h16" />
                </svg>
              </button>
              <button
                onClick={() => setViewMode('tile')}
                className="p-2 transition-all"
                style={{
                  background: viewMode === 'tile' ? colors.primary : colors.cardBackground,
                  color: viewMode === 'tile' ? 'white' : colors.textSecondary
                }}
                title="Tile View"
              >
                <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
                  <path strokeLinecap="round" strokeLinejoin="round" d="M4 6a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2H6a2 2 0 01-2-2V6zM14 6a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2h-2a2 2 0 01-2-2V6zM4 16a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2H6a2 2 0 01-2-2v-2zM14 16a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2h-2a2 2 0 01-2-2v-2z" />
                </svg>
              </button>
            </div>
          </div>
        </div>

        {/* Asset Class Pills */}
        <div className="flex gap-2 mb-6 overflow-x-auto pb-2">
          <button
            onClick={() => setFilterAssetClass('all')}
            className="px-4 py-2 rounded-full text-sm font-medium whitespace-nowrap transition-all"
            style={{
              background: filterAssetClass === 'all'
                ? `linear-gradient(135deg, ${colors.primary} 0%, ${colors.primaryDark} 100%)`
                : colors.cardBackground,
              color: filterAssetClass === 'all' ? 'white' : colors.textSecondary,
              border: `1px solid ${filterAssetClass === 'all' ? 'transparent' : colors.cardBorder}`
            }}
          >
            All Funds
          </button>
          {assetClasses.map(assetClass => (
            <button
              key={assetClass}
              onClick={() => setFilterAssetClass(assetClass)}
              className="px-4 py-2 rounded-full text-sm font-medium whitespace-nowrap transition-all"
              style={{
                background: filterAssetClass === assetClass
                  ? `${getCategoryColor(assetClass)}15`
                  : colors.cardBackground,
                color: filterAssetClass === assetClass ? getCategoryColor(assetClass) : colors.textSecondary,
                border: `1px solid ${filterAssetClass === assetClass ? getCategoryColor(assetClass) : colors.cardBorder}`
              }}
            >
              {ASSET_CLASS_LABELS[assetClass] || assetClass}
            </button>
          ))}
        </div>

        {/* Filters Row */}
        <div
          className="p-4 rounded-xl mb-6 flex items-center gap-4"
          style={{
            background: colors.cardBackground,
            backdropFilter: 'blur(20px)',
            border: `1px solid ${colors.cardBorder}`
          }}
        >
          <div className="flex-1">
            <div className="relative">
              <svg className="w-4 h-4 absolute left-3 top-1/2 -translate-y-1/2" style={{ color: colors.textTertiary }} fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
                <path strokeLinecap="round" strokeLinejoin="round" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
              </svg>
              <input
                type="text"
                placeholder="Search funds by name or AMC..."
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
                className="w-full pl-10 pr-4 py-2 rounded-xl text-sm"
                style={{
                  background: isDark ? colors.inputBg : '#FFFFFF',
                  border: `1px solid ${colors.inputBorder}`,
                  color: colors.textPrimary
                }}
              />
              {searching && (
                <div className="absolute right-3 top-1/2 -translate-y-1/2">
                  <svg className="w-4 h-4 animate-spin" style={{ color: colors.primary }} fill="none" viewBox="0 0 24 24">
                    <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" />
                    <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z" />
                  </svg>
                </div>
              )}
            </div>
          </div>
          <select
            value={filterRisk}
            onChange={(e) => setFilterRisk(e.target.value)}
            className="px-4 py-2 rounded-xl text-sm"
            style={{
              background: isDark ? colors.inputBg : '#FFFFFF',
              border: `1px solid ${colors.inputBorder}`,
              color: colors.textPrimary
            }}
          >
            <option value="all">All Risk Levels</option>
            <option value="1">Low Risk</option>
            <option value="2">Moderately Low</option>
            <option value="3">Moderate</option>
            <option value="4">Moderately High</option>
            <option value="5">Very High Risk</option>
          </select>
          <select
            value={sortBy}
            onChange={(e) => setSortBy(e.target.value as any)}
            className="px-4 py-2 rounded-xl text-sm"
            style={{
              background: isDark ? colors.inputBg : '#FFFFFF',
              border: `1px solid ${colors.inputBorder}`,
              color: colors.textPrimary
            }}
          >
            <option value="returns">Sort by 1Y Returns</option>
            <option value="nav">Sort by NAV</option>
            <option value="dayChange">Sort by Day Change</option>
            <option value="rating">Sort by Risk Level</option>
          </select>
        </div>

        {/* Loading State */}
        {loading && (
          <div className="flex flex-col items-center justify-center py-16">
            <svg className="w-8 h-8 animate-spin mb-4" style={{ color: colors.primary }} fill="none" viewBox="0 0 24 24">
              <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" />
              <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z" />
            </svg>
            <p style={{ color: colors.textSecondary }}>Loading funds...</p>
          </div>
        )}

        {/* Error State */}
        {error && (
          <div className="text-center py-12">
            <svg className="w-12 h-12 mx-auto mb-4" style={{ color: colors.error }} fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z" />
            </svg>
            <p className="font-medium" style={{ color: colors.error }}>{error}</p>
            <button
              onClick={() => window.location.reload()}
              className="mt-4 px-4 py-2 rounded-full text-sm font-medium"
              style={{
                background: colors.chipBg,
                color: colors.primary,
                border: `1px solid ${colors.chipBorder}`
              }}
            >
              Retry
            </button>
          </div>
        )}

        {/* Funds Display */}
        {!loading && !error && (
          viewMode === 'list' ? (
            /* List View */
            <div className="space-y-3">
              {filteredFunds.map(fund => {
                const riskInfo = getRiskRatingInfo(fund.riskRating);
                return (
                  <div
                    key={fund.schemeCode}
                    className="p-4 rounded-xl transition-all hover:shadow-md cursor-pointer flex items-center gap-4"
                    style={{
                      background: isDark ? colors.pastelIndigo : colors.pastelBlue,
                      border: `1px solid ${colors.cardBorder}`,
                    }}
                    onClick={() => handleFundClick(fund)}
                  >
                    {/* Fund Info */}
                    <div className="flex-1 min-w-0">
                      <div className="flex items-center gap-2 mb-1">
                        <h3 className="font-semibold text-sm truncate" style={{ color: colors.textPrimary }}>
                          {fund.schemeName}
                        </h3>
                        {fund.fundRating && fund.fundRating > 0 && (
                          <div className="flex items-center gap-0.5 flex-shrink-0">
                            {[...Array(5)].map((_, i) => (
                              <svg
                                key={i}
                                className="w-3 h-3"
                                fill={i < fund.fundRating! ? colors.warning : 'none'}
                                stroke={colors.warning}
                                strokeWidth={1.5}
                                viewBox="0 0 24 24"
                              >
                                <path strokeLinecap="round" strokeLinejoin="round" d="M11.049 2.927c.3-.921 1.603-.921 1.902 0l1.519 4.674a1 1 0 00.95.69h4.915c.969 0 1.371 1.24.588 1.81l-3.976 2.888a1 1 0 00-.363 1.118l1.518 4.674c.3.922-.755 1.688-1.538 1.118l-3.976-2.888a1 1 0 00-1.176 0l-3.976 2.888c-.783.57-1.838-.197-1.538-1.118l1.518-4.674a1 1 0 00-.363-1.118l-3.976-2.888c-.784-.57-.38-1.81.588-1.81h4.914a1 1 0 00.951-.69l1.519-4.674z" />
                              </svg>
                            ))}
                          </div>
                        )}
                      </div>
                      <div className="flex items-center gap-2 flex-wrap">
                        <span className="text-xs" style={{ color: colors.textTertiary }}>{fund.fundHouse}</span>
                        <span style={{ color: colors.textTertiary }}>·</span>
                        <span
                          className="text-xs px-2 py-0.5 rounded-full"
                          style={{
                            background: `${getCategoryColor(fund.assetClass)}15`,
                            color: getCategoryColor(fund.assetClass),
                          }}
                        >
                          {ASSET_CLASS_LABELS[fund.assetClass] || fund.assetClass}
                        </span>
                        <span
                          className="text-xs px-2 py-0.5 rounded-full"
                          style={{
                            background: `${riskInfo.color}15`,
                            color: riskInfo.color
                          }}
                        >
                          {riskInfo.label}
                        </span>
                        {fund.expenseRatio !== undefined && fund.expenseRatio > 0 && (
                          <>
                            <span style={{ color: colors.textTertiary }}>·</span>
                            <span className="text-xs" style={{ color: colors.textTertiary }}>
                              TER: {fund.expenseRatio.toFixed(2)}%
                            </span>
                          </>
                        )}
                        {fund.aum !== undefined && fund.aum > 0 && (
                          <>
                            <span style={{ color: colors.textTertiary }}>·</span>
                            <span className="text-xs" style={{ color: colors.textTertiary }}>
                              AUM: {fund.aum >= 1000 ? `₹${(fund.aum / 1000).toFixed(0)}K Cr` : `₹${fund.aum.toFixed(0)} Cr`}
                            </span>
                          </>
                        )}
                      </div>
                    </div>

                    {/* Returns */}
                    <div className="flex items-center gap-6">
                      <div className="text-center min-w-[60px]">
                        <p className="text-xs mb-0.5" style={{ color: colors.textTertiary }}>1Y</p>
                        <p className="font-bold text-sm" style={{ color: (fund.return1Y ?? 0) >= 15 ? colors.success : colors.textPrimary }}>
                          {fund.return1Y !== undefined ? `${fund.return1Y > 0 ? '+' : ''}${fund.return1Y.toFixed(1)}%` : '-'}
                        </p>
                      </div>
                      <div className="text-center min-w-[60px]">
                        <p className="text-xs mb-0.5" style={{ color: colors.textTertiary }}>3Y</p>
                        <p className="font-bold text-sm" style={{ color: colors.textPrimary }}>
                          {fund.return3Y !== undefined ? `${fund.return3Y > 0 ? '+' : ''}${fund.return3Y.toFixed(1)}%` : '-'}
                        </p>
                      </div>
                      <div className="text-center min-w-[60px]">
                        <p className="text-xs mb-0.5" style={{ color: colors.textTertiary }}>5Y</p>
                        <p className="font-bold text-sm" style={{ color: colors.textPrimary }}>
                          {fund.return5Y !== undefined ? `${fund.return5Y > 0 ? '+' : ''}${fund.return5Y.toFixed(1)}%` : '-'}
                        </p>
                      </div>
                      <div className="text-center min-w-[60px]">
                        <p className="text-xs mb-0.5" style={{ color: colors.textTertiary }}>Day</p>
                        <p className="font-bold text-sm" style={{ color: fund.dayChangePercent >= 0 ? colors.success : colors.error }}>
                          {fund.dayChangePercent >= 0 ? '+' : ''}{fund.dayChangePercent.toFixed(2)}%
                        </p>
                      </div>
                    </div>

                    {/* Action */}
                    <button
                      className="px-4 py-2 rounded-full text-xs font-semibold transition-all hover:shadow-md flex items-center gap-1 flex-shrink-0"
                      style={{
                        background: `linear-gradient(135deg, ${colors.primary} 0%, ${colors.primaryDark} 100%)`,
                        color: 'white'
                      }}
                      onClick={(e) => {
                        e.stopPropagation();
                        handleFundClick(fund);
                      }}
                    >
                      <svg className="w-3 h-3" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
                        <path strokeLinecap="round" strokeLinejoin="round" d="M13 7l5 5m0 0l-5 5m5-5H6" />
                      </svg>
                      View
                    </button>
                  </div>
                );
              })}
            </div>
          ) : (
            /* Tile View */
            <div className="grid grid-cols-3 gap-4">
              {filteredFunds.map(fund => {
                const riskInfo = getRiskRatingInfo(fund.riskRating);
                return (
                  <div
                    key={fund.schemeCode}
                    className="p-4 rounded-2xl transition-all hover:-translate-y-1 hover:shadow-lg cursor-pointer"
                    style={{
                      background: isDark ? colors.pastelIndigo : colors.pastelPurple,
                      border: `1px solid ${colors.cardBorder}`,
                      boxShadow: `0 4px 20px ${colors.glassShadow}`
                    }}
                    onClick={() => handleFundClick(fund)}
                  >
                    {/* Tags */}
                    <div className="flex items-center gap-2 mb-3">
                      <span
                        className="text-xs px-2 py-0.5 rounded-full"
                        style={{
                          background: `${getCategoryColor(fund.assetClass)}15`,
                          color: getCategoryColor(fund.assetClass),
                        }}
                      >
                        {ASSET_CLASS_LABELS[fund.assetClass] || fund.assetClass}
                      </span>
                      <span
                        className="text-xs px-2 py-0.5 rounded-full"
                        style={{
                          background: `${riskInfo.color}15`,
                          color: riskInfo.color
                        }}
                      >
                        {riskInfo.label}
                      </span>
                    </div>

                    {/* Fund Name */}
                    <h3 className="font-semibold text-sm mb-1 line-clamp-2" style={{ color: colors.textPrimary }}>
                      {fund.schemeName}
                    </h3>
                    <div className="flex items-center gap-2 mb-3">
                      <span className="text-xs" style={{ color: colors.textTertiary }}>{fund.fundHouse}</span>
                      {fund.fundRating && fund.fundRating > 0 && (
                        <div className="flex items-center gap-0.5">
                          {[...Array(5)].map((_, i) => (
                            <svg
                              key={i}
                              className="w-3 h-3"
                              fill={i < fund.fundRating! ? colors.warning : 'none'}
                              stroke={colors.warning}
                              strokeWidth={1.5}
                              viewBox="0 0 24 24"
                            >
                              <path strokeLinecap="round" strokeLinejoin="round" d="M11.049 2.927c.3-.921 1.603-.921 1.902 0l1.519 4.674a1 1 0 00.95.69h4.915c.969 0 1.371 1.24.588 1.81l-3.976 2.888a1 1 0 00-.363 1.118l1.518 4.674c.3.922-.755 1.688-1.538 1.118l-3.976-2.888a1 1 0 00-1.176 0l-3.976 2.888c-.783.57-1.838-.197-1.538-1.118l1.518-4.674a1 1 0 00-.363-1.118l-3.976-2.888c-.784-.57-.38-1.81.588-1.81h4.914a1 1 0 00.951-.69l1.519-4.674z" />
                            </svg>
                          ))}
                        </div>
                      )}
                    </div>

                    {/* Metrics Row */}
                    {(fund.expenseRatio !== undefined || fund.aum !== undefined) && (
                      <div className="flex items-center gap-3 mb-3 text-xs" style={{ color: colors.textTertiary }}>
                        {fund.expenseRatio !== undefined && fund.expenseRatio > 0 && (
                          <span>TER: <strong style={{ color: colors.textSecondary }}>{fund.expenseRatio.toFixed(2)}%</strong></span>
                        )}
                        {fund.aum !== undefined && fund.aum > 0 && (
                          <span>AUM: <strong style={{ color: colors.textSecondary }}>
                            {fund.aum >= 1000 ? `₹${(fund.aum / 1000).toFixed(0)}K Cr` : `₹${fund.aum.toFixed(0)} Cr`}
                          </strong></span>
                        )}
                      </div>
                    )}

                    {/* Returns Grid */}
                    <div className="grid grid-cols-4 gap-2 mb-4">
                      <div className="text-center p-2 rounded-lg" style={{ background: colors.chipBg }}>
                        <p className="text-xs" style={{ color: colors.textTertiary }}>1Y</p>
                        <p className="font-bold text-sm" style={{ color: (fund.return1Y ?? 0) >= 15 ? colors.success : colors.textPrimary }}>
                          {fund.return1Y !== undefined ? `${fund.return1Y > 0 ? '+' : ''}${fund.return1Y.toFixed(1)}%` : '-'}
                        </p>
                      </div>
                      <div className="text-center p-2 rounded-lg" style={{ background: colors.chipBg }}>
                        <p className="text-xs" style={{ color: colors.textTertiary }}>3Y</p>
                        <p className="font-bold text-sm" style={{ color: colors.textPrimary }}>
                          {fund.return3Y !== undefined ? `${fund.return3Y > 0 ? '+' : ''}${fund.return3Y.toFixed(1)}%` : '-'}
                        </p>
                      </div>
                      <div className="text-center p-2 rounded-lg" style={{ background: colors.chipBg }}>
                        <p className="text-xs" style={{ color: colors.textTertiary }}>5Y</p>
                        <p className="font-bold text-sm" style={{ color: colors.textPrimary }}>
                          {fund.return5Y !== undefined ? `${fund.return5Y > 0 ? '+' : ''}${fund.return5Y.toFixed(1)}%` : '-'}
                        </p>
                      </div>
                      <div className="text-center p-2 rounded-lg" style={{ background: colors.chipBg }}>
                        <p className="text-xs" style={{ color: colors.textTertiary }}>Day</p>
                        <p className="font-bold text-sm" style={{ color: fund.dayChangePercent >= 0 ? colors.success : colors.error }}>
                          {fund.dayChangePercent >= 0 ? '+' : ''}{fund.dayChangePercent.toFixed(2)}%
                        </p>
                      </div>
                    </div>

                    {/* Action */}
                    <button
                      className="w-full py-2 rounded-full text-xs font-semibold transition-all hover:shadow-md flex items-center justify-center gap-1"
                      style={{
                        background: `linear-gradient(135deg, ${colors.primary} 0%, ${colors.primaryDark} 100%)`,
                        color: 'white'
                      }}
                      onClick={(e) => {
                        e.stopPropagation();
                        handleFundClick(fund);
                      }}
                    >
                      <svg className="w-3 h-3" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
                        <path strokeLinecap="round" strokeLinejoin="round" d="M13 7l5 5m0 0l-5 5m5-5H6" />
                      </svg>
                      View Details
                    </button>
                  </div>
                );
              })}
            </div>
          )
        )}

        {!loading && !error && filteredFunds.length === 0 && (
          <div className="text-center py-12" style={{ color: colors.textSecondary }}>
            <svg className="w-12 h-12 mx-auto mb-4 opacity-50" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.5}>
              <path strokeLinecap="round" strokeLinejoin="round" d="M19 11H5m14 0a2 2 0 012 2v6a2 2 0 01-2 2H5a2 2 0 01-2-2v-6a2 2 0 012-2m14 0V9a2 2 0 00-2-2M5 11V9a2 2 0 012-2m0 0V5a2 2 0 012-2h6a2 2 0 012 2v2M7 7h10" />
            </svg>
            <p className="font-medium">No funds found</p>
            <p className="text-sm mt-1">Try adjusting your search or filters</p>
          </div>
        )}
      </div>
    </AdvisorLayout>
  );
};

export default FundsPage;
