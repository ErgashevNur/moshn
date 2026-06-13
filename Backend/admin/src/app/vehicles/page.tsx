'use client'
import { useEffect, useState } from 'react'
import AdminLayout from '@/components/AdminLayout'
import api from '@/lib/api'

interface Vehicle {
  id: string
  plate: string
  make: string
  model: string
  year: number
  color: string
  owner: { fullName: string; phone: string; email: string }
  createdAt: string
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
      .then((r) => { setVehicles(r.data.data.vehicles ?? []); setTotal(r.data.data.total ?? 0) })
      .catch(console.error)
      .finally(() => setLoading(false))
  }

  useEffect(() => { fetchVehicles() }, [page])

  return (
    <AdminLayout title="Avtomobillar">
      <div className="space-y-4">
        <form onSubmit={(e) => { e.preventDefault(); setPage(1); fetchVehicles() }} className="flex gap-2">
          <input type="text" value={search} onChange={(e) => setSearch(e.target.value)}
            placeholder="Plaka raqami bo'yicha qidirish..." className="inp flex-1" />
          <button type="submit" className="btn-primary">Qidirish</button>
          <span className="self-center text-text3 text-sm">{total} ta</span>
        </form>

        <div className="card overflow-x-auto">
          <table className="tbl">
            <thead>
              <tr>
                <th>Plaka</th>
                <th>Avtomobil</th>
                <th>Rang / Yil</th>
                <th>Egasi</th>
                <th>Telefon</th>
                <th>Qo'shilgan</th>
              </tr>
            </thead>
            <tbody>
              {loading ? (
                Array.from({ length: 6 }).map((_, i) => (
                  <tr key={i} className="animate-pulse">
                    {Array.from({ length: 6 }).map((__, j) => (
                      <td key={j}><div className="skel h-4 w-24" /></td>
                    ))}
                  </tr>
                ))
              ) : vehicles.length === 0 ? (
                <tr><td colSpan={6} style={{ textAlign: 'center', padding: '40px 16px', color: 'var(--text3)' }}>Avtomobil topilmadi</td></tr>
              ) : vehicles.map((v) => (
                <tr key={v.id}>
                  <td>
                    <span style={{ fontFamily: 'monospace', fontWeight: 700, fontSize: 13, letterSpacing: '0.1em', background: 'var(--surface2)', padding: '3px 8px', borderRadius: 6 }}>
                      {v.plate}
                    </span>
                  </td>
                  <td>
                    <p className="text-text font-medium">{v.make} {v.model}</p>
                  </td>
                  <td className="text-text2 text-xs">
                    <p>{v.color || '—'}</p>
                    <p className="text-text3">{v.year > 0 ? v.year : '—'}</p>
                  </td>
                  <td className="text-text2">{v.owner?.fullName || '—'}</td>
                  <td className="text-text3 text-xs font-mono">{v.owner?.phone}</td>
                  <td className="text-text3 text-xs">
                    {new Date(v.createdAt).toLocaleDateString('uz-UZ')}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>

        {total > 20 && (
          <div className="flex items-center gap-2">
            <button onClick={() => setPage(p => Math.max(1, p - 1))} disabled={page === 1} className="btn-ghost disabled:opacity-40">← Oldingi</button>
            <span className="text-text3 text-sm">{page}-sahifa</span>
            <button onClick={() => setPage(p => p + 1)} disabled={page * 20 >= total} className="btn-ghost disabled:opacity-40">Keyingi →</button>
          </div>
        )}
      </div>
    </AdminLayout>
  )
}
