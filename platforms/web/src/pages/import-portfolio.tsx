/**
 * Import Portfolio Page — Self-service
 *
 * Allows self-service users to import their own CAS PDF
 * to populate Folio and Holding records.
 */

import { useState, useEffect } from 'react'
import { useRouter } from 'next/router'
import Navbar from '@/components/layout/Navbar'
import Footer from '@/components/layout/Footer'
import CASUploadForm from '@/components/CASUploadForm'
import { casApi, CASImportRecord } from '@/services/api'

// V4 Color Palette
const V4_COLORS_LIGHT = {
  primary: '#2563EB',
  primaryDark: '#1D4ED8',
  success: '#10B981',
  warning: '#F59E0B',
  error: '#EF4444',
  background: '#F8FAFC',
  cardBg: 'rgba(255, 255, 255, 0.8)',
  cardBorder: 'rgba(37, 99, 235, 0.1)',
  chipBg: 'rgba(37, 99, 235, 0.08)',
  chipBorder: 'rgba(37, 99, 235, 0.15)',
  textPrimary: '#1E293B',
  textSecondary: '#64748B',
  textTertiary: '#94A3B8',
  glassShadow: 'rgba(37, 99, 235, 0.08)',
}

const V4_COLORS_DARK = {
  primary: '#60A5FA',
  primaryDark: '#3B82F6',
  success: '#34D399',
  warning: '#FBBF24',
  error: '#F87171',
  background: '#0F172A',
  cardBg: 'rgba(30, 41, 59, 0.8)',
  cardBorder: 'rgba(96, 165, 250, 0.15)',
  chipBg: 'rgba(96, 165, 250, 0.12)',
  chipBorder: 'rgba(96, 165, 250, 0.2)',
  textPrimary: '#F1F5F9',
  textSecondary: '#94A3B8',
  textTertiary: '#64748B',
  glassShadow: 'rgba(0, 0, 0, 0.3)',
}

const useDarkMode = () => {
  const [isDark, setIsDark] = useState(false)
  useEffect(() => {
    const checkDark = () => setIsDark(document.documentElement.classList.contains('dark'))
    checkDark()
    const observer = new MutationObserver(checkDark)
    observer.observe(document.documentElement, { attributes: true, attributeFilter: ['class'] })
    return () => observer.disconnect()
  }, [])
  return isDark
}

const useV4Colors = () => {
  const isDark = useDarkMode()
  return { colors: isDark ? V4_COLORS_DARK : V4_COLORS_LIGHT, isDark }
}

const formatCurrency = (value: number) => {
  return new Intl.NumberFormat('en-IN', {
    style: 'currency',
    currency: 'INR',
    maximumFractionDigits: 0,
  }).format(value)
}

export default function ImportPortfolioPage() {
  const router = useRouter()
  const { colors, isDark } = useV4Colors()
  const [imports, setImports] = useState<CASImportRecord[]>([])

  useEffect(() => {
    loadImports()
  }, [])

  const loadImports = async () => {
    try {
      const data = await casApi.getImports()
      setImports(data)
    } catch {
      // ignore
    }
  }

  return (
    <div className="min-h-screen" style={{ background: colors.background }}>
      <Navbar />
      <main className="max-w-2xl mx-auto px-4 py-8">
        {/* Back link */}
        <button
          onClick={() => router.back()}
          className="flex items-center gap-1 text-sm mb-6 transition-colors"
          style={{ color: colors.textSecondary }}
        >
          <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
            <path strokeLinecap="round" strokeLinejoin="round" d="M15 19l-7-7 7-7" />
          </svg>
          Back
        </button>

        {/* Header */}
        <div className="mb-6">
          <h1 className="text-2xl font-bold" style={{ color: colors.textPrimary }}>
            Import Portfolio
          </h1>
          <p className="text-sm mt-1" style={{ color: colors.textSecondary }}>
            Upload your CAMS or KFintech CAS (Consolidated Account Statement) to import your mutual fund holdings.
          </p>
        </div>

        {/* Upload Card */}
        <div className="p-5 rounded-xl mb-6" style={{
          background: colors.cardBg,
          border: `1px solid ${colors.cardBorder}`,
          boxShadow: `0 4px 24px ${colors.glassShadow}`,
          backdropFilter: 'blur(20px)',
        }}>
          <CASUploadForm onSuccess={() => loadImports()} />
        </div>

        {/* Import History */}
        {imports.length > 0 && (
          <div className="p-5 rounded-xl mb-6" style={{
            background: colors.cardBg,
            border: `1px solid ${colors.cardBorder}`,
            boxShadow: `0 4px 24px ${colors.glassShadow}`,
            backdropFilter: 'blur(20px)',
          }}>
            <h3 className="text-xs font-semibold uppercase tracking-wide mb-3" style={{ color: colors.primary }}>
              Previous Imports
            </h3>
            <div className="space-y-2">
              {imports.map((imp) => (
                <div
                  key={imp.id}
                  className="p-3 rounded-xl flex items-center justify-between"
                  style={{
                    background: colors.chipBg,
                    border: `1px solid ${colors.chipBorder}`,
                  }}
                >
                  <div>
                    <p className="text-sm font-semibold" style={{ color: colors.textPrimary }}>
                      {imp.investorName || 'CAS Import'}
                    </p>
                    <p className="text-xs" style={{ color: colors.textTertiary }}>
                      {imp.schemesImported} schemes, {imp.foliosImported} folios
                      {imp.fileType ? ` — ${imp.fileType}` : ''}
                    </p>
                  </div>
                  <div className="text-right">
                    <span
                      className="text-xs px-2 py-0.5 rounded font-semibold"
                      style={{
                        background: imp.status === 'COMPLETED' ? `${colors.success}12` : imp.status === 'FAILED' ? `${colors.error}12` : `${colors.warning}12`,
                        color: imp.status === 'COMPLETED' ? colors.success : imp.status === 'FAILED' ? colors.error : colors.warning,
                      }}
                    >
                      {imp.status}
                    </span>
                    {imp.totalValue && (
                      <p className="text-sm font-bold mt-1" style={{ color: colors.textPrimary }}>
                        {formatCurrency(imp.totalValue)}
                      </p>
                    )}
                  </div>
                </div>
              ))}
            </div>
          </div>
        )}

        {/* How to get CAS */}
        <div className="p-5 rounded-xl" style={{
          background: colors.chipBg,
          border: `1px solid ${colors.chipBorder}`,
        }}>
          <h3 className="text-xs font-semibold uppercase tracking-wide mb-3" style={{ color: colors.textTertiary }}>
            How to get your CAS
          </h3>
          <div className="space-y-2">
            {[
              'Visit mycams.camsonline.com or mfs.kfintech.com/investor',
              'Request a "Detailed" CAS for your email address',
              'You will receive a password-protected PDF via email',
              'Upload the PDF here with your password (PAN + DOB)',
            ].map((step, i) => (
              <div key={i} className="flex items-start gap-2">
                <span className="text-xs font-bold mt-0.5 w-5 h-5 rounded-full flex items-center justify-center flex-shrink-0" style={{
                  background: `${colors.primary}15`,
                  color: colors.primary,
                }}>
                  {i + 1}
                </span>
                <p className="text-sm" style={{ color: colors.textSecondary }}>{step}</p>
              </div>
            ))}
          </div>
        </div>
      </main>
      <Footer />
    </div>
  )
}
