import { BarChart, Bar, XAxis, YAxis, Tooltip, ResponsiveContainer, LineChart, Line } from 'recharts'

const savingsData = [
  { month: 'Jan', amount: 1200000 },
  { month: 'Feb', amount: 1450000 },
  { month: 'Mar', amount: 1680000 },
  { month: 'Apr', amount: 1920000 },
]

const loanData = [
  { month: 'Jan', disbursed: 400000, repaid: 350000 },
  { month: 'Feb', disbursed: 520000, repaid: 480000 },
  { month: 'Mar', disbursed: 380000, repaid: 420000 },
]

export default function Analytics() {
  return (
    <div>
      <h2 className="text-2xl font-bold mb-6">Platform Analytics</h2>
      <div className="grid grid-cols-1 md:grid-cols-4 gap-4 mb-8">
        {[
          { label: 'Active Groups', value: '1,247', color: 'text-savings' },
          { label: 'Total Savings', value: 'TZS 2.4B', color: 'text-savings' },
          { label: 'Active Loans', value: '3,891', color: 'text-pending' },
          { label: 'Overdue', value: '142', color: 'text-overdue' },
        ].map((s) => (
          <div key={s.label} className="bg-white rounded-xl p-6 shadow-sm">
            <p className="text-gray-500 text-sm">{s.label}</p>
            <p className={`text-2xl font-bold ${s.color}`}>{s.value}</p>
          </div>
        ))}
      </div>
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <div className="bg-white rounded-xl p-6 shadow-sm">
          <h3 className="font-semibold mb-4">Savings Growth</h3>
          <ResponsiveContainer width="100%" height={250}>
            <BarChart data={savingsData}>
              <XAxis dataKey="month" />
              <YAxis />
              <Tooltip />
              <Bar dataKey="amount" fill="#2E7D32" radius={[4, 4, 0, 0]} />
            </BarChart>
          </ResponsiveContainer>
        </div>
        <div className="bg-white rounded-xl p-6 shadow-sm">
          <h3 className="font-semibold mb-4">Loan Performance</h3>
          <ResponsiveContainer width="100%" height={250}>
            <LineChart data={loanData}>
              <XAxis dataKey="month" />
              <YAxis />
              <Tooltip />
              <Line type="monotone" dataKey="disbursed" stroke="#F9A825" />
              <Line type="monotone" dataKey="repaid" stroke="#2E7D32" />
            </LineChart>
          </ResponsiveContainer>
        </div>
      </div>
    </div>
  )
}
