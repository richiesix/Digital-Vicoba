export default function FinancialMonitoring() {
  return (
    <div>
      <h2 className="text-2xl font-bold mb-6">Financial Monitoring</h2>
      <div className="grid gap-4">
        {['M-Pesa Transactions', 'Airtel Money', 'Share-out Disbursements', 'Loan Disbursements'].map((t) => (
          <div key={t} className="bg-white rounded-xl p-6 shadow-sm flex justify-between items-center">
            <div>
              <h3 className="font-semibold">{t}</h3>
              <p className="text-gray-500 text-sm">Last 24 hours</p>
            </div>
            <div className="text-right">
              <p className="text-xl font-bold text-savings">TZS {(Math.random() * 5 + 1).toFixed(1)}M</p>
              <p className="text-sm text-pending">12 pending</p>
            </div>
          </div>
        ))}
      </div>
    </div>
  )
}
