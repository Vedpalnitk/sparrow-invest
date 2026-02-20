import { useFATheme } from '@/utils/fa'

interface BseStatusBadgeProps {
  status: string
  size?: 'sm' | 'md'
}

const STATUS_COLORS: Record<string, { bg: string; text: string; label: string }> = {
  CREATED: { bg: 'rgba(59, 130, 246, 0.1)', text: '#3B82F6', label: 'Created' },
  DRAFT: { bg: 'rgba(107, 114, 128, 0.1)', text: '#6B7280', label: 'Draft' },
  SUBMITTED: { bg: 'rgba(245, 158, 11, 0.1)', text: '#F59E0B', label: 'Submitted' },
  ACCEPTED: { bg: 'rgba(16, 185, 129, 0.1)', text: '#10B981', label: 'Accepted' },
  APPROVED: { bg: 'rgba(16, 185, 129, 0.1)', text: '#10B981', label: 'Approved' },
  REJECTED: { bg: 'rgba(239, 68, 68, 0.1)', text: '#EF4444', label: 'Rejected' },
  CANCELLED: { bg: 'rgba(107, 114, 128, 0.1)', text: '#6B7280', label: 'Cancelled' },
  PAYMENT_PENDING: { bg: 'rgba(245, 158, 11, 0.1)', text: '#F59E0B', label: 'Payment Pending' },
  PAYMENT_SUCCESS: { bg: 'rgba(16, 185, 129, 0.1)', text: '#10B981', label: 'Payment Success' },
  PAYMENT_FAILED: { bg: 'rgba(239, 68, 68, 0.1)', text: '#EF4444', label: 'Payment Failed' },
  ALLOTTED: { bg: 'rgba(16, 185, 129, 0.1)', text: '#10B981', label: 'Allotted' },
  FAILED: { bg: 'rgba(239, 68, 68, 0.1)', text: '#EF4444', label: 'Failed' },
  INITIATED: { bg: 'rgba(59, 130, 246, 0.1)', text: '#3B82F6', label: 'Initiated' },
  SUCCESS: { bg: 'rgba(16, 185, 129, 0.1)', text: '#10B981', label: 'Success' },
  EXPIRED: { bg: 'rgba(107, 114, 128, 0.1)', text: '#6B7280', label: 'Expired' },
  SHIFTED: { bg: 'rgba(59, 130, 246, 0.1)', text: '#3B82F6', label: 'Shifted' },
  MODIFICATION_PENDING: { bg: 'rgba(245, 158, 11, 0.1)', text: '#F59E0B', label: 'Modification Pending' },
  ACTIVE: { bg: 'rgba(16, 185, 129, 0.1)', text: '#10B981', label: 'Active' },
  UPLOADED: { bg: 'rgba(16, 185, 129, 0.1)', text: '#10B981', label: 'Uploaded' },
}

export default function BseStatusBadge({ status, size = 'sm' }: BseStatusBadgeProps) {
  const statusConfig = STATUS_COLORS[status?.toUpperCase()] || {
    bg: 'rgba(107, 114, 128, 0.1)',
    text: '#6B7280',
    label: status || 'Unknown',
  }

  return (
    <span
      className={`inline-flex items-center rounded-full font-medium ${
        size === 'sm' ? 'text-xs px-2 py-0.5' : 'text-sm px-3 py-1'
      }`}
      style={{
        background: statusConfig.bg,
        color: statusConfig.text,
      }}
    >
      {statusConfig.label}
    </span>
  )
}
