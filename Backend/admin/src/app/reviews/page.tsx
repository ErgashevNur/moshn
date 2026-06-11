'use client'
import { useEffect, useState } from 'react'
import AdminLayout from '@/components/AdminLayout'
import api from '@/lib/api'

interface Review {
  id: string
  author: { full_name: string; phone?: string }
  target_id: string
  review_type: string  // owner_to_shop | shop_to_owner
  rating: number
  comment: string
  is_moderated: boolean
  created_at: string
}

const STARS = (n: number) => '★'.repeat(n) + '☆'.repeat(5 - n)

const TYPE_LABEL: Record<string, string> = {
  owner_to_shop:  'Mijoz → Servis',
  shop_to_owner:  'Servis → Mijoz',
}

export default function ReviewsPage() {
  const [reviews, setReviews] = useState<Review[]>([])
  const [total, setTotal] = useState(0)
  const [loading, setLoading] = useState(true)
  const [page, setPage] = useState(1)

  const fetch = () => {
    setLoading(true)
    api.get('/admin/reviews', { params: { page, limit: 20 } })
      .then((r) => { setReviews(r.data.data.reviews ?? []); setTotal(r.data.data.total ?? 0) })
      .catch(console.error)
      .finally(() => setLoading(false))
  }

  useEffect(() => { fetch() }, [page])

  const moderate = async (id: string, approve: boolean) => {
    try { await api.put(`/admin/reviews/${id}/moderate`, { approve }); fetch() }
    catch (e) { console.error(e) }
  }

  return (
    <AdminLayout title="Sharhlar moderatsiyasi">
      <div className="space-y-4">
        <p className="text-text3 text-sm">Jami: <span className="text-text font-semibold">{total}</span> ta sharh</p>

        <div className="card overflow-hidden">
          <table className="w-full text-sm">
            <thead>
              <tr className="border-b border-border text-text3 text-xs font-mono uppercase tracking-wide">
                <th className="px-4 py-3 text-left">Muallif</th>
                <th className="px-4 py-3 text-left">Tur</th>
                <th className="px-4 py-3 text-left">Reyting</th>
                <th className="px-4 py-3 text-left">Izoh</th>
                <th className="px-4 py-3 text-left">Sana</th>
                <th className="px-4 py-3 text-left">Amal</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-border">
              {loading ? (
                Array.from({ length: 5 }).map((_, i) => (
                  <tr key={i} className="animate-pulse">
                    {Array.from({ length: 6 }).map((__, j) => (
                      <td key={j} className="px-4 py-3"><div className="h-4 bg-surface2 rounded w-20" /></td>
                    ))}
                  </tr>
                ))
              ) : reviews.length === 0 ? (
                <tr><td colSpan={6} className="px-4 py-10 text-center text-text3">Sharhlar yo'q</td></tr>
              ) : reviews.map((r) => (
                <tr key={r.id} className={`hover:bg-surface2/50 transition-colors ${r.is_moderated ? 'opacity-50' : ''}`}>
                  <td className="px-4 py-3">
                    <p className="text-text font-medium">{r.author?.full_name || '—'}</p>
                    {r.author?.phone && <p className="text-text3 text-xs font-mono">{r.author.phone}</p>}
                  </td>
                  <td className="px-4 py-3 text-text3 text-xs">{TYPE_LABEL[r.review_type] ?? r.review_type}</td>
                  <td className="px-4 py-3 text-gold text-sm">{STARS(r.rating)}</td>
                  <td className="px-4 py-3 text-text2 max-w-xs truncate">{r.comment || '—'}</td>
                  <td className="px-4 py-3 text-text3 text-xs">
                    {new Date(r.created_at).toLocaleDateString('uz-UZ')}
                  </td>
                  <td className="px-4 py-3">
                    {!r.is_moderated && (
                      <div className="flex gap-1.5">
                        <button onClick={() => moderate(r.id, true)} className="btn-success text-xs py-1 px-2.5">✓</button>
                        <button onClick={() => moderate(r.id, false)} className="btn-danger text-xs py-1 px-2.5">✕</button>
                      </div>
                    )}
                    {r.is_moderated && <span className="text-text3 text-xs">Moderatsiya qilingan</span>}
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
