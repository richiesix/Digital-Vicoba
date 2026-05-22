/**
 * Web admin is platform-only (system / regional operators).
 * Day-to-day VICOBA group ops (members, governance, finance) belong on the mobile app.
 */
export type AdminRole = 'super_admin' | 'regional_admin' | 'treasurer' | 'member'

const ROLE_KEY = 'dv_admin_role'

export const getAdminRole = (): AdminRole => {
  const stored = localStorage.getItem(ROLE_KEY) as AdminRole | null
  return stored ?? 'super_admin'
}

export const setAdminRole = (role: AdminRole): void => {
  localStorage.setItem(ROLE_KEY, role)
}

export const canAccessAdmin = (role: AdminRole): boolean =>
  role === 'super_admin' || role === 'regional_admin'

export const adminPermissions: Record<AdminRole, string[]> = {
  super_admin: [
    'platform.full_access',
    'platform.manage_users',
    'platform.national_analytics',
    'platform.fraud_alerts',
    'platform.system_logs',
  ],
  regional_admin: ['platform.national_analytics'],
  treasurer: [],
  member: [],
}

export const hasAdminPermission = (permission: string): boolean => {
  const role = getAdminRole()
  return adminPermissions[role]?.includes(permission) ?? false
}
