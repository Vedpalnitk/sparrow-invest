import { useFATheme, formatCurrencyCompact } from '@/utils/fa'

interface CoverageGap {
  recommended: number
  current: number
  gap: number
  adequate: boolean
}

interface GapAnalysisData {
  life: CoverageGap
  health: CoverageGap
}

export default function GapAnalysisCard({ data }: { data: GapAnalysisData | null }) {
  const { colors, isDark } = useFATheme()

  if (!data) return null

  return (
    <div
      className="p-5 rounded-xl"
      style={{
        background: isDark ? colors.cardBg : colors.cardBg,
        border: `1px solid ${colors.cardBorder}`,
        boxShadow: `0 4px 24px ${colors.glassShadow}`,
      }}
    >
      <div className="flex items-center gap-2 mb-4">
        <div
          className="w-8 h-8 rounded-lg flex items-center justify-center"
          style={{ background: `${colors.primary}15` }}
        >
          <svg className="w-4 h-4" style={{ color: colors.primary }} fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
            <path strokeLinecap="round" strokeLinejoin="round" d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z" />
          </svg>
        </div>
        <span className="text-sm font-semibold" style={{ color: colors.textPrimary }}>
          Coverage Gap Analysis
        </span>
      </div>

      <div className="space-y-4">
        <CoverageBar
          label="Life Insurance"
          icon={
            <svg className="w-3.5 h-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
              <path strokeLinecap="round" strokeLinejoin="round" d="M9 12.75L11.25 15 15 9.75m-3-7.036A11.959 11.959 0 013.598 6 11.99 11.99 0 003 9.749c0 5.592 3.824 10.29 9 11.623 5.176-1.332 9-6.03 9-11.622 0-1.31-.21-2.571-.598-3.751h-.152c-3.196 0-6.1-1.248-8.25-3.285z" />
            </svg>
          }
          gap={data.life}
          colors={colors}
          isDark={isDark}
        />
        <CoverageBar
          label="Health Insurance"
          icon={
            <svg className="w-3.5 h-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
              <path strokeLinecap="round" strokeLinejoin="round" d="M21 8.25c0-2.485-2.099-4.5-4.688-4.5-1.935 0-3.597 1.126-4.312 2.733-.715-1.607-2.377-2.733-4.313-2.733C5.1 3.75 3 5.765 3 8.25c0 7.22 9 12 9 12s9-4.78 9-12z" />
            </svg>
          }
          gap={data.health}
          colors={colors}
          isDark={isDark}
        />
      </div>
    </div>
  )
}

function CoverageBar({
  label,
  icon,
  gap,
  colors,
  isDark,
}: {
  label: string
  icon: React.ReactNode
  gap: CoverageGap
  colors: any
  isDark: boolean
}) {
  const progress = gap.recommended > 0 ? Math.min(gap.current / gap.recommended, 1) : 0
  const barColor = gap.adequate ? colors.success : colors.error

  return (
    <div
      className="p-3 rounded-lg"
      style={{
        background: isDark ? 'rgba(255,255,255,0.04)' : 'rgba(0,0,0,0.02)',
      }}
    >
      <div className="flex items-center justify-between mb-2">
        <div className="flex items-center gap-1.5">
          <span style={{ color: barColor }}>{icon}</span>
          <span className="text-xs font-semibold" style={{ color: colors.textPrimary }}>
            {label}
          </span>
        </div>
        {gap.adequate ? (
          <div className="flex items-center gap-1">
            <svg className="w-3 h-3" style={{ color: colors.success }} fill="currentColor" viewBox="0 0 20 20">
              <path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.857-9.809a.75.75 0 00-1.214-.882l-3.483 4.79-1.88-1.88a.75.75 0 10-1.06 1.061l2.5 2.5a.75.75 0 001.137-.089l4-5.5z" clipRule="evenodd" />
            </svg>
            <span className="text-xs font-medium" style={{ color: colors.success }}>Adequate</span>
          </div>
        ) : (
          <span className="text-xs font-medium" style={{ color: colors.error }}>
            Gap: {formatAmount(gap.gap)}
          </span>
        )}
      </div>

      {/* Progress bar */}
      <div
        className="w-full h-2 rounded-full overflow-hidden"
        style={{ background: isDark ? 'rgba(255,255,255,0.08)' : 'rgba(0,0,0,0.06)' }}
      >
        <div
          className="h-full rounded-full transition-all duration-500"
          style={{
            width: `${progress * 100}%`,
            background: `linear-gradient(90deg, ${barColor}, ${barColor}99)`,
          }}
        />
      </div>

      <div className="flex justify-between mt-1">
        <span className="text-xs" style={{ color: colors.textTertiary }}>
          Current: {formatAmount(gap.current)}
        </span>
        <span className="text-xs" style={{ color: colors.textTertiary }}>
          Recommended: {formatAmount(gap.recommended)}
        </span>
      </div>
    </div>
  )
}

function formatAmount(amount: number): string {
  if (amount >= 10000000) return `₹${(amount / 10000000).toFixed(1)} Cr`
  if (amount >= 100000) return `₹${(amount / 100000).toFixed(1)} L`
  return `₹${amount.toLocaleString('en-IN', { maximumFractionDigits: 0 })}`
}
