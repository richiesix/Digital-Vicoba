import { ReactNode } from 'react'
import { hasAdminPermission } from '../lib/rbac'

type Props = {
  permission: string
  children: ReactNode
  fallback?: ReactNode
}

export default function RoleGate({ permission, children, fallback = null }: Props) {
  if (!hasAdminPermission(permission)) {
    return <>{fallback}</>
  }
  return <>{children}</>
}
