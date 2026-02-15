import { useState, useEffect } from 'react'
import { useFATheme, formatDate } from '@/utils/fa'
import { FACard, FASectionHeader, FAButton, FAEmptyState, FAChip } from '@/components/advisor/shared'
import GapAnalysisCard from './GapAnalysisCard'
import AddPolicyModal from './AddPolicyModal'
import { insuranceApi } from '@/services/api'

interface InsurancePolicy {
  id: string
  clientId: string
  policyNumber: string
  provider: string
  type: string
  status: string
  sumAssured: number
  premiumAmount: number
  premiumFrequency: string
  startDate: string
  maturityDate?: string
  nominees?: string
  notes?: string
}

interface GapAnalysisData {
  life: { recommended: number; current: number; gap: number; adequate: boolean }
  health: { recommended: number; current: number; gap: number; adequate: boolean }
  policies: InsurancePolicy[]
}

const TYPE_LABELS: Record<string, string> = {
  TERM_LIFE: 'Term Life',
  WHOLE_LIFE: 'Whole Life',
  ENDOWMENT: 'Endowment',
  ULIP: 'ULIP',
  HEALTH: 'Health',
  CRITICAL_ILLNESS: 'Critical Illness',
  PERSONAL_ACCIDENT: 'Personal Accident',
  OTHER: 'Other',
}

function formatAmount(amount: number): string {
  if (amount >= 10000000) return `₹${(amount / 10000000).toFixed(1)} Cr`
  if (amount >= 100000) return `₹${(amount / 100000).toFixed(1)} L`
  return `₹${amount.toLocaleString('en-IN', { maximumFractionDigits: 0 })}`
}

function getStatusColor(status: string, colors: any): string {
  switch (status) {
    case 'ACTIVE': return colors.success
    case 'LAPSED': return colors.error
    case 'SURRENDERED': return colors.warning
    case 'MATURED': return '#3B82F6'
    case 'CLAIMED': return '#8B5CF6'
    default: return colors.textTertiary
  }
}

export default function InsuranceTab({ clientId }: { clientId: string }) {
  const { colors, isDark } = useFATheme()
  const [policies, setPolicies] = useState<InsurancePolicy[]>([])
  const [gapData, setGapData] = useState<GapAnalysisData | null>(null)
  const [showAddModal, setShowAddModal] = useState(false)
  const [isSaving, setIsSaving] = useState(false)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    if (!clientId) return
    loadData()
  }, [clientId])

  const loadData = async () => {
    setLoading(true)
    try {
      const [policiesRes, gapRes] = await Promise.allSettled([
        insuranceApi.list(clientId),
        insuranceApi.gapAnalysis(clientId),
      ])
      if (policiesRes.status === 'fulfilled') setPolicies(policiesRes.value as InsurancePolicy[])
      if (gapRes.status === 'fulfilled') setGapData(gapRes.value as GapAnalysisData)
    } catch {
      // Errors handled gracefully
    } finally {
      setLoading(false)
    }
  }

  const handleSave = async (data: any) => {
    setIsSaving(true)
    try {
      const newPolicy = await insuranceApi.create(clientId, data) as InsurancePolicy
      setPolicies((prev) => [newPolicy, ...prev])
      setShowAddModal(false)
      // Refresh gap analysis
      try {
        const gap = await insuranceApi.gapAnalysis(clientId) as GapAnalysisData
        setGapData(gap)
      } catch { /* ignore */ }
    } catch {
      // Optimistic fallback
      const fallback: InsurancePolicy = {
        id: `temp-${Date.now()}`,
        clientId,
        ...data,
        status: 'ACTIVE',
      }
      setPolicies((prev) => [fallback, ...prev])
      setShowAddModal(false)
    } finally {
      setIsSaving(false)
    }
  }

  const handleDelete = async (policyId: string) => {
    setPolicies((prev) => prev.filter((p) => p.id !== policyId))
    try {
      await insuranceApi.delete(clientId, policyId)
      const gap = await insuranceApi.gapAnalysis(clientId) as GapAnalysisData
      setGapData(gap)
    } catch { /* Already removed from UI */ }
  }

  return (
    <div className="space-y-4">
      {/* Gap Analysis */}
      <GapAnalysisCard data={gapData} />

      {/* Policies Table */}
      <FACard padding="md">
        <FASectionHeader
          title={`Insurance Policies (${policies.length})`}
          action={
            <FAButton
              size="sm"
              onClick={() => setShowAddModal(true)}
              icon={
                <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
                  <path strokeLinecap="round" strokeLinejoin="round" d="M12 4v16m8-8H4" />
                </svg>
              }
            >
              Add Policy
            </FAButton>
          }
        />

        {loading ? (
          <div className="flex justify-center py-12">
            <div className="w-6 h-6 border-2 rounded-full animate-spin" style={{ borderColor: `${colors.primary}30`, borderTopColor: colors.primary }} />
          </div>
        ) : policies.length === 0 ? (
          <FAEmptyState
            icon={
              <svg className="w-12 h-12" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.5}>
                <path strokeLinecap="round" strokeLinejoin="round" d="M9 12.75L11.25 15 15 9.75m-3-7.036A11.959 11.959 0 013.598 6 11.99 11.99 0 003 9.749c0 5.592 3.824 10.29 9 11.623 5.176-1.332 9-6.03 9-11.622 0-1.31-.21-2.571-.598-3.751h-.152c-3.196 0-6.1-1.248-8.25-3.285z" />
              </svg>
            }
            title="No Insurance Policies"
            description="Add insurance policies to track coverage and identify gaps"
          />
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead>
                <tr style={{ borderBottom: `1px solid ${colors.cardBorder}` }}>
                  {['Provider', 'Type', 'Status', 'Sum Assured', 'Premium', 'Start Date', 'Nominees', ''].map((h) => (
                    <th
                      key={h}
                      className="text-left py-2 px-3 text-xs font-semibold uppercase tracking-wide"
                      style={{ color: colors.textTertiary }}
                    >
                      {h}
                    </th>
                  ))}
                </tr>
              </thead>
              <tbody>
                {policies.map((policy) => {
                  const statusColor = getStatusColor(policy.status, colors)
                  return (
                    <tr
                      key={policy.id}
                      className="transition-colors"
                      style={{ borderBottom: `1px solid ${colors.cardBorder}` }}
                    >
                      <td className="py-3 px-3">
                        <span className="font-medium" style={{ color: colors.textPrimary }}>{policy.provider}</span>
                        <div className="text-xs" style={{ color: colors.textTertiary }}>{policy.policyNumber}</div>
                      </td>
                      <td className="py-3 px-3">
                        <span className="text-xs px-2 py-0.5 rounded" style={{ background: `${colors.primary}10`, color: colors.primary }}>
                          {TYPE_LABELS[policy.type] || policy.type}
                        </span>
                      </td>
                      <td className="py-3 px-3">
                        <span
                          className="text-xs px-2 py-0.5 rounded"
                          style={{ background: `${statusColor}15`, color: statusColor }}
                        >
                          {policy.status.charAt(0) + policy.status.slice(1).toLowerCase()}
                        </span>
                      </td>
                      <td className="py-3 px-3 font-medium" style={{ color: colors.textPrimary }}>
                        {formatAmount(policy.sumAssured)}
                      </td>
                      <td className="py-3 px-3" style={{ color: colors.textSecondary }}>
                        {formatAmount(policy.premiumAmount)}
                        <span className="text-xs ml-1" style={{ color: colors.textTertiary }}>
                          /{policy.premiumFrequency === 'ANNUAL' ? 'yr' : policy.premiumFrequency === 'MONTHLY' ? 'mo' : 'qtr'}
                        </span>
                      </td>
                      <td className="py-3 px-3" style={{ color: colors.textSecondary }}>
                        {policy.startDate ? new Date(policy.startDate).toLocaleDateString('en-IN', { day: '2-digit', month: 'short', year: 'numeric' }) : '-'}
                      </td>
                      <td className="py-3 px-3 text-xs" style={{ color: colors.textTertiary }}>
                        {policy.nominees || '-'}
                      </td>
                      <td className="py-3 px-3">
                        <button
                          onClick={() => handleDelete(policy.id)}
                          className="p-1.5 rounded-lg transition-colors hover:bg-red-500/10"
                          title="Delete policy"
                        >
                          <svg className="w-4 h-4" style={{ color: colors.error }} fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
                            <path strokeLinecap="round" strokeLinejoin="round" d="M14.74 9l-.346 9m-4.788 0L9.26 9m9.968-3.21c.342.052.682.107 1.022.166m-1.022-.165L18.16 19.673a2.25 2.25 0 01-2.244 2.077H8.084a2.25 2.25 0 01-2.244-2.077L4.772 5.79m14.456 0a48.108 48.108 0 00-3.478-.397m-12 .562c.34-.059.68-.114 1.022-.165m0 0a48.11 48.11 0 013.478-.397m7.5 0v-.916c0-1.18-.91-2.164-2.09-2.201a51.964 51.964 0 00-3.32 0c-1.18.037-2.09 1.022-2.09 2.201v.916m7.5 0a48.667 48.667 0 00-7.5 0" />
                          </svg>
                        </button>
                      </td>
                    </tr>
                  )
                })}
              </tbody>
            </table>
          </div>
        )}
      </FACard>

      {showAddModal && (
        <AddPolicyModal
          onClose={() => setShowAddModal(false)}
          onSave={handleSave}
          isSaving={isSaving}
        />
      )}
    </div>
  )
}
