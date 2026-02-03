/**
 * Prospect Form Modal
 *
 * Modal component for adding/editing prospects in the FA portal.
 * Includes form for prospect details and activities.
 */

import { useState, useEffect } from 'react'
import { useFATheme, formatCurrency } from '@/utils/fa'
import { Prospect, ProspectFormData, LeadSource, ProspectStage } from '@/utils/faTypes'
import {
  FACard,
  FALabel,
  FAInput,
  FATextarea,
  FASelect,
  FAButton,
} from '@/components/advisor/shared'

interface ProspectFormModalProps {
  isOpen: boolean
  onClose: () => void
  onSubmit: (data: ProspectFormData) => void
  prospect?: Prospect | null // If provided, edit mode
}

const LEAD_SOURCES: { value: LeadSource; label: string }[] = [
  { value: 'Referral', label: 'Referral' },
  { value: 'Website', label: 'Website' },
  { value: 'LinkedIn', label: 'LinkedIn' },
  { value: 'Event', label: 'Event / Seminar' },
  { value: 'Cold Call', label: 'Cold Call' },
  { value: 'Social Media', label: 'Social Media' },
  { value: 'Other', label: 'Other' },
]

const ProspectFormModal = ({
  isOpen,
  onClose,
  onSubmit,
  prospect,
}: ProspectFormModalProps) => {
  const { colors } = useFATheme()
  const isEditMode = !!prospect

  const [formData, setFormData] = useState<ProspectFormData>({
    name: '',
    email: '',
    phone: '',
    potentialAum: 0,
    source: 'Website',
    notes: '',
    referredBy: '',
  })

  const [errors, setErrors] = useState<Partial<Record<keyof ProspectFormData, string>>>({})

  useEffect(() => {
    if (prospect) {
      setFormData({
        name: prospect.name,
        email: prospect.email,
        phone: prospect.phone,
        potentialAum: prospect.potentialAum,
        source: prospect.source,
        notes: prospect.notes,
        referredBy: prospect.referredBy || '',
      })
    } else {
      setFormData({
        name: '',
        email: '',
        phone: '',
        potentialAum: 0,
        source: 'Website',
        notes: '',
        referredBy: '',
      })
    }
    setErrors({})
  }, [prospect, isOpen])

  const validateForm = (): boolean => {
    const newErrors: Partial<Record<keyof ProspectFormData, string>> = {}

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
    } else if (!/^(\+91[\s-]?)?[6-9]\d{4}[\s-]?\d{5}$/.test(formData.phone.replace(/\s/g, ''))) {
      newErrors.phone = 'Invalid phone number'
    }

    if (formData.potentialAum <= 0) {
      newErrors.potentialAum = 'Potential AUM must be greater than 0'
    }

    setErrors(newErrors)
    return Object.keys(newErrors).length === 0
  }

  const handleSubmit = () => {
    if (validateForm()) {
      onSubmit(formData)
      onClose()
    }
  }

  if (!isOpen) return null

  return (
    <div
      className="fixed inset-0 z-50 flex items-center justify-center p-4"
      style={{ background: 'rgba(0, 0, 0, 0.5)', backdropFilter: 'blur(4px)' }}
      onClick={onClose}
    >
      <div
        className="w-full max-w-lg max-h-[90vh] overflow-y-auto rounded-2xl"
        style={{
          background: colors.cardBackground,
          border: `1px solid ${colors.cardBorder}`,
          boxShadow: `0 25px 50px ${colors.glassShadow}`,
        }}
        onClick={(e) => e.stopPropagation()}
      >
        {/* Header */}
        <div
          className="sticky top-0 p-5 flex items-center justify-between"
          style={{
            background: colors.cardBackground,
            borderBottom: `1px solid ${colors.cardBorder}`,
          }}
        >
          <div>
            <h2 className="text-lg font-bold" style={{ color: colors.textPrimary }}>
              {isEditMode ? 'Edit Prospect' : 'Add New Prospect'}
            </h2>
            <p className="text-sm mt-0.5" style={{ color: colors.textSecondary }}>
              {isEditMode ? 'Update prospect details' : 'Enter prospect information'}
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
        <div className="p-5 space-y-4">
          {/* Name */}
          <div>
            <FALabel required>Full Name</FALabel>
            <FAInput
              placeholder="Enter prospect's name"
              value={formData.name}
              onChange={(e) => setFormData({ ...formData, name: e.target.value })}
              error={errors.name}
            />
          </div>

          {/* Contact Row */}
          <div className="grid grid-cols-2 gap-4">
            <div>
              <FALabel required>Email</FALabel>
              <FAInput
                type="email"
                placeholder="email@example.com"
                value={formData.email}
                onChange={(e) => setFormData({ ...formData, email: e.target.value })}
                error={errors.email}
              />
            </div>
            <div>
              <FALabel required>Phone</FALabel>
              <FAInput
                type="tel"
                placeholder="+91 98765 43210"
                value={formData.phone}
                onChange={(e) => setFormData({ ...formData, phone: e.target.value })}
                error={errors.phone}
              />
            </div>
          </div>

          {/* Potential AUM & Source */}
          <div className="grid grid-cols-2 gap-4">
            <div>
              <FALabel required>Potential AUM</FALabel>
              <FAInput
                type="number"
                placeholder="5000000"
                value={formData.potentialAum || ''}
                onChange={(e) => setFormData({ ...formData, potentialAum: parseFloat(e.target.value) || 0 })}
                error={errors.potentialAum}
              />
              {formData.potentialAum > 0 && (
                <p className="text-xs mt-1" style={{ color: colors.primary }}>
                  {formatCurrency(formData.potentialAum)}
                </p>
              )}
            </div>
            <div>
              <FALabel required>Lead Source</FALabel>
              <FASelect
                options={LEAD_SOURCES}
                value={formData.source}
                onChange={(e) => setFormData({ ...formData, source: e.target.value as LeadSource })}
              />
            </div>
          </div>

          {/* Referred By (conditional) */}
          {formData.source === 'Referral' && (
            <div>
              <FALabel>Referred By</FALabel>
              <FAInput
                placeholder="Name of the referrer"
                value={formData.referredBy || ''}
                onChange={(e) => setFormData({ ...formData, referredBy: e.target.value })}
              />
            </div>
          )}

          {/* Notes */}
          <div>
            <FALabel>Notes</FALabel>
            <FATextarea
              placeholder="Additional notes about the prospect..."
              rows={3}
              value={formData.notes || ''}
              onChange={(e) => setFormData({ ...formData, notes: e.target.value })}
            />
          </div>
        </div>

        {/* Footer */}
        <div
          className="sticky bottom-0 p-5 flex items-center justify-end gap-3"
          style={{
            background: colors.cardBackground,
            borderTop: `1px solid ${colors.cardBorder}`,
          }}
        >
          <button
            onClick={onClose}
            className="px-5 py-2.5 rounded-full text-sm font-semibold transition-all"
            style={{
              background: colors.chipBg,
              color: colors.textPrimary,
              border: `1px solid ${colors.cardBorder}`,
            }}
          >
            Cancel
          </button>
          <FAButton onClick={handleSubmit}>
            {isEditMode ? 'Update Prospect' : 'Add Prospect'}
          </FAButton>
        </div>
      </div>
    </div>
  )
}

export default ProspectFormModal
