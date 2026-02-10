/**
 * Export Utilities for Admin Portal
 *
 * CSV and JSON export functionality for data exports.
 */

/**
 * Convert an array of objects to CSV format
 */
export function toCSV<T extends Record<string, any>>(
  data: T[],
  columns?: { key: keyof T; header: string }[]
): string {
  if (data.length === 0) return '';

  // Determine columns to export
  const cols = columns || Object.keys(data[0]).map((key) => ({
    key: key as keyof T,
    header: key.toString(),
  }));

  // Create header row
  const header = cols.map((col) => `"${col.header}"`).join(',');

  // Create data rows
  const rows = data.map((row) =>
    cols
      .map((col) => {
        const value = row[col.key];
        // Handle null, undefined, objects
        if (value === null || value === undefined) return '""';
        if (typeof value === 'object') return `"${JSON.stringify(value).replace(/"/g, '""')}"`;
        // Escape quotes and wrap in quotes
        return `"${String(value).replace(/"/g, '""')}"`;
      })
      .join(',')
  );

  return [header, ...rows].join('\n');
}

/**
 * Convert an array of objects to JSON format (pretty printed)
 */
export function toJSON<T>(data: T[]): string {
  return JSON.stringify(data, null, 2);
}

/**
 * Download data as a file
 */
export function downloadFile(content: string, filename: string, mimeType: string): void {
  const blob = new Blob([content], { type: mimeType });
  const url = URL.createObjectURL(blob);
  const link = document.createElement('a');
  link.href = url;
  link.download = filename;
  document.body.appendChild(link);
  link.click();
  document.body.removeChild(link);
  URL.revokeObjectURL(url);
}

/**
 * Export data to CSV and trigger download
 */
export function exportToCSV<T extends Record<string, any>>(
  data: T[],
  filename: string,
  columns?: { key: keyof T; header: string }[]
): void {
  const csv = toCSV(data, columns);
  const timestamp = new Date().toISOString().slice(0, 10);
  downloadFile(csv, `${filename}_${timestamp}.csv`, 'text/csv;charset=utf-8;');
}

/**
 * Export data to JSON and trigger download
 */
export function exportToJSON<T>(data: T[], filename: string): void {
  const json = toJSON(data);
  const timestamp = new Date().toISOString().slice(0, 10);
  downloadFile(json, `${filename}_${timestamp}.json`, 'application/json');
}

/**
 * User-specific export columns
 */
export const userExportColumns = [
  { key: 'id' as const, header: 'ID' },
  { key: 'email' as const, header: 'Email' },
  { key: 'name' as const, header: 'Name' },
  { key: 'role' as const, header: 'Role' },
  { key: 'phone' as const, header: 'Phone' },
  { key: 'isActive' as const, header: 'Status' },
  { key: 'isVerified' as const, header: 'Verified' },
  { key: 'lastLoginAt' as const, header: 'Last Login' },
  { key: 'createdAt' as const, header: 'Created At' },
];

/**
 * Transform SystemUser to exportable format
 */
export interface UserExportRow {
  id: string;
  email: string;
  name: string;
  role: string;
  phone: string;
  isActive: string;
  isVerified: string;
  lastLoginAt: string;
  createdAt: string;
}

export function transformUserForExport(user: {
  id: string;
  email: string;
  profile?: { name?: string } | null;
  role: string;
  phone?: string | null;
  isActive: boolean;
  isVerified: boolean;
  lastLoginAt?: string | null;
  createdAt: string;
}): UserExportRow {
  return {
    id: user.id,
    email: user.email,
    name: user.profile?.name || '',
    role: user.role,
    phone: user.phone || '',
    isActive: user.isActive ? 'Active' : 'Inactive',
    isVerified: user.isVerified ? 'Yes' : 'No',
    lastLoginAt: user.lastLoginAt || 'Never',
    createdAt: user.createdAt,
  };
}
