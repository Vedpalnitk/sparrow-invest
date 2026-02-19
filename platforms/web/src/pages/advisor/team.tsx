import { useState, useEffect, useCallback } from 'react'
import AdvisorLayout from '@/components/layout/AdvisorLayout'
import StaffManagement from '@/components/advisor/StaffManagement'
import { staffApi, teamApi, branchesApi, Branch } from '@/services/api'
import { useFATheme, formatCurrency } from '@/utils/fa'

type TabKey = 'staff' | 'euin' | 'assignment'

interface EuinRecord {
  id: string; displayName: string; email: string; euin: string
  euinExpiry: string; branchName: string; daysUntilExpiry: number
}

interface StaffClient {
  id: string; name: string; email: string; aum: number
  sipCount: number; status: string
}

export default function TeamPage() {
  const { colors, isDark } = useFATheme()
  const [activeTab, setActiveTab] = useState<TabKey>('staff')
  const [euinData, setEuinData] = useState<EuinRecord[]>([])
  const [staffList, setStaffList] = useState<any[]>([])
  const [selectedStaff, setSelectedStaff] = useState<string>('')
  const [staffClients, setStaffClients] = useState<StaffClient[]>([])
  const [loading, setLoading] = useState(false)

  const fetchEuinExpiry = useCallback(async () => {
    try {
      setLoading(true)
      const data = await teamApi.getEuinExpiry()
      setEuinData(data)
    } catch {} finally { setLoading(false) }
  }, [])

  const fetchStaffList = useCallback(async () => {
    try {
      const data = await staffApi.list()
      setStaffList(data)
    } catch {}
  }, [])

  const fetchStaffClients = useCallback(async (staffId: string) => {
    if (!staffId) { setStaffClients([]); return }
    try {
      setLoading(true)
      const data = await teamApi.getStaffClients(staffId)
      setStaffClients(data)
    } catch {} finally { setLoading(false) }
  }, [])

  useEffect(() => {
    if (activeTab === 'euin') fetchEuinExpiry()
    if (activeTab === 'assignment') fetchStaffList()
  }, [activeTab, fetchEuinExpiry, fetchStaffList])

  useEffect(() => {
    if (selectedStaff) fetchStaffClients(selectedStaff)
  }, [selectedStaff, fetchStaffClients])

  const tabs: { key: TabKey; label: string }[] = [
    { key: 'staff', label: 'Staff List' },
    { key: 'euin', label: 'EUIN Management' },
    { key: 'assignment', label: 'Client Assignment' },
  ]

  const getExpiryColor = (days: number) => {
    if (days <= 0) return colors.error
    if (days <= 30) return colors.warning
    if (days <= 60) return colors.warning
    return colors.success
  }

  return (
    <AdvisorLayout title="Team Management">
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

      {/* Staff List Tab */}
      {activeTab === 'staff' && <StaffManagement />}

      {/* EUIN Management Tab */}
      {activeTab === 'euin' && (
        <div>
          <div
            className="p-5 rounded-2xl mb-4"
            style={{
              background: isDark
                ? 'linear-gradient(135deg, rgba(147, 197, 253, 0.06) 0%, rgba(191, 219, 254, 0.03) 100%)'
                : 'linear-gradient(135deg, rgba(59, 130, 246, 0.03) 0%, rgba(96, 165, 250, 0.01) 100%)',
              border: `1px solid ${colors.cardBorder}`,
            }}
          >
            <h3 className="text-sm font-semibold mb-1" style={{ color: colors.textPrimary }}>
              EUIN Expiry Tracker
            </h3>
            <p className="text-xs" style={{ color: colors.textTertiary }}>
              Staff with EUINs expiring within 90 days
            </p>
          </div>

          {loading ? (
            <div className="flex items-center justify-center py-12">
              <div className="w-6 h-6 border-2 rounded-full animate-spin" style={{ borderColor: `${colors.primary}30`, borderTopColor: colors.primary }} />
            </div>
          ) : euinData.length === 0 ? (
            <div className="text-center py-12 rounded-2xl" style={{ background: colors.chipBg, border: `1px solid ${colors.cardBorder}` }}>
              <p className="text-sm font-medium" style={{ color: colors.textSecondary }}>No expiring EUINs found</p>
            </div>
          ) : (
            <div className="space-y-3">
              {euinData.map((item) => (
                <div
                  key={item.id}
                  className="p-4 rounded-xl flex items-center justify-between"
                  style={{
                    background: isDark ? colors.chipBg : colors.inputBg,
                    border: `1px solid ${colors.cardBorder}`,
                    borderLeft: `4px solid ${getExpiryColor(item.daysUntilExpiry)}`,
                  }}
                >
                  <div>
                    <p className="text-sm font-semibold" style={{ color: colors.textPrimary }}>{item.displayName}</p>
                    <p className="text-xs" style={{ color: colors.textTertiary }}>{item.email}</p>
                    <p className="text-xs mt-1" style={{ color: colors.textSecondary }}>
                      EUIN: <span className="font-medium">{item.euin}</span>
                      {item.branchName && <span> | {item.branchName}</span>}
                    </p>
                  </div>
                  <div className="text-right">
                    <p className="text-xs" style={{ color: colors.textTertiary }}>Expires</p>
                    <p className="text-sm font-semibold" style={{ color: getExpiryColor(item.daysUntilExpiry) }}>
                      {item.euinExpiry}
                    </p>
                    <p className="text-xs font-medium" style={{ color: getExpiryColor(item.daysUntilExpiry) }}>
                      {item.daysUntilExpiry <= 0 ? 'Expired' : `${item.daysUntilExpiry} days left`}
                    </p>
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>
      )}

      {/* Client Assignment Tab */}
      {activeTab === 'assignment' && (
        <div>
          <div className="mb-4">
            <label className="block text-xs font-semibold mb-1.5 uppercase tracking-wide" style={{ color: colors.primary }}>
              Select Staff Member
            </label>
            <select
              className="w-full max-w-sm h-10 px-4 rounded-xl text-sm focus:outline-none"
              style={{ background: colors.inputBg, border: `1px solid ${colors.inputBorder}`, color: colors.textPrimary }}
              value={selectedStaff}
              onChange={(e) => setSelectedStaff(e.target.value)}
            >
              <option value="">-- Select --</option>
              {staffList.filter((s: any) => s.isActive).map((s: any) => (
                <option key={s.id} value={s.id}>{s.displayName} ({s.staffRole || 'RM'})</option>
              ))}
            </select>
          </div>

          {selectedStaff && (
            loading ? (
              <div className="flex items-center justify-center py-12">
                <div className="w-6 h-6 border-2 rounded-full animate-spin" style={{ borderColor: `${colors.primary}30`, borderTopColor: colors.primary }} />
              </div>
            ) : staffClients.length === 0 ? (
              <div className="text-center py-12 rounded-2xl" style={{ background: colors.chipBg, border: `1px solid ${colors.cardBorder}` }}>
                <p className="text-sm font-medium" style={{ color: colors.textSecondary }}>No clients assigned to this staff member</p>
              </div>
            ) : (
              <div className="space-y-2">
                <p className="text-xs font-semibold uppercase tracking-wide mb-3" style={{ color: colors.primary }}>
                  {staffClients.length} Assigned Clients
                </p>
                {staffClients.map((client) => (
                  <div
                    key={client.id}
                    className="p-3 rounded-xl flex items-center justify-between"
                    style={{ background: colors.chipBg, border: `1px solid ${colors.cardBorder}` }}
                  >
                    <div>
                      <p className="text-sm font-medium" style={{ color: colors.textPrimary }}>{client.name}</p>
                      <p className="text-xs" style={{ color: colors.textTertiary }}>{client.email}</p>
                    </div>
                    <div className="text-right">
                      <p className="text-sm font-bold" style={{ color: colors.primary }}>
                        {formatCurrency(client.aum)}
                      </p>
                      <p className="text-xs" style={{ color: colors.textTertiary }}>
                        {client.sipCount} SIPs
                      </p>
                    </div>
                  </div>
                ))}
              </div>
            )
          )}
        </div>
      )}
    </AdvisorLayout>
  )
}
