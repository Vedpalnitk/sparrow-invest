/**
 * Client Form Modal Component
 *
 * Modal dialog for adding or editing client information.
 * Import with: import ClientFormModal from '@/components/advisor/ClientFormModal'
 */

import { useState, useEffect } from 'react'
import { useFATheme } from '@/utils/faHooks'
import { ClientFormData, RiskProfile } from '@/utils/faTypes'
import {
  FAButton,
  FAInput,
  FASelect,
  FALabel,
  FAFormSection,
} from '@/components/advisor/shared'

interface ClientFormModalProps {
  isOpen: boolean
  onClose: () => void
  onSubmit: (data: ClientFormData) => void
  initialData?: Partial<ClientFormData>
  mode: 'add' | 'edit'
}

const RISK_PROFILE_OPTIONS = [
  { value: 'Conservative', label: 'Conservative' },
  { value: 'Moderate', label: 'Moderate' },
  { value: 'Aggressive', label: 'Aggressive' },
]

const RELATIONSHIP_OPTIONS = [
  { value: 'Spouse', label: 'Spouse' },
  { value: 'Child', label: 'Child' },
  { value: 'Parent', label: 'Parent' },
  { value: 'Sibling', label: 'Sibling' },
  { value: 'Other', label: 'Other' },
]

const INDIAN_STATES = [
  { value: '', label: 'Select State' },
  { value: 'Andhra Pradesh', label: 'Andhra Pradesh' },
  { value: 'Delhi', label: 'Delhi' },
  { value: 'Gujarat', label: 'Gujarat' },
  { value: 'Karnataka', label: 'Karnataka' },
  { value: 'Kerala', label: 'Kerala' },
  { value: 'Maharashtra', label: 'Maharashtra' },
  { value: 'Tamil Nadu', label: 'Tamil Nadu' },
  { value: 'Telangana', label: 'Telangana' },
  { value: 'Uttar Pradesh', label: 'Uttar Pradesh' },
  { value: 'West Bengal', label: 'West Bengal' },
  // Add more states as needed
]

const emptyFormData: ClientFormData = {
  name: '',
  email: '',
  phone: '',
  pan: '',
  dateOfBirth: '',
  address: '',
  city: '',
  state: '',
  pincode: '',
  riskProfile: 'Moderate',
  nominee: {
    name: '',
    relationship: '',
    percentage: 100,
  },
}

const ClientFormModal = ({
  isOpen,
  onClose,
  onSubmit,
  initialData,
  mode,
}: ClientFormModalProps) => {
  const { colors, isDark } = useFATheme()
  const [formData, setFormData] = useState<ClientFormData>(emptyFormData)
  const [errors, setErrors] = useState<Partial<Record<keyof ClientFormData, string>>>({})
  const [activeTab, setActiveTab] = useState<'personal' | 'kyc' | 'nominee'>('personal')

  useEffect(() => {
    if (isOpen) {
      if (initialData) {
        setFormData({ ...emptyFormData, ...initialData })
      } else {
        setFormData(emptyFormData)
      }
      setErrors({})
      setActiveTab('personal')
    }
  }, [isOpen, initialData])

  const validateForm = (): boolean => {
    const newErrors: Partial<Record<keyof ClientFormData, string>> = {}

    if (!formData.name.trim()) {
      newErrors.name = 'Name is required'
    }

    if (!formData.email.trim()) {
      newErrors.email = 'Email is required'
    } else if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(formData.email)) {
      newErrors.email = 'Invalid email format'
    }

    if (!formData.phone.trim()) {
      newErrors.phone = 'Phone is required'
    } else if (!/^[+]?[\d\s-]{10,}$/.test(formData.phone.replace(/\s/g, ''))) {
      newErrors.phone = 'Invalid phone number'
    }

    if (formData.pan && !/^[A-Z]{5}[0-9]{4}[A-Z]{1}$/.test(formData.pan.toUpperCase())) {
      newErrors.pan = 'Invalid PAN format (e.g., ABCDE1234F)'
    }

    if (formData.pincode && !/^\d{6}$/.test(formData.pincode)) {
      newErrors.pincode = 'Pincode must be 6 digits'
    }

    setErrors(newErrors)
    return Object.keys(newErrors).length === 0
  }

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault()
    if (validateForm()) {
      onSubmit({
        ...formData,
        pan: formData.pan.toUpperCase(),
      })
    }
  }

  const updateField = <K extends keyof ClientFormData>(
    field: K,
    value: ClientFormData[K]
  ) => {
    setFormData(prev => ({ ...prev, [field]: value }))
    if (errors[field]) {
      setErrors(prev => ({ ...prev, [field]: undefined }))
    }
  }

  const updateNominee = (field: string, value: string | number) => {
    setFormData(prev => ({
      ...prev,
      nominee: {
        ...prev.nominee!,
        [field]: value,
      },
    }))
  }

  if (!isOpen) return null

  const tabs = [
    { id: 'personal', label: 'Personal Info' },
    { id: 'kyc', label: 'KYC Details' },
    { id: 'nominee', label: 'Nominee' },
  ] as const

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center">
      {/* Backdrop */}
      <div
        className="absolute inset-0 bg-black/50 backdrop-blur-sm"
        onClick={onClose}
      />

      {/* Modal */}
      <div
        className="relative w-full max-w-2xl max-h-[90vh] overflow-hidden rounded-2xl"
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
          <h2 className="text-lg font-semibold" style={{ color: colors.textPrimary }}>
            {mode === 'add' ? 'Add New Client' : 'Edit Client'}
          </h2>
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

        {/* Tabs */}
        <div
          className="flex gap-1 px-6 py-3 border-b"
          style={{ borderColor: colors.cardBorder }}
        >
          {tabs.map(tab => (
            <button
              key={tab.id}
              onClick={() => setActiveTab(tab.id)}
              className="px-4 py-2 rounded-lg text-sm font-medium transition-all"
              style={{
                background: activeTab === tab.id
                  ? `linear-gradient(135deg, ${colors.primary} 0%, ${colors.primaryDark} 100%)`
                  : colors.chipBg,
                color: activeTab === tab.id ? '#FFFFFF' : colors.textSecondary,
              }}
            >
              {tab.label}
            </button>
          ))}
        </div>

        {/* Form */}
        <form onSubmit={handleSubmit}>
          <div className="px-6 py-5 overflow-y-auto" style={{ maxHeight: 'calc(90vh - 200px)' }}>
            {/* Personal Info Tab */}
            {activeTab === 'personal' && (
              <div className="space-y-4">
                <FAFormSection title="Basic Information">
                  <div className="grid grid-cols-2 gap-4">
                    <FAInput
                      label="Full Name"
                      placeholder="Enter full name"
                      value={formData.name}
                      onChange={(e) => updateField('name', e.target.value)}
                      error={errors.name}
                      required
                      containerClassName="col-span-2"
                    />
                    <FAInput
                      label="Email Address"
                      type="email"
                      placeholder="email@example.com"
                      value={formData.email}
                      onChange={(e) => updateField('email', e.target.value)}
                      error={errors.email}
                      required
                    />
                    <FAInput
                      label="Phone Number"
                      type="tel"
                      placeholder="+91 98765 43210"
                      value={formData.phone}
                      onChange={(e) => updateField('phone', e.target.value)}
                      error={errors.phone}
                      required
                    />
                    <FAInput
                      label="Date of Birth"
                      type="date"
                      value={formData.dateOfBirth}
                      onChange={(e) => updateField('dateOfBirth', e.target.value)}
                    />
                    <FASelect
                      label="Risk Profile"
                      options={RISK_PROFILE_OPTIONS}
                      value={formData.riskProfile}
                      onChange={(e) => updateField('riskProfile', e.target.value as RiskProfile)}
                      required
                    />
                  </div>
                </FAFormSection>

                <FAFormSection title="Address">
                  <div className="grid grid-cols-2 gap-4">
                    <FAInput
                      label="Street Address"
                      placeholder="Enter address"
                      value={formData.address}
                      onChange={(e) => updateField('address', e.target.value)}
                      containerClassName="col-span-2"
                    />
                    <FAInput
                      label="City"
                      placeholder="City"
                      value={formData.city}
                      onChange={(e) => updateField('city', e.target.value)}
                    />
                    <FASelect
                      label="State"
                      options={INDIAN_STATES}
                      value={formData.state}
                      onChange={(e) => updateField('state', e.target.value)}
                    />
                    <FAInput
                      label="Pincode"
                      placeholder="400001"
                      value={formData.pincode}
                      onChange={(e) => updateField('pincode', e.target.value)}
                      error={errors.pincode}
                    />
                  </div>
                </FAFormSection>
              </div>
            )}

            {/* KYC Tab */}
            {activeTab === 'kyc' && (
              <div className="space-y-4">
                <FAFormSection
                  title="KYC Information"
                  description="Verify client identity as per SEBI/AMFI regulations"
                >
                  <div className="grid grid-cols-2 gap-4">
                    <FAInput
                      label="PAN Number"
                      placeholder="ABCDE1234F"
                      value={formData.pan}
                      onChange={(e) => updateField('pan', e.target.value.toUpperCase())}
                      error={errors.pan}
                      helperText="Permanent Account Number for tax purposes"
                      containerClassName="col-span-2 md:col-span-1"
                    />
                  </div>
                </FAFormSection>

                <div
                  className="p-4 rounded-xl"
                  style={{
                    background: isDark
                      ? 'rgba(147, 197, 253, 0.08)'
                      : 'rgba(59, 130, 246, 0.04)',
                    border: `1px solid ${colors.cardBorder}`,
                  }}
                >
                  <div className="flex items-start gap-3">
                    <div
                      className="w-8 h-8 rounded-lg flex items-center justify-center flex-shrink-0"
                      style={{ background: `${colors.primary}15` }}
                    >
                      <svg className="w-4 h-4" style={{ color: colors.primary }} fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
                        <path strokeLinecap="round" strokeLinejoin="round" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
                      </svg>
                    </div>
                    <div>
                      <p className="text-sm font-medium" style={{ color: colors.textPrimary }}>
                        KYC Verification
                      </p>
                      <p className="text-xs mt-1" style={{ color: colors.textSecondary }}>
                        After adding the client, you can initiate KYC verification through the client detail page.
                        Documents required: PAN card, Aadhaar, Address proof, and Bank statement.
                      </p>
                    </div>
                  </div>
                </div>
              </div>
            )}

            {/* Nominee Tab */}
            {activeTab === 'nominee' && (
              <div className="space-y-4">
                <FAFormSection
                  title="Nominee Details"
                  description="Designate a beneficiary for the client's investments"
                >
                  <div className="grid grid-cols-2 gap-4">
                    <FAInput
                      label="Nominee Name"
                      placeholder="Enter nominee name"
                      value={formData.nominee?.name || ''}
                      onChange={(e) => updateNominee('name', e.target.value)}
                      containerClassName="col-span-2"
                    />
                    <FASelect
                      label="Relationship"
                      options={[{ value: '', label: 'Select Relationship' }, ...RELATIONSHIP_OPTIONS]}
                      value={formData.nominee?.relationship || ''}
                      onChange={(e) => updateNominee('relationship', e.target.value)}
                    />
                    <FAInput
                      label="Percentage"
                      type="number"
                      placeholder="100"
                      value={formData.nominee?.percentage?.toString() || '100'}
                      onChange={(e) => updateNominee('percentage', Number(e.target.value))}
                      helperText="Percentage of holdings"
                    />
                  </div>
                </FAFormSection>

                <div
                  className="p-4 rounded-xl"
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
                        Important Note
                      </p>
                      <p className="text-xs mt-1" style={{ color: colors.textSecondary }}>
                        Nominee details are optional but recommended. The nominee will be entitled to the
                        investments in case of unfortunate events. For multiple nominees, additional details
                        can be added from the client detail page.
                      </p>
                    </div>
                  </div>
                </div>
              </div>
            )}
          </div>

          {/* Footer */}
          <div
            className="flex items-center justify-between px-6 py-4 border-t"
            style={{ borderColor: colors.cardBorder }}
          >
            <div className="flex items-center gap-2">
              {activeTab !== 'personal' && (
                <FAButton
                  type="button"
                  variant="ghost"
                  onClick={() => setActiveTab(activeTab === 'nominee' ? 'kyc' : 'personal')}
                >
                  Back
                </FAButton>
              )}
            </div>
            <div className="flex items-center gap-3">
              <FAButton type="button" variant="secondary" onClick={onClose}>
                Cancel
              </FAButton>
              {activeTab !== 'nominee' ? (
                <FAButton
                  type="button"
                  onClick={() => setActiveTab(activeTab === 'personal' ? 'kyc' : 'nominee')}
                >
                  Next
                </FAButton>
              ) : (
                <FAButton type="submit">
                  {mode === 'add' ? 'Add Client' : 'Save Changes'}
                </FAButton>
              )}
            </div>
          </div>
        </form>
      </div>
    </div>
  )
}

export default ClientFormModal
