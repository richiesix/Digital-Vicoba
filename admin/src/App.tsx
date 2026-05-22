import { BrowserRouter, Routes, Route, NavLink } from 'react-router-dom'
import { LayoutDashboard, Users, Building2, AlertTriangle, MapPin } from 'lucide-react'
import Analytics from './pages/Analytics'
import UserManagement from './pages/UserManagement'
import FinancialMonitoring from './pages/FinancialMonitoring'
import RegionalReports from './pages/RegionalReports'
import FraudMonitoring from './pages/FraudMonitoring'
import RoleGate from './components/RoleGate'
import { canAccessAdmin, getAdminRole } from './lib/rbac'

const nav = [
  { to: '/', icon: LayoutDashboard, label: 'Analytics', permission: 'platform.national_analytics' },
  { to: '/users', icon: Users, label: 'Users', permission: 'platform.manage_users' },
  { to: '/financial', icon: Building2, label: 'Financial', permission: 'platform.full_access' },
  { to: '/regional', icon: MapPin, label: 'Regional', permission: 'platform.national_analytics' },
  { to: '/fraud', icon: AlertTriangle, label: 'Fraud', permission: 'platform.fraud_alerts' },
]

export default function App() {
  const role = getAdminRole()

  if (!canAccessAdmin(role)) {
    return (
      <div className="min-h-screen flex items-center justify-center p-8">
        <p className="text-lg text-gray-700">
          Dashibodi ya wavuti ni kwa Msimamizi Mkuu au Msimamizi wa Mkoa pekee.
        </p>
      </div>
    )
  }

  return (
    <BrowserRouter basename="/admin">
      <div className="flex min-h-screen">
        <aside className="w-64 bg-primary text-white p-4">
          <h1 className="text-xl font-bold mb-2">Digital Vikoba</h1>
          <p className="text-sm text-white/70 mb-2">Msimamizi Mkuu</p>
          <p className="text-xs text-white/50 mb-8">Mipangilio ya mfumo pekee — shughuli za vikundi kwenye simu</p>
          <nav className="space-y-2">
            {nav.map(({ to, icon: Icon, label, permission }) => (
              <RoleGate key={to} permission={permission}>
                <NavLink
                  to={to}
                  end={to === '/'}
                  className={({ isActive }) =>
                    `flex items-center gap-3 px-3 py-2 rounded-lg ${isActive ? 'bg-white/20' : 'hover:bg-white/10'}`
                  }
                >
                  <Icon size={20} />
                  {label}
                </NavLink>
              </RoleGate>
            ))}
          </nav>
        </aside>
        <main className="flex-1 p-8 overflow-auto">
          <Routes>
            <Route path="/" element={<RoleGate permission="platform.national_analytics"><Analytics /></RoleGate>} />
            <Route path="/users" element={<RoleGate permission="platform.manage_users"><UserManagement /></RoleGate>} />
            <Route path="/financial" element={<RoleGate permission="platform.full_access"><FinancialMonitoring /></RoleGate>} />
            <Route path="/regional" element={<RoleGate permission="platform.national_analytics"><RegionalReports /></RoleGate>} />
            <Route path="/fraud" element={<RoleGate permission="platform.fraud_alerts"><FraudMonitoring /></RoleGate>} />
          </Routes>
        </main>
      </div>
    </BrowserRouter>
  )
}
