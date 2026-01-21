import Link from 'next/link';
import { useState, useEffect } from 'react';

// iOS 26 Liquid Glass Color Palette
const V4_COLORS_LIGHT = {
  primary: '#2563EB',
  primaryDark: '#1D4ED8',
  secondary: '#7C3AED',
  success: '#10B981',
  warning: '#F59E0B',
  error: '#EF4444',
  background: '#F8FAFC',
  cardBackground: 'rgba(255, 255, 255, 0.35)',
  cardBorder: 'rgba(255, 255, 255, 0.2)',
  chipBg: 'rgba(255, 255, 255, 0.2)',
  chipBorder: 'rgba(255, 255, 255, 0.3)',
  textPrimary: '#1E293B',
  textSecondary: '#64748B',
  textTertiary: '#94A3B8',
  glassShadow: 'rgba(0, 0, 0, 0.08)',
  glassHighlight: 'rgba(255, 255, 255, 0.5)',
};

const V4_COLORS_DARK = {
  primary: '#60A5FA',
  primaryDark: '#3B82F6',
  secondary: '#A78BFA',
  success: '#34D399',
  warning: '#FBBF24',
  error: '#F87171',
  background: '#0F172A',
  cardBackground: 'rgba(30, 41, 59, 0.4)',
  cardBorder: 'rgba(255, 255, 255, 0.1)',
  chipBg: 'rgba(255, 255, 255, 0.1)',
  chipBorder: 'rgba(255, 255, 255, 0.15)',
  textPrimary: '#F1F5F9',
  textSecondary: '#94A3B8',
  textTertiary: '#64748B',
  glassShadow: 'rgba(0, 0, 0, 0.4)',
  glassHighlight: 'rgba(255, 255, 255, 0.15)',
};

const useDarkMode = () => {
  const [isDark, setIsDark] = useState(false);
  useEffect(() => {
    const checkDark = () => setIsDark(document.documentElement.classList.contains('dark'));
    checkDark();
    const observer = new MutationObserver(checkDark);
    observer.observe(document.documentElement, { attributes: true, attributeFilter: ['class'] });
    return () => observer.disconnect();
  }, []);
  return isDark;
};

const useV4Colors = () => {
  const isDark = useDarkMode();
  return isDark ? V4_COLORS_DARK : V4_COLORS_LIGHT;
};

const Home = () => {
  const colors = useV4Colors();
  const isDark = useDarkMode();

  return (
    <div className="min-h-screen" style={{ background: colors.background }}>
      {/* Header */}
      <header className="max-w-6xl mx-auto px-6 py-6">
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-3">
            <div
              className="w-10 h-10 rounded-xl flex items-center justify-center text-white"
              style={{
                background: `linear-gradient(135deg, ${colors.primary} 0%, ${colors.primaryDark} 100%)`,
                boxShadow: `0 4px 14px ${colors.glassShadow}`
              }}
            >
              <svg viewBox="0 0 24 24" className="w-6 h-6" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round">
                <path d="M17 5H9a4 4 0 000 8h6a4 4 0 010 8H7"/>
              </svg>
            </div>
            <div>
              <span className="text-lg font-semibold" style={{ color: colors.primary }}>Sparrow Invest</span>
              <p className="text-xs" style={{ color: colors.textTertiary }}>Wealth Management Platform</p>
            </div>
          </div>
          <div className="flex items-center gap-3">
            <span
              className="text-xs px-3 py-1.5 rounded-full font-medium hidden md:inline-flex"
              style={{ background: colors.chipBg, color: colors.success, border: `1px solid ${colors.chipBorder}` }}
            >
              <span className="w-2 h-2 rounded-full mr-2 animate-pulse" style={{ background: colors.success }} />
              Platform Active
            </span>
          </div>
        </div>
      </header>

      {/* Main Content */}
      <main className="max-w-6xl mx-auto px-6 py-8">
        {/* Hero Section */}
        <div
          className="p-10 md:p-14 rounded-3xl mb-8"
          style={{
            background: colors.cardBackground,
            backdropFilter: 'blur(30px) saturate(180%)',
            WebkitBackdropFilter: 'blur(30px) saturate(180%)',
            border: `1px solid ${colors.cardBorder}`,
            boxShadow: `0 8px 32px ${colors.glassShadow}, inset 0 1px 0 ${colors.glassHighlight}`
          }}
        >
          <div className="flex flex-col md:flex-row md:items-center md:justify-between gap-8">
            <div className="max-w-2xl">
              <div
                className="inline-flex items-center gap-2 px-3 py-1.5 rounded-full mb-4"
                style={{ background: colors.chipBg }}
              >
                <span className="w-2 h-2 rounded-full animate-pulse" style={{ background: colors.success }} />
                <span className="text-xs font-medium" style={{ color: colors.primary }}>AI-Powered Platform</span>
              </div>
              <h1 className="text-3xl md:text-4xl font-bold leading-tight" style={{ color: colors.textPrimary }}>
                Intelligent wealth management for{' '}
                <span
                  style={{
                    background: `linear-gradient(90deg, ${colors.primary} 0%, ${colors.secondary} 100%)`,
                    WebkitBackgroundClip: 'text',
                    WebkitTextFillColor: 'transparent',
                    backgroundClip: 'text',
                  }}
                >
                  financial advisors
                </span>
              </h1>
              <p className="mt-4 text-base leading-relaxed" style={{ color: colors.textSecondary }}>
                A comprehensive platform for managing client portfolios, AI-driven recommendations, and seamless fund transactions. Built for modern financial advisors.
              </p>
            </div>
            <div className="flex flex-col gap-2">
              <span
                className="text-xs px-3 py-1.5 rounded-full font-medium"
                style={{ background: colors.chipBg, color: colors.primary, border: `1px solid ${colors.chipBorder}` }}
              >
                Client Portfolio Management
              </span>
              <span
                className="text-xs px-3 py-1.5 rounded-full font-medium"
                style={{ background: colors.chipBg, color: colors.primary, border: `1px solid ${colors.chipBorder}` }}
              >
                AI Recommendations
              </span>
              <span
                className="text-xs px-3 py-1.5 rounded-full font-medium"
                style={{ background: colors.chipBg, color: colors.primary, border: `1px solid ${colors.chipBorder}` }}
              >
                Transaction Execution
              </span>
            </div>
          </div>
        </div>

        {/* Portal Selection */}
        <h2 className="text-sm font-semibold uppercase tracking-wide mb-4" style={{ color: colors.textSecondary }}>
          Select Portal
        </h2>
        <div className="grid md:grid-cols-2 gap-6 mb-12">
          {/* Admin Portal */}
          <Link
            href="/admin/dashboard"
            className="p-6 rounded-2xl transition-all duration-200 hover:-translate-y-1 group"
            style={{
              background: isDark ? 'rgba(30, 41, 59, 0.5)' : 'rgba(255, 255, 255, 0.6)',
              backdropFilter: 'blur(20px) saturate(180%)',
              WebkitBackdropFilter: 'blur(20px) saturate(180%)',
              border: `1px solid ${colors.cardBorder}`,
              boxShadow: `0 4px 24px ${colors.glassShadow}, inset 0 1px 0 ${colors.glassHighlight}`
            }}
          >
            <div className="flex items-start justify-between">
              <div>
                <div className="flex items-center gap-2 mb-2">
                  <span
                    className="text-xs px-2 py-1 rounded-full font-medium"
                    style={{ background: `${colors.primary}20`, color: colors.primary }}
                  >
                    Internal
                  </span>
                </div>
                <h2 className="text-2xl font-semibold transition-colors" style={{ color: colors.textPrimary }}>
                  Admin Portal
                </h2>
                <p className="text-sm mt-2 leading-relaxed" style={{ color: colors.textSecondary }}>
                  Manage users, roles, AI models, fund universe, and platform settings. Full control over the ecosystem.
                </p>
                <div className="mt-4 flex flex-wrap gap-2">
                  {['User Management', 'ML Models', 'Fund Universe', 'Analytics'].map((tag) => (
                    <span
                      key={tag}
                      className="text-xs px-2 py-1 rounded"
                      style={{ background: colors.chipBg, color: colors.textSecondary }}
                    >
                      {tag}
                    </span>
                  ))}
                </div>
              </div>
              <div
                className="w-14 h-14 rounded-2xl flex items-center justify-center text-white flex-shrink-0"
                style={{ background: `linear-gradient(135deg, ${colors.primary} 0%, ${colors.secondary} 100%)` }}
              >
                <svg className="w-7 h-7" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M10.325 4.317c.426-1.756 2.924-1.756 3.35 0a1.724 1.724 0 002.573 1.066c1.543-.94 3.31.826 2.37 2.37a1.724 1.724 0 001.065 2.572c1.756.426 1.756 2.924 0 3.35a1.724 1.724 0 00-1.066 2.573c.94 1.543-.826 3.31-2.37 2.37a1.724 1.724 0 00-2.572 1.065c-.426 1.756-2.924 1.756-3.35 0a1.724 1.724 0 00-2.573-1.066c-1.543.94-3.31-.826-2.37-2.37a1.724 1.724 0 00-1.065-2.572c-1.756-.426-1.756-2.924 0-3.35a1.724 1.724 0 001.066-2.573c-.94-1.543.826-3.31 2.37-2.37.996.608 2.296.07 2.572-1.065z" />
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
                </svg>
              </div>
            </div>
            <div className="mt-6">
              <span
                className="inline-flex items-center gap-2 px-5 py-2.5 rounded-full font-semibold text-sm text-white transition-all group-hover:shadow-lg"
                style={{
                  background: `linear-gradient(135deg, ${colors.primary} 0%, ${colors.primaryDark} 100%)`,
                  boxShadow: `0 4px 14px ${colors.glassShadow}`
                }}
              >
                Enter Admin Portal
                <svg className="w-4 h-4 transition-transform group-hover:translate-x-1" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5l7 7-7 7" />
                </svg>
              </span>
            </div>
          </Link>

          {/* Financial Advisor Portal */}
          <Link
            href="/advisor/dashboard"
            className="p-6 rounded-2xl transition-all duration-200 hover:-translate-y-1 group"
            style={{
              background: isDark ? 'rgba(30, 41, 59, 0.5)' : 'rgba(255, 255, 255, 0.6)',
              backdropFilter: 'blur(20px) saturate(180%)',
              WebkitBackdropFilter: 'blur(20px) saturate(180%)',
              border: `1px solid ${colors.cardBorder}`,
              boxShadow: `0 4px 24px ${colors.glassShadow}, inset 0 1px 0 ${colors.glassHighlight}`
            }}
          >
            <div className="flex items-start justify-between">
              <div>
                <div className="flex items-center gap-2 mb-2">
                  <span
                    className="text-xs px-2 py-1 rounded-full font-medium"
                    style={{ background: `${colors.success}20`, color: colors.success }}
                  >
                    Advisor
                  </span>
                </div>
                <h2 className="text-2xl font-semibold transition-colors" style={{ color: colors.textPrimary }}>
                  Financial Advisor Portal
                </h2>
                <p className="text-sm mt-2 leading-relaxed" style={{ color: colors.textSecondary }}>
                  Manage client portfolios, execute transactions, run AI analysis, and generate recommendations for prospects.
                </p>
                <div className="mt-4 flex flex-wrap gap-2">
                  {['Client Portfolios', 'Transactions', 'AI Analysis', 'Prospects'].map((tag) => (
                    <span
                      key={tag}
                      className="text-xs px-2 py-1 rounded"
                      style={{ background: colors.chipBg, color: colors.textSecondary }}
                    >
                      {tag}
                    </span>
                  ))}
                </div>
              </div>
              <div
                className="w-14 h-14 rounded-2xl flex items-center justify-center text-white flex-shrink-0"
                style={{ background: `linear-gradient(135deg, ${colors.success} 0%, #059669 100%)` }}
              >
                <svg className="w-7 h-7" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z" />
                </svg>
              </div>
            </div>
            <div className="mt-6">
              <span
                className="inline-flex items-center gap-2 px-5 py-2.5 rounded-full font-semibold text-sm text-white transition-all group-hover:shadow-lg"
                style={{
                  background: `linear-gradient(135deg, ${colors.success} 0%, #059669 100%)`,
                  boxShadow: `0 4px 14px ${colors.glassShadow}`
                }}
              >
                Enter Advisor Portal
                <svg className="w-4 h-4 transition-transform group-hover:translate-x-1" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5l7 7-7 7" />
                </svg>
              </span>
            </div>
          </Link>
        </div>

        {/* Platform Features */}
        <h2 className="text-sm font-semibold uppercase tracking-wide mb-4" style={{ color: colors.textSecondary }}>
          Platform Capabilities
        </h2>
        <div className="grid md:grid-cols-4 gap-4">
          {[
            {
              icon: (
                <svg className="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9.663 17h4.673M12 3v1m6.364 1.636l-.707.707M21 12h-1M4 12H3m3.343-5.657l-.707-.707m2.828 9.9a5 5 0 117.072 0l-.548.547A3.374 3.374 0 0014 18.469V19a2 2 0 11-4 0v-.531c0-.895-.356-1.754-.988-2.386l-.548-.547z" />
                </svg>
              ),
              title: 'AI Analysis',
              desc: 'ML-powered portfolio insights'
            },
            {
              icon: (
                <svg className="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
                </svg>
              ),
              title: 'Transactions',
              desc: 'Buy/sell on behalf of clients'
            },
            {
              icon: (
                <svg className="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z" />
                </svg>
              ),
              title: 'Analytics',
              desc: 'Real-time portfolio tracking'
            },
            {
              icon: (
                <svg className="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z" />
                </svg>
              ),
              title: 'Compliance',
              desc: 'Built-in regulatory controls'
            }
          ].map((feature) => (
            <div
              key={feature.title}
              className="p-4 rounded-xl"
              style={{
                background: colors.cardBackground,
                backdropFilter: 'blur(20px) saturate(180%)',
                WebkitBackdropFilter: 'blur(20px) saturate(180%)',
                border: `1px solid ${colors.cardBorder}`,
                boxShadow: `0 4px 24px ${colors.glassShadow}, inset 0 1px 0 ${colors.glassHighlight}`
              }}
            >
              <div
                className="w-10 h-10 rounded-xl flex items-center justify-center text-white mb-3"
                style={{ background: `linear-gradient(135deg, ${colors.primary} 0%, ${colors.primaryDark} 100%)` }}
              >
                {feature.icon}
              </div>
              <h3 className="font-semibold text-sm" style={{ color: colors.textPrimary }}>{feature.title}</h3>
              <p className="text-xs mt-1" style={{ color: colors.textSecondary }}>{feature.desc}</p>
            </div>
          ))}
        </div>
      </main>

      {/* Footer */}
      <footer className="max-w-6xl mx-auto px-6 py-8 text-center">
        <p className="text-xs" style={{ color: colors.textTertiary }}>
          2024 Sparrow Invest. AI-Powered Wealth Management Platform.
        </p>
      </footer>
    </div>
  );
};

export default Home;
