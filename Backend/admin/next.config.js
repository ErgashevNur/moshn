/** @type {import('next').NextConfig} */
const nextConfig = {
  output: 'standalone',
  env: {
    NEXT_PUBLIC_API_URL: process.env.NEXT_PUBLIC_API_URL || 'https://api.pitgo.uz/v1',
  },
  images: {
    remotePatterns: [
      {
        protocol: 'https',
        hostname: 'api.pitgo.uz',
      },
      {
        protocol: 'https',
        hostname: '*.ngrok-free.dev',
      },
    ],
  },
}

module.exports = nextConfig
