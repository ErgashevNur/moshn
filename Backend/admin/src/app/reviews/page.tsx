'use client'
import { useEffect, useState } from 'react'
import AdminLayout from '@/components/AdminLayout'
import api from '@/lib/api'

interface Review {
  id: string
  mechanic: { user: { full_name: string } }
  owner: { full_name: string; phone: string }
  rating: number
  comment: string
  is_moderated: boolean
  created_at: string
}

export default function ReviewsPage() {
  const [reviews, setReviews] = useState<Review[]>([])
  const [total, setTotal] = useState(0)
  const [loading, setLoading] = useState(true)
  const [page, setPage] = useState(1)

  const fetchReviews = () => {
    setLoading(true)
    api.get('/admin/reviews', { params: { page, limit: 20 } })
      .then((res) => { setReviews(res.data.data.reviews); setTotal(res.data.data.total) })
      .catch(console.error)
      .finally(() => setLoading(false))
  }

  useEffect(() => { fetchReviews() }, [page])

  const handleModerate = async (id: string, approve: boolean) => {
    try {
      await api.put(`/admin/reviews/${id}/moderate`, { approve })
      fetchReviews()
    } catch (e) {
      console.error(e)
    }
  }

  return (
    <AdminLayout title="Sharhlar moderatsiyasi">
      <div className="space-y-4">
        <div className="flex justify-between items-center">
          <p className="text-gray-400 text-sm">Moderatsiya qilinmagan sharhlar: {total}</p>
        </div>

        <div className="bg-dark-card rounded-xl border border-dark-border overflow-hidden">
          <table className="w-full text-sm">
            <thead>
              <tr className="border-b border-dark-border text-gray-400">
                <th className="px-4 py-3 text-left">Usta</th>
                <th className="px-4 py-3 text-left">Egasi</th>
                <th className="px-4 py-3 text-left">Reyting</th>
                <th className="px-4 py-3 text-left">Izoh</th>
                <th className="px-4 py-3 text-left">Sana</th>
                <th className="px-4 py-3 text-left">Amallar</th>
              </tr>
            </thead>
            <tbody>
              {loading ? (
                <tr><td colSpan={6} className="text-center py-8 text-gray-400">Yuklanmoqda...</td></tr>
              ) : reviews.length === 0 ? (
                <tr><td colSpan={6} className="text-center py-8 text-gray-400">Hammasi moderatsiya qilingan</td></tr>
              ) : reviews.map((r) => (
                <tr key={r.id} className="border-b border-dark-border/50 hover:bg-dark-input/30 transition-colors">
                  <td className="px-4 py-3">{r.mechanic?.user?.full_name}</td>
                  <td className="px-4 py-3">
                    <div>{r.owner?.full_name}</div>
                    <div className="text-gray-400 text-xs">{r.owner?.phone}</div>
                  </td>
                  <td className="px-4 py-3 text-yellow-400">{'⭐'.repeat(r.rating)}</td>
                  <td className="px-4 py-3 max-w-xs text-gray-300">{r.comment || '—'}</td>
                  <td className="px-4 py-3 text-gray-400">{new Date(r.created_at).toLocaleDateString('uz')}</td>
                  <td className="px-4 py-3">
                    <div className="flex gap-2">
                      <button
                        onClick={() => handleModerate(r.id, true)}
                        className="text-xs bg-green-500/10 text-green-400 hover:bg-green-500/20 px-3 py-1.5 rounded-lg transition-colors"
                      >
                        ✓ Tasdiqlash
                      </button>
                      <button
                        onClick={() => handleModerate(r.id, false)}
                        className="text-xs bg-red-500/10 text-red-400 hover:bg-red-500/20 px-3 py-1.5 rounded-lg transition-colors"
                      >
                        ✕ O'chirish
                      </button>
                    </div>
                  </td>
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
