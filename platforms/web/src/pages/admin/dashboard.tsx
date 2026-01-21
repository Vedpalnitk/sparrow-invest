import { useState, useEffect } from 'react';
import Link from 'next/link';
import Navbar from '@/components/layout/Navbar';
import Footer from '@/components/layout/Footer';
import {
  engineModules,
  personaProfiles,
  personaRules,
} from '@/utils/constants';

// V4 Color Palette - Refined Blue
const V4_COLORS_LIGHT = {
  primary: '#2563EB',
  primaryDark: '#1D4ED8',
  secondary: '#7C3AED',
  success: '#10B981',
  warning: '#F59E0B',
  error: '#EF4444',
  background: '#F8FAFC',
  cardBackground: 'rgba(255, 255, 255, 0.8)',
  cardBorder: 'rgba(37, 99, 235, 0.1)',
  inputBg: 'rgba(255, 255, 255, 0.9)',
  inputBorder: 'rgba(37, 99, 235, 0.2)',
  chipBg: 'rgba(37, 99, 235, 0.08)',
  chipBorder: 'rgba(37, 99, 235, 0.15)',
  textPrimary: '#1E293B',
  textSecondary: '#64748B',
  textTertiary: '#94A3B8',
  progressBg: 'rgba(37, 99, 235, 0.1)',
  glassShadow: 'rgba(37, 99, 235, 0.08)',
};

const V4_COLORS_DARK = {
  primary: '#60A5FA',
  primaryDark: '#3B82F6',
  secondary: '#A78BFA',
  success: '#34D399',
  warning: '#FBBF24',
  error: '#F87171',
  background: '#0F172A',
  cardBackground: 'rgba(30, 41, 59, 0.8)',
  cardBorder: 'rgba(96, 165, 250, 0.15)',
  inputBg: 'rgba(30, 41, 59, 0.9)',
  inputBorder: 'rgba(96, 165, 250, 0.25)',
  chipBg: 'rgba(96, 165, 250, 0.12)',
  chipBorder: 'rgba(96, 165, 250, 0.2)',
  textPrimary: '#F1F5F9',
  textSecondary: '#94A3B8',
  textTertiary: '#64748B',
  progressBg: 'rgba(96, 165, 250, 0.15)',
  glassShadow: 'rgba(0, 0, 0, 0.3)',
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

// Icon paths
const ICONS = {
  chart: 'M11 3.055A9.001 9.001 0 1020.945 13H11V3.055z M20.488 9H15V3.512A9.025 9.025 0 0120.488 9z',
  cpu: 'M9 3v2m6-2v2M9 19v2m6-2v2M5 9H3m2 6H3m18-6h-2m2 6h-2M7 19h10a2 2 0 002-2V7a2 2 0 00-2-2H7a2 2 0 00-2 2v10a2 2 0 002 2zM9 9h6v6H9V9z',
  rules: 'M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2',
  users: 'M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197M13 7a4 4 0 11-8 0 4 4 0 018 0z',
  user: 'M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z',
  dashboard: 'M4 5a1 1 0 011-1h14a1 1 0 011 1v2a1 1 0 01-1 1H5a1 1 0 01-1-1V5zM4 13a1 1 0 011-1h6a1 1 0 011 1v6a1 1 0 01-1 1H5a1 1 0 01-1-1v-6zM16 13a1 1 0 011-1h2a1 1 0 011 1v6a1 1 0 01-1 1h-2a1 1 0 01-1-1v-6z',
  play: 'M14.752 11.168l-3.197-2.132A1 1 0 0010 9.87v4.263a1 1 0 001.555.832l3.197-2.132a1 1 0 000-1.664z M21 12a9 9 0 11-18 0 9 9 0 0118 0z',
  cog: 'M10.325 4.317c.426-1.756 2.924-1.756 3.35 0a1.724 1.724 0 002.573 1.066c1.543-.94 3.31.826 2.37 2.37a1.724 1.724 0 001.065 2.572c1.756.426 1.756 2.924 0 3.35a1.724 1.724 0 00-1.066 2.573c.94 1.543-.826 3.31-2.37 2.37a1.724 1.724 0 00-2.572 1.065c-.426 1.756-2.924 1.756-3.35 0a1.724 1.724 0 00-2.573-1.066c-1.543.94-3.31-.826-2.37-2.37a1.724 1.724 0 00-1.065-2.572c-1.756-.426-1.756-2.924 0-3.35a1.724 1.724 0 001.066-2.573c-.94-1.543.826-3.31 2.37-2.37.996.608 2.296.07 2.572-1.065z',
};

// Quick navigation items for admin
const adminNavItems = [
  { label: 'Users & Roles', href: '/admin/users', icon: ICONS.users, description: 'Manage users, advisors, permissions' },
  { label: 'ML Models', href: '/admin/models', icon: ICONS.cpu, description: 'Model versions, deployments' },
  { label: 'Personas', href: '/admin/personas', icon: ICONS.user, description: 'Investor persona templates' },
  { label: 'Fund Universe', href: '/admin/funds', icon: ICONS.chart, description: 'Fund catalog, restrictions' },
  { label: 'Allocations', href: '/admin/allocations', icon: ICONS.rules, description: 'Asset allocation strategies' },
  { label: 'Recommendations', href: '/admin/recommendations', icon: ICONS.play, description: 'Recommendation engine config' },
];

const AdminDashboard = () => {
  const colors = useV4Colors();
  const isDark = useDarkMode();

  const getRiskBandStyle = (band: string) => {
    switch (band) {
      case 'Capital Protection':
        return { bg: isDark ? 'rgba(16, 185, 129, 0.15)' : 'rgba(16, 185, 129, 0.1)', color: colors.success };
      case 'Balanced Growth':
        return { bg: isDark ? 'rgba(96, 165, 250, 0.15)' : 'rgba(37, 99, 235, 0.1)', color: colors.primary };
      case 'Accelerated Growth':
        return { bg: isDark ? 'rgba(167, 139, 250, 0.15)' : 'rgba(124, 58, 237, 0.1)', color: colors.secondary };
      default:
        return { bg: colors.chipBg, color: colors.textSecondary };
    }
  };

  return (
    <div className="min-h-screen" style={{ background: colors.background }}>
      <Navbar mode="admin" />
      <main className="max-w-6xl mx-auto px-6 py-8">
        {/* Page Header */}
        <div className="flex items-center justify-between mb-8">
          <div className="flex items-center gap-4">
            <div
              className="w-12 h-12 rounded-xl flex items-center justify-center"
              style={{ background: `linear-gradient(135deg, ${colors.primary} 0%, ${colors.primaryDark} 100%)` }}
            >
              <svg className="w-6 h-6 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d={ICONS.cog} />
              </svg>
            </div>
            <div>
              <div className="flex items-center gap-3">
                <h1 className="text-2xl font-bold" style={{ color: colors.textPrimary }}>
                  Admin Dashboard
                </h1>
                <span
                  className="text-xs px-2 py-0.5 rounded font-medium"
                  style={{ background: colors.chipBg, color: colors.primary, border: `1px solid ${colors.chipBorder}` }}
                >
                  Admin
                </span>
              </div>
              <p className="text-sm mt-1" style={{ color: colors.textSecondary }}>
                Manage platform settings, users, models, and analytics.
              </p>
            </div>
          </div>
          <Link href="/">
            <span
              className="flex items-center gap-2 px-4 py-2 rounded-full font-medium text-sm transition-all hover:shadow-lg"
              style={{
                background: colors.chipBg,
                border: `1px solid ${colors.chipBorder}`,
                color: colors.primary
              }}
            >
              <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M10 19l-7-7m0 0l7-7m-7 7h18" />
              </svg>
              Back to Home
            </span>
          </Link>
        </div>

        {/* Quick Navigation */}
        <div className="mb-8">
          <h2 className="text-sm font-semibold uppercase tracking-wide mb-4" style={{ color: colors.textSecondary }}>
            Quick Access
          </h2>
          <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-6 gap-3">
            {adminNavItems.map((item) => (
              <Link
                key={item.label}
                href={item.href}
                className="p-4 rounded-xl transition-all duration-200 hover:-translate-y-1"
                style={{
                  background: colors.cardBackground,
                  border: `1px solid ${colors.cardBorder}`,
                  boxShadow: `0 4px 24px ${colors.glassShadow}`
                }}
              >
                <div
                  className="w-10 h-10 rounded-xl flex items-center justify-center mb-3"
                  style={{ background: `linear-gradient(135deg, ${colors.primary} 0%, ${colors.primaryDark} 100%)` }}
                >
                  <svg className="w-5 h-5 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d={item.icon} />
                  </svg>
                </div>
                <p className="text-sm font-semibold" style={{ color: colors.textPrimary }}>{item.label}</p>
                <p className="text-xs mt-1" style={{ color: colors.textSecondary }}>{item.description}</p>
              </Link>
            ))}
          </div>
        </div>

        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
          {/* Main Content */}
          <div className="lg:col-span-2 space-y-6">
            {/* Platform KPIs */}
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
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d={ICONS.chart} />
                    </svg>
                  </div>
                  <h3 className="text-base font-semibold" style={{ color: colors.textPrimary }}>Platform Overview</h3>
                </div>
                <span className="text-xs" style={{ color: colors.textSecondary }}>Last updated: Today</span>
              </div>
              <div className="grid grid-cols-2 md:grid-cols-4 gap-3">
                {[
                  { label: 'TOTAL AUM', value: '₹847.2 Cr', change: '+12.4%' },
                  { label: 'ACTIVE ADVISORS', value: '142', change: '+8.2%' },
                  { label: 'TOTAL CLIENTS', value: '12,847', change: '+15.3%' },
                  { label: 'MONTHLY TXNS', value: '₹24.5 Cr', change: '+18.7%' },
                ].map((stat) => (
                  <div
                    key={stat.label}
                    className="p-4 rounded-2xl"
                    style={{
                      background: `linear-gradient(135deg, ${colors.primary} 0%, ${colors.primaryDark} 100%)`,
                      boxShadow: `0 8px 32px ${isDark ? 'rgba(96, 165, 250, 0.3)' : 'rgba(37, 99, 235, 0.25)'}`
                    }}
                  >
                    <p className="text-xs font-semibold uppercase tracking-wider text-white/70">{stat.label}</p>
                    <p className="text-xl font-bold mt-2 text-white">{stat.value}</p>
                    <div className="mt-3 flex items-center gap-2">
                      <span
                        className="text-xs font-medium px-2 py-0.5 rounded-full"
                        style={{
                          background: 'rgba(255, 255, 255, 0.2)',
                          border: '1px solid rgba(255, 255, 255, 0.3)',
                          color: '#FFFFFF'
                        }}
                      >
                        {stat.change}
                      </span>
                    </div>
                  </div>
                ))}
              </div>
            </div>

            {/* Model Performance */}
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
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d={ICONS.cpu} />
                    </svg>
                  </div>
                  <h3 className="text-base font-semibold" style={{ color: colors.textPrimary }}>Model Performance</h3>
                </div>
                <Link href="/admin/models" className="text-sm font-medium hover:underline" style={{ color: colors.primary }}>
                  View Details
                </Link>
              </div>
              <div className="space-y-3">
                {[
                  { name: 'Risk Profiler', accuracy: 94.2, status: 'Healthy' },
                  { name: 'Goal Alignment Engine', accuracy: 91.8, status: 'Healthy' },
                  { name: 'Portfolio Optimizer', accuracy: 88.5, status: 'Monitoring' },
                  { name: 'Drift Detection', accuracy: 96.1, status: 'Healthy' },
                ].map((model) => (
                  <div
                    key={model.name}
                    className="p-3 rounded-2xl transition-all duration-200 hover:-translate-y-0.5"
                    style={{
                      background: isDark
                        ? 'linear-gradient(135deg, rgba(96, 165, 250, 0.08) 0%, rgba(147, 197, 253, 0.04) 100%)'
                        : 'linear-gradient(135deg, rgba(37, 99, 235, 0.04) 0%, rgba(59, 130, 246, 0.02) 100%)',
                      border: `1px solid ${colors.cardBorder}`,
                      boxShadow: `0 4px 20px ${colors.glassShadow}`
                    }}
                  >
                    <div className="flex items-center justify-between mb-2">
                      <span className="text-sm font-medium" style={{ color: colors.textPrimary }}>{model.name}</span>
                      <span
                        className="text-xs px-2 py-0.5 rounded-full"
                        style={{
                          background: model.status === 'Healthy'
                            ? (isDark ? 'rgba(52, 211, 153, 0.15)' : 'rgba(16, 185, 129, 0.15)')
                            : (isDark ? 'rgba(251, 191, 36, 0.15)' : 'rgba(245, 158, 11, 0.15)'),
                          border: `1px solid ${model.status === 'Healthy'
                            ? (isDark ? 'rgba(52, 211, 153, 0.25)' : 'rgba(16, 185, 129, 0.25)')
                            : (isDark ? 'rgba(251, 191, 36, 0.25)' : 'rgba(245, 158, 11, 0.25)')}`,
                          color: model.status === 'Healthy' ? colors.success : colors.warning
                        }}
                      >
                        {model.status}
                      </span>
                    </div>
                    <div className="flex items-center gap-3">
                      <div className="flex-1 h-2 rounded-full overflow-hidden" style={{ background: colors.progressBg }}>
                        <div
                          className="h-full rounded-full"
                          style={{
                            width: `${model.accuracy}%`,
                            background: `linear-gradient(90deg, ${colors.primary} 0%, ${colors.secondary} 100%)`
                          }}
                        />
                      </div>
                      <span className="text-sm font-bold w-14 text-right" style={{ color: colors.primary }}>
                        {model.accuracy}%
                      </span>
                    </div>
                  </div>
                ))}
              </div>
            </div>

            {/* Recent Activity */}
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
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
                    </svg>
                  </div>
                  <h3 className="text-base font-semibold" style={{ color: colors.textPrimary }}>Recent Activity</h3>
                </div>
                <button className="text-sm font-medium hover:underline" style={{ color: colors.primary }}>
                  View All
                </button>
              </div>
              <div className="space-y-2">
                {[
                  { action: 'New advisor onboarded', detail: 'Rajesh Kumar (Mumbai)', time: '1 hour ago', type: 'user' },
                  { action: 'Model retrained', detail: 'Risk Profiler v2.4', time: '3 hours ago', type: 'model' },
                  { action: 'Fund added to universe', detail: 'HDFC Mid-Cap Opportunities', time: '5 hours ago', type: 'create' },
                  { action: 'Compliance check passed', detail: 'SEBI guidelines validation', time: '1 day ago', type: 'check' },
                  { action: 'Bulk client import', detail: '234 clients by Axis Advisors', time: '1 day ago', type: 'user' },
                ].map((activity, idx) => (
                  <div
                    key={idx}
                    className="flex items-center gap-3 p-3 rounded-2xl transition-all duration-200 hover:-translate-y-0.5"
                    style={{
                      background: isDark
                        ? 'linear-gradient(135deg, rgba(96, 165, 250, 0.08) 0%, rgba(147, 197, 253, 0.04) 100%)'
                        : 'linear-gradient(135deg, rgba(37, 99, 235, 0.04) 0%, rgba(59, 130, 246, 0.02) 100%)',
                      border: `1px solid ${colors.cardBorder}`,
                      boxShadow: `0 4px 20px ${colors.glassShadow}`
                    }}
                  >
                    <div
                      className="w-8 h-8 rounded-xl flex items-center justify-center flex-shrink-0"
                      style={{ background: isDark ? 'rgba(96, 165, 250, 0.15)' : 'rgba(37, 99, 235, 0.1)' }}
                    >
                      <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" style={{ color: colors.primary }}>
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d={
                          activity.type === 'create' ? 'M12 4v16m8-8H4' :
                          activity.type === 'model' ? ICONS.cpu :
                          activity.type === 'check' ? 'M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z' :
                          ICONS.user
                        } />
                      </svg>
                    </div>
                    <div className="flex-1 min-w-0">
                      <p className="text-sm font-medium" style={{ color: colors.textPrimary }}>{activity.action}</p>
                      <p className="text-xs mt-1 truncate" style={{ color: colors.textSecondary }}>{activity.detail}</p>
                    </div>
                    <span className="text-xs flex-shrink-0" style={{ color: colors.textTertiary }}>{activity.time}</span>
                  </div>
                ))}
              </div>
            </div>
          </div>

          {/* Sidebar */}
          <div className="space-y-6">
            {/* Engine Modules */}
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
                  style={{ background: `linear-gradient(135deg, ${colors.primary} 0%, ${colors.primaryDark} 100%)` }}
                >
                  <svg className="w-5 h-5 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d={ICONS.cpu} />
                  </svg>
                </div>
                <div>
                  <h3 className="text-base font-semibold" style={{ color: colors.textPrimary }}>Engine Modules</h3>
                  <p className="text-xs" style={{ color: colors.textSecondary }}>
                    Model scoring & compliance
                  </p>
                </div>
              </div>
              <div className="space-y-2">
                {engineModules.map((module) => (
                  <div
                    key={module.title}
                    className="p-3 rounded-2xl transition-all duration-200 hover:-translate-y-0.5"
                    style={{
                      background: isDark
                        ? 'linear-gradient(135deg, rgba(96, 165, 250, 0.08) 0%, rgba(147, 197, 253, 0.04) 100%)'
                        : 'linear-gradient(135deg, rgba(37, 99, 235, 0.04) 0%, rgba(59, 130, 246, 0.02) 100%)',
                      border: `1px solid ${colors.cardBorder}`,
                      boxShadow: `0 4px 20px ${colors.glassShadow}`
                    }}
                  >
                    <p className="text-sm font-medium" style={{ color: colors.textPrimary }}>{module.title}</p>
                    <p className="text-xs mt-1" style={{ color: colors.textSecondary }}>{module.detail}</p>
                  </div>
                ))}
              </div>
            </div>

            {/* Persona Library */}
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
                  style={{ background: `linear-gradient(135deg, ${colors.primary} 0%, ${colors.primaryDark} 100%)` }}
                >
                  <svg className="w-5 h-5 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d={ICONS.user} />
                  </svg>
                </div>
                <div>
                  <h3 className="text-base font-semibold" style={{ color: colors.textPrimary }}>Persona Library</h3>
                  <p className="text-xs" style={{ color: colors.textSecondary }}>
                    Active personas & biases
                  </p>
                </div>
              </div>
              <div className="space-y-2">
                {personaProfiles.map((persona) => {
                  const riskStyle = getRiskBandStyle(persona.riskBand);
                  return (
                    <div
                      key={persona.name}
                      className="p-3 rounded-2xl transition-all duration-200 hover:-translate-y-0.5"
                      style={{
                        background: isDark
                          ? 'linear-gradient(135deg, rgba(96, 165, 250, 0.08) 0%, rgba(147, 197, 253, 0.04) 100%)'
                          : 'linear-gradient(135deg, rgba(37, 99, 235, 0.04) 0%, rgba(59, 130, 246, 0.02) 100%)',
                        border: `1px solid ${colors.cardBorder}`,
                        boxShadow: `0 4px 20px ${colors.glassShadow}`
                      }}
                    >
                      <div className="flex items-center justify-between">
                        <p className="text-sm font-medium" style={{ color: colors.textPrimary }}>{persona.name}</p>
                        <span
                          className="text-xs px-2 py-0.5 rounded"
                          style={{ background: riskStyle.bg, color: riskStyle.color }}
                        >
                          {persona.riskBand}
                        </span>
                      </div>
                      <p className="text-xs mt-1.5" style={{ color: colors.textSecondary }}>{persona.description}</p>
                    </div>
                  );
                })}
              </div>
            </div>
          </div>
        </div>
      </main>
      <Footer />
    </div>
  );
};

export default AdminDashboard;
