export default function FraudMonitoring() {
  const alerts = [
    { type: 'Duplicate Transaction', group: 'Vikoba Mama Shujaa', severity: 'high' },
    { type: 'Rapid Withdrawals', group: 'Umoja Wanawake', severity: 'medium' },
    { type: 'Outside Meeting Hours', group: 'Kilimo Kwanza', severity: 'low' },
  ]

  return (
    <div>
      <h2 className="text-2xl font-bold mb-6">Fraud Monitoring</h2>
      <div className="space-y-4">
        {alerts.map((a, i) => (
          <div key={i} className="bg-white rounded-xl p-6 shadow-sm border-l-4 border-overdue">
            <div className="flex justify-between">
              <div>
                <h3 className="font-semibold">{a.type}</h3>
                <p className="text-gray-500">{a.group}</p>
              </div>
              <span className={`px-3 py-1 rounded-full text-sm ${
                a.severity === 'high' ? 'bg-red-100 text-overdue' :
                a.severity === 'medium' ? 'bg-yellow-100 text-pending' : 'bg-gray-100'
              }`}>
                {a.severity}
              </span>
            </div>
          </div>
        ))}
      </div>
    </div>
  )
}
