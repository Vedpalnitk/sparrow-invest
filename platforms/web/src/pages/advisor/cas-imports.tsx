/**
 * CAS Imports Management Page — FA Portal
 *
 * Central view of all CAS PDF imports across clients.
 * Track status, failures, and import history for the ARN.
 */

import { useState, useEffect, useMemo } from 'react'
import { useRouter } from 'next/router'
import AdvisorLayout from '@/components/layout/AdvisorLayout'
import { useFATheme, formatCurrency } from '@/utils/fa'
import { FACard, FAButton, FAEmptyState } from '@/components/advisor/shared'
import { casApi, CASImportRecord } from '@/services/api'

type FilterStatus = 'ALL' | 'COMPLETED' | 'FAILED' | 'PROCESSING'

const CASImportsPage = () => {
  const router = useRouter()
  const { colors, isDark } = useFATheme()
  const [imports, setImports] = useState<CASImportRecord[]>([])
  const [loading, setLoading] = useState(true)
  const [filterStatus, setFilterStatus] = useState<FilterStatus>('ALL')
  const [searchTerm, setSearchTerm] = useState('')

  useEffect(() => {
    loadImports()
  }, [])

  const loadImports = async () => {
    setLoading(true)
    try {
      const data = await casApi.getImports()
      setImports(data)
    } catch {
      // ignore
    } finally {
      setLoading(false)
    }
  }

  // Stats
  const stats = useMemo(() => {
    const total = imports.length
    const completed = imports.filter((i) => i.status === 'COMPLETED').length
    const failed = imports.filter((i) => i.status === 'FAILED').length
    const processing = imports.filter((i) => i.status === 'PROCESSING').length
    const totalValue = imports
      .filter((i) => i.status === 'COMPLETED' && i.totalValue)
      .reduce((sum, i) => sum + (i.totalValue || 0), 0)
    const totalSchemes = imports
      .filter((i) => i.status === 'COMPLETED')
      .reduce((sum, i) => sum + i.schemesImported, 0)
    return { total, completed, failed, processing, totalValue, totalSchemes }
  }, [imports])

  // Filtered list
  const filtered = useMemo(() => {
    let list = imports
    if (filterStatus !== 'ALL') {
      list = list.filter((i) => i.status === filterStatus)
    }
    if (searchTerm) {
      const q = searchTerm.toLowerCase()
      list = list.filter(
        (i) =>
          (i.clientName && i.clientName.toLowerCase().includes(q)) ||
          (i.investorName && i.investorName.toLowerCase().includes(q)) ||
          (i.clientEmail && i.clientEmail.toLowerCase().includes(q)) ||
          (i.investorEmail && i.investorEmail.toLowerCase().includes(q))
      )
    }
    return list
  }, [imports, filterStatus, searchTerm])

  const formatDate = (dateStr: string) => {
    try {
      return new Date(dateStr).toLocaleDateString('en-IN', {
        day: '2-digit',
        month: 'short',
        year: 'numeric',
        hour: '2-digit',
        minute: '2-digit',
      })
    } catch {
      return dateStr
    }
  }

  const statusConfig: Record<string, { bg: string; color: string; label: string }> = {
    COMPLETED: { bg: `${colors.success}12`, color: colors.success, label: 'Completed' },
    FAILED: { bg: `${colors.error}12`, color: colors.error, label: 'Failed' },
    PROCESSING: { bg: `${colors.warning}12`, color: colors.warning, label: 'Processing' },
  }

  return (
    <AdvisorLayout title="CAS Imports">
      <div className="space-y-6">
        {/* Header */}
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-2xl font-bold" style={{ color: colors.textPrimary }}>
              CAS Imports
            </h1>
            <p className="text-sm mt-1" style={{ color: colors.textSecondary }}>
              Track all CAS PDF imports across your clients
            </p>
          </div>
          <button
            onClick={() => router.push('/advisor/cas-import')}
            className="px-5 py-2.5 rounded-full font-semibold text-sm text-white transition-all hover:shadow-lg"
            style={{
              background: `linear-gradient(135deg, ${colors.primary} 0%, ${colors.primaryDark} 100%)`,
              boxShadow: `0 4px 14px ${colors.glassShadow}`,
            }}
          >
            <span className="flex items-center gap-2">
              <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
                <path strokeLinecap="round" strokeLinejoin="round" d="M3 16.5v2.25A2.25 2.25 0 005.25 21h13.5A2.25 2.25 0 0021 18.75V16.5m-13.5-9L12 3m0 0l4.5 4.5M12 3v13.5" />
              </svg>
              Import CAS
            </span>
          </button>
        </div>

        {/* Stats Cards */}
        <div className="grid grid-cols-2 md:grid-cols-4 gap-3">
          {[
            { label: 'Total Imports', value: stats.total, color: colors.primary },
            { label: 'Completed', value: stats.completed, color: colors.success },
            { label: 'Failed', value: stats.failed, color: colors.error },
            { label: 'Total Value', value: stats.totalValue ? formatCurrency(stats.totalValue) : '--', color: colors.primary },
          ].map((stat) => (
            <div
              key={stat.label}
              className="p-4 rounded-xl"
              style={{
                background: `linear-gradient(135deg, ${stat.color}08 0%, ${stat.color}03 100%)`,
                border: `1px solid ${colors.cardBorder}`,
              }}
            >
              <p className="text-xs font-semibold uppercase tracking-wide mb-1" style={{ color: colors.textTertiary }}>
                {stat.label}
              </p>
              <p className="text-xl font-bold" style={{ color: stat.color }}>
                {stat.value}
              </p>
            </div>
          ))}
        </div>

        {/* Filters */}
        <div className="flex items-center gap-3 flex-wrap">
          {/* Status filters */}
          <div className="flex gap-1">
            {(['ALL', 'COMPLETED', 'FAILED', 'PROCESSING'] as FilterStatus[]).map((status) => {
              const isActive = filterStatus === status
              const count = status === 'ALL' ? stats.total : stats[status.toLowerCase() as keyof typeof stats]
              return (
                <button
                  key={status}
                  onClick={() => setFilterStatus(status)}
                  className="px-3 py-1.5 rounded-full text-xs font-semibold transition-all"
                  style={{
                    background: isActive
                      ? `linear-gradient(135deg, ${colors.primary} 0%, ${colors.primaryDark} 100%)`
                      : colors.chipBg,
                    color: isActive ? 'white' : colors.textSecondary,
                    border: `1px solid ${isActive ? 'transparent' : colors.chipBorder}`,
                  }}
                >
                  {status === 'ALL' ? 'All' : status.charAt(0) + status.slice(1).toLowerCase()} ({count})
                </button>
              )
            })}
          </div>

          {/* Search */}
          <div className="flex-1 min-w-[200px]">
            <input
              type="text"
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              placeholder="Search by client or investor name..."
              className="w-full h-9 px-4 rounded-xl text-sm transition-all focus:outline-none"
              style={{
                background: colors.inputBg,
                border: `1px solid ${colors.inputBorder}`,
                color: colors.textPrimary,
              }}
            />
          </div>
        </div>

        {/* Imports List */}
        {loading ? (
          <div className="space-y-3">
            {[1, 2, 3].map((i) => (
              <div key={i} className="h-20 rounded-xl animate-pulse" style={{ background: colors.chipBg }} />
            ))}
          </div>
        ) : filtered.length === 0 ? (
          <div className="p-8 rounded-xl text-center" style={{
            background: colors.cardBg,
            border: `1px solid ${colors.cardBorder}`,
          }}>
            <div className="w-12 h-12 rounded-xl flex items-center justify-center mx-auto mb-3" style={{ background: `${colors.primary}08` }}>
              <svg className="w-6 h-6" style={{ color: colors.textTertiary }} fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.5}>
                <path strokeLinecap="round" strokeLinejoin="round" d="M19.5 14.25v-2.625a3.375 3.375 0 00-3.375-3.375h-1.5A1.125 1.125 0 0113.5 7.125v-1.5a3.375 3.375 0 00-3.375-3.375H8.25m6.75 12H9.75m3 0h.008v.008h-.008v-.008zm0 3h.008v.008h-.008v-.008zm-3 0h.008v.008h-.008v-.008zM10.5 2.25H5.625c-.621 0-1.125.504-1.125 1.125v17.25c0 .621.504 1.125 1.125 1.125h12.75c.621 0 1.125-.504 1.125-1.125V11.25a9 9 0 00-9-9z" />
              </svg>
            </div>
            <p className="text-sm font-semibold mb-1" style={{ color: colors.textPrimary }}>
              {imports.length === 0 ? 'No CAS imports yet' : 'No matching imports'}
            </p>
            <p className="text-xs mb-4" style={{ color: colors.textTertiary }}>
              {imports.length === 0
                ? 'Import a CAS PDF to populate client portfolios automatically.'
                : 'Try adjusting your filters or search term.'}
            </p>
            {imports.length === 0 && (
              <button
                onClick={() => router.push('/advisor/cas-import')}
                className="px-5 py-2 rounded-full font-semibold text-sm text-white transition-all hover:shadow-lg"
                style={{
                  background: `linear-gradient(135deg, ${colors.primary} 0%, ${colors.primaryDark} 100%)`,
                }}
              >
                Import First CAS
              </button>
            )}
          </div>
        ) : (
          <div className="space-y-2">
            {filtered.map((imp) => {
              const sc = statusConfig[imp.status] || statusConfig.PROCESSING
              return (
                <div
                  key={imp.id}
                  className="p-4 rounded-xl transition-all duration-200 hover:-translate-y-0.5"
                  style={{
                    background: colors.cardBg,
                    border: `1px solid ${colors.cardBorder}`,
                    boxShadow: `0 2px 12px ${colors.glassShadow}`,
                  }}
                >
                  <div className="flex items-start justify-between gap-4">
                    {/* Left: Client & Investor Info */}
                    <div className="flex items-start gap-3 min-w-0 flex-1">
                      <div className="w-10 h-10 rounded-xl flex items-center justify-center flex-shrink-0" style={{
                        background: imp.status === 'FAILED'
                          ? `${colors.error}12`
                          : `linear-gradient(135deg, ${colors.primary} 0%, ${colors.primaryDark} 100%)`,
                      }}>
                        {imp.status === 'FAILED' ? (
                          <svg className="w-5 h-5" style={{ color: colors.error }} fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
                            <path strokeLinecap="round" strokeLinejoin="round" d="M12 9v3.75m9-.75a9 9 0 11-18 0 9 9 0 0118 0zm-9 3.75h.008v.008H12v-.008z" />
                          </svg>
                        ) : (
                          <span className="text-sm font-bold text-white">
                            {(imp.clientName || imp.investorName || '?').charAt(0).toUpperCase()}
                          </span>
                        )}
                      </div>
                      <div className="min-w-0">
                        <div className="flex items-center gap-2 mb-0.5">
                          <p className="text-sm font-semibold truncate" style={{ color: colors.textPrimary }}>
                            {imp.clientName || imp.investorName || 'Unknown'}
                          </p>
                          <span
                            className="text-xs px-2 py-0.5 rounded font-semibold flex-shrink-0"
                            style={{ background: sc.bg, color: sc.color }}
                          >
                            {sc.label}
                          </span>
                        </div>
                        <p className="text-xs truncate" style={{ color: colors.textTertiary }}>
                          {imp.clientEmail || imp.investorEmail || ''}
                          {imp.context === 'SELF' && (
                            <span className="ml-1" style={{ color: colors.primary }}>(Self-service)</span>
                          )}
                        </p>
                        {imp.status === 'FAILED' && imp.errorMessage && (
                          <p className="text-xs mt-1 truncate" style={{ color: colors.error }}>
                            {imp.errorMessage}
                          </p>
                        )}
                      </div>
                    </div>

                    {/* Right: Stats */}
                    <div className="flex items-center gap-4 flex-shrink-0">
                      {imp.status === 'COMPLETED' && (
                        <>
                          <div className="text-right hidden sm:block">
                            <p className="text-xs" style={{ color: colors.textTertiary }}>Schemes</p>
                            <p className="text-sm font-bold" style={{ color: colors.textPrimary }}>{imp.schemesImported}</p>
                          </div>
                          <div className="text-right hidden sm:block">
                            <p className="text-xs" style={{ color: colors.textTertiary }}>Folios</p>
                            <p className="text-sm font-bold" style={{ color: colors.textPrimary }}>{imp.foliosImported}</p>
                          </div>
                          <div className="text-right">
                            <p className="text-xs" style={{ color: colors.textTertiary }}>Value</p>
                            <p className="text-sm font-bold" style={{ color: colors.success }}>
                              {imp.totalValue ? formatCurrency(imp.totalValue) : '--'}
                            </p>
                          </div>
                        </>
                      )}
                      <div className="text-right">
                        <p className="text-xs" style={{ color: colors.textTertiary }}>
                          {formatDate(imp.createdAt)}
                        </p>
                        {imp.fileType && (
                          <span
                            className="text-xs px-1.5 py-0.5 rounded mt-0.5 inline-block"
                            style={{ background: colors.chipBg, color: colors.textSecondary, border: `1px solid ${colors.chipBorder}` }}
                          >
                            {imp.fileType}
                          </span>
                        )}
                      </div>
                    </div>
                  </div>
                </div>
              )
            })}
          </div>
        )}
      </div>
    </AdvisorLayout>
  )
}

export default CASImportsPage
