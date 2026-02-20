/**
 * BSE Reports Viewer
 *
 * Tabbed report interface for BSE StAR MF reports:
 * - Order Status Report
 * - Allotment Statement
 * - Redemption Statement
 */

import { useState, useCallback } from 'react'
import AdvisorLayout from '@/components/layout/AdvisorLayout'
import { useFATheme, formatCurrency } from '@/utils/fa'
import { bseApi } from '@/services/api'
import {
  FACard,
  FAButton,
  FAInput,
  FAEmptyState,
  FASpinner,
} from '@/components/advisor/shared'

type ReportTab = 'order-status' | 'allotment' | 'redemption'

interface ReportRow {
  [key: string]: string | number | undefined
}

const TABS: { id: ReportTab; label: string; icon: string }[] = [
  {
    id: 'order-status',
    label: 'Order Status',
    icon: 'M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2',
  },
  {
    id: 'allotment',
    label: 'Allotment Statement',
    icon: 'M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z',
  },
  {
    id: 'redemption',
    label: 'Redemption Statement',
    icon: 'M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1M21 12a9 9 0 11-18 0 9 9 0 0118 0z',
  },
]

const BSEReportsPage = () => {
  const { colors, isDark } = useFATheme()

  const [activeTab, setActiveTab] = useState<ReportTab>('order-status')
  const [dateFrom, setDateFrom] = useState('')
  const [dateTo, setDateTo] = useState('')
  const [clientCode, setClientCode] = useState('')
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [results, setResults] = useState<ReportRow[]>([])
  const [columns, setColumns] = useState<string[]>([])
  const [hasSearched, setHasSearched] = useState(false)

  // Fetch report data
  const fetchReport = useCallback(async () => {
    if (!dateFrom || !dateTo) {
      setError('Please select both From and To dates')
      return
    }

    try {
      setLoading(true)
      setError(null)
      setHasSearched(true)

      const payload: Record<string, string> = {
        fromDate: dateFrom,
        toDate: dateTo,
      }
      if (clientCode.trim()) {
        payload.clientCode = clientCode.trim()
      }

      let res: any
      switch (activeTab) {
        case 'order-status':
          res = await bseApi.reports.orderStatus(payload)
          break
        case 'allotment':
          res = await bseApi.reports.allotment(payload)
          break
        case 'redemption':
          res = await bseApi.reports.redemption(payload)
          break
      }

      const data: ReportRow[] = Array.isArray(res) ? res : res?.data || []
      setResults(data)

      // Extract columns from first row
      if (data.length > 0) {
        setColumns(Object.keys(data[0]))
      } else {
        setColumns([])
      }
    } catch (err) {
      console.error('[BSE Reports] Error:', err)
      setError(err instanceof Error ? err.message : 'Failed to fetch report')
      setResults([])
      setColumns([])
    } finally {
      setLoading(false)
    }
  }, [activeTab, dateFrom, dateTo, clientCode])

  // Export to CSV
  const handleExportCSV = () => {
    if (results.length === 0 || columns.length === 0) return

    const csvHeader = columns.join(',')
    const csvRows = results.map(row =>
      columns.map(col => {
        const val = row[col]
        const str = val !== undefined && val !== null ? String(val) : ''
        // Escape commas and quotes
        if (str.includes(',') || str.includes('"') || str.includes('\n')) {
          return `"${str.replace(/"/g, '""')}"`
        }
        return str
      }).join(',')
    )
    const csv = [csvHeader, ...csvRows].join('\n')

    const blob = new Blob([csv], { type: 'text/csv;charset=utf-8;' })
    const url = URL.createObjectURL(blob)
    const link = document.createElement('a')
    link.href = url
    link.download = `bse-${activeTab}-${dateFrom}-to-${dateTo}.csv`
    document.body.appendChild(link)
    link.click()
    document.body.removeChild(link)
    URL.revokeObjectURL(url)
  }

  // Format cell value for display
  const formatCellValue = (value: string | number | undefined, column: string): string => {
    if (value === undefined || value === null) return '-'
    const strVal = String(value)
    // Try formatting as currency for amount-like columns
    const amountKeys = ['amount', 'nav', 'units', 'value', 'price', 'total']
    if (typeof value === 'number' && amountKeys.some(k => column.toLowerCase().includes(k))) {
      return formatCurrency(value)
    }
    return strVal
  }

  return (
    <AdvisorLayout title="BSE Reports">
      <div style={{ background: colors.background, minHeight: '100%', margin: '-2rem', padding: '2rem' }}>
        {/* Header */}
        <div className="flex items-center justify-between mb-8">
          <div>
            <p className="text-sm" style={{ color: colors.textSecondary }}>
              View BSE StAR MF reports and statements
            </p>
          </div>
          {results.length > 0 && (
            <FAButton
              onClick={handleExportCSV}
              variant="secondary"
              icon={
                <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
                  <path strokeLinecap="round" strokeLinejoin="round" d="M12 10v6m0 0l-3-3m3 3l3-3m2 8H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
                </svg>
              }
            >
              Export CSV
            </FAButton>
          )}
        </div>

        {/* Tabs */}
        <div className="flex items-center gap-1 mb-6">
          {TABS.map(tab => (
            <button
              key={tab.id}
              onClick={() => {
                setActiveTab(tab.id)
                setResults([])
                setColumns([])
                setHasSearched(false)
                setError(null)
              }}
              className="flex items-center gap-2 px-4 py-2.5 rounded-full text-sm font-medium transition-all"
              style={{
                background: activeTab === tab.id
                  ? `linear-gradient(135deg, ${colors.primary} 0%, ${colors.primaryDark} 100%)`
                  : colors.chipBg,
                color: activeTab === tab.id ? '#FFFFFF' : colors.textSecondary,
                border: `1px solid ${activeTab === tab.id ? 'transparent' : colors.chipBorder}`,
                boxShadow: activeTab === tab.id ? `0 4px 14px ${colors.glassShadow}` : 'none',
              }}
            >
              <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.5}>
                <path strokeLinecap="round" strokeLinejoin="round" d={tab.icon} />
              </svg>
              {tab.label}
            </button>
          ))}
        </div>

        {/* Filter Bar */}
        <div
          className="p-5 rounded-xl mb-6"
          style={{
            background: colors.cardBackground,
            border: `1px solid ${colors.cardBorder}`,
            boxShadow: `0 4px 24px ${colors.glassShadow}`,
          }}
        >
          <div className="flex items-end gap-4 flex-wrap">
            <div className="flex-1 min-w-[160px]">
              <FAInput
                label="From Date"
                required
                type="date"
                value={dateFrom}
                onChange={e => setDateFrom(e.target.value)}
              />
            </div>
            <div className="flex-1 min-w-[160px]">
              <FAInput
                label="To Date"
                required
                type="date"
                value={dateTo}
                onChange={e => setDateTo(e.target.value)}
              />
            </div>
            <div className="flex-1 min-w-[160px]">
              <FAInput
                label="Client Code"
                placeholder="All clients (optional)"
                value={clientCode}
                onChange={e => setClientCode(e.target.value)}
              />
            </div>
            <div>
              <FAButton onClick={fetchReport} loading={loading}>
                <span className="flex items-center gap-2">
                  <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
                    <path strokeLinecap="round" strokeLinejoin="round" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
                  </svg>
                  Fetch Report
                </span>
              </FAButton>
            </div>
          </div>

          {error && (
            <div
              className="p-3 rounded-lg mt-4 text-sm"
              style={{
                background: `${colors.error}10`,
                border: `1px solid ${colors.error}30`,
                color: colors.error,
              }}
            >
              {error}
            </div>
          )}
        </div>

        {/* Results */}
        <FACard padding="none" className="overflow-hidden">
          {loading ? (
            <div className="flex items-center justify-center py-20">
              <div className="flex items-center gap-3">
                <div
                  className="w-5 h-5 rounded-full border-2 border-t-transparent animate-spin"
                  style={{ borderColor: `${colors.primary} transparent ${colors.primary} ${colors.primary}` }}
                />
                <span className="text-sm" style={{ color: colors.textSecondary }}>Fetching report data...</span>
              </div>
            </div>
          ) : !hasSearched ? (
            <div className="py-12">
              <FAEmptyState
                icon={
                  <svg className="w-10 h-10" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.5}>
                    <path strokeLinecap="round" strokeLinejoin="round" d="M19.5 14.25v-2.625a3.375 3.375 0 00-3.375-3.375h-1.5A1.125 1.125 0 0113.5 7.125v-1.5a3.375 3.375 0 00-3.375-3.375H8.25m0 12.75h7.5m-7.5 3H12M10.5 2.25H5.625c-.621 0-1.125.504-1.125 1.125v17.25c0 .621.504 1.125 1.125 1.125h12.75c.621 0 1.125-.504 1.125-1.125V11.25a9 9 0 00-9-9z" />
                  </svg>
                }
                title="Select date range to view report"
                description="Choose a from/to date and optionally filter by client code"
              />
            </div>
          ) : results.length === 0 ? (
            <div className="py-12">
              <FAEmptyState
                icon={
                  <svg className="w-10 h-10" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.5}>
                    <path strokeLinecap="round" strokeLinejoin="round" d="M20.25 7.5l-.625 10.632a2.25 2.25 0 01-2.247 2.118H6.622a2.25 2.25 0 01-2.247-2.118L3.75 7.5m6 4.125l2.25 2.25m0 0l2.25 2.25M12 13.875l2.25-2.25M12 13.875l-2.25 2.25M3.375 7.5h17.25c.621 0 1.125-.504 1.125-1.125v-1.5c0-.621-.504-1.125-1.125-1.125H3.375c-.621 0-1.125.504-1.125 1.125v1.5c0 .621.504 1.125 1.125 1.125z" />
                  </svg>
                }
                title="No data found"
                description="No records match the selected date range and filters"
              />
            </div>
          ) : (
            <>
              {/* Results count + export */}
              <div
                className="flex items-center justify-between px-4 py-3"
                style={{
                  background: isDark
                    ? 'linear-gradient(135deg, rgba(147,197,253,0.06) 0%, rgba(125,211,252,0.03) 100%)'
                    : 'linear-gradient(135deg, rgba(59,130,246,0.05) 0%, rgba(56,189,248,0.02) 100%)',
                  borderBottom: `1px solid ${colors.cardBorder}`,
                }}
              >
                <span className="text-xs font-semibold uppercase tracking-wider" style={{ color: colors.primary }}>
                  {results.length} records
                </span>
                <button
                  onClick={handleExportCSV}
                  className="text-xs font-medium px-2.5 py-1 rounded-full transition-all flex items-center gap-1"
                  style={{ background: colors.chipBg, color: colors.primary }}
                >
                  <svg className="w-3 h-3" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
                    <path strokeLinecap="round" strokeLinejoin="round" d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-4l-4 4m0 0l-4-4m4 4V4" />
                  </svg>
                  CSV
                </button>
              </div>

              {/* Data Table */}
              <div className="overflow-x-auto">
                <table className="w-full">
                  <thead>
                    <tr style={{ borderBottom: `1px solid ${colors.cardBorder}` }}>
                      {columns.map(col => (
                        <th
                          key={col}
                          className="text-left px-4 py-3 text-xs font-semibold uppercase tracking-wider whitespace-nowrap"
                          style={{ color: colors.primary }}
                        >
                          {col.replace(/([A-Z])/g, ' $1').replace(/_/g, ' ').trim()}
                        </th>
                      ))}
                    </tr>
                  </thead>
                  <tbody>
                    {results.map((row, idx) => (
                      <tr
                        key={idx}
                        style={{ borderBottom: `1px solid ${colors.cardBorder}` }}
                        onMouseEnter={e => e.currentTarget.style.background = isDark ? 'rgba(147,197,253,0.04)' : 'rgba(59,130,246,0.02)'}
                        onMouseLeave={e => e.currentTarget.style.background = 'transparent'}
                      >
                        {columns.map(col => (
                          <td
                            key={col}
                            className="px-4 py-3 text-sm whitespace-nowrap"
                            style={{ color: colors.textPrimary }}
                          >
                            {formatCellValue(row[col], col)}
                          </td>
                        ))}
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </>
          )}
        </FACard>
      </div>
    </AdvisorLayout>
  )
}

export default BSEReportsPage
