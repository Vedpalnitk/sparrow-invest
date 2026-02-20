/**
 * BSE Mandate Detail Page
 *
 * View mandate details, status timeline, e-NACH auth, and linked orders.
 */

import { useState, useEffect, useCallback } from 'react'
import { useRouter } from 'next/router'
import AdvisorLayout from '@/components/layout/AdvisorLayout'
import { useFATheme, formatDate, formatCurrency } from '@/utils/fa'
import { bseApi } from '@/services/api'
import { FACard, FAButton, FASpinner } from '@/components/advisor/shared'
import BseStatusBadge from '@/components/bse/BseStatusBadge'

interface MandateDetail {
  id: string
  mandateId: string
  clientId: string
  clientName: string
  clientCode: string
  bankAccountNo: string
  bankName: string
  amount: number
  mandateType: string
  status: string
  startDate: string
  endDate: string
  umrn?: string
  createdAt: string
  updatedAt: string
}

interface LinkedOrder {
  id: string
  orderId: string
  schemeName: string
  orderType: string
  amount: number
  status: string
  orderDate: string
}

const MANDATE_STEPS = ['Created', 'Submitted', 'Approved'] as const

function getMandateStepStatus(mandateStatus: string, stepIndex: number): 'completed' | 'current' | 'pending' | 'failed' {
  const upper = mandateStatus?.toUpperCase()

  if (upper === 'REJECTED') {
    if (stepIndex === 0) return 'completed'
    if (stepIndex === 1) return 'failed'
    return 'pending'
  }

  const statusMap: Record<string, number> = {
    CREATED: 0,
    SUBMITTED: 1,
    APPROVED: 2,
  }

  const currentIndex = statusMap[upper] ?? 0

  if (stepIndex < currentIndex) return 'completed'
  if (stepIndex === currentIndex) return upper === 'APPROVED' ? 'completed' : 'current'
  return 'pending'
}

const MandateDetailPage = () => {
  const router = useRouter()
  const { id } = router.query
  const { colors, isDark } = useFATheme()

  const [mandate, setMandate] = useState<MandateDetail | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  // Auth URL
  const [authUrl, setAuthUrl] = useState<string | null>(null)
  const [authLoading, setAuthLoading] = useState(false)
  const [authError, setAuthError] = useState<string | null>(null)

  // Refresh status
  const [refreshing, setRefreshing] = useState(false)

  // Shift mandate
  const [targetMandateId, setTargetMandateId] = useState('')
  const [shifting, setShifting] = useState(false)
  const [shiftError, setShiftError] = useState<string | null>(null)

  // Linked orders
  const [linkedOrders, setLinkedOrders] = useState<LinkedOrder[]>([])
  const [ordersLoading, setOrdersLoading] = useState(false)

  const fetchMandate = useCallback(async () => {
    if (!id || typeof id !== 'string') return
    try {
      setLoading(true)
      setError(null)
      const data = await bseApi.mandates.getOne(id)
      setMandate(data)
    } catch (err) {
      console.error('[Mandate Detail] Error:', err)
      setError('Failed to load mandate details')
    } finally {
      setLoading(false)
    }
  }, [id])

  const fetchLinkedOrders = useCallback(async () => {
    if (!mandate?.clientId) return
    try {
      setOrdersLoading(true)
      const res = await bseApi.orders.list({ clientId: mandate.clientId })
      const data = Array.isArray(res) ? res : res?.data || []
      setLinkedOrders(data)
    } catch {
      setLinkedOrders([])
    } finally {
      setOrdersLoading(false)
    }
  }, [mandate?.clientId])

  useEffect(() => {
    fetchMandate()
  }, [fetchMandate])

  useEffect(() => {
    if (mandate?.clientId) {
      fetchLinkedOrders()
    }
  }, [mandate?.clientId, fetchLinkedOrders])

  const handleGetAuthUrl = async () => {
    if (!id || typeof id !== 'string') return
    try {
      setAuthLoading(true)
      setAuthError(null)
      const res = await bseApi.mandates.getAuthUrl(id)
      setAuthUrl(res?.authUrl || res?.url || null)
    } catch (err) {
      setAuthError(err instanceof Error ? err.message : 'Failed to get auth URL')
    } finally {
      setAuthLoading(false)
    }
  }

  const handleRefreshStatus = async () => {
    if (!id || typeof id !== 'string') return
    try {
      setRefreshing(true)
      await bseApi.mandates.refreshStatus(id)
      await fetchMandate()
    } catch {
      // Silent fail, data will reload
    } finally {
      setRefreshing(false)
    }
  }

  const handleShiftMandate = async () => {
    if (!id || typeof id !== 'string' || !targetMandateId) return
    try {
      setShifting(true)
      setShiftError(null)
      await bseApi.mandates.shift(id, {
        fromMandateId: id,
        toMandateId: targetMandateId,
      })
      await fetchMandate()
      setTargetMandateId('')
    } catch (err) {
      setShiftError(err instanceof Error ? err.message : 'Failed to shift mandate')
    } finally {
      setShifting(false)
    }
  }

  const getStepColor = (status: 'completed' | 'current' | 'pending' | 'failed') => {
    switch (status) {
      case 'completed': return colors.success
      case 'current': return colors.primary
      case 'failed': return colors.error
      default: return colors.textTertiary
    }
  }

  if (loading) {
    return (
      <AdvisorLayout title="Mandate Detail">
        <div className="flex items-center justify-center py-20">
          <FASpinner size="lg" />
        </div>
      </AdvisorLayout>
    )
  }

  if (error || !mandate) {
    return (
      <AdvisorLayout title="Mandate Detail">
        <div style={{ background: colors.background, minHeight: '100%', margin: '-2rem', padding: '2rem' }}>
          <div className="text-center py-20">
            <p className="text-sm" style={{ color: colors.error }}>{error || 'Mandate not found'}</p>
            <FAButton className="mt-4" variant="secondary" onClick={() => router.push('/advisor/bse/mandates')}>
              Back to Mandates
            </FAButton>
          </div>
        </div>
      </AdvisorLayout>
    )
  }

  return (
    <AdvisorLayout title="Mandate Detail">
      <div style={{ background: colors.background, minHeight: '100%', margin: '-2rem', padding: '2rem' }}>
        {/* Header */}
        <div className="flex items-center gap-4 mb-6">
          <button
            onClick={() => router.push('/advisor/bse/mandates')}
            className="flex items-center gap-1.5 px-3 py-1.5 rounded-full text-sm font-medium transition-all"
            style={{
              color: colors.primary,
              background: colors.chipBg,
              border: `1px solid ${colors.chipBorder}`,
            }}
          >
            <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
              <path strokeLinecap="round" strokeLinejoin="round" d="M10 19l-7-7m0 0l7-7m-7 7h18" />
            </svg>
            Back
          </button>
          <div className="flex-1">
            <div className="flex items-center gap-3">
              <h1 className="text-xl font-bold" style={{ color: colors.textPrimary }}>
                Mandate {mandate.mandateId}
              </h1>
              <BseStatusBadge status={mandate.status} size="md" />
            </div>
            <p className="text-sm mt-0.5" style={{ color: colors.textSecondary }}>
              {mandate.clientName} ({mandate.clientCode})
            </p>
          </div>
        </div>

        {/* Status Timeline */}
        <FACard className="mb-6">
          <p className="text-xs font-semibold uppercase tracking-wide mb-4" style={{ color: colors.primary }}>
            Status Timeline
          </p>
          <div className="flex items-center justify-center py-2">
            {MANDATE_STEPS.map((step, i) => {
              const stepStatus = getMandateStepStatus(mandate.status, i)
              const stepColor = getStepColor(stepStatus)
              return (
                <div key={step} className="flex items-center">
                  <div className="flex flex-col items-center">
                    <div
                      className="w-8 h-8 rounded-full flex items-center justify-center"
                      style={{
                        background: stepStatus === 'pending' ? `${stepColor}20` : stepColor,
                        border: stepStatus === 'pending' ? `2px dashed ${stepColor}` : 'none',
                      }}
                    >
                      {stepStatus === 'completed' && (
                        <svg className="w-4 h-4 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={3}>
                          <path strokeLinecap="round" strokeLinejoin="round" d="M5 13l4 4L19 7" />
                        </svg>
                      )}
                      {stepStatus === 'current' && (
                        <div className="w-2.5 h-2.5 rounded-full bg-white" />
                      )}
                      {stepStatus === 'failed' && (
                        <svg className="w-4 h-4 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={3}>
                          <path strokeLinecap="round" strokeLinejoin="round" d="M6 18L18 6M6 6l12 12" />
                        </svg>
                      )}
                    </div>
                    <span
                      className="text-xs mt-2 whitespace-nowrap font-medium"
                      style={{
                        color: stepStatus === 'pending' ? colors.textTertiary : stepColor,
                      }}
                    >
                      {step}
                    </span>
                  </div>
                  {i < MANDATE_STEPS.length - 1 && (
                    <div
                      className="w-16 sm:w-24 h-0.5 mx-2 mb-6"
                      style={{
                        background: stepStatus === 'completed' ? colors.success : `${colors.textTertiary}30`,
                      }}
                    />
                  )}
                </div>
              )
            })}
          </div>
        </FACard>

        {/* Details Card */}
        <FACard className="mb-6">
          <p className="text-xs font-semibold uppercase tracking-wide mb-4" style={{ color: colors.primary }}>
            Mandate Details
          </p>
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
            {[
              { label: 'Mandate Type', value: mandate.mandateType === 'X' ? 'XSIP (e-NACH)' : mandate.mandateType === 'N' ? 'Normal' : mandate.mandateType },
              { label: 'Bank Name', value: mandate.bankName || '-' },
              { label: 'Bank Account', value: mandate.bankAccountNo || '-' },
              { label: 'Amount', value: formatCurrency(mandate.amount) },
              { label: 'Start Date', value: mandate.startDate ? formatDate(mandate.startDate) : '-' },
              { label: 'End Date', value: mandate.endDate ? formatDate(mandate.endDate) : '-' },
              ...(mandate.umrn ? [{ label: 'UMRN', value: mandate.umrn }] : []),
              { label: 'Created At', value: mandate.createdAt ? formatDate(mandate.createdAt) : '-' },
            ].map(item => (
              <div key={item.label}>
                <p className="text-xs" style={{ color: colors.textTertiary }}>{item.label}</p>
                <p className="text-sm font-medium mt-0.5" style={{ color: colors.textPrimary }}>{item.value}</p>
              </div>
            ))}
          </div>
        </FACard>

        {/* e-NACH Authentication */}
        <FACard className="mb-6">
          <p className="text-xs font-semibold uppercase tracking-wide mb-4" style={{ color: colors.primary }}>
            e-NACH Authentication
          </p>
          <div className="flex items-start gap-4 flex-wrap">
            <FAButton
              onClick={handleGetAuthUrl}
              loading={authLoading}
              variant="secondary"
              size="sm"
              icon={
                <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
                  <path strokeLinecap="round" strokeLinejoin="round" d="M13.828 10.172a4 4 0 00-5.656 0l-4 4a4 4 0 105.656 5.656l1.102-1.101m-.758-4.899a4 4 0 005.656 0l4-4a4 4 0 00-5.656-5.656l-1.1 1.1" />
                </svg>
              }
            >
              Get Auth URL
            </FAButton>
            {authError && (
              <p className="text-xs" style={{ color: colors.error }}>{authError}</p>
            )}
          </div>
          {authUrl && (
            <div className="mt-4">
              <p className="text-xs mb-2" style={{ color: colors.textTertiary }}>Authentication URL</p>
              <div
                className="p-3 rounded-lg flex items-center gap-3"
                style={{ background: colors.inputBg, border: `1px solid ${colors.inputBorder}` }}
              >
                <a
                  href={authUrl}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="text-sm truncate flex-1 underline"
                  style={{ color: colors.primary }}
                >
                  {authUrl}
                </a>
                <button
                  onClick={() => window.open(authUrl, '_blank')}
                  className="px-3 py-1.5 rounded-full text-xs font-medium whitespace-nowrap transition-all"
                  style={{
                    background: `${colors.primary}10`,
                    border: `1px solid ${colors.primary}30`,
                    color: colors.primary,
                  }}
                >
                  Open in New Tab
                </button>
              </div>
            </div>
          )}
        </FACard>

        {/* Actions */}
        <FACard className="mb-6">
          <p className="text-xs font-semibold uppercase tracking-wide mb-4" style={{ color: colors.primary }}>
            Actions
          </p>
          <div className="space-y-4">
            {/* Refresh Status */}
            <div>
              <FAButton
                onClick={handleRefreshStatus}
                loading={refreshing}
                variant="secondary"
                size="sm"
                icon={
                  <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
                    <path strokeLinecap="round" strokeLinejoin="round" d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15" />
                  </svg>
                }
              >
                Refresh Status
              </FAButton>
            </div>

            {/* Shift Mandate */}
            <div>
              <p className="text-xs font-medium mb-2" style={{ color: colors.textSecondary }}>Shift Mandate</p>
              <div className="flex items-center gap-3">
                <input
                  type="text"
                  placeholder="Target Mandate ID..."
                  value={targetMandateId}
                  onChange={e => setTargetMandateId(e.target.value)}
                  className="h-9 px-3 rounded-lg text-sm flex-1 max-w-xs focus:outline-none"
                  style={{
                    background: colors.inputBg,
                    border: `1px solid ${colors.inputBorder}`,
                    color: colors.textPrimary,
                  }}
                />
                <FAButton
                  onClick={handleShiftMandate}
                  loading={shifting}
                  disabled={!targetMandateId}
                  variant="secondary"
                  size="sm"
                >
                  Shift
                </FAButton>
              </div>
              {shiftError && (
                <p className="text-xs mt-2" style={{ color: colors.error }}>{shiftError}</p>
              )}
            </div>
          </div>
        </FACard>

        {/* Linked Orders */}
        <div
          className="rounded-xl overflow-hidden"
          style={{
            background: colors.cardBackground,
            border: `1px solid ${colors.cardBorder}`,
            boxShadow: `0 4px 24px ${colors.glassShadow}`,
          }}
        >
          <div className="px-5 pt-5 pb-3">
            <p className="text-xs font-semibold uppercase tracking-wide" style={{ color: colors.primary }}>
              Linked Orders ({mandate.clientName})
            </p>
          </div>
          {ordersLoading ? (
            <div className="flex items-center justify-center py-12">
              <FASpinner />
            </div>
          ) : linkedOrders.length === 0 ? (
            <div className="text-center py-10 px-5">
              <p className="text-sm" style={{ color: colors.textTertiary }}>No linked orders found</p>
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
                    <th className="text-left px-4 py-3 text-xs font-semibold uppercase tracking-wider" style={{ color: colors.primary }}>Order ID</th>
                    <th className="text-left px-4 py-3 text-xs font-semibold uppercase tracking-wider" style={{ color: colors.primary }}>Scheme</th>
                    <th className="text-center px-4 py-3 text-xs font-semibold uppercase tracking-wider" style={{ color: colors.primary }}>Type</th>
                    <th className="text-right px-4 py-3 text-xs font-semibold uppercase tracking-wider" style={{ color: colors.primary }}>Amount</th>
                    <th className="text-center px-4 py-3 text-xs font-semibold uppercase tracking-wider" style={{ color: colors.primary }}>Status</th>
                    <th className="text-left px-4 py-3 text-xs font-semibold uppercase tracking-wider" style={{ color: colors.primary }}>Date</th>
                  </tr>
                </thead>
                <tbody>
                  {linkedOrders.map(order => (
                    <tr
                      key={order.id}
                      className="transition-colors cursor-pointer"
                      style={{ borderBottom: `1px solid ${colors.cardBorder}` }}
                      onClick={() => router.push(`/advisor/bse/orders/${order.id}`)}
                      onMouseEnter={e => e.currentTarget.style.background = isDark ? 'rgba(147,197,253,0.04)' : 'rgba(59,130,246,0.02)'}
                      onMouseLeave={e => e.currentTarget.style.background = 'transparent'}
                    >
                      <td className="px-4 py-3 text-sm font-mono" style={{ color: colors.textSecondary }}>
                        {order.orderId}
                      </td>
                      <td className="px-4 py-3 text-sm truncate max-w-[200px]" style={{ color: colors.textPrimary }}>
                        {order.schemeName}
                      </td>
                      <td className="px-4 py-3 text-center">
                        <BseStatusBadge status={order.orderType} />
                      </td>
                      <td className="px-4 py-3 text-right text-sm font-semibold" style={{ color: colors.textPrimary }}>
                        {formatCurrency(order.amount)}
                      </td>
                      <td className="px-4 py-3 text-center">
                        <BseStatusBadge status={order.status} />
                      </td>
                      <td className="px-4 py-3 text-sm" style={{ color: colors.textSecondary }}>
                        {order.orderDate ? formatDate(order.orderDate, { format: 'short' }) : '-'}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </div>
      </div>
    </AdvisorLayout>
  )
}

export default MandateDetailPage
