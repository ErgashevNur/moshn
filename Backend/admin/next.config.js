/** @type {import('next').NextConfig} */
const nextConfig = {
  output: 'standalone',
  env: {
    NEXT_PUBLIC_API_URL: process.env.NEXT_PUBLIC_API_URL || 'https://snore-likewise-aground.ngrok-free.dev/v1',
  },
  images: {
    remotePatterns: [
      {
        protocol: 'https',
        hostname: 'api.moshn.uz',
      },
      {
        protocol: 'https',
        hostname: '*.ngrok-free.dev',
      },
    ],
  },
}

module.exports = nextConfig
