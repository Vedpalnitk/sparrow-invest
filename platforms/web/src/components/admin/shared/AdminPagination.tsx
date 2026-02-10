/**
 * Admin Portal Pagination Component - "Sage & Cream" Design System
 *
 * Shared pagination component for Admin pages with consistent styling.
 * Import with: import { AdminPagination } from '@/components/admin/shared'
 */

import { useAdminTheme } from '@/utils/adminTheme'

export interface AdminPaginationProps {
  currentPage: number
  totalPages: number
  totalItems: number
  itemsPerPage: number
  onPageChange: (page: number) => void
  onItemsPerPageChange?: (itemsPerPage: number) => void
  itemsPerPageOptions?: number[]
  showItemsPerPage?: boolean
}

export const AdminPagination = ({
  currentPage,
  totalPages,
  totalItems,
  itemsPerPage,
  onPageChange,
  onItemsPerPageChange,
  itemsPerPageOptions = [10, 25, 50, 100],
  showItemsPerPage = true,
}: AdminPaginationProps) => {
  const { colors } = useAdminTheme()

  const startIndex = (currentPage - 1) * itemsPerPage + 1
  const endIndex = Math.min(currentPage * itemsPerPage, totalItems)

  return (
    <div
      className="p-4 border-t flex items-center justify-between"
      style={{ borderColor: colors.chipBorder }}
    >
      {/* Left side - showing count and items per page */}
      <div className="flex items-center gap-4">
        <span className="text-sm" style={{ color: colors.textSecondary }}>
          Showing {startIndex}-{endIndex} of {totalItems}
        </span>

        {showItemsPerPage && onItemsPerPageChange && (
          <div className="flex items-center gap-2">
            <span className="text-xs" style={{ color: colors.textTertiary }}>
              Per page:
            </span>
            <select
              value={itemsPerPage}
              onChange={(e) => onItemsPerPageChange(Number(e.target.value))}
              className="h-8 px-2 rounded-lg text-sm focus:outline-none"
              style={{
                background: colors.inputBg,
                border: `1px solid ${colors.inputBorder}`,
                color: colors.textPrimary,
              }}
            >
              {itemsPerPageOptions.map((option) => (
                <option key={option} value={option}>
                  {option}
                </option>
              ))}
            </select>
          </div>
        )}
      </div>

      {/* Right side - pagination controls */}
      <div className="flex items-center gap-2">
        {/* First page */}
        <button
          onClick={() => onPageChange(1)}
          disabled={currentPage === 1}
          className="p-2 rounded-lg transition-all disabled:opacity-40"
          style={{ background: colors.chipBg }}
          aria-label="First page"
        >
          <svg
            className="w-4 h-4"
            fill="none"
            viewBox="0 0 24 24"
            stroke="currentColor"
            style={{ color: colors.textSecondary }}
          >
            <path
              strokeLinecap="round"
              strokeLinejoin="round"
              strokeWidth={2}
              d="M11 19l-7-7 7-7m8 14l-7-7 7-7"
            />
          </svg>
        </button>

        {/* Previous page */}
        <button
          onClick={() => onPageChange(Math.max(1, currentPage - 1))}
          disabled={currentPage === 1}
          className="p-2 rounded-lg transition-all disabled:opacity-40"
          style={{ background: colors.chipBg }}
          aria-label="Previous page"
        >
          <svg
            className="w-4 h-4"
            fill="none"
            viewBox="0 0 24 24"
            stroke="currentColor"
            style={{ color: colors.textSecondary }}
          >
            <path
              strokeLinecap="round"
              strokeLinejoin="round"
              strokeWidth={2}
              d="M15 19l-7-7 7-7"
            />
          </svg>
        </button>

        {/* Page indicator */}
        <span className="px-3 text-sm" style={{ color: colors.textPrimary }}>
          Page {currentPage} of {totalPages || 1}
        </span>

        {/* Next page */}
        <button
          onClick={() => onPageChange(Math.min(totalPages, currentPage + 1))}
          disabled={currentPage === totalPages || totalPages === 0}
          className="p-2 rounded-lg transition-all disabled:opacity-40"
          style={{ background: colors.chipBg }}
          aria-label="Next page"
        >
          <svg
            className="w-4 h-4"
            fill="none"
            viewBox="0 0 24 24"
            stroke="currentColor"
            style={{ color: colors.textSecondary }}
          >
            <path
              strokeLinecap="round"
              strokeLinejoin="round"
              strokeWidth={2}
              d="M9 5l7 7-7 7"
            />
          </svg>
        </button>

        {/* Last page */}
        <button
          onClick={() => onPageChange(totalPages)}
          disabled={currentPage === totalPages || totalPages === 0}
          className="p-2 rounded-lg transition-all disabled:opacity-40"
          style={{ background: colors.chipBg }}
          aria-label="Last page"
        >
          <svg
            className="w-4 h-4"
            fill="none"
            viewBox="0 0 24 24"
            stroke="currentColor"
            style={{ color: colors.textSecondary }}
          >
            <path
              strokeLinecap="round"
              strokeLinejoin="round"
              strokeWidth={2}
              d="M13 5l7 7-7 7M5 5l7 7-7 7"
            />
          </svg>
        </button>
      </div>
    </div>
  )
}

export default AdminPagination
