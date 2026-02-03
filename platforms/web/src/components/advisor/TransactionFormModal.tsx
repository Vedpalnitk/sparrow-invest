/**
 * Transaction Form Modal Component
 *
 * Modal dialog for creating new transactions (Buy, Sell, SIP, Switch, etc.)
 * Import with: import TransactionFormModal from '@/components/advisor/TransactionFormModal'
 */

import { useState, useEffect, useCallback, useRef } from 'react'
import { useFATheme, formatCurrency } from '@/utils/fa'
import { TransactionType, TransactionFormData } from '@/utils/faTypes'
import { dbFundsApi, DatabaseFund } from '@/services/api'
import {
  FAButton,
  FAInput,
  FASelect,
  FALabel,
  FAFormSection,
  FARadioGroup,
  FASpinner,
} from '@/components/advisor/shared'

interface TransactionFormModalProps {
  isOpen: boolean
  onClose: () => void
  onSubmit: (data: TransactionFormData) => void
  clientId: string
  clientName: string
  initialType?: TransactionType
}

const TRANSACTION_TYPES = [
  { value: 'Buy', label: 'Lumpsum Purchase' },
  { value: 'SIP', label: 'Start New SIP' },
  { value: 'Sell', label: 'Redemption' },
  { value: 'Switch', label: 'Switch Funds' },
  { value: 'SWP', label: 'Systematic Withdrawal' },
  { value: 'STP', label: 'Systematic Transfer' },
]

const PAYMENT_MODES = [
  { value: 'Net Banking', label: 'Net Banking' },
  { value: 'UPI', label: 'UPI' },
  { value: 'NACH', label: 'NACH Mandate' },
]

const SIP_FREQUENCIES = [
  { value: 'Monthly', label: 'Monthly' },
  { value: 'Quarterly', label: 'Quarterly' },
  { value: 'Weekly', label: 'Weekly' },
]

// Fallback fund list when API is unavailable
const FALLBACK_FUNDS = [
  { schemeCode: 118989, schemeName: 'HDFC Flexi Cap Fund - Direct Growth', category: 'Flexi Cap', currentNav: 1425.3, fundHouse: 'HDFC', assetClass: 'Equity', dayChange: 0, dayChangePercent: 0 },
  { schemeCode: 120594, schemeName: 'ICICI Prudential Bluechip Fund - Direct Growth', category: 'Large Cap', currentNav: 92.3, fundHouse: 'ICICI', assetClass: 'Equity', dayChange: 0, dayChangePercent: 0 },
  { schemeCode: 112323, schemeName: 'Axis Long Term Equity Fund - Direct Growth', category: 'ELSS', currentNav: 98.7, fundHouse: 'Axis', assetClass: 'Equity', dayChange: 0, dayChangePercent: 0 },
  { schemeCode: 119598, schemeName: 'SBI Corporate Bond Fund - Direct Growth', category: 'Corporate Bond', currentNav: 41.2, fundHouse: 'SBI', assetClass: 'Debt', dayChange: 0, dayChangePercent: 0 },
  { schemeCode: 122639, schemeName: 'Mirae Asset Large Cap Fund - Direct Growth', category: 'Large Cap', currentNav: 89.5, fundHouse: 'Mirae', assetClass: 'Equity', dayChange: 0, dayChangePercent: 0 },
  { schemeCode: 135781, schemeName: 'Parag Parikh Flexi Cap Fund - Direct Growth', category: 'Flexi Cap', currentNav: 68.2, fundHouse: 'PPFAS', assetClass: 'Equity', dayChange: 0, dayChangePercent: 0 },
] as DatabaseFund[]

// Debounce hook
function useDebounce<T>(value: T, delay: number): T {
  const [debouncedValue, setDebouncedValue] = useState<T>(value)

  useEffect(() => {
    const handler = setTimeout(() => {
      setDebouncedValue(value)
    }, delay)

    return () => {
      clearTimeout(handler)
    }
  }, [value, delay])

  return debouncedValue
}

const emptyFormData: TransactionFormData = {
  clientId: '',
  fundSchemeCode: '',
  type: 'Buy',
  amount: 0,
  folioNumber: '',
  paymentMode: 'Net Banking',
}

const TransactionFormModal = ({
  isOpen,
  onClose,
  onSubmit,
  clientId,
  clientName,
  initialType = 'Buy',
}: TransactionFormModalProps) => {
  const { colors, isDark } = useFATheme()
  const [formData, setFormData] = useState<TransactionFormData>({
    ...emptyFormData,
    clientId,
    type: initialType,
  })
  const [errors, setErrors] = useState<Partial<Record<string, string>>>({})

  // Fund search state
  const [searchQuery, setSearchQuery] = useState('')
  const [searchResults, setSearchResults] = useState<DatabaseFund[]>([])
  const [isSearching, setIsSearching] = useState(false)
  const [showSearchResults, setShowSearchResults] = useState(false)
  const [selectedFund, setSelectedFund] = useState<DatabaseFund | null>(null)
  const searchInputRef = useRef<HTMLInputElement>(null)

  // Target fund search (for Switch/STP)
  const [targetSearchQuery, setTargetSearchQuery] = useState('')
  const [targetSearchResults, setTargetSearchResults] = useState<DatabaseFund[]>([])
  const [isTargetSearching, setIsTargetSearching] = useState(false)
  const [showTargetSearchResults, setShowTargetSearchResults] = useState(false)
  const [targetFund, setTargetFund] = useState<DatabaseFund | null>(null)

  // Debounced search queries
  const debouncedSearchQuery = useDebounce(searchQuery, 300)
  const debouncedTargetSearchQuery = useDebounce(targetSearchQuery, 300)

  // SIP specific fields
  const [sipFrequency, setSipFrequency] = useState<'Monthly' | 'Quarterly' | 'Weekly'>('Monthly')
  const [sipDate, setSipDate] = useState(5)
  const [sipStartDate, setSipStartDate] = useState('')
  const [isPerpetual, setIsPerpetual] = useState(true)
  const [sipEndDate, setSipEndDate] = useState('')

  // Switch/STP specific fields
  const [targetFundCode, setTargetFundCode] = useState('')

  // Search funds when query changes
  useEffect(() => {
    const searchFunds = async () => {
      if (debouncedSearchQuery.length < 2) {
        setSearchResults([])
        return
      }

      setIsSearching(true)
      try {
        const results = await dbFundsApi.searchFunds(debouncedSearchQuery)
        setSearchResults(results.slice(0, 10)) // Limit to 10 results
      } catch (err) {
        // Fallback to local search
        const filtered = FALLBACK_FUNDS.filter(
          f => f.schemeName.toLowerCase().includes(debouncedSearchQuery.toLowerCase()) ||
               f.category.toLowerCase().includes(debouncedSearchQuery.toLowerCase())
        )
        setSearchResults(filtered)
      } finally {
        setIsSearching(false)
      }
    }

    searchFunds()
  }, [debouncedSearchQuery])

  // Search target funds when query changes
  useEffect(() => {
    const searchTargetFunds = async () => {
      if (debouncedTargetSearchQuery.length < 2) {
        setTargetSearchResults([])
        return
      }

      setIsTargetSearching(true)
      try {
        const results = await dbFundsApi.searchFunds(debouncedTargetSearchQuery)
        // Filter out selected fund
        const filtered = results.filter(f => f.schemeCode !== selectedFund?.schemeCode)
        setTargetSearchResults(filtered.slice(0, 10))
      } catch (err) {
        const filtered = FALLBACK_FUNDS.filter(
          f => (f.schemeName.toLowerCase().includes(debouncedTargetSearchQuery.toLowerCase()) ||
               f.category.toLowerCase().includes(debouncedTargetSearchQuery.toLowerCase())) &&
               f.schemeCode !== selectedFund?.schemeCode
        )
        setTargetSearchResults(filtered)
      } finally {
        setIsTargetSearching(false)
      }
    }

    searchTargetFunds()
  }, [debouncedTargetSearchQuery, selectedFund])

  useEffect(() => {
    if (isOpen) {
      setFormData({
        ...emptyFormData,
        clientId,
        type: initialType,
      })
      setErrors({})
      setSearchQuery('')
      setSearchResults([])
      setSelectedFund(null)
      setTargetSearchQuery('')
      setTargetSearchResults([])
      setTargetFund(null)
      setSipFrequency('Monthly')
      setSipDate(5)
      setSipStartDate('')
      setIsPerpetual(true)
      setSipEndDate('')
      setTargetFundCode('')
    }
  }, [isOpen, clientId, initialType])

  const handleSelectFund = (fund: DatabaseFund) => {
    setSelectedFund(fund)
    setFormData(prev => ({
      ...prev,
      fundSchemeCode: fund.schemeCode.toString(),
      fundName: fund.schemeName,
    }))
    setSearchQuery(fund.schemeName)
    setShowSearchResults(false)
    if (errors.fundSchemeCode) {
      setErrors(prev => ({ ...prev, fundSchemeCode: undefined }))
    }
  }

  const handleSelectTargetFund = (fund: DatabaseFund) => {
    setTargetFund(fund)
    setTargetFundCode(fund.schemeCode.toString())
    setTargetSearchQuery(fund.schemeName)
    setShowTargetSearchResults(false)
    if (errors.targetFund) {
      setErrors(prev => ({ ...prev, targetFund: undefined }))
    }
  }

  const validateForm = (): boolean => {
    const newErrors: Partial<Record<string, string>> = {}

    if (!formData.fundSchemeCode) {
      newErrors.fundSchemeCode = 'Please select a fund'
    }

    if (!formData.amount || formData.amount <= 0) {
      newErrors.amount = 'Please enter a valid amount'
    }

    if (formData.type === 'Buy' && formData.amount < 5000) {
      newErrors.amount = 'Minimum lumpsum amount is ₹5,000'
    }

    if (formData.type === 'SIP' && formData.amount < 500) {
      newErrors.amount = 'Minimum SIP amount is ₹500'
    }

    if ((formData.type === 'Switch' || formData.type === 'STP') && !targetFundCode) {
      newErrors.targetFund = 'Please select target fund'
    }

    if (formData.type === 'SIP' && !sipStartDate) {
      newErrors.sipStartDate = 'Please select start date'
    }

    setErrors(newErrors)
    return Object.keys(newErrors).length === 0
  }

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault()
    if (validateForm()) {
      // Include SIP-specific fields in form data
      const submitData: TransactionFormData = {
        ...formData,
        sipFrequency,
        sipDate,
        sipStartDate,
        sipEndDate: isPerpetual ? undefined : sipEndDate,
        isPerpetual,
        targetFundCode: targetFundCode || undefined,
      }
      onSubmit(submitData)
    }
  }

  const updateField = <K extends keyof TransactionFormData>(
    field: K,
    value: TransactionFormData[K]
  ) => {
    setFormData(prev => ({ ...prev, [field]: value }))
    if (errors[field]) {
      setErrors(prev => ({ ...prev, [field]: undefined }))
    }
  }

  if (!isOpen) return null

  const showSIPFields = formData.type === 'SIP'
  const showSwitchFields = formData.type === 'Switch' || formData.type === 'STP'
  const showSellFields = formData.type === 'Sell' || formData.type === 'SWP'

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center">
      {/* Backdrop */}
      <div
        className="absolute inset-0 bg-black/50 backdrop-blur-sm"
        onClick={onClose}
      />

      {/* Modal */}
      <div
        className="relative w-full max-w-xl max-h-[90vh] overflow-hidden rounded-2xl"
        style={{
          background: colors.cardBackground,
          backdropFilter: 'blur(20px)',
          border: `1px solid ${colors.cardBorder}`,
          boxShadow: `0 25px 50px -12px ${colors.glassShadow}`,
        }}
      >
        {/* Header */}
        <div
          className="flex items-center justify-between px-6 py-4 border-b"
          style={{ borderColor: colors.cardBorder }}
        >
          <div>
            <h2 className="text-lg font-semibold" style={{ color: colors.textPrimary }}>
              New Transaction
            </h2>
            <p className="text-sm" style={{ color: colors.textSecondary }}>
              For {clientName}
            </p>
          </div>
          <button
            onClick={onClose}
            className="p-2 rounded-lg transition-all hover:scale-105"
            style={{ background: colors.chipBg, color: colors.textSecondary }}
          >
            <svg className="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
              <path strokeLinecap="round" strokeLinejoin="round" d="M6 18L18 6M6 6l12 12" />
            </svg>
          </button>
        </div>

        {/* Form */}
        <form onSubmit={handleSubmit}>
          <div className="px-6 py-5 overflow-y-auto" style={{ maxHeight: 'calc(90vh - 160px)' }}>
            {/* Transaction Type */}
            <FAFormSection title="Transaction Type">
              <div className="grid grid-cols-3 gap-2">
                {TRANSACTION_TYPES.map(type => (
                  <button
                    key={type.value}
                    type="button"
                    onClick={() => updateField('type', type.value as TransactionType)}
                    className="p-3 rounded-xl text-sm font-medium transition-all text-center"
                    style={{
                      background: formData.type === type.value
                        ? `linear-gradient(135deg, ${colors.primary} 0%, ${colors.primaryDark} 100%)`
                        : isDark
                          ? 'rgba(147, 197, 253, 0.08)'
                          : 'rgba(59, 130, 246, 0.04)',
                      color: formData.type === type.value ? '#FFFFFF' : colors.textPrimary,
                      border: `1px solid ${formData.type === type.value ? 'transparent' : colors.cardBorder}`,
                    }}
                  >
                    {type.label}
                  </button>
                ))}
              </div>
            </FAFormSection>

            {/* Fund Selection */}
            <FAFormSection title="Select Fund" className="mt-6">
              <div className="relative">
                <FAInput
                  placeholder="Search funds by name or category..."
                  value={searchQuery}
                  onChange={(e) => {
                    setSearchQuery(e.target.value)
                    setShowSearchResults(true)
                    if (selectedFund && e.target.value !== selectedFund.schemeName) {
                      setSelectedFund(null)
                      setFormData(prev => ({ ...prev, fundSchemeCode: '', fundName: '' }))
                    }
                  }}
                  onFocus={() => setShowSearchResults(true)}
                  error={errors.fundSchemeCode}
                />
                {isSearching && (
                  <div className="absolute right-3 top-1/2 -translate-y-1/2">
                    <FASpinner size="sm" />
                  </div>
                )}
                {/* Search Results Dropdown */}
                {showSearchResults && searchResults.length > 0 && (
                  <div
                    className="absolute z-10 w-full mt-1 rounded-xl overflow-hidden max-h-60 overflow-y-auto"
                    style={{
                      background: colors.cardBackground,
                      border: `1px solid ${colors.cardBorder}`,
                      boxShadow: `0 8px 32px ${colors.glassShadow}`,
                    }}
                  >
                    {searchResults.map((fund) => (
                      <button
                        key={fund.schemeCode}
                        type="button"
                        onClick={() => handleSelectFund(fund)}
                        className="w-full p-3 text-left transition-all hover:bg-opacity-50"
                        style={{
                          borderBottom: `1px solid ${colors.cardBorder}`,
                        }}
                        onMouseEnter={(e) => {
                          e.currentTarget.style.background = isDark
                            ? 'rgba(147, 197, 253, 0.1)'
                            : 'rgba(59, 130, 246, 0.05)'
                        }}
                        onMouseLeave={(e) => {
                          e.currentTarget.style.background = 'transparent'
                        }}
                      >
                        <p className="text-sm font-medium" style={{ color: colors.textPrimary }}>
                          {fund.schemeName}
                        </p>
                        <div className="flex items-center gap-2 mt-1">
                          <span className="text-xs" style={{ color: colors.textTertiary }}>
                            {fund.category}
                          </span>
                          <span className="text-xs" style={{ color: colors.textTertiary }}>•</span>
                          <span className="text-xs font-medium" style={{ color: colors.primary }}>
                            NAV: ₹{fund.currentNav?.toFixed(2) || 'N/A'}
                          </span>
                        </div>
                      </button>
                    ))}
                  </div>
                )}
                {/* No results message */}
                {showSearchResults && searchQuery.length >= 2 && !isSearching && searchResults.length === 0 && (
                  <div
                    className="absolute z-10 w-full mt-1 p-4 rounded-xl text-center"
                    style={{
                      background: colors.cardBackground,
                      border: `1px solid ${colors.cardBorder}`,
                    }}
                  >
                    <p className="text-sm" style={{ color: colors.textSecondary }}>
                      No funds found matching "{searchQuery}"
                    </p>
                  </div>
                )}
              </div>
              {selectedFund && (
                <div
                  className="mt-3 p-3 rounded-xl flex items-center justify-between"
                  style={{
                    background: isDark
                      ? 'rgba(147, 197, 253, 0.08)'
                      : 'rgba(59, 130, 246, 0.04)',
                    border: `1px solid ${colors.cardBorder}`,
                  }}
                >
                  <div>
                    <p className="text-sm font-medium" style={{ color: colors.textPrimary }}>
                      {selectedFund.schemeName}
                    </p>
                    <p className="text-xs" style={{ color: colors.textTertiary }}>
                      {selectedFund.category} • {selectedFund.fundHouse}
                    </p>
                  </div>
                  <div className="text-right">
                    <p className="text-xs" style={{ color: colors.textTertiary }}>Current NAV</p>
                    <p className="font-semibold" style={{ color: colors.primary }}>
                      ₹{selectedFund.currentNav?.toFixed(2) || 'N/A'}
                    </p>
                  </div>
                </div>
              )}
            </FAFormSection>

            {/* Target Fund for Switch/STP */}
            {showSwitchFields && (
              <FAFormSection title="Target Fund" className="mt-6">
                <div className="relative">
                  <FAInput
                    placeholder="Search target fund..."
                    value={targetSearchQuery}
                    onChange={(e) => {
                      setTargetSearchQuery(e.target.value)
                      setShowTargetSearchResults(true)
                      if (targetFund && e.target.value !== targetFund.schemeName) {
                        setTargetFund(null)
                        setTargetFundCode('')
                      }
                    }}
                    onFocus={() => setShowTargetSearchResults(true)}
                    error={errors.targetFund}
                  />
                  {isTargetSearching && (
                    <div className="absolute right-3 top-1/2 -translate-y-1/2">
                      <FASpinner size="sm" />
                    </div>
                  )}
                  {/* Target Search Results Dropdown */}
                  {showTargetSearchResults && targetSearchResults.length > 0 && (
                    <div
                      className="absolute z-10 w-full mt-1 rounded-xl overflow-hidden max-h-60 overflow-y-auto"
                      style={{
                        background: colors.cardBackground,
                        border: `1px solid ${colors.cardBorder}`,
                        boxShadow: `0 8px 32px ${colors.glassShadow}`,
                      }}
                    >
                      {targetSearchResults.map((fund) => (
                        <button
                          key={fund.schemeCode}
                          type="button"
                          onClick={() => handleSelectTargetFund(fund)}
                          className="w-full p-3 text-left transition-all"
                          style={{
                            borderBottom: `1px solid ${colors.cardBorder}`,
                          }}
                          onMouseEnter={(e) => {
                            e.currentTarget.style.background = isDark
                              ? 'rgba(147, 197, 253, 0.1)'
                              : 'rgba(59, 130, 246, 0.05)'
                          }}
                          onMouseLeave={(e) => {
                            e.currentTarget.style.background = 'transparent'
                          }}
                        >
                          <p className="text-sm font-medium" style={{ color: colors.textPrimary }}>
                            {fund.schemeName}
                          </p>
                          <div className="flex items-center gap-2 mt-1">
                            <span className="text-xs" style={{ color: colors.textTertiary }}>
                              {fund.category}
                            </span>
                            <span className="text-xs" style={{ color: colors.textTertiary }}>•</span>
                            <span className="text-xs font-medium" style={{ color: colors.primary }}>
                              NAV: ₹{fund.currentNav?.toFixed(2) || 'N/A'}
                            </span>
                          </div>
                        </button>
                      ))}
                    </div>
                  )}
                </div>
                {targetFund && (
                  <div
                    className="mt-3 p-3 rounded-xl flex items-center justify-between"
                    style={{
                      background: isDark
                        ? 'rgba(147, 197, 253, 0.08)'
                        : 'rgba(59, 130, 246, 0.04)',
                      border: `1px solid ${colors.cardBorder}`,
                    }}
                  >
                    <div>
                      <p className="text-sm font-medium" style={{ color: colors.textPrimary }}>
                        {targetFund.schemeName}
                      </p>
                      <p className="text-xs" style={{ color: colors.textTertiary }}>
                        {targetFund.category} • {targetFund.fundHouse}
                      </p>
                    </div>
                    <div className="text-right">
                      <p className="text-xs" style={{ color: colors.textTertiary }}>Current NAV</p>
                      <p className="font-semibold" style={{ color: colors.primary }}>
                        ₹{targetFund.currentNav?.toFixed(2) || 'N/A'}
                      </p>
                    </div>
                  </div>
                )}
              </FAFormSection>
            )}

            {/* Amount */}
            <FAFormSection title="Amount" className="mt-6">
              <div className="grid grid-cols-2 gap-4">
                <FAInput
                  label={formData.type === 'SIP' ? 'SIP Amount' : 'Amount'}
                  type="number"
                  placeholder="Enter amount"
                  value={formData.amount || ''}
                  onChange={(e) => updateField('amount', Number(e.target.value))}
                  error={errors.amount}
                  helperText={
                    formData.type === 'SIP'
                      ? 'Minimum ₹500 per month'
                      : formData.type === 'Buy'
                        ? 'Minimum ₹5,000 for lumpsum'
                        : undefined
                  }
                  required
                />
                <FASelect
                  label="Folio"
                  options={[
                    { value: '', label: 'Create New Folio' },
                    { value: 'FOL123456', label: 'FOL123456 (Existing)' },
                  ]}
                  value={formData.folioNumber || ''}
                  onChange={(e) => updateField('folioNumber', e.target.value)}
                />
              </div>
              {formData.amount > 0 && selectedFund && selectedFund.currentNav > 0 && (
                <div className="mt-3 p-3 rounded-xl" style={{ background: colors.chipBg }}>
                  <p className="text-sm" style={{ color: colors.textSecondary }}>
                    Estimated Units: <span className="font-semibold" style={{ color: colors.textPrimary }}>
                      {(formData.amount / selectedFund.currentNav).toFixed(3)}
                    </span>
                  </p>
                </div>
              )}
            </FAFormSection>

            {/* SIP Fields */}
            {showSIPFields && (
              <FAFormSection title="SIP Details" className="mt-6">
                <div className="grid grid-cols-2 gap-4">
                  <FASelect
                    label="Frequency"
                    options={SIP_FREQUENCIES}
                    value={sipFrequency}
                    onChange={(e) => setSipFrequency(e.target.value as typeof sipFrequency)}
                  />
                  <FASelect
                    label="SIP Date"
                    options={[1, 5, 10, 15, 20, 25, 28].map(d => ({
                      value: d.toString(),
                      label: `${d}${d === 1 ? 'st' : d === 2 ? 'nd' : d === 3 ? 'rd' : 'th'} of every month`,
                    }))}
                    value={sipDate.toString()}
                    onChange={(e) => setSipDate(Number(e.target.value))}
                  />
                  <FAInput
                    label="Start Date"
                    type="date"
                    value={sipStartDate}
                    onChange={(e) => setSipStartDate(e.target.value)}
                    error={errors.sipStartDate}
                    required
                  />
                  <div>
                    <FALabel>Duration</FALabel>
                    <div className="flex items-center gap-4 mt-2">
                      <label className="flex items-center gap-2 cursor-pointer">
                        <input
                          type="radio"
                          checked={isPerpetual}
                          onChange={() => setIsPerpetual(true)}
                          className="sr-only"
                        />
                        <div
                          className="w-5 h-5 rounded-full border-2 flex items-center justify-center"
                          style={{ borderColor: isPerpetual ? colors.primary : colors.inputBorder }}
                        >
                          {isPerpetual && (
                            <div className="w-2.5 h-2.5 rounded-full" style={{ background: colors.primary }} />
                          )}
                        </div>
                        <span className="text-sm" style={{ color: colors.textPrimary }}>Perpetual</span>
                      </label>
                      <label className="flex items-center gap-2 cursor-pointer">
                        <input
                          type="radio"
                          checked={!isPerpetual}
                          onChange={() => setIsPerpetual(false)}
                          className="sr-only"
                        />
                        <div
                          className="w-5 h-5 rounded-full border-2 flex items-center justify-center"
                          style={{ borderColor: !isPerpetual ? colors.primary : colors.inputBorder }}
                        >
                          {!isPerpetual && (
                            <div className="w-2.5 h-2.5 rounded-full" style={{ background: colors.primary }} />
                          )}
                        </div>
                        <span className="text-sm" style={{ color: colors.textPrimary }}>Fixed</span>
                      </label>
                    </div>
                    {!isPerpetual && (
                      <FAInput
                        type="date"
                        placeholder="End Date"
                        value={sipEndDate}
                        onChange={(e) => setSipEndDate(e.target.value)}
                        containerClassName="mt-2"
                      />
                    )}
                  </div>
                </div>
              </FAFormSection>
            )}

            {/* Payment Mode */}
            {(formData.type === 'Buy' || formData.type === 'SIP') && (
              <FAFormSection title="Payment Mode" className="mt-6">
                <div className="flex gap-3">
                  {PAYMENT_MODES.map(mode => (
                    <button
                      key={mode.value}
                      type="button"
                      onClick={() => updateField('paymentMode', mode.value as TransactionFormData['paymentMode'])}
                      className="flex-1 p-3 rounded-xl text-sm font-medium transition-all text-center"
                      style={{
                        background: formData.paymentMode === mode.value
                          ? `linear-gradient(135deg, ${colors.primary} 0%, ${colors.primaryDark} 100%)`
                          : colors.chipBg,
                        color: formData.paymentMode === mode.value ? '#FFFFFF' : colors.textPrimary,
                        border: `1px solid ${formData.paymentMode === mode.value ? 'transparent' : colors.cardBorder}`,
                      }}
                    >
                      {mode.label}
                    </button>
                  ))}
                </div>
              </FAFormSection>
            )}

            {/* Sell/SWP Notice */}
            {showSellFields && (
              <div
                className="mt-6 p-4 rounded-xl"
                style={{
                  background: isDark
                    ? 'rgba(251, 191, 36, 0.08)'
                    : 'rgba(245, 158, 11, 0.04)',
                  border: `1px solid ${colors.warning}30`,
                }}
              >
                <div className="flex items-start gap-3">
                  <div
                    className="w-8 h-8 rounded-lg flex items-center justify-center flex-shrink-0"
                    style={{ background: `${colors.warning}15` }}
                  >
                    <svg className="w-4 h-4" style={{ color: colors.warning }} fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
                      <path strokeLinecap="round" strokeLinejoin="round" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z" />
                    </svg>
                  </div>
                  <div>
                    <p className="text-sm font-medium" style={{ color: colors.textPrimary }}>
                      {formData.type === 'Sell' ? 'Redemption Notice' : 'SWP Notice'}
                    </p>
                    <p className="text-xs mt-1" style={{ color: colors.textSecondary }}>
                      {formData.type === 'Sell'
                        ? 'Exit load may apply. Funds will be credited to the registered bank account within 3-5 business days.'
                        : 'SWP will redeem units periodically. Ensure sufficient balance in folio.'
                      }
                    </p>
                  </div>
                </div>
              </div>
            )}
          </div>

          {/* Footer */}
          <div
            className="flex items-center justify-end gap-3 px-6 py-4 border-t"
            style={{ borderColor: colors.cardBorder }}
          >
            <FAButton type="button" variant="secondary" onClick={onClose}>
              Cancel
            </FAButton>
            <FAButton type="submit">
              {formData.type === 'Buy' ? 'Place Order' :
               formData.type === 'SIP' ? 'Register SIP' :
               formData.type === 'Sell' ? 'Submit Redemption' :
               formData.type === 'Switch' ? 'Initiate Switch' :
               formData.type === 'SWP' ? 'Register SWP' :
               'Register STP'}
            </FAButton>
          </div>
        </form>
      </div>
    </div>
  )
}

export default TransactionFormModal
