import { useState, useEffect, useCallback } from 'react';
import Link from 'next/link';
import AdminLayout from '@/components/layout/AdminLayout';
import {
  AdminCard,
  AdminTintedCard,
  AdminSectionHeader,
  AdminChip,
  AdminSpinner,
} from '@/components/admin/shared';
import {
  useAdminTheme,
  getModelStatusColor,
  getRiskBandColor,
} from '@/utils/adminTheme';
import {
  usersApi,
  modelsApi,
  personasApi,
  SystemUser,
  MlModel,
  Persona,
} from '@/services/api';

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

// Icon paths - 'fill' type icons use fill="currentColor", 'stroke' type use stroke
const ICONS: Record<string, { d: string; type: 'fill' | 'stroke' }> = {
  chart: { d: 'M11 3.055A9.001 9.001 0 1020.945 13H11V3.055z M20.488 9H15V3.512A9.025 9.025 0 0120.488 9z', type: 'fill' },
  cpu: { d: 'M9 3v2m6-2v2M9 19v2m6-2v2M5 9H3m2 6H3m18-6h-2m2 6h-2M7 19h10a2 2 0 002-2V7a2 2 0 00-2-2H7a2 2 0 00-2 2v10a2 2 0 002 2zM9 9h6v6H9V9z', type: 'stroke' },
  users: { d: 'M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197M13 7a4 4 0 11-8 0 4 4 0 018 0z', type: 'stroke' },
  user: { d: 'M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z', type: 'stroke' },
  arrowRight: { d: 'M13.5 4.5L21 12m0 0l-7.5 7.5M21 12H3', type: 'stroke' },
};

const AdminDashboard = () => {
  const { colors, isDark } = useAdminTheme();

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

  // Derived data
  const advisors = users.filter(u => u.role === 'advisor');
  const clients = users.filter(u => u.role === 'client' || u.role === 'user');
  const activeAdvisors = advisors.filter(u => u.isActive);
  const activeClients = clients.filter(u => u.isActive);

  // Model display data from API
  const modelDisplayData: ModelDisplay[] = models.map(m => ({
    name: m.name,
    accuracy: m.productionVersion?.metrics?.accuracy || 0,
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

  // Check if any data is loading
  const isLoading = loadingUsers || loadingModels || loadingPersonas;

  // Format date for display
  const formatDate = (dateStr: string) => {
    const d = new Date(dateStr);
    return d.toLocaleDateString('en-IN', { day: '2-digit', month: 'short', year: 'numeric' });
  };

  // Format relative time
  const formatRelativeTime = (dateStr: string | null) => {
    if (!dateStr) return 'Never';
    const d = new Date(dateStr);
    const now = new Date();
    const diffMs = now.getTime() - d.getTime();
    const diffMins = Math.floor(diffMs / 60000);
    if (diffMins < 1) return 'Just now';
    if (diffMins < 60) return `${diffMins}m ago`;
    const diffHours = Math.floor(diffMins / 60);
    if (diffHours < 24) return `${diffHours}h ago`;
    const diffDays = Math.floor(diffHours / 24);
    if (diffDays < 30) return `${diffDays}d ago`;
    return formatDate(dateStr);
  };

  return (
    <AdminLayout title="Dashboard">
      <div style={{ background: colors.background, minHeight: '100%', margin: '-2rem', padding: '2rem' }}>
        {/* Platform KPIs */}
        <div className="grid grid-cols-2 md:grid-cols-4 gap-4 mb-6">
          {[
            {
              label: 'Active Advisors',
              value: loadingUsers ? '—' : activeAdvisors.length.toString(),
              total: loadingUsers ? '' : `${advisors.length} total`,
              variant: 'primary' as const,
              icon: ICONS.users.d,
              iconType: ICONS.users.type,
            },
            {
              label: 'Total Clients',
              value: loadingUsers ? '—' : clients.length.toString(),
              total: loadingUsers ? '' : `${activeClients.length} active`,
              variant: 'secondary' as const,
              icon: ICONS.user.d,
              iconType: ICONS.user.type,
            },
            {
              label: 'ML Models',
              value: loadingModels ? '—' : models.length.toString(),
              total: loadingModels ? '' : `${models.filter(m => m.productionVersion?.status === 'active').length} active`,
              variant: 'accent' as const,
              icon: ICONS.cpu.d,
              iconType: ICONS.cpu.type,
            },
            {
              label: 'Personas',
              value: loadingPersonas ? '—' : personas.length.toString(),
              total: loadingPersonas ? '' : `${personas.filter(p => p.isActive).length} active`,
              variant: 'success' as const,
              icon: ICONS.chart.d,
              iconType: ICONS.chart.type,
            },
          ].map((stat) => {
            const getGradient = () => {
              switch (stat.variant) {
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
              <div
                key={stat.label}
                className="p-4 rounded-2xl relative overflow-hidden"
                style={{
                  background: getGradient(),
                  boxShadow: `0 8px 32px ${isDark ? 'rgba(96, 165, 250, 0.3)' : 'rgba(37, 99, 235, 0.25)'}`,
                }}
              >
                <div className="absolute -top-4 -right-4 w-16 h-16 rounded-full" style={{ background: 'rgba(255,255,255,0.1)' }} />
                <div className="absolute -bottom-6 -left-6 w-20 h-20 rounded-full" style={{ background: 'rgba(255,255,255,0.05)' }} />
                <div className="relative z-10">
                  <div className="flex items-center gap-2 mb-2">
                    <div className="w-9 h-9 rounded-lg flex items-center justify-center" style={{ background: 'rgba(255,255,255,0.25)' }}>
                      <svg className="w-5 h-5 text-white" viewBox="0 0 24 24"
                        fill={stat.iconType === 'fill' ? 'currentColor' : 'none'}
                        stroke={stat.iconType === 'stroke' ? 'currentColor' : 'none'}
                      >
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={stat.iconType === 'stroke' ? 2 : 0} d={stat.icon} />
                      </svg>
                    </div>
                    <p className="text-xs font-semibold uppercase tracking-wider text-white/70">
                      {stat.label}
                    </p>
                  </div>
                  <p className="text-2xl font-bold text-white">{stat.value}</p>
                  {stat.total && (
                    <p className="text-xs text-white/60 mt-1">{stat.total}</p>
                  )}
                </div>
              </div>
            );
          })}
        </div>

        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
          {/* Main Content */}
          <div className="lg:col-span-2 space-y-6">
            {/* Top Advisors */}
            <AdminCard padding="lg">
              <AdminSectionHeader
                title="Top Advisors"
                subtitle="Financial advisors on the platform"
                icon={
                  <svg className="w-5 h-5 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d={ICONS.users.d} />
                  </svg>
                }
                action={
                  <div className="flex items-center gap-3">
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
                    <Link
                      href="/admin/overview?tab=advisors"
                      className="flex items-center gap-1.5 text-sm font-medium hover:underline"
                      style={{ color: colors.primary }}
                    >
                      View All
                      <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d={ICONS.arrowRight.d} />
                      </svg>
                    </Link>
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
              ) : advisors.length > 0 ? (
                <div className="overflow-x-auto">
                  <table className="w-full">
                    <thead>
                      <tr style={{ background: `${colors.primary}08` }}>
                        <th className="text-left py-3 px-4 text-xs font-semibold uppercase tracking-wide" style={{ color: colors.primary }}>Advisor</th>
                        <th className="text-left py-3 px-4 text-xs font-semibold uppercase tracking-wide" style={{ color: colors.primary }}>Status</th>
                        <th className="text-left py-3 px-4 text-xs font-semibold uppercase tracking-wide" style={{ color: colors.primary }}>Last Login</th>
                        <th className="text-left py-3 px-4 text-xs font-semibold uppercase tracking-wide" style={{ color: colors.primary }}>Joined</th>
                      </tr>
                    </thead>
                    <tbody>
                      {advisors
                        .sort((a, b) => {
                          // Active first, then by most recent login
                          if (a.isActive !== b.isActive) return a.isActive ? -1 : 1;
                          const aLogin = a.lastLoginAt ? new Date(a.lastLoginAt).getTime() : 0;
                          const bLogin = b.lastLoginAt ? new Date(b.lastLoginAt).getTime() : 0;
                          return bLogin - aLogin;
                        })
                        .slice(0, 5)
                        .map((advisor, idx) => (
                          <tr
                            key={advisor.id}
                            className="transition-all"
                            style={{
                              background: 'transparent',
                              borderBottom: `1px solid ${colors.cardBorder}`,
                            }}
                            onMouseEnter={(e) => e.currentTarget.style.background = colors.chipBg}
                            onMouseLeave={(e) => e.currentTarget.style.background = 'transparent'}
                          >
                            <td className="py-3 px-4">
                              <div className="flex items-center gap-3">
                                <div
                                  className="w-9 h-9 rounded-xl flex items-center justify-center text-white text-xs font-bold flex-shrink-0"
                                  style={{ background: `linear-gradient(135deg, ${colors.primary} 0%, ${colors.primaryDark} 100%)` }}
                                >
                                  {(advisor.profile?.name || advisor.email.split('@')[0])
                                    .split(' ')
                                    .map((n: string) => n[0])
                                    .join('')
                                    .slice(0, 2)
                                    .toUpperCase()}
                                </div>
                                <div>
                                  <p className="text-sm font-medium" style={{ color: colors.textPrimary }}>
                                    {advisor.profile?.name || advisor.email.split('@')[0]}
                                  </p>
                                  <p className="text-xs" style={{ color: colors.textSecondary }}>{advisor.email}</p>
                                </div>
                              </div>
                            </td>
                            <td className="py-3 px-4">
                              <AdminChip
                                color={advisor.isActive ? colors.success : colors.textTertiary}
                                size="xs"
                              >
                                {advisor.isActive ? 'Active' : 'Inactive'}
                              </AdminChip>
                            </td>
                            <td className="py-3 px-4">
                              <p className="text-sm" style={{ color: colors.textSecondary }}>
                                {formatRelativeTime(advisor.lastLoginAt)}
                              </p>
                            </td>
                            <td className="py-3 px-4">
                              <p className="text-sm" style={{ color: colors.textSecondary }}>
                                {formatDate(advisor.createdAt)}
                              </p>
                            </td>
                          </tr>
                        ))}
                    </tbody>
                  </table>
                </div>
              ) : (
                <div className="text-center py-8">
                  <p className="text-sm" style={{ color: colors.textSecondary }}>No advisors found</p>
                </div>
              )}
            </AdminCard>

            {/* Self-Service Customers */}
            <AdminCard padding="lg">
              <AdminSectionHeader
                title="Self-Service Customers"
                subtitle="Clients not managed by an advisor"
                icon={
                  <svg className="w-5 h-5 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d={ICONS.user.d} />
                  </svg>
                }
                action={
                  <Link
                    href="/admin/overview?tab=self-service"
                    className="flex items-center gap-1.5 text-sm font-medium hover:underline"
                    style={{ color: colors.primary }}
                  >
                    View All
                    <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d={ICONS.arrowRight.d} />
                    </svg>
                  </Link>
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
              ) : clients.length > 0 ? (
                <div className="overflow-x-auto">
                  <table className="w-full">
                    <thead>
                      <tr style={{ background: `${colors.primary}08` }}>
                        <th className="text-left py-3 px-4 text-xs font-semibold uppercase tracking-wide" style={{ color: colors.primary }}>Customer</th>
                        <th className="text-left py-3 px-4 text-xs font-semibold uppercase tracking-wide" style={{ color: colors.primary }}>Status</th>
                        <th className="text-left py-3 px-4 text-xs font-semibold uppercase tracking-wide" style={{ color: colors.primary }}>Verified</th>
                        <th className="text-left py-3 px-4 text-xs font-semibold uppercase tracking-wide" style={{ color: colors.primary }}>Joined</th>
                      </tr>
                    </thead>
                    <tbody>
                      {clients
                        .sort((a, b) => new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime())
                        .slice(0, 5)
                        .map((client, idx) => (
                          <tr
                            key={client.id}
                            className="transition-all"
                            style={{
                              background: 'transparent',
                              borderBottom: `1px solid ${colors.cardBorder}`,
                            }}
                            onMouseEnter={(e) => e.currentTarget.style.background = colors.chipBg}
                            onMouseLeave={(e) => e.currentTarget.style.background = 'transparent'}
                          >
                            <td className="py-3 px-4">
                              <div className="flex items-center gap-3">
                                <div
                                  className="w-9 h-9 rounded-xl flex items-center justify-center text-white text-xs font-bold flex-shrink-0"
                                  style={{ background: `linear-gradient(135deg, ${colors.secondary} 0%, ${colors.primary} 100%)` }}
                                >
                                  {(client.profile?.name || client.email.split('@')[0])
                                    .split(' ')
                                    .map((n: string) => n[0])
                                    .join('')
                                    .slice(0, 2)
                                    .toUpperCase()}
                                </div>
                                <div>
                                  <p className="text-sm font-medium" style={{ color: colors.textPrimary }}>
                                    {client.profile?.name || client.email.split('@')[0]}
                                  </p>
                                  <p className="text-xs" style={{ color: colors.textSecondary }}>{client.email}</p>
                                </div>
                              </div>
                            </td>
                            <td className="py-3 px-4">
                              <AdminChip
                                color={client.isActive ? colors.success : colors.textTertiary}
                                size="xs"
                              >
                                {client.isActive ? 'Active' : 'Inactive'}
                              </AdminChip>
                            </td>
                            <td className="py-3 px-4">
                              <AdminChip
                                color={client.isVerified ? colors.success : colors.warning}
                                size="xs"
                              >
                                {client.isVerified ? 'Verified' : 'Pending'}
                              </AdminChip>
                            </td>
                            <td className="py-3 px-4">
                              <p className="text-sm" style={{ color: colors.textSecondary }}>
                                {formatDate(client.createdAt)}
                              </p>
                            </td>
                          </tr>
                        ))}
                    </tbody>
                  </table>
                </div>
              ) : (
                <div className="text-center py-8">
                  <p className="text-sm" style={{ color: colors.textSecondary }}>No customers found</p>
                </div>
              )}
            </AdminCard>

            {/* Model Performance */}
            <AdminCard padding="lg">
              <AdminSectionHeader
                title="Model Performance"
                icon={
                  <svg className="w-5 h-5 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d={ICONS.cpu.d} />
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
          </div>

          {/* Sidebar */}
          <div className="space-y-6">
            {/* Persona Library */}
            <AdminCard padding="lg">
              <AdminSectionHeader
                title="Persona Library"
                subtitle="Active personas & biases"
                icon={
                  <svg className="w-5 h-5 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d={ICONS.user.d} />
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
