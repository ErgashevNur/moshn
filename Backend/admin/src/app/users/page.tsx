'use client'
import { useEffect, useState } from 'react'
import AdminLayout from '@/components/AdminLayout'
import api from '@/lib/api'

interface User {
  id: string
  full_name: string
  phone: string
  email: string
  role: string
  created_at: string
  is_verified: boolean
}

const ROLE_LABELS: Record<string, string> = {
  owner:   'Mijoz',
  service: 'Servis',
  admin:   'Admin',
}

export default function UsersPage() {
  const [users, setUsers] = useState<User[]>([])
  const [total, setTotal] = useState(0)
  const [loading, setLoading] = useState(true)
  const [search, setSearch] = useState('')
  const [page, setPage] = useState(1)

  const fetchUsers = () => {
    setLoading(true)
    api.get('/admin/users', { params: { search, page, limit: 20 } })
      .then((r) => { setUsers(r.data.data.users ?? []); setTotal(r.data.data.total ?? 0) })
      .catch(console.error)
      .finally(() => setLoading(false))
  }

  useEffect(() => { fetchUsers() }, [page])

  return (
    <AdminLayout title="Foydalanuvchilar">
      <div className="space-y-4">
        {/* Toolbar */}
        <form onSubmit={(e) => { e.preventDefault(); setPage(1); fetchUsers() }}
          className="flex gap-2">
          <input
            type="text"
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            placeholder="Ism yoki telefon..."
            className="inp flex-1"
          />
          <button type="submit" className="btn-primary">Qidirish</button>
          <span className="self-center text-text3 text-sm">{total} ta</span>
        </form>

        {/* Table */}
        <div className="card overflow-hidden">
          <table className="w-full text-sm">
            <thead>
              <tr className="border-b border-border text-text3 text-xs font-mono uppercase tracking-wide">
                <th className="px-4 py-3 text-left">Ism</th>
                <th className="px-4 py-3 text-left">Telefon</th>
                <th className="px-4 py-3 text-left">Rol</th>
                <th className="px-4 py-3 text-left">Sana</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-border">
              {loading ? (
                Array.from({ length: 6 }).map((_, i) => (
                  <tr key={i} className="animate-pulse">
                    <td className="px-4 py-3"><div className="h-4 bg-surface2 rounded w-32" /></td>
                    <td className="px-4 py-3"><div className="h-4 bg-surface2 rounded w-24" /></td>
                    <td className="px-4 py-3"><div className="h-4 bg-surface2 rounded w-14" /></td>
                    <td className="px-4 py-3"><div className="h-4 bg-surface2 rounded w-20" /></td>
                  </tr>
                ))
              ) : users.length === 0 ? (
                <tr><td colSpan={4} className="px-4 py-10 text-center text-text3">Ma'lumot topilmadi</td></tr>
              ) : users.map((u) => (
                <tr key={u.id} className="hover:bg-surface2/50 transition-colors">
                  <td className="px-4 py-3 font-medium text-text">{u.full_name || '—'}</td>
                  <td className="px-4 py-3 text-text2 font-mono text-xs">{u.phone}</td>
                  <td className="px-4 py-3">
                    <span className={`badge badge-${u.role}`}>{ROLE_LABELS[u.role] ?? u.role}</span>
                  </td>
                  <td className="px-4 py-3 text-text3 text-xs">
                    {new Date(u.created_at).toLocaleDateString('uz-UZ')}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>

        {/* Pagination */}
        {total > 20 && (
          <div className="flex items-center gap-2">
            <button onClick={() => setPage(p => Math.max(1, p - 1))} disabled={page === 1}
              className="btn-ghost disabled:opacity-40">← Oldingi</button>
            <span className="text-text3 text-sm">{page}-sahifa</span>
            <button onClick={() => setPage(p => p + 1)} disabled={page * 20 >= total}
              className="btn-ghost disabled:opacity-40">Keyingi →</button>
          </div>
        )}
      </div>
    </AdminLayout>
  )
}
