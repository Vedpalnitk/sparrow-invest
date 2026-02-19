import { useState, useEffect, useCallback } from 'react'
import AdvisorLayout from '@/components/layout/AdvisorLayout'
import { biApi, AumOverview, NetFlowPeriod, SipHealth, RevenueProjection, ClientConcentration } from '@/services/api'
import { useFATheme, formatCurrency } from '@/utils/fa'

type TabKey = 'overview' | 'revenue' | 'clients'

export default function BusinessPage() {
  const { colors, isDark } = useFATheme()
  const [activeTab, setActiveTab] = useState<TabKey>('overview')
  const [loading, setLoading] = useState(false)

  // Overview state
  const [aum, setAum] = useState<AumOverview | null>(null)
  const [netFlows, setNetFlows] = useState<NetFlowPeriod[]>([])
  const [sipHealth, setSipHealth] = useState<SipHealth | null>(null)

  // Revenue state
  const [revenue, setRevenue] = useState<RevenueProjection | null>(null)

  // Clients state
  const [concentration, setConcentration] = useState<ClientConcentration | null>(null)
  const [dormantClients, setDormantClients] = useState<any[]>([])

  const fetchOverview = useCallback(async () => {
    try {
      setLoading(true)
      const [aumData, flowsData, sipData] = await Promise.allSettled([
        biApi.getAumOverview(),
        biApi.getNetFlows(6),
        biApi.getSipHealth(),
      ])
      if (aumData.status === 'fulfilled') setAum(aumData.value)
      if (flowsData.status === 'fulfilled') setNetFlows(flowsData.value)
      if (sipData.status === 'fulfilled') setSipHealth(sipData.value)
    } finally { setLoading(false) }
  }, [])

  const fetchRevenue = useCallback(async () => {
    try { setLoading(true); setRevenue(await biApi.getRevenueProjection()) } catch {} finally { setLoading(false) }
  }, [])

  const fetchClients = useCallback(async () => {
    try {
      setLoading(true)
      const [concData, dormantData] = await Promise.allSettled([
        biApi.getClientConcentration(10),
        biApi.getDormantClients(),
      ])
      if (concData.status === 'fulfilled') setConcentration(concData.value)
      if (dormantData.status === 'fulfilled') setDormantClients(dormantData.value)
    } finally { setLoading(false) }
  }, [])

  useEffect(() => {
    if (activeTab === 'overview') fetchOverview()
    if (activeTab === 'revenue') fetchRevenue()
    if (activeTab === 'clients') fetchClients()
  }, [activeTab, fetchOverview, fetchRevenue, fetchClients])

  const tabs: { key: TabKey; label: string }[] = [
    { key: 'overview', label: 'AUM Overview' },
    { key: 'revenue', label: 'Revenue' },
    { key: 'clients', label: 'Client Analysis' },
  ]

  const maxFlowBar = netFlows.length > 0
    ? Math.max(...netFlows.map(f => Math.max(f.purchases, f.redemptions)), 1)
    : 1

  return (
    <AdvisorLayout title="AUM & Business Analytics">
      {/* Tabs */}
      <div className="flex gap-2 mb-6 overflow-x-auto pb-2">
        {tabs.map((tab) => (
          <button
            key={tab.key}
            onClick={() => setActiveTab(tab.key)}
            className="px-4 py-2 rounded-full text-sm font-semibold whitespace-nowrap transition-all"
            style={{
              background: activeTab === tab.key
                ? `linear-gradient(135deg, ${colors.primary} 0%, ${colors.primaryDark} 100%)`
                : colors.chipBg,
              color: activeTab === tab.key ? '#FFFFFF' : colors.textSecondary,
              border: activeTab === tab.key ? 'none' : `1px solid ${colors.chipBorder}`,
            }}
          >
            {tab.label}
          </button>
        ))}
      </div>

      {loading && (
        <div className="flex items-center justify-center py-12">
          <div className="w-6 h-6 border-2 rounded-full animate-spin" style={{ borderColor: `${colors.primary}30`, borderTopColor: colors.primary }} />
        </div>
      )}

      {/* ============= AUM OVERVIEW TAB ============= */}
      {activeTab === 'overview' && !loading && aum && (
        <div className="space-y-4">
          {/* Hero AUM Card */}
          <div className="p-6 rounded-2xl relative overflow-hidden" style={{
            background: `linear-gradient(135deg, ${colors.primary} 0%, ${colors.primaryDark} 50%, ${isDark ? colors.accent : colors.secondary} 100%)`,
            boxShadow: `0 8px 32px ${isDark ? 'rgba(0,0,0,0.4)' : `${colors.primary}30`}`
          }}>
            <div className="absolute -top-6 -right-6 w-24 h-24 rounded-full" style={{ background: 'rgba(255,255,255,0.1)' }} />
            <div className="absolute -bottom-8 -left-8 w-32 h-32 rounded-full" style={{ background: 'rgba(255,255,255,0.05)' }} />
            <div className="relative z-10">
              <p className="text-xs font-semibold uppercase tracking-wider text-white/70 mb-1">Total Assets Under Management</p>
              <p className="text-3xl font-bold text-white">{formatCurrency(aum.totalAum)}</p>
            </div>
          </div>

          {/* Asset Class Breakdown */}
          <div className="grid grid-cols-2 md:grid-cols-4 gap-3">
            {[
              { label: 'Equity', value: aum.equityAum, color: colors.primary },
              { label: 'Debt', value: aum.debtAum, color: colors.secondary },
              { label: 'Hybrid', value: aum.hybridAum, color: colors.warning },
              { label: 'Other', value: aum.otherAum, color: colors.textTertiary },
            ].map((item) => (
              <div key={item.label} className="p-4 rounded-xl" style={{
                background: `${item.color}08`,
                border: `1px solid ${isDark ? `${item.color}20` : `${item.color}15`}`,
              }}>
                <p className="text-xs font-semibold uppercase tracking-wide" style={{ color: item.color }}>{item.label}</p>
                <p className="text-lg font-bold mt-1" style={{ color: colors.textPrimary }}>{formatCurrency(item.value)}</p>
                <p className="text-xs" style={{ color: colors.textTertiary }}>
                  {aum.totalAum > 0 ? `${Math.round((item.value / aum.totalAum) * 100)}%` : '0%'}
                </p>
              </div>
            ))}
          </div>

          {/* Category Breakdown */}
          {Object.keys(aum.byCategory).length > 0 && (
            <div className="p-5 rounded-xl" style={{ background: colors.chipBg, border: `1px solid ${colors.cardBorder}` }}>
              <p className="text-xs font-semibold uppercase tracking-wide mb-3" style={{ color: colors.primary }}>AUM by Category</p>
              <div className="space-y-2">
                {Object.entries(aum.byCategory).slice(0, 10).map(([cat, val]) => {
                  const pct = aum.totalAum > 0 ? (val / aum.totalAum) * 100 : 0
                  return (
                    <div key={cat} className="flex items-center gap-3">
                      <span className="text-xs w-28 truncate" style={{ color: colors.textSecondary }}>{cat}</span>
                      <div className="flex-1 h-2 rounded-full overflow-hidden" style={{ background: `${colors.primary}15` }}>
                        <div className="h-full rounded-full" style={{ width: `${pct}%`, background: `linear-gradient(90deg, ${colors.primary} 0%, ${colors.secondary} 100%)` }} />
                      </div>
                      <span className="text-xs font-semibold w-16 text-right" style={{ color: colors.textPrimary }}>{formatCurrency(val)}</span>
                    </div>
                  )
                })}
              </div>
            </div>
          )}

          {/* Net Flows */}
          {netFlows.length > 0 && (
            <div className="p-5 rounded-xl" style={{ background: colors.chipBg, border: `1px solid ${colors.cardBorder}` }}>
              <p className="text-xs font-semibold uppercase tracking-wide mb-3" style={{ color: colors.primary }}>Net Flows (Last 6 Months)</p>
              <div className="space-y-3">
                {netFlows.map((f) => (
                  <div key={f.period}>
                    <div className="flex items-center justify-between mb-1">
                      <span className="text-xs font-medium" style={{ color: colors.textSecondary }}>{f.period}</span>
                      <span className="text-xs font-bold" style={{ color: f.net >= 0 ? colors.success : colors.error }}>
                        {f.net >= 0 ? '+' : ''}{formatCurrency(f.net)}
                      </span>
                    </div>
                    <div className="flex gap-1 h-3">
                      <div className="rounded-full" style={{ width: `${(f.purchases / maxFlowBar) * 50}%`, background: colors.success, minWidth: f.purchases > 0 ? '4px' : '0' }} />
                      <div className="rounded-full" style={{ width: `${(f.redemptions / maxFlowBar) * 50}%`, background: colors.error, minWidth: f.redemptions > 0 ? '4px' : '0' }} />
                    </div>
                  </div>
                ))}
                <div className="flex gap-4 mt-2">
                  <div className="flex items-center gap-1.5">
                    <div className="w-2.5 h-2.5 rounded-full" style={{ background: colors.success }} />
                    <span className="text-xs" style={{ color: colors.textTertiary }}>Purchases</span>
                  </div>
                  <div className="flex items-center gap-1.5">
                    <div className="w-2.5 h-2.5 rounded-full" style={{ background: colors.error }} />
                    <span className="text-xs" style={{ color: colors.textTertiary }}>Redemptions</span>
                  </div>
                </div>
              </div>
            </div>
          )}

          {/* SIP Health */}
          {sipHealth && (
            <div className="p-5 rounded-xl" style={{ background: colors.chipBg, border: `1px solid ${colors.cardBorder}` }}>
              <p className="text-xs font-semibold uppercase tracking-wide mb-3" style={{ color: colors.primary }}>SIP Health</p>
              <div className="grid grid-cols-2 md:grid-cols-3 gap-3">
                {[
                  { label: 'Active SIPs', value: sipHealth.active, color: colors.success },
                  { label: 'Paused', value: sipHealth.paused, color: colors.warning },
                  { label: 'Cancelled', value: sipHealth.cancelled, color: colors.error },
                  { label: 'Monthly Book', value: formatCurrency(sipHealth.totalMonthlyAmount), color: colors.primary },
                  { label: 'Total SIPs', value: sipHealth.total, color: colors.textSecondary },
                  { label: 'Mandate Expiring', value: sipHealth.mandateExpiringCount, color: sipHealth.mandateExpiringCount > 0 ? colors.warning : colors.success },
                ].map((item) => (
                  <div key={item.label} className="p-3 rounded-xl" style={{ background: isDark ? colors.backgroundTertiary : colors.inputBg, border: `1px solid ${colors.cardBorder}` }}>
                    <p className="text-xs" style={{ color: colors.textTertiary }}>{item.label}</p>
                    <p className="text-lg font-bold" style={{ color: item.color }}>{item.value}</p>
                  </div>
                ))}
              </div>
            </div>
          )}
        </div>
      )}

      {/* ============= REVENUE TAB ============= */}
      {activeTab === 'revenue' && !loading && revenue && (
        <div className="space-y-4">
          {/* Revenue KPIs */}
          <div className="grid grid-cols-2 md:grid-cols-4 gap-3">
            {[
              { label: 'Current AUM', value: formatCurrency(revenue.currentAum), color: colors.primary },
              { label: 'Avg Trail Rate', value: `${revenue.avgTrailRate.toFixed(2)}%`, color: colors.secondary },
              { label: 'Monthly Trail', value: formatCurrency(revenue.currentMonthlyTrail), color: colors.success },
              { label: '12M Projection', value: formatCurrency(revenue.annual12MProjection), color: colors.warning },
            ].map((card) => (
              <div key={card.label} className="p-4 rounded-xl" style={{ background: `${card.color}08`, border: `1px solid ${isDark ? `${card.color}20` : `${card.color}15`}` }}>
                <p className="text-xs font-semibold uppercase tracking-wide" style={{ color: colors.textTertiary }}>{card.label}</p>
                <p className="text-lg font-bold mt-1" style={{ color: card.color }}>{card.value}</p>
              </div>
            ))}
          </div>

          {/* 12-Month Projection Table */}
          <div className="p-5 rounded-xl" style={{ background: colors.chipBg, border: `1px solid ${colors.cardBorder}` }}>
            <p className="text-xs font-semibold uppercase tracking-wide mb-3" style={{ color: colors.primary }}>12-Month Revenue Projection</p>
            <div className="overflow-x-auto">
              <table className="w-full text-sm">
                <thead>
                  <tr>
                    <th className="text-left px-3 py-2 text-xs font-semibold uppercase tracking-wide" style={{ color: colors.primary }}>Month</th>
                    <th className="text-right px-3 py-2 text-xs font-semibold uppercase tracking-wide" style={{ color: colors.primary }}>Projected AUM</th>
                    <th className="text-right px-3 py-2 text-xs font-semibold uppercase tracking-wide" style={{ color: colors.primary }}>Projected Trail</th>
                    <th className="text-right px-3 py-2 text-xs font-semibold uppercase tracking-wide" style={{ color: colors.primary }}>Cumulative</th>
                  </tr>
                </thead>
                <tbody>
                  {revenue.projections.map((p, idx) => {
                    const cumulative = revenue.projections.slice(0, idx + 1).reduce((s, x) => s + x.projectedTrail, 0)
                    return (
                      <tr key={p.period} style={{ borderTop: `1px solid ${colors.cardBorder}` }}>
                        <td className="px-3 py-2 font-medium" style={{ color: colors.textPrimary }}>{p.period}</td>
                        <td className="px-3 py-2 text-right" style={{ color: colors.textSecondary }}>{formatCurrency(p.projectedAum)}</td>
                        <td className="px-3 py-2 text-right font-semibold" style={{ color: colors.success }}>{formatCurrency(p.projectedTrail)}</td>
                        <td className="px-3 py-2 text-right font-semibold" style={{ color: colors.primary }}>{formatCurrency(cumulative)}</td>
                      </tr>
                    )
                  })}
                </tbody>
              </table>
            </div>
          </div>

          {/* Visual Bar */}
          {revenue.projections.length > 0 && (() => {
            const maxTrail = Math.max(...revenue.projections.map(p => p.projectedTrail), 1)
            return (
              <div className="p-5 rounded-xl" style={{ background: colors.chipBg, border: `1px solid ${colors.cardBorder}` }}>
                <p className="text-xs font-semibold uppercase tracking-wide mb-3" style={{ color: colors.primary }}>Monthly Trail Trend</p>
                <div className="flex items-end gap-1.5" style={{ height: '120px' }}>
                  {revenue.projections.map((p) => (
                    <div key={p.period} className="flex-1 flex flex-col items-center gap-1">
                      <div className="w-full rounded-t" style={{
                        height: `${(p.projectedTrail / maxTrail) * 100}px`,
                        background: `linear-gradient(180deg, ${colors.primary} 0%, ${colors.secondary} 100%)`,
                        minHeight: '4px',
                      }} />
                      <span className="text-[9px]" style={{ color: colors.textTertiary }}>{p.period.split('-')[1]}</span>
                    </div>
                  ))}
                </div>
              </div>
            )
          })()}
        </div>
      )}

      {/* ============= CLIENT ANALYSIS TAB ============= */}
      {activeTab === 'clients' && !loading && (
        <div className="space-y-4">
          {/* Concentration */}
          {concentration && (
            <div>
              <div className="p-5 rounded-2xl mb-4" style={{
                background: isDark
                  ? 'linear-gradient(135deg, rgba(147, 197, 253, 0.06) 0%, rgba(191, 219, 254, 0.03) 100%)'
                  : 'linear-gradient(135deg, rgba(59, 130, 246, 0.03) 0%, rgba(96, 165, 250, 0.01) 100%)',
                border: `1px solid ${colors.cardBorder}`,
              }}>
                <div className="flex items-center justify-between">
                  <div>
                    <h3 className="text-sm font-semibold" style={{ color: colors.textPrimary }}>Client Concentration</h3>
                    <p className="text-xs" style={{ color: colors.textTertiary }}>Top {concentration.topN} clients hold <span className="font-bold" style={{ color: concentration.concentrationPercent > 60 ? colors.warning : colors.success }}>{concentration.concentrationPercent}%</span> of total AUM</p>
                  </div>
                  <div className="text-right">
                    <p className="text-xs" style={{ color: colors.textTertiary }}>Total AUM</p>
                    <p className="text-sm font-bold" style={{ color: colors.primary }}>{formatCurrency(concentration.totalAum)}</p>
                  </div>
                </div>
              </div>

              {/* Pareto Chart (bar representation) */}
              <div className="p-5 rounded-xl mb-4" style={{ background: colors.chipBg, border: `1px solid ${colors.cardBorder}` }}>
                <p className="text-xs font-semibold uppercase tracking-wide mb-3" style={{ color: colors.primary }}>AUM Distribution</p>
                <div className="space-y-2">
                  {concentration.clients.map((c) => (
                    <div key={c.id} className="flex items-center gap-3">
                      <span className="text-xs w-5 font-semibold" style={{ color: colors.textTertiary }}>#{c.rank}</span>
                      <span className="text-xs w-28 truncate" style={{ color: colors.textPrimary }}>{c.name}</span>
                      <div className="flex-1 h-3 rounded-full overflow-hidden" style={{ background: `${colors.primary}12` }}>
                        <div className="h-full rounded-full" style={{
                          width: `${c.percentOfTotal}%`,
                          background: `linear-gradient(90deg, ${colors.primary} 0%, ${colors.secondary} 100%)`,
                          minWidth: c.percentOfTotal > 0 ? '4px' : '0',
                        }} />
                      </div>
                      <span className="text-xs font-bold w-20 text-right" style={{ color: colors.primary }}>{formatCurrency(c.aum)}</span>
                      <span className="text-xs w-12 text-right" style={{ color: colors.textTertiary }}>{c.percentOfTotal}%</span>
                    </div>
                  ))}
                </div>
              </div>
            </div>
          )}

          {/* Dormant Clients */}
          <div>
            <div className="flex items-center justify-between mb-3">
              <p className="text-xs font-semibold uppercase tracking-wide" style={{ color: colors.warning }}>Dormant Clients</p>
              <span className="text-xs px-2 py-0.5 rounded" style={{ background: `${colors.warning}15`, color: colors.warning }}>
                {dormantClients.length} clients
              </span>
            </div>
            {dormantClients.length === 0 ? (
              <div className="text-center py-8 rounded-xl" style={{ background: colors.chipBg, border: `1px solid ${colors.cardBorder}` }}>
                <p className="text-sm" style={{ color: colors.textSecondary }}>No dormant clients found</p>
                <p className="text-xs mt-1" style={{ color: colors.textTertiary }}>All clients have transacted within the last 12 months</p>
              </div>
            ) : (
              <div className="space-y-2">
                {dormantClients.map((c) => (
                  <div key={c.id} className="p-3 rounded-xl flex items-center justify-between" style={{
                    background: colors.chipBg,
                    border: `1px solid ${colors.cardBorder}`,
                    borderLeft: `4px solid ${colors.warning}`,
                  }}>
                    <div>
                      <p className="text-sm font-medium" style={{ color: colors.textPrimary }}>{c.name}</p>
                      <p className="text-xs" style={{ color: colors.textTertiary }}>{c.email}</p>
                    </div>
                    <div className="text-right">
                      <p className="text-sm font-bold" style={{ color: colors.primary }}>{formatCurrency(c.aum)}</p>
                      <p className="text-xs" style={{ color: colors.warning }}>
                        {c.daysSinceLastTxn ? `${c.daysSinceLastTxn} days` : 'Never'}
                      </p>
                    </div>
                  </div>
                ))}
              </div>
            )}
          </div>
        </div>
      )}
    </AdvisorLayout>
  )
}
