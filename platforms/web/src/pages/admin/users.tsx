import { useState, useEffect, useMemo, useCallback } from 'react';
import AdminLayout from '@/components/layout/AdminLayout';
import { AdminModal } from '@/components/admin/shared';
import { usersApi, SystemUser, CreateUserRequest, UpdateUserRequest } from '@/services/api';
import { useAdminColors, useDarkMode } from '@/utils/useAdminColors';
import {
  exportToCSV,
  exportToJSON,
  userExportColumns,
  transformUserForExport,
  UserExportRow,
} from '@/utils/exportUtils';

// Role badge colors
const getRoleBadge = (role: string, colors: ReturnType<typeof useAdminColors>, isDark: boolean) => {
  switch (role.toLowerCase()) {
    case 'super_admin':
      return {
        bg: isDark ? 'rgba(168, 85, 247, 0.15)' : 'rgba(147, 51, 234, 0.1)',
        color: '#A855F7',
        label: 'Super Admin',
      };
    case 'admin':
      return {
        bg: isDark ? 'rgba(248, 113, 113, 0.15)' : 'rgba(239, 68, 68, 0.1)',
        color: colors.error,
        label: 'Admin',
      };
    case 'advisor':
    case 'fa':
      return {
        bg: isDark ? 'rgba(96, 165, 250, 0.15)' : 'rgba(37, 99, 235, 0.1)',
        color: colors.primary,
        label: 'Financial Advisor',
      };
    case 'client':
    case 'user':
      return {
        bg: isDark ? 'rgba(52, 211, 153, 0.15)' : 'rgba(16, 185, 129, 0.1)',
        color: colors.success,
        label: role === 'client' ? 'Client' : 'User',
      };
    default:
      return {
        bg: colors.chipBg,
        color: colors.textSecondary,
        label: role,
      };
  }
};

const UsersPage = () => {
  const colors = useAdminColors();
  const isDark = useDarkMode();

  // Data state
  const [users, setUsers] = useState<SystemUser[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [successMessage, setSuccessMessage] = useState<string | null>(null);

  // Modal state
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [isCreateMode, setIsCreateMode] = useState(false);
  const [selectedUser, setSelectedUser] = useState<SystemUser | null>(null);

  // Password reset modal
  const [isResetModalOpen, setIsResetModalOpen] = useState(false);
  const [resetUserId, setResetUserId] = useState<string | null>(null);
  const [newPassword, setNewPassword] = useState('');

  // Form state
  const [formData, setFormData] = useState({
    email: '',
    password: '',
    name: '',
    role: 'user',
    phone: '',
  });

  // Tab state
  type UserTab = 'all' | 'admin' | 'advisor' | 'client';
  const [activeTab, setActiveTab] = useState<UserTab>('all');

  // Search/Filter state
  const [searchTerm, setSearchTerm] = useState('');
  const [filterStatus, setFilterStatus] = useState<string>('all');

  // Pagination state
  const [currentPage, setCurrentPage] = useState(1);
  const [itemsPerPage, setItemsPerPage] = useState(10);

  // Bulk selection state
  const [selectedUserIds, setSelectedUserIds] = useState<Set<string>>(new Set());

  // Load users on mount
  useEffect(() => {
    loadUsers();
  }, []);

  const loadUsers = async () => {
    setLoading(true);
    setError(null);
    try {
      const data = await usersApi.getAll();
      setUsers(data);
    } catch (err: any) {
      setError(err.message || 'Failed to load users');
    } finally {
      setLoading(false);
    }
  };

  // Helper function to match user role to tab
  const matchesTab = (user: SystemUser, tab: UserTab): boolean => {
    if (tab === 'all') return true;
    const role = user.role.toLowerCase();
    if (tab === 'admin') return role === 'admin' || role === 'super_admin';
    if (tab === 'advisor') return role === 'advisor' || role === 'fa';
    if (tab === 'client') return role === 'client' || role === 'user';
    return false;
  };

  // Filtered users
  const filteredUsers = useMemo(() => {
    return users.filter((user) => {
      const matchesSearch =
        user.email.toLowerCase().includes(searchTerm.toLowerCase()) ||
        (user.profile?.name || '').toLowerCase().includes(searchTerm.toLowerCase());
      const matchesRole = matchesTab(user, activeTab);
      const matchesStatus =
        filterStatus === 'all' ||
        (filterStatus === 'active' && user.isActive) ||
        (filterStatus === 'inactive' && !user.isActive);
      return matchesSearch && matchesRole && matchesStatus;
    });
  }, [users, searchTerm, activeTab, filterStatus]);

  // Reset to page 1 and clear selection when filters change
  useEffect(() => {
    setCurrentPage(1);
    setSelectedUserIds(new Set());
  }, [searchTerm, activeTab, filterStatus]);

  // Pagination calculations
  const totalPages = Math.ceil(filteredUsers.length / itemsPerPage);
  const startIndex = (currentPage - 1) * itemsPerPage;
  const endIndex = startIndex + itemsPerPage;
  const paginatedUsers = filteredUsers.slice(startIndex, endIndex);

  // KPI calculations
  const kpis = useMemo(() => {
    const totalUsers = users.length;
    const activeUsers = users.filter((u) => u.isActive).length;
    const adminCount = users.filter((u) => u.role === 'admin' || u.role === 'super_admin').length;
    const advisorCount = users.filter((u) => u.role === 'advisor' || u.role === 'fa').length;
    const clientCount = users.filter((u) => u.role === 'client' || u.role === 'user').length;

    return { totalUsers, activeUsers, adminCount, advisorCount, clientCount };
  }, [users]);

  // Tab definitions with counts
  const tabs: { key: UserTab; label: string; count: number; icon: string; color: string }[] = [
    { key: 'all', label: 'All Users', count: users.length, icon: 'M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z', color: colors.primary },
    { key: 'admin', label: 'Admins', count: kpis.adminCount, icon: 'M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z', color: colors.error },
    { key: 'advisor', label: 'Financial Advisors', count: kpis.advisorCount, icon: 'M21 13.255A23.931 23.931 0 0112 15c-3.183 0-6.22-.62-9-1.745M16 6V4a2 2 0 00-2-2h-4a2 2 0 00-2 2v2m4 6h.01M5 20h14a2 2 0 002-2V8a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z', color: colors.primary },
    { key: 'client', label: 'Clients', count: kpis.clientCount, icon: 'M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z', color: colors.success },
  ];

  // CRUD handlers
  const handleCreate = () => {
    setIsCreateMode(true);
    setFormData({
      email: '',
      password: '',
      name: '',
      role: 'user',
      phone: '',
    });
    setIsModalOpen(true);
  };

  const handleEdit = (user: SystemUser) => {
    setIsCreateMode(false);
    setSelectedUser(user);
    setFormData({
      email: user.email,
      password: '',
      name: user.profile?.name || '',
      role: user.role,
      phone: user.phone || '',
    });
    setIsModalOpen(true);
  };

  const handleSave = async () => {
    try {
      if (isCreateMode) {
        const createData: CreateUserRequest = {
          email: formData.email,
          password: formData.password,
          name: formData.name,
          role: formData.role,
          phone: formData.phone || undefined,
        };
        await usersApi.create(createData);
        setSuccessMessage('User created successfully');
      } else if (selectedUser) {
        const updateData: UpdateUserRequest = {
          email: formData.email,
          name: formData.name,
          role: formData.role,
          phone: formData.phone || undefined,
        };
        await usersApi.update(selectedUser.id, updateData);
        setSuccessMessage('User updated successfully');
      }
      setIsModalOpen(false);
      loadUsers();
    } catch (err: any) {
      setError(err.message || 'Operation failed');
    }
  };

  const handleDelete = async (id: string) => {
    if (!confirm('Are you sure you want to delete this user?')) return;
    try {
      await usersApi.delete(id);
      setSuccessMessage('User deleted successfully');
      loadUsers();
    } catch (err: any) {
      setError(err.message || 'Delete failed');
    }
  };

  const handleToggleActive = async (id: string) => {
    try {
      await usersApi.toggleActive(id);
      setSuccessMessage('User status updated');
      loadUsers();
    } catch (err: any) {
      setError(err.message || 'Update failed');
    }
  };

  const handleResetPassword = async () => {
    if (!resetUserId || !newPassword) return;
    try {
      await usersApi.resetPassword(resetUserId, newPassword);
      setSuccessMessage('Password reset successfully');
      setIsResetModalOpen(false);
      setResetUserId(null);
      setNewPassword('');
    } catch (err: any) {
      setError(err.message || 'Password reset failed');
    }
  };

  const openResetModal = (userId: string) => {
    setResetUserId(userId);
    setNewPassword('');
    setIsResetModalOpen(true);
  };

  // Bulk selection handlers
  const toggleSelectUser = useCallback((userId: string) => {
    setSelectedUserIds((prev) => {
      const newSet = new Set(prev);
      if (newSet.has(userId)) {
        newSet.delete(userId);
      } else {
        newSet.add(userId);
      }
      return newSet;
    });
  }, []);

  const toggleSelectAll = useCallback(() => {
    if (selectedUserIds.size === paginatedUsers.length) {
      // Deselect all
      setSelectedUserIds(new Set());
    } else {
      // Select all on current page
      setSelectedUserIds(new Set(paginatedUsers.map((u) => u.id)));
    }
  }, [paginatedUsers, selectedUserIds.size]);

  const clearSelection = useCallback(() => {
    setSelectedUserIds(new Set());
  }, []);

  // Bulk action handlers
  const handleBulkActivate = async () => {
    const toActivate = Array.from(selectedUserIds).filter((id) => {
      const user = users.find((u) => u.id === id);
      return user && !user.isActive;
    });
    if (toActivate.length === 0) {
      setSuccessMessage('All selected users are already active');
      return;
    }
    try {
      for (const id of toActivate) {
        await usersApi.toggleActive(id);
      }
      setSuccessMessage(`Activated ${toActivate.length} users`);
      clearSelection();
      loadUsers();
    } catch (err: any) {
      setError(err.message || 'Bulk activate failed');
    }
  };

  const handleBulkDeactivate = async () => {
    const toDeactivate = Array.from(selectedUserIds).filter((id) => {
      const user = users.find((u) => u.id === id);
      return user && user.isActive;
    });
    if (toDeactivate.length === 0) {
      setSuccessMessage('All selected users are already inactive');
      return;
    }
    try {
      for (const id of toDeactivate) {
        await usersApi.toggleActive(id);
      }
      setSuccessMessage(`Deactivated ${toDeactivate.length} users`);
      clearSelection();
      loadUsers();
    } catch (err: any) {
      setError(err.message || 'Bulk deactivate failed');
    }
  };

  const handleBulkDelete = async () => {
    const count = selectedUserIds.size;
    if (!confirm(`Are you sure you want to delete ${count} users? This action cannot be undone.`)) return;
    try {
      const idsToDelete = Array.from(selectedUserIds);
      for (const id of idsToDelete) {
        await usersApi.delete(id);
      }
      setSuccessMessage(`Deleted ${count} users`);
      clearSelection();
      loadUsers();
    } catch (err: any) {
      setError(err.message || 'Bulk delete failed');
    }
  };

  // Export handlers
  const handleExportCSV = useCallback(() => {
    const dataToExport = filteredUsers.map(transformUserForExport);
    exportToCSV<UserExportRow>(dataToExport, 'users', userExportColumns);
    setSuccessMessage(`Exported ${dataToExport.length} users to CSV`);
  }, [filteredUsers]);

  const handleExportJSON = useCallback(() => {
    const dataToExport = filteredUsers.map(transformUserForExport);
    exportToJSON(dataToExport, 'users');
    setSuccessMessage(`Exported ${dataToExport.length} users to JSON`);
  }, [filteredUsers]);

  // Check if all users on current page are selected
  const allSelected = paginatedUsers.length > 0 && selectedUserIds.size === paginatedUsers.length;
  const someSelected = selectedUserIds.size > 0;

  return (
    <AdminLayout title="User Management">
      <div style={{ background: colors.background, minHeight: '100%', margin: '-2rem', padding: '2rem' }}>
        {/* Action Buttons */}
        <div className="flex items-center justify-between mb-6">
          <p className="text-sm" style={{ color: colors.textSecondary }}>
            Manage system users - Admins, Financial Advisors, and Clients.
          </p>
          <div className="flex items-center gap-3">
            {/* Export Dropdown */}
            <div className="relative group">
              <button
                className="flex items-center gap-2 px-4 py-2.5 rounded-full font-medium text-sm transition-all hover:shadow-md"
                style={{
                  background: colors.chipBg,
                  color: colors.textSecondary,
                  border: `1px solid ${colors.chipBorder}`,
                }}
              >
                <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-4l-4 4m0 0l-4-4m4 4V4" />
                </svg>
                Export
                <svg className="w-3 h-3" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 9l-7 7-7-7" />
                </svg>
              </button>
              <div
                className="absolute right-0 mt-2 w-40 rounded-xl opacity-0 invisible group-hover:opacity-100 group-hover:visible transition-all z-10"
                style={{
                  background: colors.cardBackground,
                  border: `1px solid ${colors.cardBorder}`,
                  boxShadow: `0 4px 24px ${colors.glassShadow}`,
                }}
              >
                <button
                  onClick={handleExportCSV}
                  className="w-full px-4 py-2.5 text-left text-sm font-medium transition-colors rounded-t-xl hover:opacity-80"
                  style={{ color: colors.textPrimary }}
                  onMouseEnter={(e) => (e.currentTarget.style.background = colors.chipBg)}
                  onMouseLeave={(e) => (e.currentTarget.style.background = 'transparent')}
                >
                  Export as CSV
                </button>
                <button
                  onClick={handleExportJSON}
                  className="w-full px-4 py-2.5 text-left text-sm font-medium transition-colors rounded-b-xl hover:opacity-80"
                  style={{ color: colors.textPrimary }}
                  onMouseEnter={(e) => (e.currentTarget.style.background = colors.chipBg)}
                  onMouseLeave={(e) => (e.currentTarget.style.background = 'transparent')}
                >
                  Export as JSON
                </button>
              </div>
            </div>
            {/* Add User Button */}
            <button
              onClick={handleCreate}
              className="flex items-center gap-2 px-5 py-2.5 rounded-full font-semibold text-sm text-white transition-all hover:shadow-lg"
              style={{
                background: `linear-gradient(135deg, ${colors.primary} 0%, ${colors.primaryDark} 100%)`,
                boxShadow: `0 4px 14px ${colors.glassShadow}`,
              }}
            >
              <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 4v16m8-8H4" />
              </svg>
              Add User
            </button>
          </div>
        </div>

        {/* Success Message */}
        {successMessage && (
          <div
            className="mb-6 p-4 rounded-xl flex items-center justify-between"
            style={{
              background: isDark ? 'rgba(52, 211, 153, 0.15)' : 'rgba(16, 185, 129, 0.1)',
              border: `1px solid ${colors.success}`,
            }}
          >
            <span style={{ color: colors.success }}>{successMessage}</span>
            <button onClick={() => setSuccessMessage(null)} className="text-sm underline" style={{ color: colors.success }}>
              Dismiss
            </button>
          </div>
        )}

        {/* Error Message */}
        {error && (
          <div
            className="mb-6 p-4 rounded-xl flex items-center justify-between"
            style={{
              background: isDark ? 'rgba(248, 113, 113, 0.15)' : 'rgba(239, 68, 68, 0.1)',
              border: `1px solid ${colors.error}`,
            }}
          >
            <span style={{ color: colors.error }}>{error}</span>
            <button onClick={() => setError(null)} className="text-sm underline" style={{ color: colors.error }}>
              Dismiss
            </button>
          </div>
        )}

        {/* Role Tabs */}
        <div className="mb-6">
          <div
            className="p-1.5 rounded-2xl inline-flex gap-1"
            style={{
              background: colors.cardBackground,
              border: `1px solid ${colors.cardBorder}`,
              boxShadow: `0 4px 24px ${colors.glassShadow}`,
            }}
          >
            {tabs.map((tab) => {
              const isActive = activeTab === tab.key;
              return (
                <button
                  key={tab.key}
                  onClick={() => setActiveTab(tab.key)}
                  className="flex items-center gap-2 px-4 py-2.5 rounded-xl font-medium text-sm transition-all"
                  style={{
                    background: isActive
                      ? `linear-gradient(135deg, ${tab.color} 0%, ${tab.color}dd 100%)`
                      : 'transparent',
                    color: isActive ? '#FFFFFF' : colors.textSecondary,
                    boxShadow: isActive ? `0 4px 12px ${tab.color}40` : 'none',
                  }}
                >
                  <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
                    <path strokeLinecap="round" strokeLinejoin="round" d={tab.icon} />
                  </svg>
                  <span>{tab.label}</span>
                  <span
                    className="px-2 py-0.5 rounded-full text-xs font-bold"
                    style={{
                      background: isActive ? 'rgba(255, 255, 255, 0.2)' : colors.chipBg,
                      color: isActive ? '#FFFFFF' : colors.textTertiary,
                    }}
                  >
                    {tab.count}
                  </span>
                </button>
              );
            })}
          </div>
        </div>

        {/* Search and Filters */}
        <div
          className="p-4 rounded-xl mb-6"
          style={{
            background: colors.cardBackground,
            border: `1px solid ${colors.cardBorder}`,
            boxShadow: `0 4px 24px ${colors.glassShadow}`,
          }}
        >
          <div className="flex flex-wrap items-center gap-4">
            {/* Search */}
            <div className="flex-1 min-w-[200px]">
              <div className="relative">
                <svg
                  className="absolute left-4 top-1/2 -translate-y-1/2 w-4 h-4"
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke="currentColor"
                  style={{ color: colors.textTertiary }}
                >
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
                </svg>
                <input
                  type="text"
                  value={searchTerm}
                  onChange={(e) => setSearchTerm(e.target.value)}
                  placeholder="Search by name or email..."
                  className="w-full h-10 pl-11 pr-4 rounded-xl text-sm transition-all focus:outline-none"
                  style={{ background: colors.inputBg, border: `1px solid ${colors.inputBorder}`, color: colors.textPrimary }}
                />
              </div>
            </div>

            {/* Status Filter */}
            <div>
              <select
                value={filterStatus}
                onChange={(e) => setFilterStatus(e.target.value)}
                className="h-10 px-4 rounded-xl text-sm transition-all focus:outline-none"
                style={{ background: colors.inputBg, border: `1px solid ${colors.inputBorder}`, color: colors.textPrimary }}
              >
                <option value="all">All Status</option>
                <option value="active">Active</option>
                <option value="inactive">Inactive</option>
              </select>
            </div>

            {/* Refresh */}
            <button
              onClick={loadUsers}
              className="h-10 px-4 rounded-xl text-sm font-medium transition-all hover:opacity-80"
              style={{ background: colors.chipBg, color: colors.primary }}
            >
              Refresh
            </button>
          </div>
        </div>

        {/* Bulk Actions Toolbar */}
        {someSelected && (
          <div
            className="p-4 rounded-xl mb-6 flex items-center justify-between"
            style={{
              background: isDark ? `${colors.primary}15` : `${colors.primary}08`,
              border: `1px solid ${colors.primary}`,
            }}
          >
            <div className="flex items-center gap-3">
              <span className="text-sm font-semibold" style={{ color: colors.primary }}>
                {selectedUserIds.size} user{selectedUserIds.size > 1 ? 's' : ''} selected
              </span>
              <button
                onClick={clearSelection}
                className="text-sm font-medium underline hover:opacity-80"
                style={{ color: colors.textSecondary }}
              >
                Clear selection
              </button>
            </div>
            <div className="flex items-center gap-2">
              <button
                onClick={handleBulkActivate}
                className="px-4 py-2 rounded-full text-sm font-medium transition-all hover:opacity-80"
                style={{
                  background: isDark ? 'rgba(52, 211, 153, 0.15)' : 'rgba(16, 185, 129, 0.1)',
                  color: colors.success,
                }}
              >
                Activate
              </button>
              <button
                onClick={handleBulkDeactivate}
                className="px-4 py-2 rounded-full text-sm font-medium transition-all hover:opacity-80"
                style={{
                  background: isDark ? 'rgba(251, 191, 36, 0.15)' : 'rgba(245, 158, 11, 0.1)',
                  color: colors.warning,
                }}
              >
                Deactivate
              </button>
              <button
                onClick={handleBulkDelete}
                className="px-4 py-2 rounded-full text-sm font-medium transition-all hover:opacity-80"
                style={{
                  background: isDark ? 'rgba(248, 113, 113, 0.15)' : 'rgba(239, 68, 68, 0.1)',
                  color: colors.error,
                }}
              >
                Delete
              </button>
            </div>
          </div>
        )}

        {/* Users Table */}
        <div
          className="rounded-xl overflow-hidden"
          style={{
            background: colors.cardBackground,
            border: `1px solid ${colors.cardBorder}`,
            boxShadow: `0 4px 24px ${colors.glassShadow}`,
          }}
        >
          {/* Table Header Bar */}
          <div className="p-4 border-b flex items-center justify-between" style={{ borderColor: colors.chipBorder }}>
            <h2 className="text-lg font-bold" style={{ color: colors.textPrimary }}>
              {tabs.find((t) => t.key === activeTab)?.label || 'Users'}
            </h2>
            <span className="text-sm" style={{ color: colors.textSecondary }}>
              {filteredUsers.length} {activeTab === 'all' ? `of ${users.length} total` : 'users'}
            </span>
          </div>

          {/* Loading State */}
          {loading ? (
            <div className="flex items-center justify-center py-12">
              <div className="animate-spin rounded-full h-8 w-8 border-b-2" style={{ borderColor: colors.primary }} />
            </div>
          ) : filteredUsers.length === 0 ? (
            /* Empty State */
            <div className="text-center py-12">
              <div className="w-12 h-12 rounded-xl flex items-center justify-center mx-auto mb-3" style={{ background: colors.chipBg }}>
                <svg className="w-6 h-6" style={{ color: colors.textTertiary }} fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.5}>
                  <path strokeLinecap="round" strokeLinejoin="round" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z" />
                </svg>
              </div>
              <p className="text-sm" style={{ color: colors.textSecondary }}>
                {searchTerm || activeTab !== 'all' || filterStatus !== 'all'
                  ? `No ${activeTab === 'all' ? 'users' : tabs.find(t => t.key === activeTab)?.label.toLowerCase()} match your filters`
                  : 'No users yet. Add your first user to get started.'}
              </p>
            </div>
          ) : (
            /* Table */
            <div className="overflow-x-auto">
              <table className="w-full">
                <thead>
                  <tr style={{ background: colors.chipBg }}>
                    <th className="w-12 px-4 py-3">
                      <input
                        type="checkbox"
                        checked={allSelected}
                        onChange={toggleSelectAll}
                        className="w-4 h-4 rounded cursor-pointer accent-current"
                        style={{ accentColor: colors.primary }}
                      />
                    </th>
                    <th className="text-left text-xs font-semibold uppercase tracking-wide px-4 py-3" style={{ color: colors.primary }}>
                      User
                    </th>
                    <th className="text-left text-xs font-semibold uppercase tracking-wide px-4 py-3" style={{ color: colors.primary }}>
                      Role
                    </th>
                    <th className="text-left text-xs font-semibold uppercase tracking-wide px-4 py-3" style={{ color: colors.primary }}>
                      Status
                    </th>
                    <th className="text-left text-xs font-semibold uppercase tracking-wide px-4 py-3" style={{ color: colors.primary }}>
                      Last Login
                    </th>
                    <th className="text-left text-xs font-semibold uppercase tracking-wide px-4 py-3" style={{ color: colors.primary }}>
                      Created
                    </th>
                    <th className="text-left text-xs font-semibold uppercase tracking-wide px-4 py-3" style={{ color: colors.primary }}>
                      Actions
                    </th>
                  </tr>
                </thead>
                <tbody>
                  {paginatedUsers.map((user, index) => {
                    const roleBadge = getRoleBadge(user.role, colors, isDark);
                    return (
                      <tr
                        key={user.id}
                        className="transition-colors"
                        style={{
                          borderBottom: index < paginatedUsers.length - 1 ? `1px solid ${colors.chipBorder}` : undefined,
                        }}
                        onMouseEnter={(e) => (e.currentTarget.style.background = colors.chipBg)}
                        onMouseLeave={(e) => (e.currentTarget.style.background = 'transparent')}
                      >
                        {/* Checkbox */}
                        <td className="w-12 px-4 py-3">
                          <input
                            type="checkbox"
                            checked={selectedUserIds.has(user.id)}
                            onChange={() => toggleSelectUser(user.id)}
                            className="w-4 h-4 rounded cursor-pointer accent-current"
                            style={{ accentColor: colors.primary }}
                          />
                        </td>
                        {/* User info */}
                        <td className="px-4 py-3">
                          <div className="flex items-center gap-3">
                            <div>
                              <p className="text-sm font-medium" style={{ color: colors.textPrimary }}>
                                {user.profile?.name || 'No Name'}
                              </p>
                              <p className="text-xs" style={{ color: colors.textTertiary }}>
                                {user.email}
                              </p>
                            </div>
                          </div>
                        </td>

                        {/* Role */}
                        <td className="px-4 py-3">
                          <span
                            className="text-xs px-2 py-1 rounded font-medium"
                            style={{ background: roleBadge.bg, color: roleBadge.color }}
                          >
                            {roleBadge.label}
                          </span>
                        </td>

                        {/* Status */}
                        <td className="px-4 py-3">
                          <span
                            className="text-xs px-2 py-1 rounded font-medium cursor-pointer"
                            style={{
                              background: user.isActive
                                ? isDark
                                  ? 'rgba(52, 211, 153, 0.15)'
                                  : 'rgba(16, 185, 129, 0.1)'
                                : isDark
                                ? 'rgba(248, 113, 113, 0.15)'
                                : 'rgba(239, 68, 68, 0.1)',
                              color: user.isActive ? colors.success : colors.error,
                            }}
                            onClick={() => handleToggleActive(user.id)}
                            title="Click to toggle status"
                          >
                            {user.isActive ? 'Active' : 'Inactive'}
                          </span>
                        </td>

                        {/* Last Login */}
                        <td className="px-4 py-3">
                          <span className="text-sm" style={{ color: colors.textSecondary }}>
                            {user.lastLoginAt ? new Date(user.lastLoginAt).toLocaleDateString() : 'Never'}
                          </span>
                        </td>

                        {/* Created */}
                        <td className="px-4 py-3">
                          <span className="text-sm" style={{ color: colors.textSecondary }}>
                            {new Date(user.createdAt).toLocaleDateString()}
                          </span>
                        </td>

                        {/* Actions */}
                        <td className="px-4 py-3">
                          <div className="flex items-center gap-2">
                            <button
                              onClick={() => handleEdit(user)}
                              className="px-3 py-1.5 rounded-full text-xs font-medium transition-colors hover:opacity-80"
                              style={{ background: colors.chipBg, color: colors.textSecondary }}
                            >
                              Edit
                            </button>
                            <button
                              onClick={() => openResetModal(user.id)}
                              className="px-3 py-1.5 rounded-full text-xs font-medium transition-colors hover:opacity-80"
                              style={{ background: colors.chipBg, color: colors.warning }}
                            >
                              Reset Password
                            </button>
                            <button
                              onClick={() => handleDelete(user.id)}
                              className="px-3 py-1.5 rounded-full text-xs font-medium transition-colors hover:opacity-80"
                              style={{
                                background: isDark ? 'rgba(248, 113, 113, 0.15)' : 'rgba(239, 68, 68, 0.1)',
                                color: colors.error,
                              }}
                            >
                              Delete
                            </button>
                          </div>
                        </td>
                      </tr>
                    );
                  })}
                </tbody>
              </table>
            </div>
          )}

          {/* Pagination Controls */}
          {filteredUsers.length > 0 && (
            <div className="p-4 border-t flex items-center justify-between" style={{ borderColor: colors.chipBorder }}>
              <div className="flex items-center gap-4">
                <span className="text-sm" style={{ color: colors.textSecondary }}>
                  Showing {startIndex + 1}-{Math.min(endIndex, filteredUsers.length)} of {filteredUsers.length}
                </span>
                <div className="flex items-center gap-2">
                  <span className="text-xs" style={{ color: colors.textTertiary }}>
                    Per page:
                  </span>
                  <select
                    value={itemsPerPage}
                    onChange={(e) => {
                      setItemsPerPage(Number(e.target.value));
                      setCurrentPage(1);
                    }}
                    className="h-8 px-2 rounded-lg text-sm focus:outline-none"
                    style={{ background: colors.inputBg, border: `1px solid ${colors.inputBorder}`, color: colors.textPrimary }}
                  >
                    <option value={5}>5</option>
                    <option value={10}>10</option>
                    <option value={25}>25</option>
                    <option value={50}>50</option>
                  </select>
                </div>
              </div>

              <div className="flex items-center gap-2">
                <button
                  onClick={() => setCurrentPage(1)}
                  disabled={currentPage === 1}
                  className="p-2 rounded-lg transition-all disabled:opacity-40"
                  style={{ background: colors.chipBg }}
                >
                  <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" style={{ color: colors.textSecondary }}>
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M11 19l-7-7 7-7m8 14l-7-7 7-7" />
                  </svg>
                </button>
                <button
                  onClick={() => setCurrentPage((p) => Math.max(1, p - 1))}
                  disabled={currentPage === 1}
                  className="p-2 rounded-lg transition-all disabled:opacity-40"
                  style={{ background: colors.chipBg }}
                >
                  <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" style={{ color: colors.textSecondary }}>
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 19l-7-7 7-7" />
                  </svg>
                </button>
                <span className="px-3 text-sm" style={{ color: colors.textPrimary }}>
                  Page {currentPage} of {totalPages || 1}
                </span>
                <button
                  onClick={() => setCurrentPage((p) => Math.min(totalPages, p + 1))}
                  disabled={currentPage === totalPages || totalPages === 0}
                  className="p-2 rounded-lg transition-all disabled:opacity-40"
                  style={{ background: colors.chipBg }}
                >
                  <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" style={{ color: colors.textSecondary }}>
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5l7 7-7 7" />
                  </svg>
                </button>
                <button
                  onClick={() => setCurrentPage(totalPages)}
                  disabled={currentPage === totalPages || totalPages === 0}
                  className="p-2 rounded-lg transition-all disabled:opacity-40"
                  style={{ background: colors.chipBg }}
                >
                  <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" style={{ color: colors.textSecondary }}>
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M13 5l7 7-7 7M5 5l7 7-7 7" />
                  </svg>
                </button>
              </div>
            </div>
          )}
        </div>

        {/* Add/Edit Modal */}
        <AdminModal isOpen={isModalOpen} onClose={() => setIsModalOpen(false)} title={isCreateMode ? 'Add User' : 'Edit User'} size="md">
          <div className="space-y-4">
            {/* Name Input */}
            <div>
              <label className="block text-xs font-semibold mb-1.5 uppercase tracking-wide" style={{ color: colors.primary }}>
                NAME
              </label>
              <input
                type="text"
                value={formData.name}
                onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                className="w-full h-10 px-4 rounded-xl text-sm transition-all focus:outline-none"
                style={{ background: colors.inputBg, border: `1px solid ${colors.inputBorder}`, color: colors.textPrimary }}
                placeholder="Full name"
              />
            </div>

            {/* Email Input */}
            <div>
              <label className="block text-xs font-semibold mb-1.5 uppercase tracking-wide" style={{ color: colors.primary }}>
                EMAIL
              </label>
              <input
                type="email"
                value={formData.email}
                onChange={(e) => setFormData({ ...formData, email: e.target.value })}
                className="w-full h-10 px-4 rounded-xl text-sm transition-all focus:outline-none"
                style={{ background: colors.inputBg, border: `1px solid ${colors.inputBorder}`, color: colors.textPrimary }}
                placeholder="user@example.com"
              />
            </div>

            {/* Password (only for create) */}
            {isCreateMode && (
              <div>
                <label className="block text-xs font-semibold mb-1.5 uppercase tracking-wide" style={{ color: colors.primary }}>
                  PASSWORD
                </label>
                <input
                  type="password"
                  value={formData.password}
                  onChange={(e) => setFormData({ ...formData, password: e.target.value })}
                  className="w-full h-10 px-4 rounded-xl text-sm transition-all focus:outline-none"
                  style={{ background: colors.inputBg, border: `1px solid ${colors.inputBorder}`, color: colors.textPrimary }}
                  placeholder="Password"
                />
              </div>
            )}

            {/* Role and Phone */}
            <div className="grid grid-cols-2 gap-3">
              <div>
                <label className="block text-xs font-semibold mb-1.5 uppercase tracking-wide" style={{ color: colors.primary }}>
                  ROLE
                </label>
                <select
                  value={formData.role}
                  onChange={(e) => setFormData({ ...formData, role: e.target.value })}
                  className="w-full h-10 px-4 rounded-xl text-sm transition-all focus:outline-none"
                  style={{ background: colors.inputBg, border: `1px solid ${colors.inputBorder}`, color: colors.textPrimary }}
                >
                  <option value="user">User</option>
                  <option value="client">Client</option>
                  <option value="advisor">Financial Advisor</option>
                  <option value="admin">Admin</option>
                </select>
              </div>
              <div>
                <label className="block text-xs font-semibold mb-1.5 uppercase tracking-wide" style={{ color: colors.primary }}>
                  PHONE
                </label>
                <input
                  type="tel"
                  value={formData.phone}
                  onChange={(e) => setFormData({ ...formData, phone: e.target.value })}
                  className="w-full h-10 px-4 rounded-xl text-sm transition-all focus:outline-none"
                  style={{ background: colors.inputBg, border: `1px solid ${colors.inputBorder}`, color: colors.textPrimary }}
                  placeholder="+91 98765 43210"
                />
              </div>
            </div>

            {/* Action Buttons */}
            <div className="flex items-center gap-3 pt-4">
              <button
                onClick={() => setIsModalOpen(false)}
                className="flex-1 h-10 rounded-full font-semibold text-sm transition-all hover:opacity-80"
                style={{ background: colors.chipBg, color: colors.textSecondary }}
              >
                Cancel
              </button>
              <button
                onClick={handleSave}
                className="flex-1 h-10 rounded-full font-semibold text-sm text-white transition-all hover:shadow-lg"
                style={{
                  background: `linear-gradient(135deg, ${colors.primary} 0%, ${colors.primaryDark} 100%)`,
                  boxShadow: `0 4px 14px ${colors.glassShadow}`,
                }}
              >
                {isCreateMode ? 'Add User' : 'Save Changes'}
              </button>
            </div>
          </div>
        </AdminModal>

        {/* Reset Password Modal */}
        <AdminModal isOpen={isResetModalOpen} onClose={() => setIsResetModalOpen(false)} title="Reset Password" size="sm">
          <div className="space-y-4">
            <p className="text-sm" style={{ color: colors.textSecondary }}>
              Enter a new password for this user.
            </p>
            <div>
              <label className="block text-xs font-semibold mb-1.5 uppercase tracking-wide" style={{ color: colors.primary }}>
                NEW PASSWORD
              </label>
              <input
                type="password"
                value={newPassword}
                onChange={(e) => setNewPassword(e.target.value)}
                className="w-full h-10 px-4 rounded-xl text-sm transition-all focus:outline-none"
                style={{ background: colors.inputBg, border: `1px solid ${colors.inputBorder}`, color: colors.textPrimary }}
                placeholder="New password"
              />
            </div>
            <div className="flex items-center gap-3 pt-4">
              <button
                onClick={() => setIsResetModalOpen(false)}
                className="flex-1 h-10 rounded-full font-semibold text-sm transition-all hover:opacity-80"
                style={{ background: colors.chipBg, color: colors.textSecondary }}
              >
                Cancel
              </button>
              <button
                onClick={handleResetPassword}
                disabled={!newPassword}
                className="flex-1 h-10 rounded-full font-semibold text-sm text-white transition-all hover:shadow-lg disabled:opacity-50"
                style={{
                  background: `linear-gradient(135deg, ${colors.warning} 0%, ${colors.error} 100%)`,
                  boxShadow: `0 4px 14px ${colors.glassShadow}`,
                }}
              >
                Reset Password
              </button>
            </div>
          </div>
        </AdminModal>
      </div>
    </AdminLayout>
  );
};

export default UsersPage;
