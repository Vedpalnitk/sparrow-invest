import { useState } from 'react'
import { useFATheme } from '@/utils/fa'
import { FAButton, FAInput, FASelect, FALabel, FATextarea } from '@/components/advisor/shared'

const POLICY_TYPES = [
  { value: 'TERM_LIFE', label: 'Term Life' },
  { value: 'WHOLE_LIFE', label: 'Whole Life' },
  { value: 'ENDOWMENT', label: 'Endowment' },
  { value: 'ULIP', label: 'ULIP' },
  { value: 'HEALTH', label: 'Health' },
  { value: 'CRITICAL_ILLNESS', label: 'Critical Illness' },
  { value: 'PERSONAL_ACCIDENT', label: 'Personal Accident' },
  { value: 'OTHER', label: 'Other' },
]

const FREQUENCIES = [
  { value: 'MONTHLY', label: 'Monthly' },
  { value: 'QUARTERLY', label: 'Quarterly' },
  { value: 'HALF_YEARLY', label: 'Half Yearly' },
  { value: 'ANNUAL', label: 'Annual' },
  { value: 'SINGLE', label: 'Single Premium' },
]

interface AddPolicyModalProps {
  onClose: () => void
  onSave: (data: any) => void
  isSaving?: boolean
}

export default function AddPolicyModal({ onClose, onSave, isSaving }: AddPolicyModalProps) {
  const { colors, isDark } = useFATheme()

  const [policyNumber, setPolicyNumber] = useState('')
  const [provider, setProvider] = useState('')
  const [type, setType] = useState('TERM_LIFE')
  const [sumAssured, setSumAssured] = useState('')
  const [premiumAmount, setPremiumAmount] = useState('')
  const [premiumFrequency, setPremiumFrequency] = useState('ANNUAL')
  const [startDate, setStartDate] = useState('')
  const [maturityDate, setMaturityDate] = useState('')
  const [nominees, setNominees] = useState('')
  const [notes, setNotes] = useState('')

  const isValid = policyNumber.trim() !== '' &&
    provider.trim() !== '' &&
    Number(sumAssured) > 0 &&
    Number(premiumAmount) > 0 &&
    startDate !== ''

  const handleSubmit = () => {
    if (!isValid) return
    onSave({
      policyNumber: policyNumber.trim(),
      provider: provider.trim(),
      type,
      sumAssured: Number(sumAssured),
      premiumAmount: Number(premiumAmount),
      premiumFrequency,
      startDate,
      maturityDate: maturityDate || undefined,
      nominees: nominees.trim() || undefined,
      notes: notes.trim() || undefined,
    })
  }

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4" style={{ background: 'rgba(0,0,0,0.5)' }}>
      <div
        className="w-full max-w-lg max-h-[90vh] overflow-y-auto rounded-xl p-6"
        style={{
          background: isDark ? colors.backgroundSecondary : '#FFFFFF',
          border: `1px solid ${colors.cardBorder}`,
          boxShadow: `0 20px 60px rgba(0,0,0,0.3)`,
        }}
      >
        <div className="flex items-center justify-between mb-5">
          <h3 className="text-lg font-semibold" style={{ color: colors.textPrimary }}>
            Add Insurance Policy
          </h3>
          <button
            onClick={onClose}
            className="w-8 h-8 rounded-lg flex items-center justify-center transition-colors"
            style={{ background: colors.chipBg }}
          >
            <svg className="w-4 h-4" style={{ color: colors.textSecondary }} fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
              <path strokeLinecap="round" strokeLinejoin="round" d="M6 18L18 6M6 6l12 12" />
            </svg>
          </button>
        </div>

        <div className="space-y-4">
          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-xs font-semibold mb-1.5 uppercase tracking-wide" style={{ color: colors.primary }}>
                Policy Number
              </label>
              <input
                value={policyNumber}
                onChange={(e) => setPolicyNumber(e.target.value)}
                placeholder="e.g. LIC-87654321"
                className="w-full h-10 px-4 rounded-xl text-sm transition-all focus:outline-none"
                style={{ background: colors.inputBg, border: `1px solid ${colors.inputBorder}`, color: colors.textPrimary }}
              />
            </div>
            <div>
              <label className="block text-xs font-semibold mb-1.5 uppercase tracking-wide" style={{ color: colors.primary }}>
                Provider
              </label>
              <input
                value={provider}
                onChange={(e) => setProvider(e.target.value)}
                placeholder="e.g. LIC, HDFC Life"
                className="w-full h-10 px-4 rounded-xl text-sm transition-all focus:outline-none"
                style={{ background: colors.inputBg, border: `1px solid ${colors.inputBorder}`, color: colors.textPrimary }}
              />
            </div>
          </div>

          <div>
            <label className="block text-xs font-semibold mb-1.5 uppercase tracking-wide" style={{ color: colors.primary }}>
              Policy Type
            </label>
            <select
              value={type}
              onChange={(e) => setType(e.target.value)}
              className="w-full h-10 px-4 rounded-xl text-sm transition-all focus:outline-none"
              style={{ background: colors.inputBg, border: `1px solid ${colors.inputBorder}`, color: colors.textPrimary }}
            >
              {POLICY_TYPES.map((t) => (
                <option key={t.value} value={t.value}>{t.label}</option>
              ))}
            </select>
          </div>

          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-xs font-semibold mb-1.5 uppercase tracking-wide" style={{ color: colors.primary }}>
                Sum Assured (₹)
              </label>
              <input
                type="number"
                value={sumAssured}
                onChange={(e) => setSumAssured(e.target.value)}
                placeholder="e.g. 10000000"
                className="w-full h-10 px-4 rounded-xl text-sm transition-all focus:outline-none"
                style={{ background: colors.inputBg, border: `1px solid ${colors.inputBorder}`, color: colors.textPrimary }}
              />
            </div>
            <div>
              <label className="block text-xs font-semibold mb-1.5 uppercase tracking-wide" style={{ color: colors.primary }}>
                Premium Amount (₹)
              </label>
              <input
                type="number"
                value={premiumAmount}
                onChange={(e) => setPremiumAmount(e.target.value)}
                placeholder="e.g. 12000"
                className="w-full h-10 px-4 rounded-xl text-sm transition-all focus:outline-none"
                style={{ background: colors.inputBg, border: `1px solid ${colors.inputBorder}`, color: colors.textPrimary }}
              />
            </div>
          </div>

          <div>
            <label className="block text-xs font-semibold mb-1.5 uppercase tracking-wide" style={{ color: colors.primary }}>
              Premium Frequency
            </label>
            <select
              value={premiumFrequency}
              onChange={(e) => setPremiumFrequency(e.target.value)}
              className="w-full h-10 px-4 rounded-xl text-sm transition-all focus:outline-none"
              style={{ background: colors.inputBg, border: `1px solid ${colors.inputBorder}`, color: colors.textPrimary }}
            >
              {FREQUENCIES.map((f) => (
                <option key={f.value} value={f.value}>{f.label}</option>
              ))}
            </select>
          </div>

          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-xs font-semibold mb-1.5 uppercase tracking-wide" style={{ color: colors.primary }}>
                Start Date
              </label>
              <input
                type="date"
                value={startDate}
                onChange={(e) => setStartDate(e.target.value)}
                className="w-full h-10 px-4 rounded-xl text-sm transition-all focus:outline-none"
                style={{ background: colors.inputBg, border: `1px solid ${colors.inputBorder}`, color: colors.textPrimary }}
              />
            </div>
            <div>
              <label className="block text-xs font-semibold mb-1.5 uppercase tracking-wide" style={{ color: colors.primary }}>
                Maturity Date (optional)
              </label>
              <input
                type="date"
                value={maturityDate}
                onChange={(e) => setMaturityDate(e.target.value)}
                className="w-full h-10 px-4 rounded-xl text-sm transition-all focus:outline-none"
                style={{ background: colors.inputBg, border: `1px solid ${colors.inputBorder}`, color: colors.textPrimary }}
              />
            </div>
          </div>

          <div>
            <label className="block text-xs font-semibold mb-1.5 uppercase tracking-wide" style={{ color: colors.primary }}>
              Nominees (optional)
            </label>
            <input
              value={nominees}
              onChange={(e) => setNominees(e.target.value)}
              placeholder="e.g. Spouse - 100%"
              className="w-full h-10 px-4 rounded-xl text-sm transition-all focus:outline-none"
              style={{ background: colors.inputBg, border: `1px solid ${colors.inputBorder}`, color: colors.textPrimary }}
            />
          </div>

          <div>
            <label className="block text-xs font-semibold mb-1.5 uppercase tracking-wide" style={{ color: colors.primary }}>
              Notes (optional)
            </label>
            <textarea
              value={notes}
              onChange={(e) => setNotes(e.target.value)}
              placeholder="Additional notes..."
              rows={2}
              className="w-full px-4 py-2 rounded-xl text-sm transition-all focus:outline-none resize-none"
              style={{ background: colors.inputBg, border: `1px solid ${colors.inputBorder}`, color: colors.textPrimary }}
            />
          </div>

          <div className="flex gap-3 pt-2">
            <button
              onClick={onClose}
              className="flex-1 py-2.5 rounded-full font-semibold text-sm transition-all"
              style={{
                background: colors.chipBg,
                color: colors.textSecondary,
                border: `1px solid ${colors.cardBorder}`,
              }}
            >
              Cancel
            </button>
            <button
              onClick={handleSubmit}
              disabled={!isValid || isSaving}
              className="flex-1 py-2.5 rounded-full font-semibold text-sm text-white transition-all hover:shadow-lg disabled:opacity-50"
              style={{
                background: `linear-gradient(135deg, ${colors.primary} 0%, ${colors.primaryDark} 100%)`,
                boxShadow: `0 4px 14px ${colors.glassShadow}`,
              }}
            >
              {isSaving ? 'Saving...' : 'Save Policy'}
            </button>
          </div>
        </div>
      </div>
    </div>
  )
}
