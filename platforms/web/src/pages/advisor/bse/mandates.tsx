/**
 * BSE Mandate Management
 *
 * Create and manage BSE mandates (e-NACH / auto-debit authorizations).
 * Mandates are required for SIP execution via BSE StAR MF.
 */

import { useState, useEffect, useCallback } from 'react'
import AdvisorLayout from '@/components/layout/AdvisorLayout'
import { useFATheme, formatCurrency, formatDate } from '@/utils/fa'
import { bseApi } from '@/services/api'
import {
  FACard,
  FAButton,
  FAChip,
  FASearchInput,
  FASelect,
  FAInput,
  FALabel,
  FAEmptyState,
  FASpinner,
} from '@/components/advisor/shared'

type MandateStatus = 'Created' | 'Submitted' | 'Approved' | 'Rejected'

interface Mandate {
  id: string
  mandateId: string
  clientId: string
  clientName: string
  clientCode: string
  bankAccountNo: string
  bankName: string
  amount: number
  mandateType: string
  status: MandateStatus
  startDate: string
  endDate: string
  createdAt: string
  updatedAt: string
}

const STATUS_COLORS: Record<MandateStatus, string> = {
  'Created': '#94A3B8',
  'Submitted': '#F59E0B',
  'Approved': '#10B981',
  'Rejected': '#EF4444',
}

const MandatesPage = () => {
  const { colors, isDark } = useFATheme()

  const [mandates, setMandates] = useState<Mandate[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [statusFilter, setStatusFilter] = useState<MandateStatus | 'All'>('All')
  const [clientFilter, setClientFilter] = useState('')
  const [selectedMandate, setSelectedMandate] = useState<Mandate | null>(null)
  const [showNewModal, setShowNewModal] = useState(false)
  const [refreshingId, setRefreshingId] = useState<string | null>(null)

  // New Mandate Form
  const [formClientId, setFormClientId] = useState('')
  const [formAmount, setFormAmount] = useState('')
  const [formBankAccount, setFormBankAccount] = useState('')
  const [formStartDate, setFormStartDate] = useState('')
  const [formEndDate, setFormEndDate] = useState('')
  const [formType, setFormType] = useState('X')
  const [formSubmitting, setFormSubmitting] = useState(false)
  const [formError, setFormError] = useState<string | null>(null)

  // Fetch mandates
  const fetchMandates = useCallback(async () => {
    try {
      setLoading(true)
      setError(null)
      const params: { clientId?: string; status?: string } = {}
      if (clientFilter) params.clientId = clientFilter
      if (statusFilter !== 'All') params.status = statusFilter
      const res = await bseApi.mandates.list(params)
      setMandates(Array.isArray(res) ? res : res?.data || [])
    } catch (err) {
      console.error('[BSE Mandates] Error:', err)
      setError('Failed to load mandates')
      setMandates([])
    } finally {
      setLoading(false)
    }
  }, [statusFilter, clientFilter])

  useEffect(() => {
    fetchMandates()
  }, [fetchMandates])

  // Refresh single mandate status
  const handleRefreshStatus = async (mandate: Mandate) => {
    try {
      setRefreshingId(mandate.id)
      await bseApi.mandates.refreshStatus(mandate.id)
      await fetchMandates()
    } catch {
      // Silent fail, user can retry
    } finally {
      setRefreshingId(null)
    }
  }

  // Create new mandate
  const handleCreateMandate = async () => {
    if (!formClientId || !formAmount || !formStartDate || !formEndDate) {
      setFormError('Please fill in all required fields')
      return
    }

    try {
      setFormSubmitting(true)
      setFormError(null)
      await bseApi.mandates.create({
        clientId: formClientId,
        amount: parseFloat(formAmount),
        bankAccountNo: formBankAccount,
        mandateType: formType,
        startDate: formStartDate,
        endDate: formEndDate,
      })
      setShowNewModal(false)
      resetForm()
      fetchMandates()
    } catch (err) {
      setFormError(err instanceof Error ? err.message : 'Failed to create mandate')
    } finally {
      setFormSubmitting(false)
    }
  }

  const resetForm = () => {
    setFormClientId('')
    setFormAmount('')
    setFormBankAccount('')
    setFormStartDate('')
    setFormEndDate('')
    setFormType('X')
    setFormError(null)
  }

  // Stats
  const approvedCount = mandates.filter(m => m.status === 'Approved').length
  const submittedCount = mandates.filter(m => m.status === 'Submitted').length
  const totalAmount = mandates.filter(m => m.status === 'Approved').reduce((s, m) => s + m.amount, 0)

  return (
    <AdvisorLayout title="BSE Mandates">
      <div style={{ background: colors.background, minHeight: '100%', margin: '-2rem', padding: '2rem' }}>
        {/* Header */}
        <div className="flex items-center justify-between mb-8">
          <div>
            <p className="text-sm" style={{ color: colors.textSecondary }}>
              Manage e-NACH mandates for SIP auto-debit authorization
            </p>
          </div>
          <FAButton
            onClick={() => setShowNewModal(true)}
            icon={
              <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
                <path strokeLinecap="round" strokeLinejoin="round" d="M12 4v16m8-8H4" />
              </svg>
            }
          >
            New Mandate
          </FAButton>
        </div>

        {/* KPI Row */}
        <div className="grid grid-cols-2 md:grid-cols-4 gap-4 mb-6">
          {[
            { label: 'TOTAL MANDATES', value: mandates.length.toString(), color: colors.primary },
            { label: 'APPROVED', value: approvedCount.toString(), color: colors.success },
            { label: 'PENDING', value: submittedCount.toString(), color: colors.warning },
            { label: 'APPROVED LIMIT', value: formatCurrency(totalAmount), color: colors.secondary },
          ].map(kpi => (
            <div
              key={kpi.label}
              className="p-4 rounded-xl"
              style={{
                background: `${kpi.color}08`,
                border: `1px solid ${kpi.color}20`,
              }}
            >
              <p className="text-xs font-semibold uppercase tracking-wide" style={{ color: kpi.color }}>{kpi.label}</p>
              <p className="text-xl font-bold mt-1" style={{ color: kpi.color }}>{kpi.value}</p>
            </div>
          ))}
        </div>

        {/* Filters */}
        <FACard className="mb-4">
          <div className="flex items-center gap-3 flex-wrap">
            <div className="flex-1 min-w-[200px] max-w-xs">
              <FASearchInput
                value={clientFilter}
                onChange={setClientFilter}
                placeholder="Filter by client ID..."
              />
            </div>
            <div className="w-px h-6" style={{ background: colors.cardBorder }} />
            <div className="flex items-center gap-1">
              {(['All', 'Created', 'Submitted', 'Approved', 'Rejected'] as const).map(s => (
                <button
                  key={s}
                  onClick={() => setStatusFilter(s)}
                  className="text-xs px-2.5 py-1 rounded-full transition-all"
                  style={{
                    background: statusFilter === s ? `${colors.primary}15` : 'transparent',
                    border: `1px solid ${statusFilter === s ? `${colors.primary}30` : 'transparent'}`,
                    color: statusFilter === s ? colors.primary : colors.textTertiary,
                    fontWeight: statusFilter === s ? 600 : 400,
                  }}
                >
                  {s}
                </button>
              ))}
            </div>
          </div>
        </FACard>

        {/* Mandates List */}
        <div
          className="rounded-xl overflow-hidden"
          style={{
            background: colors.cardBackground,
            border: `1px solid ${colors.cardBorder}`,
            boxShadow: `0 4px 24px ${colors.glassShadow}`,
          }}
        >
          {loading ? (
            <div className="flex items-center justify-center py-20">
              <FASpinner />
            </div>
          ) : error ? (
            <div className="py-8 px-5">
              <FAEmptyState
                icon={
                  <svg className="w-full h-full" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.5}>
                    <path strokeLinecap="round" strokeLinejoin="round" d="M12 9v3.75m-9.303 3.376c-.866 1.5.217 3.374 1.948 3.374h14.71c1.73 0 2.813-1.874 1.948-3.374L13.949 3.378c-.866-1.5-3.032-1.5-3.898 0L2.697 16.126zM12 15.75h.007v.008H12v-.008z" />
                  </svg>
                }
                title="Error loading mandates"
                description={error}
                action={<FAButton onClick={fetchMandates}>Retry</FAButton>}
              />
            </div>
          ) : mandates.length === 0 ? (
            <div className="py-8 px-5">
              <FAEmptyState
                icon={
                  <svg className="w-full h-full" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.5}>
                    <path strokeLinecap="round" strokeLinejoin="round" d="M2.25 8.25h19.5M2.25 9h19.5m-16.5 5.25h6m-6 2.25h3m-3.75 3h15a2.25 2.25 0 002.25-2.25V6.75A2.25 2.25 0 0019.5 4.5h-15a2.25 2.25 0 00-2.25 2.25v10.5A2.25 2.25 0 004.5 19.5z" />
                  </svg>
                }
                title="No mandates found"
                description="Create a mandate to enable auto-debit for SIP orders"
                action={<FAButton onClick={() => setShowNewModal(true)}>Create Mandate</FAButton>}
              />
            </div>
          ) : (
            <div className="overflow-x-auto">
              <table className="w-full">
                <thead>
                  <tr
                    style={{
                      background: isDark
                        ? 'linear-gradient(135deg, rgba(147,197,253,0.06) 0%, rgba(125,211,252,0.03) 100%)'
                        : 'linear-gradient(135deg, rgba(59,130,246,0.05) 0%, rgba(56,189,248,0.02) 100%)',
                      borderBottom: `1px solid ${colors.cardBorder}`,
                    }}
                  >
                    <th className="text-left px-4 py-3 text-xs font-semibold uppercase tracking-wider" style={{ color: colors.primary }}>Client</th>
                    <th className="text-left px-4 py-3 text-xs font-semibold uppercase tracking-wider" style={{ color: colors.primary }}>Mandate ID</th>
                    <th className="text-left px-4 py-3 text-xs font-semibold uppercase tracking-wider" style={{ color: colors.primary }}>Bank</th>
                    <th className="text-right px-4 py-3 text-xs font-semibold uppercase tracking-wider" style={{ color: colors.primary }}>Amount</th>
                    <th className="text-center px-4 py-3 text-xs font-semibold uppercase tracking-wider" style={{ color: colors.primary }}>Period</th>
                    <th className="text-center px-4 py-3 text-xs font-semibold uppercase tracking-wider" style={{ color: colors.primary }}>Status</th>
                    <th className="text-center px-4 py-3 text-xs font-semibold uppercase tracking-wider" style={{ color: colors.primary }}>Actions</th>
                  </tr>
                </thead>
                <tbody>
                  {mandates.map(mandate => {
                    const statusColor = STATUS_COLORS[mandate.status]
                    return (
                      <tr
                        key={mandate.id}
                        className="transition-colors cursor-pointer"
                        style={{ borderBottom: `1px solid ${colors.cardBorder}` }}
                        onClick={() => setSelectedMandate(selectedMandate?.id === mandate.id ? null : mandate)}
                        onMouseEnter={e => e.currentTarget.style.background = isDark ? 'rgba(147,197,253,0.04)' : 'rgba(59,130,246,0.02)'}
                        onMouseLeave={e => e.currentTarget.style.background = 'transparent'}
                      >
                        <td className="px-4 py-3">
                          <p className="text-sm font-medium" style={{ color: colors.textPrimary }}>{mandate.clientName}</p>
                          <p className="text-xs" style={{ color: colors.textTertiary }}>{mandate.clientCode}</p>
                        </td>
                        <td className="px-4 py-3">
                          <p className="text-sm font-mono" style={{ color: colors.textSecondary }}>{mandate.mandateId}</p>
                        </td>
                        <td className="px-4 py-3">
                          <p className="text-sm" style={{ color: colors.textPrimary }}>{mandate.bankName}</p>
                          <p className="text-xs" style={{ color: colors.textTertiary }}>
                            ****{mandate.bankAccountNo?.slice(-4)}
                          </p>
                        </td>
                        <td className="px-4 py-3 text-right">
                          <p className="text-sm font-semibold" style={{ color: colors.textPrimary }}>
                            {formatCurrency(mandate.amount)}
                          </p>
                        </td>
                        <td className="px-4 py-3 text-center">
                          <p className="text-xs" style={{ color: colors.textSecondary }}>
                            {mandate.startDate ? new Date(mandate.startDate).toLocaleDateString('en-IN', { day: '2-digit', month: 'short', year: '2-digit' }) : '-'}
                            {' - '}
                            {mandate.endDate ? new Date(mandate.endDate).toLocaleDateString('en-IN', { day: '2-digit', month: 'short', year: '2-digit' }) : '-'}
                          </p>
                        </td>
                        <td className="px-4 py-3 text-center">
                          <span
                            className="inline-flex items-center gap-1.5 text-xs font-medium px-2 py-0.5 rounded-full"
                            style={{
                              background: `${statusColor}15`,
                              color: statusColor,
                            }}
                          >
                            <span className="w-1.5 h-1.5 rounded-full" style={{ background: statusColor }} />
                            {mandate.status}
                          </span>
                        </td>
                        <td className="px-4 py-3 text-center">
                          <button
                            onClick={e => { e.stopPropagation(); handleRefreshStatus(mandate) }}
                            disabled={refreshingId === mandate.id}
                            className="p-1.5 rounded-lg transition-all hover:opacity-80"
                            style={{ background: colors.chipBg }}
                            title="Refresh status"
                          >
                            {refreshingId === mandate.id ? (
                              <div
                                className="w-4 h-4 rounded-full border-2 border-t-transparent animate-spin"
                                style={{ borderColor: `${colors.primary} transparent ${colors.primary} ${colors.primary}` }}
                              />
                            ) : (
                              <svg className="w-4 h-4" style={{ color: colors.primary }} fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
                                <path strokeLinecap="round" strokeLinejoin="round" d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15" />
                              </svg>
                            )}
                          </button>
                        </td>
                      </tr>
                    )
                  })}
                </tbody>
              </table>
            </div>
          )}

          {/* Detail Panel */}
          {selectedMandate && (
            <div
              className="px-5 py-4"
              style={{
                background: isDark ? 'rgba(147, 197, 253, 0.03)' : 'rgba(59, 130, 246, 0.02)',
                borderTop: `1px solid ${colors.cardBorder}`,
              }}
            >
              <div className="flex items-center justify-between mb-3">
                <h4 className="text-xs font-semibold uppercase tracking-wide" style={{ color: colors.primary }}>
                  Mandate Details
                </h4>
                <button
                  onClick={() => setSelectedMandate(null)}
                  className="text-xs px-2 py-1 rounded-full"
                  style={{ color: colors.textTertiary }}
                >
                  Close
                </button>
              </div>
              <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
                <div>
                  <p className="text-xs" style={{ color: colors.textTertiary }}>Mandate ID</p>
                  <p className="text-sm font-medium font-mono" style={{ color: colors.textPrimary }}>{selectedMandate.mandateId}</p>
                </div>
                <div>
                  <p className="text-xs" style={{ color: colors.textTertiary }}>Client</p>
                  <p className="text-sm font-medium" style={{ color: colors.textPrimary }}>{selectedMandate.clientName}</p>
                </div>
                <div>
                  <p className="text-xs" style={{ color: colors.textTertiary }}>Amount Limit</p>
                  <p className="text-sm font-medium" style={{ color: colors.textPrimary }}>{formatCurrency(selectedMandate.amount)}</p>
                </div>
                <div>
                  <p className="text-xs" style={{ color: colors.textTertiary }}>Type</p>
                  <p className="text-sm font-medium" style={{ color: colors.textPrimary }}>{selectedMandate.mandateType === 'X' ? 'XSIP' : 'Normal'}</p>
                </div>
                <div>
                  <p className="text-xs" style={{ color: colors.textTertiary }}>Bank</p>
                  <p className="text-sm font-medium" style={{ color: colors.textPrimary }}>{selectedMandate.bankName}</p>
                </div>
                <div>
                  <p className="text-xs" style={{ color: colors.textTertiary }}>Account</p>
                  <p className="text-sm font-medium font-mono" style={{ color: colors.textPrimary }}>{selectedMandate.bankAccountNo}</p>
                </div>
                <div>
                  <p className="text-xs" style={{ color: colors.textTertiary }}>Start Date</p>
                  <p className="text-sm font-medium" style={{ color: colors.textPrimary }}>
                    {selectedMandate.startDate ? new Date(selectedMandate.startDate).toLocaleDateString('en-IN') : '-'}
                  </p>
                </div>
                <div>
                  <p className="text-xs" style={{ color: colors.textTertiary }}>End Date</p>
                  <p className="text-sm font-medium" style={{ color: colors.textPrimary }}>
                    {selectedMandate.endDate ? new Date(selectedMandate.endDate).toLocaleDateString('en-IN') : '-'}
                  </p>
                </div>
              </div>
            </div>
          )}
        </div>

        {/* New Mandate Modal */}
        {showNewModal && (
          <>
            <div className="fixed inset-0 z-40 bg-black/50" onClick={() => { setShowNewModal(false); resetForm() }} />
            <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
              <div
                className="w-full max-w-lg rounded-2xl overflow-hidden"
                style={{
                  background: colors.cardBackground,
                  border: `1px solid ${colors.cardBorder}`,
                  boxShadow: `0 25px 50px -12px rgba(0, 0, 0, 0.25)`,
                }}
                onClick={e => e.stopPropagation()}
              >
                {/* Modal Header */}
                <div
                  className="px-6 py-4 flex items-center justify-between"
                  style={{
                    background: isDark
                      ? 'linear-gradient(135deg, rgba(147,197,253,0.06) 0%, rgba(125,211,252,0.03) 100%)'
                      : 'linear-gradient(135deg, rgba(59,130,246,0.05) 0%, rgba(56,189,248,0.02) 100%)',
                    borderBottom: `1px solid ${colors.cardBorder}`,
                  }}
                >
                  <h3 className="text-base font-semibold" style={{ color: colors.textPrimary }}>New Mandate</h3>
                  <button
                    onClick={() => { setShowNewModal(false); resetForm() }}
                    className="p-1 rounded-lg transition-all hover:opacity-70"
                    style={{ color: colors.textTertiary }}
                  >
                    <svg className="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
                      <path strokeLinecap="round" strokeLinejoin="round" d="M6 18L18 6M6 6l12 12" />
                    </svg>
                  </button>
                </div>

                {/* Modal Body */}
                <div className="px-6 py-5 space-y-4">
                  <FAInput
                    label="Client ID"
                    required
                    placeholder="Enter client ID"
                    value={formClientId}
                    onChange={e => setFormClientId(e.target.value)}
                  />
                  <div className="grid grid-cols-2 gap-4">
                    <FAInput
                      label="Amount Limit"
                      required
                      type="number"
                      placeholder="e.g. 100000"
                      value={formAmount}
                      onChange={e => setFormAmount(e.target.value)}
                    />
                    <div>
                      <FALabel required>Mandate Type</FALabel>
                      <select
                        value={formType}
                        onChange={e => setFormType(e.target.value)}
                        className="w-full h-10 px-4 rounded-lg text-sm focus:outline-none"
                        style={{
                          background: isDark ? colors.inputBg : '#FFFFFF',
                          border: `1px solid ${colors.inputBorder}`,
                          color: colors.textPrimary,
                        }}
                      >
                        <option value="X">XSIP (e-NACH)</option>
                        <option value="N">Normal</option>
                      </select>
                    </div>
                  </div>
                  <FAInput
                    label="Bank Account Number"
                    placeholder="Enter bank account number"
                    value={formBankAccount}
                    onChange={e => setFormBankAccount(e.target.value)}
                  />
                  <div className="grid grid-cols-2 gap-4">
                    <FAInput
                      label="Start Date"
                      required
                      type="date"
                      value={formStartDate}
                      onChange={e => setFormStartDate(e.target.value)}
                    />
                    <FAInput
                      label="End Date"
                      required
                      type="date"
                      value={formEndDate}
                      onChange={e => setFormEndDate(e.target.value)}
                    />
                  </div>

                  {formError && (
                    <div
                      className="p-3 rounded-lg text-sm"
                      style={{
                        background: `${colors.error}10`,
                        border: `1px solid ${colors.error}30`,
                        color: colors.error,
                      }}
                    >
                      {formError}
                    </div>
                  )}
                </div>

                {/* Modal Footer */}
                <div
                  className="px-6 py-4 flex items-center justify-end gap-3"
                  style={{ borderTop: `1px solid ${colors.cardBorder}` }}
                >
                  <button
                    onClick={() => { setShowNewModal(false); resetForm() }}
                    className="px-4 py-2 rounded-full text-sm font-medium transition-all"
                    style={{ color: colors.textSecondary }}
                  >
                    Cancel
                  </button>
                  <FAButton onClick={handleCreateMandate} loading={formSubmitting}>
                    Create Mandate
                  </FAButton>
                </div>
              </div>
            </div>
          </>
        )}
      </div>
    </AdvisorLayout>
  )
}

export default MandatesPage
