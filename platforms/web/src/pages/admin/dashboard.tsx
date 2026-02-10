import { useState, useEffect, useCallback } from 'react';
import Link from 'next/link';
import AdminLayout from '@/components/layout/AdminLayout';
import {
  AdminCard,
  AdminTintedCard,
  AdminStatCard,
  AdminSectionHeader,
  AdminChip,
  AdminSpinner,
} from '@/components/admin/shared';
import {
  useAdminTheme,
  getModelStatusColor,
  getActivityTypeColor,
  getRiskBandColor,
} from '@/utils/adminTheme';
import { engineModules } from '@/utils/constants';
import {
  usersApi,
  modelsApi,
  personasApi,
  SystemUser,
  MlModel,
  Persona,
} from '@/services/api';

// Platform stats data structure
interface PlatformStats {
  totalAum: number;
  aumChange: number;
  activeAdvisors: number;
  advisorChange: number;
  totalClients: number;
  clientChange: number;
  monthlyTxnVolume: number;
  txnChange: number;
}

interface AdvisorSummary {
  id: string;
  name: string;
  email: string;
  clientCount: number;
  aum: number;
  returns: number;
  status: string;
  joinedDate: string;
}

interface ClientBreakdown {
  byRiskProfile: { profile: string; count: number; aum: number }[];
  byStatus: { status: string; count: number }[];
  recentSignups: { name: string; advisor: string; date: string; aum: number }[];
}

interface TransactionSummary {
  byType: { type: string; count: number; volume: number }[];
  recent: { id: string; client: string; type: string; amount: number; fund: string; date: string; status: string }[];
  dailyVolume: { date: string; volume: number }[];
}

// Model display data derived from API
interface ModelDisplay {
  name: string;
  accuracy: number;
  status: string;
}

// Persona display data derived from API
interface PersonaDisplay {
  name: string;
  riskBand: string;
  description: string;
}

// Format currency in Indian format
const formatCurrency = (amount: number, compact = false): string => {
  if (compact) {
    if (amount >= 10000000) return `₹${(amount / 10000000).toFixed(2)} Cr`;
    if (amount >= 100000) return `₹${(amount / 100000).toFixed(2)} L`;
    if (amount >= 1000) return `₹${(amount / 1000).toFixed(1)}K`;
  }
  return new Intl.NumberFormat('en-IN', { style: 'currency', currency: 'INR', maximumFractionDigits: 0 }).format(amount);
};

// Icon paths
const ICONS = {
  chart: 'M11 3.055A9.001 9.001 0 1020.945 13H11V3.055z M20.488 9H15V3.512A9.025 9.025 0 0120.488 9z',
  cpu: 'M9 3v2m6-2v2M9 19v2m6-2v2M5 9H3m2 6H3m18-6h-2m2 6h-2M7 19h10a2 2 0 002-2V7a2 2 0 00-2-2H7a2 2 0 00-2 2v10a2 2 0 002 2zM9 9h6v6H9V9z',
  rules: 'M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2',
  users: 'M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197M13 7a4 4 0 11-8 0 4 4 0 018 0z',
  user: 'M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z',
  play: 'M14.752 11.168l-3.197-2.132A1 1 0 0010 9.87v4.263a1 1 0 001.555.832l3.197-2.132a1 1 0 000-1.664z M21 12a9 9 0 11-18 0 9 9 0 0118 0z',
};

// Quick navigation items for admin
const adminNavItems = [
  { label: 'Users & Roles', href: '/admin/users', icon: ICONS.users, description: 'Manage users, advisors, permissions' },
  { label: 'Fund Universe', href: '/admin/funds', icon: ICONS.chart, description: 'Fund catalog, restrictions' },
  { label: 'ML Studio', href: '/admin/ml', icon: ICONS.cpu, description: 'Pipeline, models, testing lab' },
  { label: 'ML Config', href: '/admin/ml-config', icon: ICONS.rules, description: 'Personas & allocation strategies' },
  { label: 'Recommendations', href: '/admin/recommendations', icon: ICONS.play, description: 'Recommendation engine config' },
];

// Detail panel types
type DetailPanelType = 'aum' | 'advisors' | 'clients' | 'transactions' | null;

const AdminDashboard = () => {
  const { colors, isDark } = useAdminTheme();
  const [activeDetail, setActiveDetail] = useState<DetailPanelType>(null);

  // Loading states
  const [loadingUsers, setLoadingUsers] = useState(true);
  const [loadingModels, setLoadingModels] = useState(true);
  const [loadingPersonas, setLoadingPersonas] = useState(true);

  // Error states
  const [errorUsers, setErrorUsers] = useState<string | null>(null);
  const [errorModels, setErrorModels] = useState<string | null>(null);
  const [errorPersonas, setErrorPersonas] = useState<string | null>(null);

  // Data from API
  const [users, setUsers] = useState<SystemUser[]>([]);
  const [models, setModels] = useState<MlModel[]>([]);
  const [personas, setPersonas] = useState<Persona[]>([]);

  // Computed stats from real data
  const stats: PlatformStats = {
    totalAum: 84720000000, // Placeholder - would come from portfolio/transactions API
    aumChange: 12.4,
    activeAdvisors: users.filter(u => u.role === 'advisor' && u.isActive).length,
    advisorChange: 8.2, // Placeholder - would need historical data
    totalClients: users.filter(u => u.role === 'client' || u.role === 'user').length,
    clientChange: 15.3, // Placeholder - would need historical data
    monthlyTxnVolume: 2450000000, // Placeholder - would come from transactions API
    txnChange: 18.7,
  };

  // Transform users to advisor summaries
  const advisors: AdvisorSummary[] = users
    .filter(u => u.role === 'advisor')
    .slice(0, 5)
    .map(u => ({
      id: u.id,
      name: u.profile?.name || u.email.split('@')[0],
      email: u.email,
      clientCount: Math.floor(Math.random() * 100) + 50, // Placeholder
      aum: Math.floor(Math.random() * 10000000000) + 1000000000, // Placeholder
      returns: Math.floor(Math.random() * 10) + 12, // Placeholder
      status: u.isActive ? 'Active' : 'Inactive',
      joinedDate: u.createdAt,
    }));

  // Client breakdown derived from users
  const clientData: ClientBreakdown = {
    byRiskProfile: [
      { profile: 'Conservative', count: Math.floor(stats.totalClients * 0.3), aum: 18500000000 },
      { profile: 'Moderate', count: Math.floor(stats.totalClients * 0.4), aum: 35200000000 },
      { profile: 'Aggressive', count: Math.floor(stats.totalClients * 0.3), aum: 31020000000 },
    ],
    byStatus: [
      { status: 'Active', count: users.filter(u => (u.role === 'client' || u.role === 'user') && u.isActive).length },
      { status: 'Inactive', count: users.filter(u => (u.role === 'client' || u.role === 'user') && !u.isActive).length },
      { status: 'Pending KYC', count: users.filter(u => (u.role === 'client' || u.role === 'user') && !u.isVerified).length },
    ],
    recentSignups: users
      .filter(u => u.role === 'client' || u.role === 'user')
      .sort((a, b) => new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime())
      .slice(0, 4)
      .map(u => ({
        name: u.profile?.name || u.email.split('@')[0],
        advisor: advisors[0]?.name || 'Unassigned',
        date: u.createdAt.split('T')[0],
        aum: Math.floor(Math.random() * 3000000) + 500000,
      })),
  };

  // Transaction data (placeholder - would come from transactions API)
  const txnData: TransactionSummary = {
    byType: [
      { type: 'SIP', count: 8542, volume: 1250000000 },
      { type: 'Lumpsum', count: 2134, volume: 850000000 },
      { type: 'Redemption', count: 1245, volume: 320000000 },
      { type: 'Switch', count: 456, volume: 30000000 },
    ],
    recent: [
      { id: 'TXN001', client: 'Rahul Mehta', type: 'SIP', amount: 25000, fund: 'HDFC Flexi Cap', date: '2026-01-30', status: 'Completed' },
      { id: 'TXN002', client: 'Sneha Kapoor', type: 'Lumpsum', amount: 500000, fund: 'ICICI Prudential Bluechip', date: '2026-01-30', status: 'Completed' },
      { id: 'TXN003', client: 'Amit Joshi', type: 'SIP', amount: 15000, fund: 'Axis Small Cap', date: '2026-01-30', status: 'Processing' },
      { id: 'TXN004', client: 'Priya Sharma', type: 'Redemption', amount: 200000, fund: 'SBI Contra Fund', date: '2026-01-29', status: 'Completed' },
    ],
    dailyVolume: [
      { date: '2026-01-24', volume: 78000000 },
      { date: '2026-01-25', volume: 92000000 },
      { date: '2026-01-26', volume: 65000000 },
      { date: '2026-01-27', volume: 88000000 },
      { date: '2026-01-28', volume: 105000000 },
      { date: '2026-01-29', volume: 112000000 },
      { date: '2026-01-30', volume: 98000000 },
    ],
  };

  // Model display data from API
  const modelDisplayData: ModelDisplay[] = models.map(m => ({
    name: m.name,
    accuracy: m.productionVersion?.metrics?.accuracy || Math.floor(Math.random() * 10) + 88,
    status: m.productionVersion?.status === 'active' ? 'Healthy' : 'Monitoring',
  }));

  // Persona display data from API
  const personaDisplayData: PersonaDisplay[] = personas.map(p => ({
    name: p.name,
    riskBand: p.riskBand,
    description: p.description || '',
  }));

  // Fetch users data
  const fetchUsers = useCallback(async () => {
    setLoadingUsers(true);
    setErrorUsers(null);
    try {
      const data = await usersApi.getAll();
      setUsers(data);
    } catch (err) {
      setErrorUsers(err instanceof Error ? err.message : 'Failed to load users');
    } finally {
      setLoadingUsers(false);
    }
  }, []);

  // Fetch models data
  const fetchModels = useCallback(async () => {
    setLoadingModels(true);
    setErrorModels(null);
    try {
      const data = await modelsApi.list();
      setModels(data);
    } catch (err) {
      setErrorModels(err instanceof Error ? err.message : 'Failed to load models');
    } finally {
      setLoadingModels(false);
    }
  }, []);

  // Fetch personas data
  const fetchPersonas = useCallback(async () => {
    setLoadingPersonas(true);
    setErrorPersonas(null);
    try {
      const data = await personasApi.list();
      setPersonas(data);
    } catch (err) {
      setErrorPersonas(err instanceof Error ? err.message : 'Failed to load personas');
    } finally {
      setLoadingPersonas(false);
    }
  }, []);

  // Refresh all data
  const refreshData = useCallback(() => {
    fetchUsers();
    fetchModels();
    fetchPersonas();
  }, [fetchUsers, fetchModels, fetchPersonas]);

  // Initial data fetch
  useEffect(() => {
    refreshData();
  }, [refreshData]);

  const toggleDetail = (panel: DetailPanelType) => {
    setActiveDetail(activeDetail === panel ? null : panel);
  };

  // Check if any data is loading
  const isLoading = loadingUsers || loadingModels || loadingPersonas;

  // Clickable stat card component - always shows gradient like original AdminStatCard
  const ClickableStatCard = ({
    label,
    value,
    change,
    variant,
    panelType,
    isActive
  }: {
    label: string;
    value: string;
    change: string;
    variant: 'primary' | 'secondary' | 'accent' | 'success';
    panelType: DetailPanelType;
    isActive: boolean;
  }) => {
    // Match original AdminStatCard gradient colors
    const getGradient = () => {
      switch (variant) {
        case 'secondary':
          return `linear-gradient(135deg, ${colors.secondary} 0%, ${colors.primary} 100%)`;
        case 'success':
          return `linear-gradient(135deg, ${colors.success} 0%, ${isDark ? '#059669' : '#047857'} 100%)`;
        case 'accent':
          return `linear-gradient(135deg, ${colors.primaryDark} 0%, ${colors.secondary} 100%)`;
        default:
          return `linear-gradient(135deg, ${colors.primary} 0%, ${colors.primaryDark} 100%)`;
      }
    };

    return (
      <button
        onClick={() => toggleDetail(panelType)}
        className={`w-full text-left p-4 rounded-2xl transition-all duration-300 hover:-translate-y-1 relative overflow-hidden`}
        style={{
          background: getGradient(),
          boxShadow: isActive
            ? `0 8px 32px ${isDark ? 'rgba(96, 165, 250, 0.4)' : 'rgba(37, 99, 235, 0.35)'}, 0 0 0 2px rgba(255,255,255,0.5)`
            : `0 8px 32px ${isDark ? 'rgba(96, 165, 250, 0.3)' : 'rgba(37, 99, 235, 0.25)'}`,
        }}
      >
        {/* Decorative circles - always visible */}
        <div className="absolute -top-4 -right-4 w-16 h-16 rounded-full" style={{ background: 'rgba(255,255,255,0.1)' }} />
        <div className="absolute -bottom-6 -left-6 w-20 h-20 rounded-full" style={{ background: 'rgba(255,255,255,0.05)' }} />

        <div className="relative z-10">
          <p className="text-xs font-semibold uppercase tracking-wider text-white/70">
            {label}
          </p>
          <p className="text-xl font-bold mt-2 text-white">
            {value}
          </p>
          <div className="flex items-center gap-2 mt-3">
            <span
              className="text-xs font-medium px-2 py-0.5 rounded-full"
              style={{
                background: 'rgba(255, 255, 255, 0.2)',
                border: '1px solid rgba(255, 255, 255, 0.3)',
                color: '#FFFFFF',
              }}
            >
              {change}
            </span>
            <svg
              className="w-4 h-4 transition-transform"
              style={{
                color: 'rgba(255,255,255,0.7)',
                transform: isActive ? 'rotate(180deg)' : 'rotate(0deg)'
              }}
              fill="none"
              viewBox="0 0 24 24"
              stroke="currentColor"
            >
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 9l-7 7-7-7" />
            </svg>
          </div>
        </div>
      </button>
    );
  };

  // AUM Detail Panel
  const AumDetailPanel = () => (
    <AdminCard padding="lg" className="mt-4">
      <AdminSectionHeader
        title="AUM Breakdown"
        subtitle="Assets Under Management details"
        icon={
          <svg className="w-5 h-5 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
          </svg>
        }
        action={
          <button onClick={() => setActiveDetail(null)} className="p-1 rounded-lg hover:bg-opacity-10" style={{ color: colors.textSecondary }}>
            <svg className="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
            </svg>
          </button>
        }
      />
      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
        {/* By Risk Profile */}
        <div>
          <p className="text-xs font-semibold uppercase tracking-wider mb-3" style={{ color: colors.textTertiary }}>By Risk Profile</p>
          <div className="space-y-2">
            {clientData.byRiskProfile.map((item) => (
              <AdminTintedCard key={item.profile} padding="sm" accentColor={
                item.profile === 'Conservative' ? colors.success :
                item.profile === 'Moderate' ? colors.primary : colors.warning
              }>
                <div className="flex items-center justify-between">
                  <div>
                    <p className="text-sm font-medium" style={{ color: colors.textPrimary }}>{item.profile}</p>
                    <p className="text-xs" style={{ color: colors.textSecondary }}>{item.count.toLocaleString()} clients</p>
                  </div>
                  <div className="text-right">
                    <p className="text-sm font-bold" style={{ color: colors.primary }}>{formatCurrency(item.aum, true)}</p>
                    <p className="text-xs" style={{ color: colors.textTertiary }}>{((item.aum / stats.totalAum) * 100).toFixed(1)}%</p>
                  </div>
                </div>
              </AdminTintedCard>
            ))}
          </div>
        </div>
        {/* Top Advisors by AUM */}
        <div>
          <p className="text-xs font-semibold uppercase tracking-wider mb-3" style={{ color: colors.textTertiary }}>Top Advisors by AUM</p>
          <div className="space-y-2">
            {advisors.slice(0, 4).map((advisor, idx) => (
              <AdminTintedCard key={advisor.id} padding="sm" accentColor={idx === 0 ? colors.warning : colors.primary}>
                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-3">
                    <div
                      className="w-8 h-8 rounded-lg flex items-center justify-center text-white text-xs font-bold"
                      style={{ background: `linear-gradient(135deg, ${colors.primary} 0%, ${colors.primaryDark} 100%)` }}
                    >
                      {advisor.name.split(' ').map(n => n[0]).join('')}
                    </div>
                    <div>
                      <p className="text-sm font-medium" style={{ color: colors.textPrimary }}>{advisor.name}</p>
                      <p className="text-xs" style={{ color: colors.textSecondary }}>{advisor.clientCount} clients</p>
                    </div>
                  </div>
                  <p className="text-sm font-bold" style={{ color: colors.primary }}>{formatCurrency(advisor.aum, true)}</p>
                </div>
              </AdminTintedCard>
            ))}
          </div>
        </div>
      </div>
    </AdminCard>
  );

  // Advisors Detail Panel
  const AdvisorsDetailPanel = () => (
    <AdminCard padding="lg" className="mt-4">
      <AdminSectionHeader
        title="Active Advisors"
        subtitle="Financial advisor performance"
        icon={
          <svg className="w-5 h-5 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d={ICONS.users} />
          </svg>
        }
        action={
          <div className="flex items-center gap-2">
            <Link href="/admin/users" className="text-sm font-medium hover:underline" style={{ color: colors.primary }}>
              Manage Users
            </Link>
            <button onClick={() => setActiveDetail(null)} className="p-1 rounded-lg hover:bg-opacity-10" style={{ color: colors.textSecondary }}>
              <svg className="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
              </svg>
            </button>
          </div>
        }
      />
      <div className="overflow-x-auto">
        <table className="w-full">
          <thead>
            <tr style={{ borderBottom: `1px solid ${colors.cardBorder}` }}>
              <th className="text-left py-3 px-4 text-xs font-semibold uppercase tracking-wider" style={{ color: colors.textTertiary }}>Advisor</th>
              <th className="text-right py-3 px-4 text-xs font-semibold uppercase tracking-wider" style={{ color: colors.textTertiary }}>Clients</th>
              <th className="text-right py-3 px-4 text-xs font-semibold uppercase tracking-wider" style={{ color: colors.textTertiary }}>AUM</th>
              <th className="text-right py-3 px-4 text-xs font-semibold uppercase tracking-wider" style={{ color: colors.textTertiary }}>Returns</th>
              <th className="text-center py-3 px-4 text-xs font-semibold uppercase tracking-wider" style={{ color: colors.textTertiary }}>Status</th>
            </tr>
          </thead>
          <tbody>
            {advisors.map((advisor) => (
              <tr key={advisor.id} className="hover:bg-opacity-50 transition-colors" style={{ borderBottom: `1px solid ${colors.cardBorder}` }}>
                <td className="py-3 px-4">
                  <div className="flex items-center gap-3">
                    <div
                      className="w-10 h-10 rounded-xl flex items-center justify-center text-white text-sm font-bold"
                      style={{ background: `linear-gradient(135deg, ${colors.primary} 0%, ${colors.secondary} 100%)` }}
                    >
                      {advisor.name.split(' ').map(n => n[0]).join('')}
                    </div>
                    <div>
                      <p className="text-sm font-medium" style={{ color: colors.textPrimary }}>{advisor.name}</p>
                      <p className="text-xs" style={{ color: colors.textSecondary }}>{advisor.email}</p>
                    </div>
                  </div>
                </td>
                <td className="py-3 px-4 text-right">
                  <p className="text-sm font-semibold" style={{ color: colors.textPrimary }}>{advisor.clientCount}</p>
                </td>
                <td className="py-3 px-4 text-right">
                  <p className="text-sm font-bold" style={{ color: colors.primary }}>{formatCurrency(advisor.aum, true)}</p>
                </td>
                <td className="py-3 px-4 text-right">
                  <p className="text-sm font-semibold" style={{ color: colors.success }}>+{advisor.returns}%</p>
                </td>
                <td className="py-3 px-4 text-center">
                  <AdminChip color={colors.success} size="xs">{advisor.status}</AdminChip>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </AdminCard>
  );

  // Clients Detail Panel
  const ClientsDetailPanel = () => (
    <AdminCard padding="lg" className="mt-4">
      <AdminSectionHeader
        title="Client Analytics"
        subtitle="Client distribution and recent signups"
        icon={
          <svg className="w-5 h-5 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d={ICONS.user} />
          </svg>
        }
        action={
          <button onClick={() => setActiveDetail(null)} className="p-1 rounded-lg hover:bg-opacity-10" style={{ color: colors.textSecondary }}>
            <svg className="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
            </svg>
          </button>
        }
      />
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        {/* By Status */}
        <div>
          <p className="text-xs font-semibold uppercase tracking-wider mb-3" style={{ color: colors.textTertiary }}>By Status</p>
          <div className="space-y-2">
            {clientData.byStatus.map((item) => (
              <AdminTintedCard key={item.status} padding="sm" accentColor={
                item.status === 'Active' ? colors.success :
                item.status === 'Inactive' ? colors.textTertiary : colors.warning
              }>
                <div className="flex items-center justify-between">
                  <p className="text-sm font-medium" style={{ color: colors.textPrimary }}>{item.status}</p>
                  <p className="text-sm font-bold" style={{ color: colors.textPrimary }}>{item.count.toLocaleString()}</p>
                </div>
                <div className="mt-2 h-2 rounded-full overflow-hidden" style={{ background: colors.progressBg }}>
                  <div
                    className="h-full rounded-full"
                    style={{
                      width: `${(item.count / stats.totalClients) * 100}%`,
                      background: item.status === 'Active' ? colors.success :
                        item.status === 'Inactive' ? colors.textTertiary : colors.warning
                    }}
                  />
                </div>
              </AdminTintedCard>
            ))}
          </div>
        </div>
        {/* By Risk Profile */}
        <div>
          <p className="text-xs font-semibold uppercase tracking-wider mb-3" style={{ color: colors.textTertiary }}>By Risk Profile</p>
          <div className="space-y-2">
            {clientData.byRiskProfile.map((item) => (
              <AdminTintedCard key={item.profile} padding="sm" accentColor={
                item.profile === 'Conservative' ? colors.success :
                item.profile === 'Moderate' ? colors.primary : colors.warning
              }>
                <div className="flex items-center justify-between">
                  <p className="text-sm font-medium" style={{ color: colors.textPrimary }}>{item.profile}</p>
                  <p className="text-sm font-bold" style={{ color: colors.textPrimary }}>{item.count.toLocaleString()}</p>
                </div>
              </AdminTintedCard>
            ))}
          </div>
        </div>
        {/* Recent Signups */}
        <div>
          <p className="text-xs font-semibold uppercase tracking-wider mb-3" style={{ color: colors.textTertiary }}>Recent Signups</p>
          <div className="space-y-2">
            {clientData.recentSignups.map((signup, idx) => (
              <AdminTintedCard key={idx} padding="sm" accentColor={colors.primary}>
                <div className="flex items-center justify-between">
                  <div>
                    <p className="text-sm font-medium" style={{ color: colors.textPrimary }}>{signup.name}</p>
                    <p className="text-xs" style={{ color: colors.textSecondary }}>via {signup.advisor}</p>
                  </div>
                  <div className="text-right">
                    <p className="text-sm font-semibold" style={{ color: colors.primary }}>{formatCurrency(signup.aum, true)}</p>
                    <p className="text-xs" style={{ color: colors.textTertiary }}>{signup.date}</p>
                  </div>
                </div>
              </AdminTintedCard>
            ))}
          </div>
        </div>
      </div>
    </AdminCard>
  );

  // Transactions Detail Panel
  const TransactionsDetailPanel = () => (
    <AdminCard padding="lg" className="mt-4">
      <AdminSectionHeader
        title="Transaction Analytics"
        subtitle="Monthly transaction breakdown"
        icon={
          <svg className="w-5 h-5 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2" />
          </svg>
        }
        action={
          <button onClick={() => setActiveDetail(null)} className="p-1 rounded-lg hover:bg-opacity-10" style={{ color: colors.textSecondary }}>
            <svg className="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
            </svg>
          </button>
        }
      />
      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
        {/* By Type */}
        <div>
          <p className="text-xs font-semibold uppercase tracking-wider mb-3" style={{ color: colors.textTertiary }}>By Transaction Type</p>
          <div className="space-y-2">
            {txnData.byType.map((item) => (
              <AdminTintedCard key={item.type} padding="sm" accentColor={
                item.type === 'SIP' ? colors.primary :
                item.type === 'Lumpsum' ? colors.success :
                item.type === 'Redemption' ? colors.warning : colors.secondary
              }>
                <div className="flex items-center justify-between mb-2">
                  <div className="flex items-center gap-2">
                    <AdminChip color={
                      item.type === 'SIP' ? colors.primary :
                      item.type === 'Lumpsum' ? colors.success :
                      item.type === 'Redemption' ? colors.warning : colors.secondary
                    } size="xs">{item.type}</AdminChip>
                    <span className="text-xs" style={{ color: colors.textSecondary }}>{item.count.toLocaleString()} txns</span>
                  </div>
                  <p className="text-sm font-bold" style={{ color: colors.primary }}>{formatCurrency(item.volume, true)}</p>
                </div>
                <div className="h-2 rounded-full overflow-hidden" style={{ background: colors.progressBg }}>
                  <div
                    className="h-full rounded-full"
                    style={{
                      width: `${(item.volume / stats.monthlyTxnVolume) * 100}%`,
                      background: item.type === 'SIP' ? colors.primary :
                        item.type === 'Lumpsum' ? colors.success :
                        item.type === 'Redemption' ? colors.warning : colors.secondary
                    }}
                  />
                </div>
              </AdminTintedCard>
            ))}
          </div>
        </div>
        {/* Recent Transactions */}
        <div>
          <p className="text-xs font-semibold uppercase tracking-wider mb-3" style={{ color: colors.textTertiary }}>Recent Transactions</p>
          <div className="space-y-2">
            {txnData.recent.map((txn) => (
              <AdminTintedCard key={txn.id} padding="sm" accentColor={
                txn.status === 'Completed' ? colors.success : colors.warning
              }>
                <div className="flex items-center justify-between">
                  <div>
                    <div className="flex items-center gap-2">
                      <p className="text-sm font-medium" style={{ color: colors.textPrimary }}>{txn.client}</p>
                      <AdminChip color={
                        txn.type === 'SIP' ? colors.primary :
                        txn.type === 'Lumpsum' ? colors.success :
                        txn.type === 'Redemption' ? colors.warning : colors.secondary
                      } size="xs">{txn.type}</AdminChip>
                    </div>
                    <p className="text-xs mt-1" style={{ color: colors.textSecondary }}>{txn.fund}</p>
                  </div>
                  <div className="text-right">
                    <p className="text-sm font-bold" style={{ color: txn.type === 'Redemption' ? colors.warning : colors.success }}>
                      {txn.type === 'Redemption' ? '-' : '+'}{formatCurrency(txn.amount)}
                    </p>
                    <AdminChip color={txn.status === 'Completed' ? colors.success : colors.warning} size="xs">{txn.status}</AdminChip>
                  </div>
                </div>
              </AdminTintedCard>
            ))}
          </div>
        </div>
      </div>
    </AdminCard>
  );

  return (
    <AdminLayout title="Dashboard">
      <div style={{ background: colors.background, minHeight: '100%', margin: '-2rem', padding: '2rem' }}>
        {/* Quick Navigation - Gradient Border Cards */}
        <div className="mb-8">
          <h2 className="text-sm font-semibold uppercase tracking-wide mb-4" style={{ color: colors.textSecondary }}>
            Quick Access
          </h2>
          <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-5 gap-3">
            {adminNavItems.map((item, index) => (
              <Link
                key={item.label}
                href={item.href}
                className="group"
              >
                <div
                  className="p-[1px] rounded-2xl transition-all duration-300 group-hover:-translate-y-1"
                  style={{
                    background: index % 2 === 0
                      ? `linear-gradient(135deg, ${colors.primary}50 0%, ${colors.secondary}30 50%, ${colors.accent}20 100%)`
                      : `linear-gradient(135deg, ${colors.secondary}50 0%, ${colors.primary}30 50%, ${colors.accent}20 100%)`
                  }}
                >
                  <div
                    className="p-4 rounded-2xl h-full"
                    style={{
                      background: colors.cardBackground,
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
                  </div>
                </div>
              </Link>
            ))}
          </div>
        </div>

        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
          {/* Main Content */}
          <div className="lg:col-span-2 space-y-6">
            {/* Platform KPIs - Now Clickable */}
            <AdminCard padding="lg">
              <AdminSectionHeader
                title="Platform Overview"
                icon={
                  <svg className="w-5 h-5 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d={ICONS.chart} />
                  </svg>
                }
                action={
                  <div className="flex items-center gap-3">
                    <span className="text-xs" style={{ color: colors.textSecondary }}>Click cards for details</span>
                    <button
                      onClick={refreshData}
                      disabled={isLoading}
                      className="p-1.5 rounded-lg transition-all hover:scale-105 disabled:opacity-50"
                      style={{ background: colors.chipBg }}
                      title="Refresh data"
                    >
                      <svg
                        className={`w-4 h-4 ${isLoading ? 'animate-spin' : ''}`}
                        fill="none"
                        viewBox="0 0 24 24"
                        stroke="currentColor"
                        style={{ color: colors.primary }}
                      >
                        <path
                          strokeLinecap="round"
                          strokeLinejoin="round"
                          strokeWidth={2}
                          d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15"
                        />
                      </svg>
                    </button>
                  </div>
                }
              />
              {loadingUsers ? (
                <div className="flex items-center justify-center py-8">
                  <AdminSpinner size="md" />
                </div>
              ) : errorUsers ? (
                <div className="text-center py-8">
                  <p className="text-sm mb-2" style={{ color: colors.error }}>{errorUsers}</p>
                  <button
                    onClick={fetchUsers}
                    className="text-sm font-medium hover:underline"
                    style={{ color: colors.primary }}
                  >
                    Retry
                  </button>
                </div>
              ) : (
                <div className="grid grid-cols-2 md:grid-cols-4 gap-3">
                  <ClickableStatCard
                    label="TOTAL AUM"
                    value={formatCurrency(stats.totalAum, true)}
                    change={`+${stats.aumChange}%`}
                    variant="primary"
                    panelType="aum"
                    isActive={activeDetail === 'aum'}
                  />
                  <ClickableStatCard
                    label="ACTIVE ADVISORS"
                    value={stats.activeAdvisors.toString()}
                    change={`+${stats.advisorChange}%`}
                    variant="secondary"
                    panelType="advisors"
                    isActive={activeDetail === 'advisors'}
                  />
                  <ClickableStatCard
                    label="TOTAL CLIENTS"
                    value={stats.totalClients.toLocaleString()}
                    change={`+${stats.clientChange}%`}
                    variant="accent"
                    panelType="clients"
                    isActive={activeDetail === 'clients'}
                  />
                  <ClickableStatCard
                    label="MONTHLY TXNS"
                    value={formatCurrency(stats.monthlyTxnVolume, true)}
                    change={`+${stats.txnChange}%`}
                    variant="success"
                    panelType="transactions"
                    isActive={activeDetail === 'transactions'}
                  />
                </div>
              )}
            </AdminCard>

            {/* Detail Panels - Show based on selection */}
            {activeDetail === 'aum' && <AumDetailPanel />}
            {activeDetail === 'advisors' && <AdvisorsDetailPanel />}
            {activeDetail === 'clients' && <ClientsDetailPanel />}
            {activeDetail === 'transactions' && <TransactionsDetailPanel />}

            {/* Model Performance */}
            <AdminCard padding="lg">
              <AdminSectionHeader
                title="Model Performance"
                icon={
                  <svg className="w-5 h-5 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d={ICONS.cpu} />
                  </svg>
                }
                action={
                  <Link href="/admin/ml?tab=models" className="text-sm font-medium hover:underline" style={{ color: colors.primary }}>
                    View Details
                  </Link>
                }
              />
              {loadingModels ? (
                <div className="flex items-center justify-center py-8">
                  <AdminSpinner size="md" />
                </div>
              ) : errorModels ? (
                <div className="text-center py-8">
                  <p className="text-sm mb-2" style={{ color: colors.error }}>{errorModels}</p>
                  <button
                    onClick={fetchModels}
                    className="text-sm font-medium hover:underline"
                    style={{ color: colors.primary }}
                  >
                    Retry
                  </button>
                </div>
              ) : modelDisplayData.length > 0 ? (
                <div className="space-y-3">
                  {modelDisplayData.map((model) => (
                    <AdminTintedCard
                      key={model.name}
                      padding="sm"
                      accentColor={getModelStatusColor(model.status, colors)}
                    >
                      <div className="flex items-center justify-between mb-2">
                        <span className="text-sm font-medium" style={{ color: colors.textPrimary }}>{model.name}</span>
                        <AdminChip
                          color={getModelStatusColor(model.status, colors)}
                          size="xs"
                        >
                          {model.status}
                        </AdminChip>
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
                    </AdminTintedCard>
                  ))}
                </div>
              ) : (
                <div className="text-center py-8">
                  <p className="text-sm" style={{ color: colors.textSecondary }}>No models found</p>
                </div>
              )}
            </AdminCard>

            {/* Recent Activity */}
            <AdminCard padding="lg">
              <AdminSectionHeader
                title="Recent Activity"
                icon={
                  <svg className="w-5 h-5 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
                  </svg>
                }
                action={
                  <button className="text-sm font-medium hover:underline" style={{ color: colors.primary }}>
                    View All
                  </button>
                }
              />
              <div className="space-y-2">
                {[
                  { action: 'New advisor onboarded', detail: 'Rajesh Kumar (Mumbai)', time: '1 hour ago', type: 'user' },
                  { action: 'Model retrained', detail: 'Risk Profiler v2.4', time: '3 hours ago', type: 'model' },
                  { action: 'Fund added to universe', detail: 'HDFC Mid-Cap Opportunities', time: '5 hours ago', type: 'create' },
                  { action: 'Compliance check passed', detail: 'SEBI guidelines validation', time: '1 day ago', type: 'check' },
                  { action: 'Bulk client import', detail: '234 clients by Axis Advisors', time: '1 day ago', type: 'user' },
                ].map((activity, idx) => (
                  <AdminTintedCard
                    key={idx}
                    padding="sm"
                    accentColor={getActivityTypeColor(activity.type, colors)}
                  >
                    <div className="flex items-center gap-3">
                      <div
                        className="w-8 h-8 rounded-xl flex items-center justify-center flex-shrink-0"
                        style={{ background: `${getActivityTypeColor(activity.type, colors)}15` }}
                      >
                        <svg
                          className="w-4 h-4"
                          fill="none"
                          viewBox="0 0 24 24"
                          stroke="currentColor"
                          style={{ color: getActivityTypeColor(activity.type, colors) }}
                        >
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
                  </AdminTintedCard>
                ))}
              </div>
            </AdminCard>
          </div>

          {/* Sidebar */}
          <div className="space-y-6">
            {/* Engine Modules */}
            <AdminCard padding="lg">
              <AdminSectionHeader
                title="Engine Modules"
                subtitle="Model scoring & compliance"
                icon={
                  <svg className="w-5 h-5 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d={ICONS.cpu} />
                  </svg>
                }
              />
              <div className="space-y-2">
                {engineModules.map((module, idx) => (
                  <AdminTintedCard
                    key={module.title}
                    padding="sm"
                    accentColor={idx % 2 === 0 ? colors.primary : colors.secondary}
                  >
                    <p className="text-sm font-medium" style={{ color: colors.textPrimary }}>{module.title}</p>
                    <p className="text-xs mt-1" style={{ color: colors.textSecondary }}>{module.detail}</p>
                  </AdminTintedCard>
                ))}
              </div>
            </AdminCard>

            {/* Persona Library */}
            <AdminCard padding="lg">
              <AdminSectionHeader
                title="Persona Library"
                subtitle="Active personas & biases"
                icon={
                  <svg className="w-5 h-5 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d={ICONS.user} />
                  </svg>
                }
              />
              {loadingPersonas ? (
                <div className="flex items-center justify-center py-8">
                  <AdminSpinner size="md" />
                </div>
              ) : errorPersonas ? (
                <div className="text-center py-8">
                  <p className="text-sm mb-2" style={{ color: colors.error }}>{errorPersonas}</p>
                  <button
                    onClick={fetchPersonas}
                    className="text-sm font-medium hover:underline"
                    style={{ color: colors.primary }}
                  >
                    Retry
                  </button>
                </div>
              ) : personaDisplayData.length > 0 ? (
                <div className="space-y-2">
                  {personaDisplayData.map((persona) => (
                    <AdminTintedCard
                      key={persona.name}
                      padding="sm"
                      accentColor={getRiskBandColor(persona.riskBand, colors)}
                    >
                      <div className="flex items-center justify-between">
                        <p className="text-sm font-medium" style={{ color: colors.textPrimary }}>{persona.name}</p>
                        <AdminChip
                          color={getRiskBandColor(persona.riskBand, colors)}
                          size="xs"
                        >
                          {persona.riskBand}
                        </AdminChip>
                      </div>
                      <p className="text-xs mt-1.5" style={{ color: colors.textSecondary }}>{persona.description}</p>
                    </AdminTintedCard>
                  ))}
                </div>
              ) : (
                <div className="text-center py-8">
                  <p className="text-sm" style={{ color: colors.textSecondary }}>No personas found</p>
                </div>
              )}
            </AdminCard>
          </div>
        </div>
      </div>
    </AdminLayout>
  );
};

export default AdminDashboard;
