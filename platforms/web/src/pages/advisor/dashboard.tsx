import Link from 'next/link';
import AdvisorLayout from '@/components/layout/AdvisorLayout';
import { useFATheme, formatCurrency, getRiskColor, getStageColor } from '@/utils/fa';
import { FACard, FATintedCard, FAChip, FAIconContainer } from '@/components/advisor/shared';

// Mock data for advisor dashboard
const mockClients = [
  { id: '1', name: 'Rajesh Sharma', aum: 4500000, returns: 18.5, riskProfile: 'Moderate', lastActive: '2 hours ago' },
  { id: '2', name: 'Priya Patel', aum: 2800000, returns: 22.3, riskProfile: 'Aggressive', lastActive: '1 day ago' },
  { id: '3', name: 'Amit Kumar', aum: 1200000, returns: 12.8, riskProfile: 'Conservative', lastActive: '3 days ago' },
  { id: '4', name: 'Sneha Gupta', aum: 8900000, returns: 15.6, riskProfile: 'Moderate', lastActive: '5 hours ago' },
  { id: '5', name: 'Vikram Singh', aum: 3400000, returns: 20.1, riskProfile: 'Aggressive', lastActive: '1 hour ago' },
];

const mockProspects = [
  { id: '1', name: 'Ananya Reddy', potentialAum: 5000000, status: 'Proposal Sent', stage: 'Negotiation' },
  { id: '2', name: 'Karthik Menon', potentialAum: 2500000, status: 'Profile Complete', stage: 'Analysis' },
  { id: '3', name: 'Deepa Nair', potentialAum: 7500000, status: 'Initial Contact', stage: 'Discovery' },
];

const mockPendingActions = [
  { id: '1', type: 'SIP', client: 'Rajesh Sharma', action: 'SIP due tomorrow', amount: 25000, urgent: true },
  { id: '2', type: 'Rebalance', client: 'Priya Patel', action: 'Portfolio drift > 5%', amount: null, urgent: true },
  { id: '3', type: 'Review', client: 'Amit Kumar', action: 'Quarterly review due', amount: null, urgent: false },
  { id: '4', type: 'KYC', client: 'Sneha Gupta', action: 'KYC renewal pending', amount: null, urgent: false },
];


// Navigation items for FA portal with gradient styling
const advisorNavItems = [
  { label: 'Clients', href: '/advisor/clients', icon: 'M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z', description: 'Manage client portfolios' },
  { label: 'Prospects', href: '/advisor/prospects', icon: 'M18 9v3m0 0v3m0-3h3m-3 0h-3m-2-5a4 4 0 11-8 0 4 4 0 018 0zM3 20a6 6 0 0112 0v1H3v-1z', description: 'Lead pipeline' },
  { label: 'Transactions', href: '/advisor/transactions', icon: 'M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1M21 12a9 9 0 11-18 0 9 9 0 0118 0z', description: 'Buy/sell funds' },
  { label: 'AI Analysis', href: '/advisor/analysis', icon: 'M9.663 17h4.673M12 3v1m6.364 1.636l-.707.707M21 12h-1M4 12H3m3.343-5.657l-.707-.707m2.828 9.9a5 5 0 117.072 0l-.548.547A3.374 3.374 0 0014 18.469V19a2 2 0 11-4 0v-.531c0-.895-.356-1.754-.988-2.386l-.548-.547z', description: 'Portfolio insights' },
  { label: 'Reports', href: '/advisor/reports', icon: 'M9 17v-2m3 2v-4m3 4v-6m2 10H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z', description: 'Generate statements' },
  { label: 'Fund Universe', href: '/advisor/funds', icon: 'M19 11H5m14 0a2 2 0 012 2v6a2 2 0 01-2 2H5a2 2 0 01-2-2v-6a2 2 0 012-2m14 0V9a2 2 0 00-2-2M5 11V9a2 2 0 012-2m0 0V5a2 2 0 012-2h6a2 2 0 012 2v2M7 7h10', description: 'Browse & recommend' },
];

const AdvisorDashboard = () => {
  const { isDark, colors } = useFATheme();

  const totalAum = mockClients.reduce((sum, c) => sum + c.aum, 0);
  const avgReturns = mockClients.reduce((sum, c) => sum + c.returns, 0) / mockClients.length;

  return (
    <AdvisorLayout title="Dashboard">
      <div style={{ background: colors.background, minHeight: '100%', margin: '-2rem', padding: '2rem' }}>
        {/* Welcome Section */}
        <div className="mb-8">
          <h1 className="text-2xl font-bold" style={{ color: colors.textPrimary }}>
            Welcome back, Advisor
          </h1>
          <p className="text-sm mt-1" style={{ color: colors.textSecondary }}>
            Here&apos;s an overview of your client portfolios and pending actions.
          </p>
        </div>

        {/* Quick Navigation - Gradient Border Cards */}
        <div className="mb-8">
          <h2 className="text-sm font-semibold uppercase tracking-wide mb-4" style={{ color: colors.textSecondary }}>
            Quick Access
          </h2>
          <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-6 gap-3">
            {advisorNavItems.map((item, index) => {
              // Cycle through accent colors for variety
              const accentColors = [colors.primary, colors.secondary, colors.success, colors.warning, colors.error, colors.accent];
              const accentColor = accentColors[index % accentColors.length];
              return (
                <Link
                  key={item.label}
                  href={item.href}
                  className="group"
                >
                  <div
                    className="p-4 rounded-2xl h-full transition-all duration-300 group-hover:-translate-y-1"
                    style={{
                      background: `linear-gradient(145deg, ${colors.cardBackground} 0%, ${isDark ? colors.backgroundTertiary : colors.backgroundSecondary} 100%)`,
                      border: `1px solid ${colors.cardBorder}`,
                      borderLeft: `4px solid ${accentColor}`,
                      boxShadow: `0 4px 20px ${colors.glassShadow}`
                    }}
                  >
                    <div
                      className="w-10 h-10 rounded-xl flex items-center justify-center mb-3"
                      style={{ background: `${accentColor}15` }}
                    >
                      <svg className="w-5 h-5" style={{ color: accentColor }} fill="none" viewBox="0 0 24 24" stroke="currentColor">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d={item.icon} />
                      </svg>
                    </div>
                    <p className="text-base font-semibold" style={{ color: colors.textPrimary }}>{item.label}</p>
                    <p className="text-xs mt-0.5" style={{ color: colors.textTertiary }}>{item.description}</p>
                  </div>
                </Link>
              );
            })}
          </div>
        </div>

        {/* KPI Cards - Duo-Tone Gradient Style */}
        <div className="grid grid-cols-2 md:grid-cols-4 gap-4 mb-8">
          {[
            { label: 'TOTAL AUM', value: formatCurrency(totalAum), change: '+12.4%', variant: 'primary' },
            { label: 'TOTAL CLIENTS', value: mockClients.length.toString(), change: '+2', variant: 'secondary' },
            { label: 'AVG. RETURNS', value: `${avgReturns.toFixed(1)}%`, change: '+3.2%', variant: 'success' },
            { label: 'PROSPECTS', value: mockProspects.length.toString(), change: '3 active', variant: 'accent' },
          ].map((kpi) => {
            const getGradient = () => {
              switch (kpi.variant) {
                case 'secondary': return `linear-gradient(135deg, ${colors.secondary} 0%, ${colors.primary} 100%)`;
                case 'success': return `linear-gradient(135deg, ${colors.success} 0%, ${isDark ? '#059669' : '#047857'} 100%)`;
                case 'accent': return `linear-gradient(135deg, ${colors.primaryDark} 0%, ${colors.secondary} 100%)`;
                default: return `linear-gradient(135deg, ${colors.primary} 0%, ${colors.primaryDark} 100%)`;
              }
            };
            return (
              <div
                key={kpi.label}
                className="p-4 rounded-2xl relative overflow-hidden transition-all duration-300 hover:-translate-y-1"
                style={{
                  background: getGradient(),
                  boxShadow: `0 8px 32px ${isDark ? 'rgba(168, 85, 247, 0.25)' : `${colors.primary}25`}`
                }}
              >
                {/* Decorative circles */}
                <div className="absolute -top-4 -right-4 w-16 h-16 rounded-full" style={{ background: 'rgba(255,255,255,0.1)' }} />
                <div className="absolute -bottom-6 -left-6 w-20 h-20 rounded-full" style={{ background: 'rgba(255,255,255,0.05)' }} />
                <div className="relative z-10">
                  <p className="text-xs font-semibold uppercase tracking-wider text-white/70">{kpi.label}</p>
                  <p className="text-xl font-bold mt-2 text-white">{kpi.value}</p>
                  <span
                    className="text-xs font-medium px-2 py-0.5 rounded-full mt-2 inline-block"
                    style={{
                      background: 'rgba(255, 255, 255, 0.2)',
                      border: '1px solid rgba(255, 255, 255, 0.3)',
                      color: '#FFFFFF'
                    }}
                  >
                    {kpi.change}
                  </span>
                </div>
              </div>
            );
          })}
        </div>

        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
          {/* Main Content */}
          <div className="lg:col-span-2 space-y-6">
            {/* Pending Actions */}
            <div
              className="p-5 rounded-xl"
              style={{
                background: colors.cardBackground,
                border: `1px solid ${colors.cardBorder}`,
                boxShadow: `0 4px 24px ${colors.glassShadow}`
              }}
            >
              <div className="flex items-center justify-between mb-5">
                <div className="flex items-center gap-3">
                  <div
                    className="w-9 h-9 rounded-xl flex items-center justify-center"
                    style={{ background: `linear-gradient(135deg, ${colors.warning} 0%, #D97706 100%)` }}
                  >
                    <svg className="w-5 h-5 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
                    </svg>
                  </div>
                  <h3 className="text-base font-semibold" style={{ color: colors.textPrimary }}>Pending Actions</h3>
                </div>
                <span
                  className="text-xs px-2 py-1 rounded-full font-medium"
                  style={{ background: `${colors.error}15`, color: colors.error }}
                >
                  {mockPendingActions.filter(a => a.urgent).length} urgent
                </span>
              </div>
              <div className="space-y-2">
                {mockPendingActions.map((action) => (
                  <div
                    key={action.id}
                    className="flex items-center gap-3 p-3 rounded-2xl transition-all duration-200 hover:-translate-y-0.5"
                    style={{
                      background: isDark
                        ? 'linear-gradient(135deg, rgba(216, 180, 254, 0.06) 0%, rgba(249, 168, 212, 0.03) 100%)'
                        : 'linear-gradient(135deg, rgba(168, 85, 247, 0.03) 0%, rgba(244, 114, 182, 0.01) 100%)',
                      border: `1px solid ${action.urgent ? colors.error + '30' : colors.cardBorder}`,
                      boxShadow: `0 4px 20px ${colors.glassShadow}`
                    }}
                  >
                    <div
                      className="w-8 h-8 rounded-xl flex items-center justify-center flex-shrink-0"
                      style={{ background: action.urgent ? `${colors.error}15` : `${colors.primary}15` }}
                    >
                      <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" style={{ color: action.urgent ? colors.error : colors.primary }}>
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d={
                          action.type === 'SIP' ? 'M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1M21 12a9 9 0 11-18 0 9 9 0 0118 0z' :
                          action.type === 'Rebalance' ? 'M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15' :
                          action.type === 'Review' ? 'M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2' :
                          'M10 6H5a2 2 0 00-2 2v9a2 2 0 002 2h14a2 2 0 002-2V8a2 2 0 00-2-2h-5m-4 0V5a2 2 0 114 0v1m-4 0a2 2 0 104 0m-5 8a2 2 0 100-4 2 2 0 000 4zm0 0c1.306 0 2.417.835 2.83 2M9 14a3.001 3.001 0 00-2.83 2M15 11h3m-3 4h2'
                        } />
                      </svg>
                    </div>
                    <div className="flex-1 min-w-0">
                      <div className="flex items-center gap-2">
                        <p className="text-sm font-medium" style={{ color: colors.textPrimary }}>{action.client}</p>
                        {action.urgent && (
                          <span className="text-xs px-1.5 py-0.5 rounded" style={{ background: `${colors.error}15`, color: colors.error }}>
                            Urgent
                          </span>
                        )}
                      </div>
                      <p className="text-xs mt-0.5" style={{ color: colors.textSecondary }}>{action.action}</p>
                    </div>
                    {action.amount && (
                      <span className="text-sm font-semibold" style={{ color: colors.success }}>
                        {formatCurrency(action.amount)}
                      </span>
                    )}
                    <button
                      className="px-3 py-1.5 rounded-lg text-xs font-medium transition-all hover:shadow"
                      style={{ background: `${colors.primary}15`, color: colors.primary }}
                    >
                      Action
                    </button>
                  </div>
                ))}
              </div>
            </div>

            {/* Client Portfolio Overview */}
            <div
              className="p-5 rounded-xl"
              style={{
                background: colors.cardBackground,
                border: `1px solid ${colors.cardBorder}`,
                boxShadow: `0 4px 24px ${colors.glassShadow}`
              }}
            >
              <div className="flex items-center justify-between mb-5">
                <div className="flex items-center gap-3">
                  <div
                    className="w-9 h-9 rounded-xl flex items-center justify-center"
                    style={{ background: `linear-gradient(135deg, ${colors.primary} 0%, ${colors.primaryDark} 100%)` }}
                  >
                    <svg className="w-5 h-5 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z" />
                    </svg>
                  </div>
                  <h3 className="text-base font-semibold" style={{ color: colors.textPrimary }}>Client Portfolios</h3>
                </div>
                <Link href="/advisor/clients" className="text-sm font-medium hover:underline" style={{ color: colors.primary }}>
                  View All
                </Link>
              </div>
              <div className="space-y-2">
                {mockClients.map((client) => (
                  <div
                    key={client.id}
                    className="flex items-center gap-3 p-3 rounded-2xl transition-all duration-200 hover:-translate-y-0.5 cursor-pointer"
                    style={{
                      background: isDark
                        ? 'linear-gradient(135deg, rgba(216, 180, 254, 0.06) 0%, rgba(249, 168, 212, 0.03) 100%)'
                        : 'linear-gradient(135deg, rgba(168, 85, 247, 0.03) 0%, rgba(244, 114, 182, 0.01) 100%)',
                      border: `1px solid ${colors.cardBorder}`,
                      boxShadow: `0 4px 20px ${colors.glassShadow}`
                    }}
                  >
                    <div
                      className="w-10 h-10 rounded-xl flex items-center justify-center text-white font-semibold"
                      style={{ background: `linear-gradient(135deg, ${colors.primary} 0%, ${colors.primaryDark} 100%)` }}
                    >
                      {client.name.split(' ').map(n => n[0]).join('')}
                    </div>
                    <div className="flex-1 min-w-0">
                      <p className="text-sm font-medium" style={{ color: colors.textPrimary }}>{client.name}</p>
                      <div className="flex items-center gap-2 mt-0.5">
                        <span className="text-xs" style={{ color: colors.textSecondary }}>{formatCurrency(client.aum)}</span>
                        <span className="text-xs" style={{ color: colors.textTertiary }}>•</span>
                        <span
                          className="text-xs px-1.5 py-0.5 rounded"
                          style={{ background: `${getRiskColor(client.riskProfile, colors)}15`, color: getRiskColor(client.riskProfile, colors) }}
                        >
                          {client.riskProfile}
                        </span>
                      </div>
                    </div>
                    <div className="text-right">
                      <p className="text-sm font-semibold" style={{ color: colors.success }}>+{client.returns}%</p>
                      <p className="text-xs" style={{ color: colors.textTertiary }}>{client.lastActive}</p>
                    </div>
                  </div>
                ))}
              </div>
            </div>
          </div>

          {/* Sidebar */}
          <div className="space-y-6">
            {/* Prospect Pipeline */}
            <div
              className="p-5 rounded-xl"
              style={{
                background: colors.cardBackground,
                border: `1px solid ${colors.cardBorder}`,
                boxShadow: `0 4px 24px ${colors.glassShadow}`
              }}
            >
              <div className="flex items-center gap-3 mb-4">
                <div
                  className="w-9 h-9 rounded-xl flex items-center justify-center"
                  style={{ background: `linear-gradient(135deg, ${colors.warning} 0%, #D97706 100%)` }}
                >
                  <svg className="w-5 h-5 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M18 9v3m0 0v3m0-3h3m-3 0h-3m-2-5a4 4 0 11-8 0 4 4 0 018 0zM3 20a6 6 0 0112 0v1H3v-1z" />
                  </svg>
                </div>
                <div>
                  <h3 className="text-base font-semibold" style={{ color: colors.textPrimary }}>Prospects</h3>
                  <p className="text-xs" style={{ color: colors.textSecondary }}>Lead pipeline</p>
                </div>
              </div>
              <div className="space-y-2">
                {mockProspects.map((prospect) => (
                  <div
                    key={prospect.id}
                    className="p-3 rounded-2xl transition-all duration-200 hover:-translate-y-0.5"
                    style={{
                      background: isDark
                        ? 'linear-gradient(135deg, rgba(216, 180, 254, 0.06) 0%, rgba(249, 168, 212, 0.03) 100%)'
                        : 'linear-gradient(135deg, rgba(168, 85, 247, 0.03) 0%, rgba(244, 114, 182, 0.01) 100%)',
                      border: `1px solid ${colors.cardBorder}`,
                      boxShadow: `0 4px 20px ${colors.glassShadow}`
                    }}
                  >
                    <div className="flex items-center justify-between mb-1">
                      <p className="text-sm font-medium" style={{ color: colors.textPrimary }}>{prospect.name}</p>
                      <span
                        className="text-xs px-2 py-0.5 rounded"
                        style={{ background: `${getStageColor(prospect.stage, colors)}15`, color: getStageColor(prospect.stage, colors) }}
                      >
                        {prospect.stage}
                      </span>
                    </div>
                    <p className="text-xs" style={{ color: colors.textSecondary }}>
                      Potential: {formatCurrency(prospect.potentialAum)}
                    </p>
                    <p className="text-xs mt-1" style={{ color: colors.textTertiary }}>{prospect.status}</p>
                  </div>
                ))}
              </div>
              <button
                className="w-full mt-4 py-2 rounded-xl text-sm font-medium transition-all hover:shadow"
                style={{ background: `${colors.warning}15`, color: colors.warning, border: `1px solid ${colors.warning}30` }}
              >
                + Add Prospect
              </button>
            </div>

            {/* AI Recommendations */}
            <div
              className="p-5 rounded-xl"
              style={{
                background: colors.cardBackground,
                border: `1px solid ${colors.cardBorder}`,
                boxShadow: `0 4px 24px ${colors.glassShadow}`
              }}
            >
              <div className="flex items-center gap-3 mb-4">
                <div
                  className="w-9 h-9 rounded-xl flex items-center justify-center"
                  style={{ background: `linear-gradient(135deg, ${colors.secondary} 0%, #7C3AED 100%)` }}
                >
                  <svg className="w-5 h-5 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M9.663 17h4.673M12 3v1m6.364 1.636l-.707.707M21 12h-1M4 12H3m3.343-5.657l-.707-.707m2.828 9.9a5 5 0 117.072 0l-.548.547A3.374 3.374 0 0014 18.469V19a2 2 0 11-4 0v-.531c0-.895-.356-1.754-.988-2.386l-.548-.547z" />
                  </svg>
                </div>
                <div>
                  <h3 className="text-base font-semibold" style={{ color: colors.textPrimary }}>AI Insights</h3>
                  <p className="text-xs" style={{ color: colors.textSecondary }}>Portfolio recommendations</p>
                </div>
              </div>
              <div className="space-y-3">
                {[
                  { title: 'Rebalance Alert', detail: '3 portfolios need attention', type: 'warning' },
                  { title: 'Tax Harvesting', detail: 'Opportunity in 2 portfolios', type: 'success' },
                  { title: 'Goal Review', detail: '5 clients approaching milestones', type: 'info' },
                ].map((insight, idx) => {
                  const getAccentColor = () => {
                    switch (insight.type) {
                      case 'warning': return colors.warning;
                      case 'success': return colors.success;
                      default: return colors.primary;
                    }
                  };
                  const accentColor = getAccentColor();
                  return (
                    <div
                      key={idx}
                      className="p-3 rounded-2xl transition-all duration-200 hover:-translate-y-0.5"
                      style={{
                        background: isDark
                          ? 'linear-gradient(135deg, rgba(216, 180, 254, 0.06) 0%, rgba(249, 168, 212, 0.03) 100%)'
                          : 'linear-gradient(135deg, rgba(168, 85, 247, 0.03) 0%, rgba(244, 114, 182, 0.01) 100%)',
                        border: `1px solid ${isDark ? `${accentColor}20` : `${accentColor}15`}`,
                        borderLeft: `4px solid ${accentColor}`,
                        boxShadow: `0 4px 20px ${colors.glassShadow}`
                      }}
                    >
                      <p className="text-sm font-medium" style={{ color: colors.textPrimary }}>{insight.title}</p>
                      <p className="text-xs mt-1" style={{ color: colors.textSecondary }}>{insight.detail}</p>
                    </div>
                  );
                })}
              </div>
              <Link href="/advisor/analysis">
                <span
                  className="block w-full mt-4 py-2 rounded-xl text-sm font-medium text-center transition-all hover:shadow"
                  style={{ background: `${colors.secondary}15`, color: colors.secondary, border: `1px solid ${colors.secondary}30` }}
                >
                  Run Full Analysis
                </span>
              </Link>
            </div>
          </div>
        </div>
      </div>
    </AdvisorLayout>
  );
};

export default AdvisorDashboard;
