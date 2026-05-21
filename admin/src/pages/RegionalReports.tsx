const regions = ['Dar es Salaam', 'Mwanza', 'Arusha', 'Dodoma', 'Mbeya', 'Morogoro']

export default function RegionalReports() {
  return (
    <div>
      <h2 className="text-2xl font-bold mb-6">Regional Reports</h2>
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
        {regions.map((r) => (
          <div key={r} className="bg-white rounded-xl p-6 shadow-sm">
            <h3 className="font-semibold text-lg">{r}</h3>
            <p className="text-3xl font-bold text-savings mt-2">{Math.floor(Math.random() * 200 + 50)}</p>
            <p className="text-gray-500 text-sm">groups</p>
          </div>
        ))}
      </div>
    </div>
  )
}
