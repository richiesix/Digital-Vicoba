export default function UserManagement() {
  const users = [
    { name: 'Asha Mohamed', phone: '+255712345678', role: 'Chairperson', status: 'Active' },
    { name: 'Fatuma Ali', phone: '+255723456789', role: 'Treasurer', status: 'Active' },
    { name: 'Regional Admin DSM', phone: '+255734567890', role: 'Regional Admin', status: 'Active' },
  ]

  return (
    <div>
      <h2 className="text-2xl font-bold mb-6">User Management</h2>
      <div className="bg-white rounded-xl shadow-sm overflow-hidden">
        <table className="w-full">
          <thead className="bg-gray-50">
            <tr>
              <th className="text-left p-4">Name</th>
              <th className="text-left p-4">Phone</th>
              <th className="text-left p-4">Role</th>
              <th className="text-left p-4">Status</th>
            </tr>
          </thead>
          <tbody>
            {users.map((u) => (
              <tr key={u.phone} className="border-t">
                <td className="p-4">{u.name}</td>
                <td className="p-4">{u.phone}</td>
                <td className="p-4">{u.role}</td>
                <td className="p-4"><span className="text-savings">{u.status}</span></td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  )
}
