/**
 * BSE Order Detail Page
 *
 * View order details, timeline, payment info, allotment, and actions.
 */

import { useState, useEffect, useCallback } from 'react'
import { useRouter } from 'next/router'
import AdvisorLayout from '@/components/layout/AdvisorLayout'
import { useFATheme, formatDate, formatCurrency } from '@/utils/fa'
import { bseApi } from '@/services/api'
import { FACard, FAButton, FASpinner } from '@/components/advisor/shared'
import BseStatusBadge from '@/components/bse/BseStatusBadge'
import BseOrderTimeline from '@/components/bse/BseOrderTimeline'

type OrderType = 'Purchase' | 'Redemption' | 'Switch' | 'SIP' | 'STP' | 'SWP'

const ORDER_TYPE_COLORS: Record<string, string> = {
  Purchase: '#10B981',
  Redemption: '#EF4444',
  Switch: '#8B5CF6',
  SIP: '#3B82F6',
  STP: '#F59E0B',
  SWP: '#EC4899',
}

interface OrderDetail {
  id: string
  orderId: string
  clientId: string
  clientName: string
  clientCode: string
  orderType: string
  schemeName: string
  schemeCode: string
  amount: number
  units?: number
  nav?: number
  status: string
  transactionCode?: string
  bseOrderNumber?: string
  bseRemarks?: string
  orderDate: string
  allotmentDate?: string
  allottedUnits?: number
  allottedNav?: number
  allottedAmount?: number
  createdAt: string
}

interface PaymentInfo {
  status?: string
  paymentMode?: string
  amount?: number
  bank?: string
  transactionRef?: string
}

const PAYMENT_MODES = [
  { value: 'DIRECT', label: 'Direct' },
  { value: 'NODAL', label: 'Nodal' },
  { value: 'NEFT', label: 'NEFT' },
  { value: 'UPI', label: 'UPI' },
]

const OrderDetailPage = () => {
  const router = useRouter()
  const { id } = router.query
  const { colors, isDark } = useFATheme()

  const [order, setOrder] = useState<OrderDetail | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  // Payment
  const [payment, setPayment] = useState<PaymentInfo | null>(null)
  const [paymentLoading, setPaymentLoading] = useState(false)
  const [selectedPaymentMode, setSelectedPaymentMode] = useState('DIRECT')
  const [initiatingPayment, setInitiatingPayment] = useState(false)
  const [paymentError, setPaymentError] = useState<string | null>(null)

  // Cancel
  const [cancelling, setCancelling] = useState(false)

  const fetchOrder = useCallback(async () => {
    if (!id || typeof id !== 'string') return
    try {
      setLoading(true)
      setError(null)
      const data = await bseApi.orders.getOne(id)
      setOrder(data)
    } catch (err) {
      console.error('[Order Detail] Error:', err)
      setError('Failed to load order details')
    } finally {
      setLoading(false)
    }
  }, [id])

  const fetchPayment = useCallback(async () => {
    if (!id || typeof id !== 'string') return
    try {
      setPaymentLoading(true)
      const data = await bseApi.payments.getStatus(id)
      setPayment(data)
    } catch {
      setPayment(null)
    } finally {
      setPaymentLoading(false)
    }
  }, [id])

  useEffect(() => {
    fetchOrder()
  }, [fetchOrder])

  useEffect(() => {
    if (order) {
      fetchPayment()
    }
  }, [order, fetchPayment])

  const handleInitiatePayment = async () => {
    if (!id || typeof id !== 'string') return
    try {
      setInitiatingPayment(true)
      setPaymentError(null)
      await bseApi.payments.initiate(id, { paymentMode: selectedPaymentMode })
      await fetchPayment()
    } catch (err) {
      setPaymentError(err instanceof Error ? err.message : 'Failed to initiate payment')
    } finally {
      setInitiatingPayment(false)
    }
  }

  const handleCancelOrder = async () => {
    if (!id || typeof id !== 'string') return
    try {
      setCancelling(true)
      await bseApi.orders.cancel(id)
      await fetchOrder()
    } catch {
      // Silent fail
    } finally {
      setCancelling(false)
    }
  }

  const typeColor = ORDER_TYPE_COLORS[order?.orderType || ''] || colors.textTertiary
  const canCancel = order?.status?.toUpperCase() === 'CREATED' || order?.status?.toUpperCase() === 'SUBMITTED'
  const isAllotted = order?.status?.toUpperCase() === 'ALLOTTED'

  if (loading) {
    return (
      <AdvisorLayout title="Order Detail">
        <div className="flex items-center justify-center py-20">
          <FASpinner size="lg" />
        </div>
      </AdvisorLayout>
    )
  }

  if (error || !order) {
    return (
      <AdvisorLayout title="Order Detail">
        <div style={{ background: colors.background, minHeight: '100%', margin: '-2rem', padding: '2rem' }}>
          <div className="text-center py-20">
            <p className="text-sm" style={{ color: colors.error }}>{error || 'Order not found'}</p>
            <FAButton className="mt-4" variant="secondary" onClick={() => router.push('/advisor/bse/orders')}>
              Back to Orders
            </FAButton>
          </div>
        </div>
      </AdvisorLayout>
    )
  }

  return (
    <AdvisorLayout title="Order Detail">
      <div style={{ background: colors.background, minHeight: '100%', margin: '-2rem', padding: '2rem' }}>
        {/* Header */}
        <div className="flex items-center gap-4 mb-6">
          <button
            onClick={() => router.push('/advisor/bse/orders')}
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
            <div className="flex items-center gap-3 flex-wrap">
              <h1 className="text-xl font-bold" style={{ color: colors.textPrimary }}>
                Order {order.orderId}
              </h1>
              <span
                className="text-xs font-semibold px-2.5 py-1 rounded-full"
                style={{ background: `${typeColor}15`, color: typeColor, border: `1px solid ${typeColor}30` }}
              >
                {order.orderType}
              </span>
              <BseStatusBadge status={order.status} size="md" />
            </div>
            <p className="text-sm mt-0.5 truncate" style={{ color: colors.textSecondary }}>
              {order.schemeName}
            </p>
          </div>
        </div>

        {/* Order Timeline */}
        <FACard className="mb-6">
          <p className="text-xs font-semibold uppercase tracking-wide mb-4" style={{ color: colors.primary }}>
            Order Progress
          </p>
          <div className="flex justify-center py-2">
            <BseOrderTimeline orderStatus={order.status?.toUpperCase()} />
          </div>
        </FACard>

        {/* Order Details Card */}
        <FACard className="mb-6">
          <p className="text-xs font-semibold uppercase tracking-wide mb-4" style={{ color: colors.primary }}>
            Order Details
          </p>
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
            {[
              { label: 'Client', value: `${order.clientName} (${order.clientCode})` },
              { label: 'Scheme Code', value: order.schemeCode },
              { label: 'Order Type', value: order.orderType },
              { label: 'Amount', value: formatCurrency(order.amount) },
              { label: 'Units', value: order.units ? order.units.toFixed(3) : '-' },
              { label: 'NAV', value: order.nav ? formatCurrency(order.nav) : '-' },
              { label: 'Transaction Code', value: order.transactionCode || '-' },
              { label: 'BSE Order Number', value: order.bseOrderNumber || '-' },
              ...(order.bseRemarks ? [{ label: 'BSE Remarks', value: order.bseRemarks }] : []),
              { label: 'Order Date', value: order.orderDate ? formatDate(order.orderDate) : '-' },
              { label: 'Created At', value: order.createdAt ? formatDate(order.createdAt) : '-' },
            ].map(item => (
              <div key={item.label}>
                <p className="text-xs" style={{ color: colors.textTertiary }}>{item.label}</p>
                <p className="text-sm font-medium mt-0.5" style={{ color: colors.textPrimary }}>{item.value}</p>
              </div>
            ))}
          </div>
        </FACard>

        {/* Payment Section */}
        <FACard className="mb-6">
          <p className="text-xs font-semibold uppercase tracking-wide mb-4" style={{ color: colors.primary }}>
            Payment
          </p>
          {paymentLoading ? (
            <div className="flex items-center justify-center py-6">
              <FASpinner />
            </div>
          ) : payment?.status ? (
            <div className="space-y-4">
              <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
                <div>
                  <p className="text-xs" style={{ color: colors.textTertiary }}>Payment Status</p>
                  <div className="mt-0.5">
                    <BseStatusBadge status={payment.status} />
                  </div>
                </div>
                {payment.paymentMode && (
                  <div>
                    <p className="text-xs" style={{ color: colors.textTertiary }}>Payment Mode</p>
                    <p className="text-sm font-medium mt-0.5" style={{ color: colors.textPrimary }}>{payment.paymentMode}</p>
                  </div>
                )}
                {payment.amount != null && (
                  <div>
                    <p className="text-xs" style={{ color: colors.textTertiary }}>Payment Amount</p>
                    <p className="text-sm font-medium mt-0.5" style={{ color: colors.textPrimary }}>{formatCurrency(payment.amount)}</p>
                  </div>
                )}
                {payment.bank && (
                  <div>
                    <p className="text-xs" style={{ color: colors.textTertiary }}>Bank</p>
                    <p className="text-sm font-medium mt-0.5" style={{ color: colors.textPrimary }}>{payment.bank}</p>
                  </div>
                )}
              </div>
            </div>
          ) : (
            <div className="space-y-4">
              <p className="text-sm" style={{ color: colors.textTertiary }}>No payment recorded for this order.</p>

              {/* Payment Initiation Form */}
              <div
                className="p-4 rounded-xl"
                style={{
                  background: isDark
                    ? 'linear-gradient(135deg, rgba(147,197,253,0.04) 0%, rgba(125,211,252,0.02) 100%)'
                    : 'linear-gradient(135deg, rgba(59,130,246,0.03) 0%, rgba(56,189,248,0.01) 100%)',
                  border: `1px solid ${colors.cardBorder}`,
                }}
              >
                <p className="text-xs font-medium mb-3" style={{ color: colors.textSecondary }}>Initiate Payment</p>
                <div className="flex items-center gap-3 flex-wrap">
                  <div className="flex items-center gap-2">
                    {PAYMENT_MODES.map(mode => (
                      <button
                        key={mode.value}
                        onClick={() => setSelectedPaymentMode(mode.value)}
                        className="text-xs px-3 py-1.5 rounded-full transition-all font-medium"
                        style={{
                          background: selectedPaymentMode === mode.value ? `${colors.primary}15` : 'transparent',
                          border: `1px solid ${selectedPaymentMode === mode.value ? `${colors.primary}40` : colors.cardBorder}`,
                          color: selectedPaymentMode === mode.value ? colors.primary : colors.textTertiary,
                        }}
                      >
                        {mode.label}
                      </button>
                    ))}
                  </div>
                  <FAButton
                    onClick={handleInitiatePayment}
                    loading={initiatingPayment}
                    size="sm"
                  >
                    Initiate Payment
                  </FAButton>
                </div>
                {paymentError && (
                  <p className="text-xs mt-2" style={{ color: colors.error }}>{paymentError}</p>
                )}
              </div>
            </div>
          )}
        </FACard>

        {/* Allotment Section */}
        {isAllotted && (
          <FACard className="mb-6">
            <p className="text-xs font-semibold uppercase tracking-wide mb-4" style={{ color: colors.success }}>
              Allotment Details
            </p>
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
              {[
                { label: 'Allotted Units', value: order.allottedUnits ? order.allottedUnits.toFixed(3) : order.units ? order.units.toFixed(3) : '-' },
                { label: 'Allotted NAV', value: order.allottedNav ? formatCurrency(order.allottedNav) : order.nav ? formatCurrency(order.nav) : '-' },
                { label: 'Allotted Amount', value: order.allottedAmount ? formatCurrency(order.allottedAmount) : formatCurrency(order.amount) },
                { label: 'Allotment Date', value: order.allotmentDate ? formatDate(order.allotmentDate) : '-' },
              ].map(item => (
                <div key={item.label}>
                  <p className="text-xs" style={{ color: colors.textTertiary }}>{item.label}</p>
                  <p className="text-sm font-medium mt-0.5" style={{ color: colors.textPrimary }}>{item.value}</p>
                </div>
              ))}
            </div>
          </FACard>
        )}

        {/* Actions */}
        {canCancel && (
          <FACard>
            <p className="text-xs font-semibold uppercase tracking-wide mb-4" style={{ color: colors.primary }}>
              Actions
            </p>
            <FAButton
              onClick={handleCancelOrder}
              loading={cancelling}
              variant="danger"
              size="sm"
              icon={
                <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
                  <path strokeLinecap="round" strokeLinejoin="round" d="M6 18L18 6M6 6l12 12" />
                </svg>
              }
            >
              Cancel Order
            </FAButton>
          </FACard>
        )}
      </div>
    </AdvisorLayout>
  )
}

export default OrderDetailPage
