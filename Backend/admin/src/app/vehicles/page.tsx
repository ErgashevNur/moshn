'use client'
import { useEffect, useState } from 'react'
import AdminLayout from '@/components/AdminLayout'
import api from '@/lib/api'

interface Vehicle {
  id: string
  vin: string
  current_plate: string
  make: string
  model: string
  year: number
  owner: { full_name: string; phone: string }
  created_at: string
}

export default function VehiclesPage() {
  const [vehicles, setVehicles] = useState<Vehicle[]>([])
  const [total, setTotal] = useState(0)
  const [loading, setLoading] = useState(true)
  const [search, setSearch] = useState('')
  const [page, setPage] = useState(1)

  const fetchVehicles = () => {
    setLoading(true)
    api.get('/admin/vehicles', { params: { search, page, limit: 20 } })
      .then((res) => { setVehicles(res.data.data.vehicles); setTotal(res.data.data.total) })
      .catch(console.error)
      .finally(() => setLoading(false))
  }

  useEffect(() => { fetchVehicles() }, [page])

  return (
    <AdminLayout title="Mashinalar">
      <div className="space-y-4">
        <div className="flex gap-3">
          <form onSubmit={(e) => { e.preventDefault(); setPage(1); fetchVehicles() }} className="flex gap-2 flex-1">
            <input
              type="text"
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              placeholder="VIN yoki davlat raqami bo'yicha qidirish..."
              className="flex-1 bg-dark-input border border-dark-border rounded-lg px-4 py-2.5 text-white placeholder-gray-500 focus:outline-none focus:border-primary text-sm"
            />
            <button type="submit" className="px-4 py-2.5 bg-primary text-white rounded-lg text-sm font-semibold hover:bg-primary/90 transition-colors">
              Qidirish
            </button>
          </form>
          <span className="text-gray-400 text-sm self-center">Jami: {total}</span>
        </div>

        <div className="bg-dark-card rounded-xl border border-dark-border overflow-hidden">
          <table className="w-full text-sm">
            <thead>
              <tr className="border-b border-dark-border text-gray-400">
                <th className="px-4 py-3 text-left">Davlat raqami</th>
                <th className="px-4 py-3 text-left">VIN</th>
                <th className="px-4 py-3 text-left">Marka/Model/Yil</th>
                <th className="px-4 py-3 text-left">Egasi</th>
                <th className="px-4 py-3 text-left">Qo'shilgan</th>
              </tr>
            </thead>
            <tbody>
              {loading ? (
                <tr><td colSpan={5} className="text-center py-8 text-gray-400">Yuklanmoqda...</td></tr>
              ) : vehicles.length === 0 ? (
                <tr><td colSpan={5} className="text-center py-8 text-gray-400">Ma'lumot yo'q</td></tr>
              ) : vehicles.map((v) => (
                <tr key={v.id} className="border-b border-dark-border/50 hover:bg-dark-input/30 transition-colors">
                  <td className="px-4 py-3 font-medium text-primary">{v.current_plate}</td>
                  <td className="px-4 py-3 font-mono text-xs text-gray-300">{v.vin}</td>
                  <td className="px-4 py-3">{v.make} {v.model} <span className="text-gray-400">({v.year})</span></td>
                  <td className="px-4 py-3">
                    <div>{v.owner?.full_name}</div>
                    <div className="text-gray-400 text-xs">{v.owner?.phone}</div>
                  </td>
                  <td className="px-4 py-3 text-gray-400">{new Date(v.created_at).toLocaleDateString('uz')}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>

        {total > 20 && (
          <div className="flex gap-2">
            <button onClick={() => setPage(p => Math.max(1, p - 1))} disabled={page === 1} className="px-3 py-1.5 bg-dark-card rounded-lg text-sm disabled:opacity-50">← Oldingi</button>
            <span className="px-3 py-1.5 text-sm text-gray-400">Sahifa {page}</span>
            <button onClick={() => setPage(p => p + 1)} disabled={page * 20 >= total} className="px-3 py-1.5 bg-dark-card rounded-lg text-sm disabled:opacity-50">Keyingi →</button>
          </div>
        )}
      </div>
    </AdminLayout>
  )
}
