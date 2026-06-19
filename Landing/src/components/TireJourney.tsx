import GarageBackdrop from './GarageBackdrop'
import TireStackHero from './TireStackHero'
import WheelSnakePath from './WheelSnakePath'

export default function TireJourney() {
  return (
    <section className="relative bg-bg">
      <GarageBackdrop />
      <div className="relative z-10">
        <TireStackHero />
        <WheelSnakePath />
      </div>
    </section>
  )
}
