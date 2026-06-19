import Navbar from '@/components/Navbar'
import TireJourney from '@/components/TireJourney'
import Benefits from '@/components/Benefits'
import DownloadCTA from '@/components/DownloadCTA'
import Footer from '@/components/Footer'

export default function Home() {
  return (
    <main>
      <Navbar />
      <TireJourney />
      <Benefits />
      <DownloadCTA />
      <Footer />
    </main>
  )
}
