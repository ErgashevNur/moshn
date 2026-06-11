'use client'
import { useEffect } from 'react'
import { useRouter } from 'next/navigation'
import Sidebar from './Sidebar'

interface AdminLayoutProps {
  title: string
  children: React.ReactNode
}

export default function AdminLayout({ title, children }: AdminLayoutProps) {
  const router = useRouter()

  useEffect(() => {
    const token = localStorage.getItem('access_token')
    if (!token) router.push('/login')
  }, [router])

  return (
    <div className="flex min-h-screen bg-bg">
      <Sidebar />
      <div className="flex-1 flex flex-col min-w-0">
        <header className="h-14 bg-elevated border-b border-border flex items-center px-6 shrink-0">
          <h2 className="text-text font-semibold text-base tracking-tight">{title}</h2>
        </header>
        <main className="flex-1 p-6 overflow-auto">
          <div className="max-w-content mx-auto w-full">
            {children}
          </div>
        </main>
      </div>
    </div>
  )
}
