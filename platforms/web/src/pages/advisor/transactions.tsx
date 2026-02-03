/**
 * Transactions Page
 *
 * Execute and track client mutual fund transactions.
 * Supports: Buy, Sell, SIP, SWP, Switch, STP
 */

import { useState, useEffect, useCallback } from 'react'
import { useRouter } from 'next/router'
import AdvisorLayout from '@/components/layout/AdvisorLayout'
import { useFATheme, formatCurrency, getTransactionTypeColor, getStatusColor } from '@/utils/fa'
import { Transaction, TransactionType, TransactionStatus, TransactionFormData } from '@/utils/faTypes'
import {
  FACard,
  FAStatCard,
  FAChip,
  FASearchInput,
  FASelect,
  FAButton,
  FAEmptyState,
  FALoadingState,
  FAInput,
  useNotification,
} from '@/components/advisor/shared'
import TransactionFormModal from '@/components/advisor/TransactionFormModal'
import { transactionsApi, sipsApi } from '@/services/api'

// Mock transactions data (fallback when API is not available)
const mockTransactions: Transaction[] = [
  { id: '1', clientId: 'c1', clientName: 'Rajesh Sharma', fundName: 'HDFC Mid-Cap Opportunities Fund', fundSchemeCode: '112090', fundCategory: 'Equity', type: 'Buy', amount: 50000, units: 125.45, nav: 398.56, status: 'Completed', date: '2024-01-20', folioNumber: 'HDFC-123456' },
  { id: '2', clientId: 'c2', clientName: 'Priya Patel', fundName: 'ICICI Prudential Bluechip Fund', fundSchemeCode: '120594', fundCategory: 'Equity', type: 'SIP', amount: 25000, units: 52.18, nav: 479.12, status: 'Completed', date: '2024-01-20', folioNumber: 'ICICI-789012' },
  { id: '3', clientId: 'c3', clientName: 'Amit Kumar', fundName: 'Axis Short Term Fund', fundSchemeCode: '118989', fundCategory: 'Debt', type: 'Buy', amount: 100000, units: 3892.15, nav: 25.69, status: 'Processing', date: '2024-01-19', folioNumber: 'AXIS-345678' },
  { id: '4', clientId: 'c4', clientName: 'Sneha Gupta', fundName: 'SBI Equity Hybrid Fund', fundSchemeCode: '119598', fundCategory: 'Hybrid', type: 'Sell', amount: 75000, units: 312.50, nav: 240.00, status: 'Pending', date: '2024-01-19', folioNumber: 'SBI-901234' },
  { id: '5', clientId: 'c5', clientName: 'Vikram Singh', fundName: 'Mirae Asset Large Cap Fund', fundSchemeCode: '122639', fundCategory: 'Equity', type: 'Switch', amount: 200000, units: 1875.00, nav: 106.67, status: 'Completed', date: '2024-01-18', folioNumber: 'MIRAE-567890' },
  { id: '6', clientId: 'c6', clientName: 'Meera Krishnan', fundName: 'Kotak Corporate Bond Fund', fundSchemeCode: '135781', fundCategory: 'Debt', type: 'SIP', amount: 15000, units: 4687.50, nav: 32.00, status: 'Completed', date: '2024-01-18', folioNumber: 'KOTAK-123789' },
  { id: '7', clientId: 'c7', clientName: 'Arjun Mehta', fundName: 'Nippon India Small Cap Fund', fundSchemeCode: '112323', fundCategory: 'Equity', type: 'Buy', amount: 30000, units: 234.38, nav: 128.00, status: 'Failed', date: '2024-01-17', folioNumber: 'NIP-456012' },
  { id: '8', clientId: 'c8', clientName: 'Kavita Rao', fundName: 'UTI Nifty 50 Index Fund', fundSchemeCode: '120503', fundCategory: 'Index', type: 'SWP', amount: 20000, units: 125.00, nav: 160.00, status: 'Completed', date: '2024-01-17', folioNumber: 'UTI-789345' },
  { id: '9', clientId: 'c1', clientName: 'Rajesh Sharma', fundName: 'Parag Parikh Flexi Cap Fund', fundSchemeCode: '135781', fundCategory: 'Equity', type: 'SIP', amount: 10000, units: 156.25, nav: 64.00, status: 'Completed', date: '2024-01-15', folioNumber: 'PPFAS-012678' },
  { id: '10', clientId: 'c2', clientName: 'Priya Patel', fundName: 'DSP Tax Saver Fund', fundSchemeCode: '119034', fundCategory: 'ELSS', type: 'Buy', amount: 150000, units: 1562.50, nav: 96.00, status: 'Completed', date: '2024-01-15', folioNumber: 'DSP-345901' },
]

const TransactionsPage = () => {
  const router = useRouter()
  const { colors, isDark } = useFATheme()
  const notification = useNotification()
  const [transactions, setTransactions] = useState<Transaction[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [searchTerm, setSearchTerm] = useState('')
  const [filterType, setFilterType] = useState<string>('all')
  const [filterStatus, setFilterStatus] = useState<string>('all')
  const [dateFrom, setDateFrom] = useState<string>('')
  const [dateTo, setDateTo] = useState<string>('')
  const [showNewTransaction, setShowNewTransaction] = useState(false)
  const [selectedTransactionType, setSelectedTransactionType] = useState<TransactionType>('Buy')
  const [submitting, setSubmitting] = useState(false)

  // Fetch transactions from API
  const fetchTransactions = useCallback(async () => {
    try {
      setLoading(true)
      setError(null)
      const response = await transactionsApi.list<Transaction>({
        search: searchTerm || undefined,
        type: filterType !== 'all' ? filterType : undefined,
        status: filterStatus !== 'all' ? filterStatus : undefined,
        dateFrom: dateFrom || undefined,
        dateTo: dateTo || undefined,
      })
      setTransactions(response.data)
    } catch {
      setError('Using demo data - API not available')
      setTransactions(mockTransactions)
    } finally {
      setLoading(false)
    }
  }, [searchTerm, filterType, filterStatus, dateFrom, dateTo])

  useEffect(() => {
    fetchTransactions()
  }, [fetchTransactions])

  // Client-side filtering for mock data
  const filteredTransactions = error
    ? transactions.filter(txn => {
        const matchesSearch = txn.clientName.toLowerCase().includes(searchTerm.toLowerCase()) ||
                             txn.fundName.toLowerCase().includes(searchTerm.toLowerCase()) ||
                             txn.folioNumber.toLowerCase().includes(searchTerm.toLowerCase())
        const matchesType = filterType === 'all' || txn.type === filterType
        const matchesStatus = filterStatus === 'all' || txn.status === filterStatus
        return matchesSearch && matchesType && matchesStatus
      })
    : transactions

  const totalVolume = transactions.reduce((sum, t) => sum + t.amount, 0)
  const completedTxns = transactions.filter(t => t.status === 'Completed').length
  const pendingTxns = transactions.filter(t => t.status === 'Pending' || t.status === 'Processing').length

  const handleQuickAction = (type: TransactionType) => {
    setSelectedTransactionType(type)
    setShowNewTransaction(true)
  }

  const handleNewTransaction = async (data: TransactionFormData) => {
    setSubmitting(true)
    try {
      if (data.type === 'Buy') {
        await transactionsApi.createLumpsum({
          clientId: data.clientId,
          fundSchemeCode: data.fundSchemeCode,
          amount: data.amount,
          folioNumber: data.folioNumber || undefined,
          paymentMode: data.paymentMode,
        })
        notification.success('Order Placed', 'Lumpsum purchase order has been submitted successfully.')
      } else if (data.type === 'Sell') {
        await transactionsApi.createRedemption({
          clientId: data.clientId,
          fundSchemeCode: data.fundSchemeCode,
          amount: data.amount,
          folioNumber: data.folioNumber || undefined,
        })
        notification.success('Redemption Submitted', 'Redemption request has been submitted successfully.')
      } else if (data.type === 'SIP') {
        await sipsApi.create({
          clientId: data.clientId,
          fundName: data.fundName || '',
          fundSchemeCode: data.fundSchemeCode,
          folioNumber: data.folioNumber || undefined,
          amount: data.amount,
          frequency: (data.sipFrequency?.toUpperCase() || 'MONTHLY') as 'DAILY' | 'WEEKLY' | 'MONTHLY' | 'QUARTERLY',
          sipDate: data.sipDate || 5,
          startDate: data.sipStartDate || new Date().toISOString().split('T')[0],
          endDate: data.sipEndDate || undefined,
          isPerpetual: data.isPerpetual ?? true,
        })
        notification.success('SIP Registered', 'New SIP has been registered successfully.')
      } else {
        notification.info('Coming Soon', `${data.type} transactions will be available soon.`)
      }
      fetchTransactions()
      setShowNewTransaction(false)
    } catch (err) {
      notification.error('Transaction Failed', err instanceof Error ? err.message : 'Failed to process transaction')
    } finally {
      setSubmitting(false)
    }
  }

  const handleRowClick = (txn: Transaction) => {
    router.push(`/advisor/transactions/${txn.id}`)
  }

  const quickActions = [
    { type: 'Buy' as TransactionType, label: 'Buy', icon: 'M12 6v6m0 0v6m0-6h6m-6 0H6', pastel: 'pastelMint' },
    { type: 'Sell' as TransactionType, label: 'Sell', icon: 'M20 12H4', pastel: 'pastelRose' },
    { type: 'SIP' as TransactionType, label: 'SIP', icon: 'M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15', pastel: 'pastelIndigo' },
    { type: 'SWP' as TransactionType, label: 'SWP', icon: 'M17 16l4-4m0 0l-4-4m4 4H7m6 4v1a3 3 0 01-3 3H6a3 3 0 01-3-3V7a3 3 0 013-3h4a3 3 0 013 3v1', pastel: 'pastelPeach' },
    { type: 'Switch' as TransactionType, label: 'Switch', icon: 'M8 7h12m0 0l-4-4m4 4l-4 4m0 6H4m0 0l4 4m-4-4l4-4', pastel: 'pastelPurple' },
  ]

  return (
    <AdvisorLayout title="Transactions">
      <div style={{ background: colors.background, minHeight: '100%', margin: '-2rem', padding: '2rem' }}>
        {/* Header */}
        <div className="flex items-center justify-between mb-8">
          <div>
            <p className="text-sm" style={{ color: colors.textSecondary }}>Execute and track client transactions</p>
          </div>
          <FAButton
            onClick={() => setShowNewTransaction(true)}
            className="flex items-center gap-2"
          >
            <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
              <path strokeLinecap="round" strokeLinejoin="round" d="M12 4v16m8-8H4" />
            </svg>
            New Transaction
          </FAButton>
        </div>

        {/* Summary Cards */}
        <div className="grid grid-cols-4 gap-4 mb-8">
          <FAStatCard
            label="Total Volume"
            value={formatCurrency(totalVolume)}
            change="This month"
            accentColor={colors.primary}
          />
          <FAStatCard
            label="Transactions"
            value={transactions.length.toString()}
            change="This month"
            accentColor={colors.secondary}
          />
          <FAStatCard
            label="Completed"
            value={completedTxns.toString()}
            change={`${((completedTxns / transactions.length) * 100).toFixed(0)}% success rate`}
            accentColor={colors.success}
          />
          <FAStatCard
            label="Pending"
            value={pendingTxns.toString()}
            change="Awaiting processing"
            accentColor={colors.warning}
          />
        </div>

        {/* Quick Actions */}
        <div className="grid grid-cols-5 gap-3 mb-8">
          {quickActions.map((action) => {
            const actionColor = getTransactionTypeColor(action.type, colors)
            return (
              <button
                key={action.type}
                onClick={() => handleQuickAction(action.type)}
                className="p-4 rounded-2xl transition-all duration-300 hover:-translate-y-1 hover:shadow-lg flex flex-col items-center gap-2"
                style={{
                  background: `${actionColor}${isDark ? '15' : '10'}`,
                  border: `1px solid ${actionColor}30`,
                }}
              >
                <div
                  className="w-10 h-10 rounded-xl flex items-center justify-center"
                  style={{ background: `${actionColor}20` }}
                >
                  <svg className="w-5 h-5" style={{ color: actionColor }} fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
                    <path strokeLinecap="round" strokeLinejoin="round" d={action.icon} />
                  </svg>
                </div>
                <span className="text-sm font-semibold" style={{ color: actionColor }}>{action.label}</span>
              </button>
            )
          })}
        </div>

        {/* Filters */}
        <FACard className="mb-6">
          <div className="flex items-center gap-4 flex-wrap">
            <div className="flex-1 min-w-[200px]">
              <FASearchInput
                placeholder="Search by client, fund, or folio..."
                value={searchTerm}
                onChange={setSearchTerm}
              />
            </div>
            <FASelect
              options={[
                { value: 'all', label: 'All Types' },
                { value: 'Buy', label: 'Buy' },
                { value: 'Sell', label: 'Sell' },
                { value: 'SIP', label: 'SIP' },
                { value: 'SWP', label: 'SWP' },
                { value: 'Switch', label: 'Switch' },
              ]}
              value={filterType}
              onChange={(e) => setFilterType(e.target.value)}
              containerClassName="w-36"
            />
            <FASelect
              options={[
                { value: 'all', label: 'All Status' },
                { value: 'Completed', label: 'Completed' },
                { value: 'Pending', label: 'Pending' },
                { value: 'Processing', label: 'Processing' },
                { value: 'Failed', label: 'Failed' },
              ]}
              value={filterStatus}
              onChange={(e) => setFilterStatus(e.target.value)}
              containerClassName="w-36"
            />
            <div className="flex items-center gap-2">
              <FAInput
                type="date"
                placeholder="From"
                value={dateFrom}
                onChange={(e) => setDateFrom(e.target.value)}
                containerClassName="w-36"
              />
              <span className="text-sm" style={{ color: colors.textTertiary }}>to</span>
              <FAInput
                type="date"
                placeholder="To"
                value={dateTo}
                onChange={(e) => setDateTo(e.target.value)}
                containerClassName="w-36"
              />
            </div>
            {(dateFrom || dateTo) && (
              <button
                onClick={() => { setDateFrom(''); setDateTo(''); }}
                className="text-xs px-2 py-1 rounded"
                style={{ color: colors.primary, background: colors.chipBg }}
              >
                Clear dates
              </button>
            )}
          </div>
        </FACard>

        {/* Transactions Table */}
        {loading ? (
          <FALoadingState message="Loading transactions..." />
        ) : (
        <FACard className="overflow-hidden">
          <table className="w-full">
            <thead>
              <tr style={{ background: colors.chipBg }}>
                <th className="text-left p-4 text-xs font-semibold uppercase tracking-wider" style={{ color: colors.textTertiary }}>Client / Fund</th>
                <th className="text-left p-4 text-xs font-semibold uppercase tracking-wider" style={{ color: colors.textTertiary }}>Type</th>
                <th className="text-right p-4 text-xs font-semibold uppercase tracking-wider" style={{ color: colors.textTertiary }}>Amount</th>
                <th className="text-right p-4 text-xs font-semibold uppercase tracking-wider" style={{ color: colors.textTertiary }}>Units</th>
                <th className="text-right p-4 text-xs font-semibold uppercase tracking-wider" style={{ color: colors.textTertiary }}>NAV</th>
                <th className="text-center p-4 text-xs font-semibold uppercase tracking-wider" style={{ color: colors.textTertiary }}>Status</th>
                <th className="text-right p-4 text-xs font-semibold uppercase tracking-wider" style={{ color: colors.textTertiary }}>Date</th>
                <th className="p-4"></th>
              </tr>
            </thead>
            <tbody>
              {filteredTransactions.map((txn, i) => {
                const typeColor = getTransactionTypeColor(txn.type, colors)
                const statusColor = getStatusColor(txn.status, colors)
                return (
                  <tr
                    key={txn.id}
                    onClick={() => handleRowClick(txn)}
                    className="transition-colors cursor-pointer"
                    style={{
                      borderTop: i > 0 ? `1px solid ${colors.cardBorder}` : undefined
                    }}
                    onMouseEnter={(e) => {
                      e.currentTarget.style.background = isDark
                        ? 'rgba(147, 197, 253, 0.05)'
                        : 'rgba(59, 130, 246, 0.03)'
                    }}
                    onMouseLeave={(e) => {
                      e.currentTarget.style.background = 'transparent'
                    }}
                  >
                    <td className="p-4">
                      <p className="text-base font-semibold" style={{ color: colors.textPrimary }}>{txn.clientName}</p>
                      <p className="text-sm" style={{ color: colors.textSecondary }}>{txn.fundName}</p>
                      <p className="text-xs" style={{ color: colors.textTertiary }}>{txn.folioNumber}</p>
                    </td>
                    <td className="p-4">
                      <FAChip color={typeColor}>{txn.type}</FAChip>
                    </td>
                    <td className="p-4 text-right font-bold" style={{ color: colors.textPrimary }}>
                      {formatCurrency(txn.amount)}
                    </td>
                    <td className="p-4 text-right" style={{ color: colors.textSecondary }}>
                      {txn.units.toFixed(2)}
                    </td>
                    <td className="p-4 text-right" style={{ color: colors.textSecondary }}>
                      {formatCurrency(txn.nav)}
                    </td>
                    <td className="p-4 text-center">
                      <FAChip color={statusColor}>{txn.status}</FAChip>
                    </td>
                    <td className="p-4 text-right text-sm" style={{ color: colors.textSecondary }}>
                      {new Date(txn.date).toLocaleDateString('en-IN', { day: 'numeric', month: 'short' })}
                    </td>
                    <td className="p-4">
                      <button
                        onClick={(e) => {
                          e.stopPropagation()
                          handleRowClick(txn)
                        }}
                        className="p-2 rounded-lg transition-all hover:scale-105"
                        style={{ background: colors.chipBg, color: colors.primary }}
                        title="View details"
                      >
                        <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
                          <path strokeLinecap="round" strokeLinejoin="round" d="M9 5l7 7-7 7" />
                        </svg>
                      </button>
                    </td>
                  </tr>
                )
              })}
            </tbody>
          </table>

          {filteredTransactions.length === 0 && (
            <FAEmptyState
              icon={
                <svg className="w-12 h-12" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.5}>
                  <path strokeLinecap="round" strokeLinejoin="round" d="M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
                </svg>
              }
              title="No transactions found"
              description="Try adjusting your search or filters"
            />
          )}
        </FACard>
        )}
      </div>

      {/* Transaction Modal */}
      <TransactionFormModal
        isOpen={showNewTransaction}
        onClose={() => setShowNewTransaction(false)}
        onSubmit={handleNewTransaction}
        clientId="c1"
        clientName="Sample Client"
        initialType={selectedTransactionType}
      />
    </AdvisorLayout>
  )
}

export default TransactionsPage
