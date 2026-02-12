import { useState, useEffect, useCallback, useMemo } from 'react';
import { useRouter } from 'next/router';
import AdminLayout from '@/components/layout/AdminLayout';
import {
  AdminCard,
  AdminSectionHeader,
  AdminChip,
  AdminSpinner,
  AdminPagination,
} from '@/components/admin/shared';
import { useAdminTheme } from '@/utils/adminTheme';
import {
  usersApi,
  personasApi,
  SystemUser,
  ClassificationStats,
} from '@/services/api';

// Tab definitions
const TABS = [
  { id: 'advisors', label: 'Advisors' },
  { id: 'self-service', label: 'Self-Service' },
  { id: 'all-users', label: 'All Users' },
  { id: 'classifications', label: 'Classifications' },
] as const;

type TabId = typeof TABS[number]['id'];

// Icon paths
const ICONS = {
  search: 'M21 21l-5.197-5.197m0 0A7.5 7.5 0 105.196 5.196a7.5 7.5 0 0010.607 10.607z',
  users: 'M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197M13 7a4 4 0 11-8 0 4 4 0 018 0z',
  user: 'M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z',
};

const AdminOverview = () => {
  const router = useRouter();
  const { colors, isDark } = useAdminTheme();

  // Active tab from URL query
  const activeTab = (router.query.tab as TabId) || 'advisors';

  // Data
  const [users, setUsers] = useState<SystemUser[]>([]);
  const [classificationStats, setClassificationStats] = useState<ClassificationStats | null>(null);
  const [loadingUsers, setLoadingUsers] = useState(true);
  const [loadingClassifications, setLoadingClassifications] = useState(true);
  const [errorUsers, setErrorUsers] = useState<string | null>(null);
  const [errorClassifications, setErrorClassifications] = useState<string | null>(null);

  // Search & pagination
  const [search, setSearch] = useState('');
  const [currentPage, setCurrentPage] = useState(1);
  const [itemsPerPage, setItemsPerPage] = useState(10);

  // Reset pagination on tab or search change
  useEffect(() => {
    setCurrentPage(1);
  }, [activeTab, search]);

  // Fetch data
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

  const fetchClassifications = useCallback(async () => {
    setLoadingClassifications(true);
    setErrorClassifications(null);
    try {
      const data = await personasApi.getClassificationStats();
      setClassificationStats(data);
    } catch (err) {
      setErrorClassifications(err instanceof Error ? err.message : 'Failed to load classifications');
    } finally {
      setLoadingClassifications(false);
    }
  }, []);

  useEffect(() => {
    fetchUsers();
    fetchClassifications();
  }, [fetchUsers, fetchClassifications]);

  // Tab switching
  const setActiveTab = (tab: TabId) => {
    router.push({ pathname: '/admin/overview', query: { tab } }, undefined, { shallow: true });
  };

  // Filtered users based on tab and search
  const filteredUsers = useMemo(() => {
    let filtered = users;

    // Filter by tab
    switch (activeTab) {
      case 'advisors':
        filtered = filtered.filter(u => u.role === 'advisor');
        break;
      case 'self-service':
        filtered = filtered.filter(u => u.role === 'client' || u.role === 'user');
        break;
      case 'all-users':
        // No filter
        break;
      case 'classifications':
        return []; // Classifications tab doesn't show users table
    }

    // Search filter
    if (search.trim()) {
      const q = search.toLowerCase();
      filtered = filtered.filter(u =>
        u.email.toLowerCase().includes(q) ||
        (u.profile?.name || '').toLowerCase().includes(q) ||
        u.role.toLowerCase().includes(q)
      );
    }

    return filtered;
  }, [users, activeTab, search]);

  // Pagination
  const totalPages = Math.ceil(filteredUsers.length / itemsPerPage);
  const paginatedUsers = filteredUsers.slice(
    (currentPage - 1) * itemsPerPage,
    currentPage * itemsPerPage
  );

  // Format helpers
  const formatDate = (dateStr: string) => {
    const d = new Date(dateStr);
    return d.toLocaleDateString('en-IN', { day: '2-digit', month: 'short', year: 'numeric' });
  };

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

  const getRoleColor = (role: string) => {
    switch (role) {
      case 'admin': return colors.error;
      case 'advisor': return colors.primary;
      case 'client':
      case 'user': return colors.secondary;
      default: return colors.textTertiary;
    }
  };

  // Tab-specific title/subtitle
  const getTabHeader = () => {
    switch (activeTab) {
      case 'advisors':
        return { title: 'Financial Advisors', subtitle: `${filteredUsers.length} advisor${filteredUsers.length !== 1 ? 's' : ''} on the platform`, icon: ICONS.users };
      case 'self-service':
        return { title: 'Self-Service Customers', subtitle: `${filteredUsers.length} self-service customer${filteredUsers.length !== 1 ? 's' : ''}`, icon: ICONS.user };
      case 'all-users':
        return { title: 'All Users', subtitle: `${filteredUsers.length} user${filteredUsers.length !== 1 ? 's' : ''} total`, icon: ICONS.users };
      case 'classifications':
        return { title: 'Classification Analytics', subtitle: 'Persona classification breakdown', icon: ICONS.user };
    }
  };

  const header = getTabHeader();

  return (
    <AdminLayout title="Overview">
      <div style={{ background: colors.background, minHeight: '100%', margin: '-2rem', padding: '2rem' }}>
        {/* Tabs */}
        <div className="flex items-center gap-1 mb-6 p-1 rounded-xl" style={{ background: colors.backgroundTertiary }}>
          {TABS.map((tab) => (
            <button
              key={tab.id}
              onClick={() => setActiveTab(tab.id)}
              className="flex-1 px-4 py-2.5 rounded-lg text-sm font-medium transition-all"
              style={{
                background: activeTab === tab.id
                  ? `linear-gradient(135deg, ${colors.primary} 0%, ${colors.primaryDark} 100%)`
                  : 'transparent',
                color: activeTab === tab.id ? '#FFFFFF' : colors.textSecondary,
                boxShadow: activeTab === tab.id ? `0 4px 12px ${colors.glassShadow}` : 'none',
              }}
            >
              {tab.label}
            </button>
          ))}
        </div>

        {/* Content */}
        <AdminCard padding="lg">
          <AdminSectionHeader
            title={header.title}
            subtitle={header.subtitle}
            icon={
              <svg className="w-5 h-5 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d={header.icon} />
              </svg>
            }
          />

          {/* Classifications tab */}
          {activeTab === 'classifications' ? (
            loadingClassifications ? (
              <div className="flex items-center justify-center py-12">
                <AdminSpinner size="md" />
              </div>
            ) : errorClassifications ? (
              <div className="text-center py-12">
                <p className="text-sm mb-2" style={{ color: colors.error }}>{errorClassifications}</p>
                <button
                  onClick={fetchClassifications}
                  className="text-sm font-medium hover:underline"
                  style={{ color: colors.primary }}
                >
                  Retry
                </button>
              </div>
            ) : classificationStats ? (
              <div className="space-y-6">
                {/* Summary stats */}
                <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                  <div
                    className="p-4 rounded-xl"
                    style={{
                      background: `linear-gradient(135deg, ${colors.primary}08 0%, ${colors.primary}03 100%)`,
                      border: `1px solid ${colors.cardBorder}`,
                    }}
                  >
                    <p className="text-xs font-semibold uppercase tracking-wide mb-1" style={{ color: colors.primary }}>
                      Total Classifications
                    </p>
                    <p className="text-2xl font-bold" style={{ color: colors.textPrimary }}>
                      {classificationStats.totalClassifications}
                    </p>
                  </div>
                  <div
                    className="p-4 rounded-xl"
                    style={{
                      background: `linear-gradient(135deg, ${colors.secondary}08 0%, ${colors.secondary}03 100%)`,
                      border: `1px solid ${colors.cardBorder}`,
                    }}
                  >
                    <p className="text-xs font-semibold uppercase tracking-wide mb-1" style={{ color: colors.secondary }}>
                      Persona Types
                    </p>
                    <p className="text-2xl font-bold" style={{ color: colors.textPrimary }}>
                      {classificationStats.personas.length}
                    </p>
                  </div>
                </div>

                {/* Persona breakdown */}
                {classificationStats.personas.length > 0 && (
                  <div>
                    <p className="text-xs font-semibold uppercase tracking-wide mb-3" style={{ color: colors.textTertiary }}>
                      Persona Breakdown
                    </p>
                    <div className="overflow-x-auto">
                      <table className="w-full">
                        <thead>
                          <tr style={{ background: `${colors.primary}08` }}>
                            <th className="text-left py-3 px-4 text-xs font-semibold uppercase tracking-wide" style={{ color: colors.primary }}>Persona</th>
                            <th className="text-left py-3 px-4 text-xs font-semibold uppercase tracking-wide" style={{ color: colors.primary }}>Slug</th>
                            <th className="text-right py-3 px-4 text-xs font-semibold uppercase tracking-wide" style={{ color: colors.primary }}>Users</th>
                            <th className="text-right py-3 px-4 text-xs font-semibold uppercase tracking-wide" style={{ color: colors.primary }}>Share</th>
                          </tr>
                        </thead>
                        <tbody>
                          {classificationStats.personas
                            .sort((a, b) => b.userCount - a.userCount)
                            .map((item, idx) => {
                              const pct = classificationStats.totalClassifications > 0
                                ? (item.userCount / classificationStats.totalClassifications) * 100
                                : 0;
                              return (
                                <tr
                                  key={item.id}
                                  className="transition-all"
                                  style={{
                                    background: 'transparent',
                                    borderBottom: `1px solid ${colors.cardBorder}`,
                                  }}
                                  onMouseEnter={(e) => e.currentTarget.style.background = colors.chipBg}
                                  onMouseLeave={(e) => e.currentTarget.style.background = 'transparent'}
                                >
                                  <td className="py-3 px-4">
                                    <p className="text-sm font-medium" style={{ color: colors.textPrimary }}>{item.name}</p>
                                  </td>
                                  <td className="py-3 px-4">
                                    <AdminChip color={colors.primary} size="xs">{item.slug}</AdminChip>
                                  </td>
                                  <td className="py-3 px-4 text-right">
                                    <p className="text-sm font-semibold" style={{ color: colors.textPrimary }}>{item.userCount}</p>
                                  </td>
                                  <td className="py-3 px-4 text-right">
                                    <div className="flex items-center justify-end gap-2">
                                      <div className="w-16 h-1.5 rounded-full overflow-hidden" style={{ background: colors.progressBg }}>
                                        <div className="h-full rounded-full" style={{ width: `${pct}%`, background: colors.primary }} />
                                      </div>
                                      <p className="text-sm font-medium w-12 text-right" style={{ color: colors.primary }}>
                                        {pct.toFixed(1)}%
                                      </p>
                                    </div>
                                  </td>
                                </tr>
                              );
                            })}
                        </tbody>
                      </table>
                    </div>
                  </div>
                )}
              </div>
            ) : (
              <div className="text-center py-12">
                <p className="text-sm" style={{ color: colors.textSecondary }}>No classification data available</p>
              </div>
            )
          ) : (
            /* Users tabs (advisors, self-service, all-users) */
            <>
              {/* Search */}
              <div className="mb-4">
                <div className="relative">
                  <svg
                    className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4"
                    fill="none"
                    viewBox="0 0 24 24"
                    stroke="currentColor"
                    style={{ color: colors.textTertiary }}
                  >
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d={ICONS.search} />
                  </svg>
                  <input
                    type="text"
                    placeholder={`Search ${activeTab === 'advisors' ? 'advisors' : activeTab === 'self-service' ? 'customers' : 'users'}...`}
                    value={search}
                    onChange={(e) => setSearch(e.target.value)}
                    className="w-full h-10 pl-10 pr-4 rounded-xl text-sm transition-all focus:outline-none"
                    style={{
                      background: colors.inputBg,
                      border: `1px solid ${colors.inputBorder}`,
                      color: colors.textPrimary,
                    }}
                  />
                </div>
              </div>

              {/* Table */}
              {loadingUsers ? (
                <div className="flex items-center justify-center py-12">
                  <AdminSpinner size="md" />
                </div>
              ) : errorUsers ? (
                <div className="text-center py-12">
                  <p className="text-sm mb-2" style={{ color: colors.error }}>{errorUsers}</p>
                  <button
                    onClick={fetchUsers}
                    className="text-sm font-medium hover:underline"
                    style={{ color: colors.primary }}
                  >
                    Retry
                  </button>
                </div>
              ) : paginatedUsers.length > 0 ? (
                <>
                  <div className="overflow-x-auto">
                    <table className="w-full">
                      <thead>
                        <tr style={{ background: `${colors.primary}08` }}>
                          <th className="text-left py-3 px-4 text-xs font-semibold uppercase tracking-wide" style={{ color: colors.primary }}>User</th>
                          {activeTab === 'all-users' && (
                            <th className="text-left py-3 px-4 text-xs font-semibold uppercase tracking-wide" style={{ color: colors.primary }}>Role</th>
                          )}
                          <th className="text-left py-3 px-4 text-xs font-semibold uppercase tracking-wide" style={{ color: colors.primary }}>Status</th>
                          <th className="text-left py-3 px-4 text-xs font-semibold uppercase tracking-wide" style={{ color: colors.primary }}>Verified</th>
                          <th className="text-left py-3 px-4 text-xs font-semibold uppercase tracking-wide" style={{ color: colors.primary }}>Last Login</th>
                          <th className="text-left py-3 px-4 text-xs font-semibold uppercase tracking-wide" style={{ color: colors.primary }}>Joined</th>
                        </tr>
                      </thead>
                      <tbody>
                        {paginatedUsers.map((user, idx) => (
                          <tr
                            key={user.id}
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
                                  style={{
                                    background: `linear-gradient(135deg, ${getRoleColor(user.role)} 0%, ${colors.primaryDark} 100%)`,
                                  }}
                                >
                                  {(user.profile?.name || user.email.split('@')[0])
                                    .split(' ')
                                    .map((n: string) => n[0])
                                    .join('')
                                    .slice(0, 2)
                                    .toUpperCase()}
                                </div>
                                <div>
                                  <p className="text-sm font-medium" style={{ color: colors.textPrimary }}>
                                    {user.profile?.name || user.email.split('@')[0]}
                                  </p>
                                  <p className="text-xs" style={{ color: colors.textSecondary }}>{user.email}</p>
                                </div>
                              </div>
                            </td>
                            {activeTab === 'all-users' && (
                              <td className="py-3 px-4">
                                <AdminChip color={getRoleColor(user.role)} size="xs">
                                  {user.role}
                                </AdminChip>
                              </td>
                            )}
                            <td className="py-3 px-4">
                              <AdminChip
                                color={user.isActive ? colors.success : colors.textTertiary}
                                size="xs"
                              >
                                {user.isActive ? 'Active' : 'Inactive'}
                              </AdminChip>
                            </td>
                            <td className="py-3 px-4">
                              <AdminChip
                                color={user.isVerified ? colors.success : colors.warning}
                                size="xs"
                              >
                                {user.isVerified ? 'Verified' : 'Pending'}
                              </AdminChip>
                            </td>
                            <td className="py-3 px-4">
                              <p className="text-sm" style={{ color: colors.textSecondary }}>
                                {formatRelativeTime(user.lastLoginAt)}
                              </p>
                            </td>
                            <td className="py-3 px-4">
                              <p className="text-sm" style={{ color: colors.textSecondary }}>
                                {formatDate(user.createdAt)}
                              </p>
                            </td>
                          </tr>
                        ))}
                      </tbody>
                    </table>
                  </div>

                  {/* Pagination */}
                  <div className="mt-4">
                    <AdminPagination
                      currentPage={currentPage}
                      totalPages={totalPages}
                      totalItems={filteredUsers.length}
                      itemsPerPage={itemsPerPage}
                      onPageChange={setCurrentPage}
                      onItemsPerPageChange={(newSize) => {
                        setItemsPerPage(newSize);
                        setCurrentPage(1);
                      }}
                      itemsPerPageOptions={[10, 25, 50]}
                    />
                  </div>
                </>
              ) : (
                <div className="text-center py-12">
                  <p className="text-sm" style={{ color: colors.textSecondary }}>
                    {search ? 'No results match your search' : 'No users found'}
                  </p>
                </div>
              )}
            </>
          )}
        </AdminCard>
      </div>
    </AdminLayout>
  );
};

export default AdminOverview;
