/**
 * Admin Portal Shared Components
 *
 * Barrel export for all Admin shared components.
 * Import with: import { AdminCard, AdminTintedCard, AdminChip, AdminModal } from '@/components/admin/shared'
 */

export {
  AdminCard,
  AdminTintedCard,
  AdminInfoTile,
  AdminStatCard,
  AdminSectionHeader,
  AdminChip,
  AdminIconContainer,
  AdminEmptyState,
  AdminSpinner,
  AdminButton,
  AdminDivider,
  AdminProgressBar,
} from './AdminCard'

export { AdminModal } from './AdminModal'
export type { AdminModalProps } from './AdminModal'

export { AdminPagination } from './AdminPagination'
export type { AdminPaginationProps } from './AdminPagination'
