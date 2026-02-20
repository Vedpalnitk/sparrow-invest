import { useFATheme } from '@/utils/fa'

interface TimelineStep {
  label: string
  status: 'completed' | 'current' | 'pending' | 'failed'
  timestamp?: string
}

interface BseOrderTimelineProps {
  orderStatus: string
  paymentStatus?: string
  submittedAt?: string
  allottedAt?: string
}

const ORDER_STEPS: Record<string, TimelineStep[]> = {
  CREATED: [
    { label: 'Created', status: 'current' },
    { label: 'Submitted', status: 'pending' },
    { label: 'Accepted', status: 'pending' },
    { label: 'Payment', status: 'pending' },
    { label: 'Allotted', status: 'pending' },
  ],
  SUBMITTED: [
    { label: 'Created', status: 'completed' },
    { label: 'Submitted', status: 'current' },
    { label: 'Accepted', status: 'pending' },
    { label: 'Payment', status: 'pending' },
    { label: 'Allotted', status: 'pending' },
  ],
  ACCEPTED: [
    { label: 'Created', status: 'completed' },
    { label: 'Submitted', status: 'completed' },
    { label: 'Accepted', status: 'current' },
    { label: 'Payment', status: 'pending' },
    { label: 'Allotted', status: 'pending' },
  ],
  PAYMENT_PENDING: [
    { label: 'Created', status: 'completed' },
    { label: 'Submitted', status: 'completed' },
    { label: 'Accepted', status: 'completed' },
    { label: 'Payment', status: 'current' },
    { label: 'Allotted', status: 'pending' },
  ],
  PAYMENT_SUCCESS: [
    { label: 'Created', status: 'completed' },
    { label: 'Submitted', status: 'completed' },
    { label: 'Accepted', status: 'completed' },
    { label: 'Payment', status: 'completed' },
    { label: 'Allotted', status: 'pending' },
  ],
  ALLOTTED: [
    { label: 'Created', status: 'completed' },
    { label: 'Submitted', status: 'completed' },
    { label: 'Accepted', status: 'completed' },
    { label: 'Payment', status: 'completed' },
    { label: 'Allotted', status: 'completed' },
  ],
  REJECTED: [
    { label: 'Created', status: 'completed' },
    { label: 'Submitted', status: 'completed' },
    { label: 'Rejected', status: 'failed' },
  ],
  CANCELLED: [
    { label: 'Created', status: 'completed' },
    { label: 'Cancelled', status: 'failed' },
  ],
  FAILED: [
    { label: 'Created', status: 'completed' },
    { label: 'Failed', status: 'failed' },
  ],
}

export default function BseOrderTimeline({ orderStatus }: BseOrderTimelineProps) {
  const { colors } = useFATheme()
  const steps = ORDER_STEPS[orderStatus] || ORDER_STEPS.CREATED

  const getStepColor = (status: string) => {
    switch (status) {
      case 'completed': return colors.success
      case 'current': return colors.primary
      case 'failed': return colors.error
      default: return colors.textTertiary
    }
  }

  return (
    <div className="flex items-center gap-1">
      {steps.map((step, i) => (
        <div key={step.label} className="flex items-center">
          <div className="flex flex-col items-center">
            <div
              className="w-3 h-3 rounded-full"
              style={{
                background: getStepColor(step.status),
                opacity: step.status === 'pending' ? 0.3 : 1,
              }}
            />
            <span
              className="text-[10px] mt-1 whitespace-nowrap"
              style={{
                color: step.status === 'pending' ? colors.textTertiary : getStepColor(step.status),
                fontWeight: step.status === 'current' ? 600 : 400,
              }}
            >
              {step.label}
            </span>
          </div>
          {i < steps.length - 1 && (
            <div
              className="w-6 h-0.5 mb-4"
              style={{
                background: step.status === 'completed' ? colors.success : colors.textTertiary,
                opacity: step.status === 'completed' ? 1 : 0.2,
              }}
            />
          )}
        </div>
      ))}
    </div>
  )
}
