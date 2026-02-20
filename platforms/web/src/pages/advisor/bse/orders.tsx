/**
 * BSE Orders Dashboard
 *
 * View and manage BSE StAR MF orders.
 * Supports purchase, redemption, switch, SIP, STP, SWP orders.
 */

import { useState, useEffect, useCallback, useRef } from 'react'
import { useRouter } from 'next/router'
import AdvisorLayout from '@/components/layout/AdvisorLayout'
import { useFATheme, formatCurrency } from '@/utils/fa'
import { bseApi } from '@/services/api'
import {
  FACard,
  FAButton,
  FAChip,
  FAEmptyState,
  FASpinner,
} from '@/components/advisor/shared'

type OrderType = 'Purchase' | 'Redemption' | 'Switch' | 'SIP' | 'STP' | 'SWP'
type OrderStatus = 'Placed' | 'Confirmed' | 'Allotted' | 'Rejected' | 'Cancelled' | 'Pending'

interface BSEOrder {
  id: string
  orderId: string
  clientId: string
  clientName: string
  clientCode: string
  orderType: OrderType
  schemeName: string
  schemeCode: string
  amount: number
  units?: number
  nav?: number
  status: OrderStatus
  bseRemarks?: string
  orderDate: string
  allotmentDate?: string
  createdAt: string
}

const ORDER_TYPE_COLORS: Record<OrderType, string> = {
  Purchase: '#10B981',
  Redemption: '#EF4444',
  Switch: '#8B5CF6',
  SIP: '#3B82F6',
  STP: '#F59E0B',
  SWP: '#EC4899',
}

const STATUS_COLORS: Record<OrderStatus, string> = {
  Placed: '#F59E0B',
  Confirmed: '#3B82F6',
  Allotted: '#10B981',
  Rejected: '#EF4444',
  Cancelled: '#94A3B8',
  Pending: '#F59E0B',
}

const ORDER_TYPES: OrderType[] = ['Purchase', 'Redemption', 'Switch', 'SIP', 'STP', 'SWP']
const ORDER_STATUSES: OrderStatus[] = ['Placed', 'Confirmed', 'Allotted', 'Rejected', 'Cancelled', 'Pending']

const PAGE_SIZE = 25

const BSEOrdersPage = () => {
  const router = useRouter()
  const { colors, isDark } = useFATheme()

  const [orders, setOrders] = useState<BSEOrder[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [total, setTotal] = useState(0)
  const [page, setPage] = useState(1)
  const [totalPages, setTotalPages] = useState(0)

  // Filters
  const [typeFilter, setTypeFilter] = useState<OrderType | 'All'>('All')
  const [statusFilter, setStatusFilter] = useState<OrderStatus | 'All'>('All')
  const [searchTerm, setSearchTerm] = useState('')
  const [searchInput, setSearchInput] = useState('')
  const searchTimeout = useRef<NodeJS.Timeout>()

  // Expanded order
  const [expandedOrderId, setExpandedOrderId] = useState<string | null>(null)

  const handleSearchChange = (value: string) => {
    setSearchInput(value)
    if (searchTimeout.current) clearTimeout(searchTimeout.current)
    searchTimeout.current = setTimeout(() => {
      setSearchTerm(value)
      setPage(1)
    }, 300)
  }

  // Fetch orders
  const fetchOrders = useCallback(async () => {
    try {
      setLoading(true)
      setError(null)
      const params: { clientId?: string; status?: string; orderType?: string; page?: number; limit?: number } = {
        page,
        limit: PAGE_SIZE,
      }
      if (typeFilter !== 'All') params.orderType = typeFilter
      if (statusFilter !== 'All') params.status = statusFilter
      if (searchTerm) params.clientId = searchTerm

      const res = await bseApi.orders.list(params)
      const data = Array.isArray(res) ? res : res?.data || []
      setOrders(data)
      setTotal(res?.total || data.length)
      setTotalPages(res?.totalPages || Math.ceil((res?.total || data.length) / PAGE_SIZE))
    } catch (err) {
      console.error('[BSE Orders] Error:', err)
      setError('Failed to load orders')
      setOrders([])
    } finally {
      setLoading(false)
    }
  }, [page, typeFilter, statusFilter, searchTerm])

  useEffect(() => {
    fetchOrders()
  }, [fetchOrders])

  // Stats from current page
  const purchaseCount = orders.filter(o => o.orderType === 'Purchase').length
  const redemptionCount = orders.filter(o => o.orderType === 'Redemption').length
  const totalVolume = orders.reduce((s, o) => s + o.amount, 0)
  const allottedCount = orders.filter(o => o.status === 'Allotted').length

  const clearFilters = () => {
    setSearchInput('')
    setSearchTerm('')
    setTypeFilter('All')
    setStatusFilter('All')
    setPage(1)
  }

  const hasActiveFilters = searchTerm || typeFilter !== 'All' || statusFilter !== 'All'
  const startItem = (page - 1) * PAGE_SIZE + 1
  const endItem = Math.min(page * PAGE_SIZE, total)

  return (
    <AdvisorLayout title="BSE Orders">
      <div style={{ background: colors.background, minHeight: '100%', margin: '-2rem', padding: '2rem' }}>
        {/* Header */}
        <div className="flex items-center justify-between mb-6">
          <div>
            <p className="text-sm" style={{ color: colors.textSecondary }}>
              {total > 0 ? `${total.toLocaleString('en-IN')} BSE orders` : 'Track BSE StAR MF order execution'}
            </p>
          </div>
        </div>

        {/* KPI Tiles */}
        <div className="grid grid-cols-2 md:grid-cols-4 gap-4 mb-6">
          {[
            { label: 'TOTAL ORDERS', value: total.toLocaleString('en-IN'), color: colors.primary },
            { label: 'VOLUME', value: formatCurrency(totalVolume), color: colors.secondary },
            { label: 'PURCHASES', value: purchaseCount.toString(), color: colors.success },
            { label: 'ALLOTTED', value: allottedCount.toString(), color: '#10B981' },
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

        {/* Filters Bar */}
        <FACard className="mb-4">
          <div className="flex items-center gap-3 flex-wrap">
            {/* Search */}
            <div className="flex-1 min-w-[200px] max-w-xs relative">
              <svg
                className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4"
                style={{ color: colors.textTertiary }}
                fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}
              >
                <path strokeLinecap="round" strokeLinejoin="round" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
              </svg>
              <input
                type="text"
                placeholder="Search client or scheme..."
                value={searchInput}
                onChange={e => handleSearchChange(e.target.value)}
                className="w-full h-9 pl-9 pr-3 rounded-lg text-sm focus:outline-none"
                style={{
                  background: colors.inputBg,
                  border: `1px solid ${colors.inputBorder}`,
                  color: colors.textPrimary,
                }}
              />
            </div>

            <div className="w-px h-6" style={{ background: colors.cardBorder }} />

            {/* Type filter */}
            <select
              value={typeFilter}
              onChange={e => { setTypeFilter(e.target.value as OrderType | 'All'); setPage(1) }}
              className="h-9 px-3 rounded-lg text-sm focus:outline-none cursor-pointer"
              style={{
                background: colors.inputBg,
                border: `1px solid ${typeFilter !== 'All' ? colors.primary : colors.inputBorder}`,
                color: typeFilter !== 'All' ? colors.primary : colors.textSecondary,
              }}
            >
              <option value="All">All Types</option>
              {ORDER_TYPES.map(t => <option key={t} value={t}>{t}</option>)}
            </select>

            {/* Status filter */}
            <select
              value={statusFilter}
              onChange={e => { setStatusFilter(e.target.value as OrderStatus | 'All'); setPage(1) }}
              className="h-9 px-3 rounded-lg text-sm focus:outline-none cursor-pointer"
              style={{
                background: colors.inputBg,
                border: `1px solid ${statusFilter !== 'All' ? colors.primary : colors.inputBorder}`,
                color: statusFilter !== 'All' ? colors.primary : colors.textSecondary,
              }}
            >
              <option value="All">All Status</option>
              {ORDER_STATUSES.map(s => <option key={s} value={s}>{s}</option>)}
            </select>

            {hasActiveFilters && (
              <button
                onClick={clearFilters}
                className="h-9 px-3 rounded-lg text-xs font-medium flex items-center gap-1 transition-all"
                style={{ color: colors.primary, background: colors.chipBg }}
              >
                <svg className="w-3 h-3" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
                  <path strokeLinecap="round" strokeLinejoin="round" d="M6 18L18 6M6 6l12 12" />
                </svg>
                Clear
              </button>
            )}
          </div>
        </FACard>

        {/* Orders Table */}
        <FACard padding="none" className="overflow-hidden">
          {loading ? (
            <div className="flex items-center justify-center py-20">
              <div className="flex items-center gap-3">
                <div
                  className="w-5 h-5 rounded-full border-2 border-t-transparent animate-spin"
                  style={{ borderColor: `${colors.primary} transparent ${colors.primary} ${colors.primary}` }}
                />
                <span className="text-sm" style={{ color: colors.textSecondary }}>Loading orders...</span>
              </div>
            </div>
          ) : error ? (
            <div className="py-8">
              <FAEmptyState
                icon={
                  <svg className="w-10 h-10" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.5}>
                    <path strokeLinecap="round" strokeLinejoin="round" d="M12 9v3.75m-9.303 3.376c-.866 1.5.217 3.374 1.948 3.374h14.71c1.73 0 2.813-1.874 1.948-3.374L13.949 3.378c-.866-1.5-3.032-1.5-3.898 0L2.697 16.126zM12 15.75h.007v.008H12v-.008z" />
                  </svg>
                }
                title="Error loading orders"
                description={error}
                action={<FAButton onClick={fetchOrders}>Retry</FAButton>}
              />
            </div>
          ) : orders.length === 0 ? (
            <div className="py-8">
              <FAEmptyState
                icon={
                  <svg className="w-10 h-10" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.5}>
                    <path strokeLinecap="round" strokeLinejoin="round" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
                  </svg>
                }
                title={hasActiveFilters ? 'No matching orders' : 'No BSE orders yet'}
                description={hasActiveFilters ? 'Try adjusting your filters' : 'Orders placed via BSE StAR MF will appear here'}
              />
            </div>
          ) : (
            <>
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
                      <th className="text-left px-4 py-3 text-xs font-semibold uppercase tracking-wider" style={{ color: colors.primary }}>Date</th>
                      <th className="text-left px-4 py-3 text-xs font-semibold uppercase tracking-wider" style={{ color: colors.primary }}>Client</th>
                      <th className="text-left px-4 py-3 text-xs font-semibold uppercase tracking-wider" style={{ color: colors.primary }}>Scheme</th>
                      <th className="text-center px-4 py-3 text-xs font-semibold uppercase tracking-wider" style={{ color: colors.primary }}>Type</th>
                      <th className="text-right px-4 py-3 text-xs font-semibold uppercase tracking-wider" style={{ color: colors.primary }}>Amount</th>
                      <th className="text-right px-4 py-3 text-xs font-semibold uppercase tracking-wider" style={{ color: colors.primary }}>Units @ NAV</th>
                      <th className="text-center px-4 py-3 text-xs font-semibold uppercase tracking-wider" style={{ color: colors.primary }}>Status</th>
                      <th className="w-8 px-2"></th>
                    </tr>
                  </thead>
                  <tbody>
                    {orders.map(order => {
                      const typeColor = ORDER_TYPE_COLORS[order.orderType]
                      const statusColor = STATUS_COLORS[order.status]
                      const isExpanded = expandedOrderId === order.id

                      return (
                        <tr key={order.id}>
                          <td
                            colSpan={8}
                            className="p-0"
                          >
                            {/* Main Row */}
                            <div
                              className="flex items-center transition-colors cursor-pointer"
                              style={{ borderBottom: isExpanded ? 'none' : `1px solid ${colors.cardBorder}` }}
                              onClick={() => setExpandedOrderId(isExpanded ? null : order.id)}
                              onMouseEnter={e => e.currentTarget.style.background = isDark ? 'rgba(147,197,253,0.04)' : 'rgba(59,130,246,0.02)'}
                              onMouseLeave={e => e.currentTarget.style.background = 'transparent'}
                            >
                              <div className="px-4 py-3 text-sm whitespace-nowrap min-w-[90px]" style={{ color: colors.textSecondary }}>
                                {new Date(order.orderDate).toLocaleDateString('en-IN', { day: '2-digit', month: 'short', year: '2-digit' })}
                              </div>
                              <div className="px-4 py-3 min-w-[140px]">
                                <p className="text-sm font-medium truncate max-w-[160px]" style={{ color: colors.textPrimary }}>{order.clientName}</p>
                                <p className="text-xs" style={{ color: colors.textTertiary }}>{order.clientCode}</p>
                              </div>
                              <div className="px-4 py-3 flex-1 min-w-[180px]">
                                <p className="text-sm truncate max-w-[260px]" style={{ color: colors.textPrimary }}>{order.schemeName}</p>
                                <p className="text-xs font-mono" style={{ color: colors.textTertiary }}>{order.schemeCode}</p>
                              </div>
                              <div className="px-4 py-3 text-center min-w-[90px]">
                                <span
                                  className="text-xs font-semibold px-2 py-0.5 rounded"
                                  style={{ background: `${typeColor}15`, color: typeColor }}
                                >
                                  {order.orderType}
                                </span>
                              </div>
                              <div className="px-4 py-3 text-right text-sm font-semibold whitespace-nowrap min-w-[100px]" style={{ color: colors.textPrimary }}>
                                {formatCurrency(order.amount)}
                              </div>
                              <div className="px-4 py-3 text-right text-sm whitespace-nowrap min-w-[120px]" style={{ color: colors.textSecondary }}>
                                {order.units ? `${order.units.toFixed(3)} @ ${formatCurrency(order.nav || 0)}` : '-'}
                              </div>
                              <div className="px-4 py-3 text-center min-w-[100px]">
                                <span
                                  className="inline-flex items-center gap-1 text-xs font-medium px-2 py-0.5 rounded"
                                  style={{ background: `${statusColor}15`, color: statusColor }}
                                >
                                  <span className="w-1.5 h-1.5 rounded-full" style={{ background: statusColor }} />
                                  {order.status}
                                </span>
                              </div>
                              <div className="px-2 py-3">
                                <svg
                                  className="w-4 h-4 transition-transform"
                                  style={{ color: colors.textTertiary, transform: isExpanded ? 'rotate(90deg)' : 'rotate(0deg)' }}
                                  fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}
                                >
                                  <path strokeLinecap="round" strokeLinejoin="round" d="M9 5l7 7-7 7" />
                                </svg>
                              </div>
                            </div>

                            {/* Expanded Detail */}
                            {isExpanded && (
                              <div
                                className="px-5 py-3"
                                style={{
                                  background: isDark ? 'rgba(147, 197, 253, 0.03)' : 'rgba(59, 130, 246, 0.02)',
                                  borderBottom: `1px solid ${colors.cardBorder}`,
                                }}
                              >
                                <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
                                  <div>
                                    <p className="text-xs" style={{ color: colors.textTertiary }}>Order ID</p>
                                    <p className="text-sm font-medium font-mono" style={{ color: colors.textPrimary }}>{order.orderId}</p>
                                  </div>
                                  <div>
                                    <p className="text-xs" style={{ color: colors.textTertiary }}>Scheme Code</p>
                                    <p className="text-sm font-medium font-mono" style={{ color: colors.textPrimary }}>{order.schemeCode}</p>
                                  </div>
                                  <div>
                                    <p className="text-xs" style={{ color: colors.textTertiary }}>Order Date</p>
                                    <p className="text-sm font-medium" style={{ color: colors.textPrimary }}>
                                      {new Date(order.orderDate).toLocaleDateString('en-IN')}
                                    </p>
                                  </div>
                                  {order.allotmentDate && (
                                    <div>
                                      <p className="text-xs" style={{ color: colors.textTertiary }}>Allotment Date</p>
                                      <p className="text-sm font-medium" style={{ color: colors.textPrimary }}>
                                        {new Date(order.allotmentDate).toLocaleDateString('en-IN')}
                                      </p>
                                    </div>
                                  )}
                                  {order.bseRemarks && (
                                    <div className="col-span-2">
                                      <p className="text-xs" style={{ color: colors.textTertiary }}>BSE Remarks</p>
                                      <p className="text-sm" style={{ color: colors.textSecondary }}>{order.bseRemarks}</p>
                                    </div>
                                  )}
                                </div>
                                {order.status === 'Placed' && (
                                  <div className="mt-3 flex items-center gap-2">
                                    <button
                                      onClick={async (e) => {
                                        e.stopPropagation()
                                        try {
                                          await bseApi.orders.cancel(order.id)
                                          fetchOrders()
                                        } catch {
                                          // Handle error silently
                                        }
                                      }}
                                      className="px-3 py-1.5 rounded-full text-xs font-medium transition-all"
                                      style={{
                                        background: `${colors.error}10`,
                                        border: `1px solid ${colors.error}30`,
                                        color: colors.error,
                                      }}
                                    >
                                      Cancel Order
                                    </button>
                                  </div>
                                )}
                              </div>
                            )}
                          </td>
                        </tr>
                      )
                    })}
                  </tbody>
                </table>
              </div>

              {/* Pagination */}
              {totalPages > 1 && (
                <div
                  className="flex items-center justify-between px-4 py-3"
                  style={{ borderTop: `1px solid ${colors.cardBorder}` }}
                >
                  <p className="text-sm" style={{ color: colors.textTertiary }}>
                    {startItem}-{endItem} of {total.toLocaleString('en-IN')}
                  </p>
                  <div className="flex items-center gap-1">
                    <button
                      onClick={() => setPage(p => Math.max(1, p - 1))}
                      disabled={page === 1}
                      className="p-1.5 rounded-lg transition-all disabled:opacity-30"
                      style={{ color: colors.textSecondary }}
                    >
                      <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
                        <path strokeLinecap="round" strokeLinejoin="round" d="M15 19l-7-7 7-7" />
                      </svg>
                    </button>

                    {Array.from({ length: totalPages }, (_, i) => i + 1)
                      .filter(p => p === 1 || p === totalPages || Math.abs(p - page) <= 1)
                      .reduce<(number | '...')[]>((acc, p, i, arr) => {
                        if (i > 0 && p - (arr[i - 1] as number) > 1) acc.push('...')
                        acc.push(p)
                        return acc
                      }, [])
                      .map((p, i) =>
                        p === '...' ? (
                          <span key={`ellipsis-${i}`} className="px-1 text-sm" style={{ color: colors.textTertiary }}>...</span>
                        ) : (
                          <button
                            key={p}
                            onClick={() => setPage(p as number)}
                            className="w-8 h-8 rounded-lg text-sm font-medium transition-all"
                            style={{
                              background: page === p ? colors.primary : 'transparent',
                              color: page === p ? 'white' : colors.textSecondary,
                            }}
                          >
                            {p}
                          </button>
                        )
                    )}

                    <button
                      onClick={() => setPage(p => Math.min(totalPages, p + 1))}
                      disabled={page === totalPages}
                      className="p-1.5 rounded-lg transition-all disabled:opacity-30"
                      style={{ color: colors.textSecondary }}
                    >
                      <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
                        <path strokeLinecap="round" strokeLinejoin="round" d="M9 5l7 7-7 7" />
                      </svg>
                    </button>
                  </div>
                </div>
              )}
            </>
          )}
        </FACard>
      </div>
    </AdvisorLayout>
  )
}

export default BSEOrdersPage
