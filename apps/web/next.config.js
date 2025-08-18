/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,
  eslint: {
    // Disable ESLint during builds
    ignoreDuringBuilds: true,
  },
  images: {
    domains: ['images.unsplash.com', 'localhost'],
  },
  // Handle Netlify deployment
  output: process.env.NETLIFY ? 'export' : undefined,
  // Ensure proper base path for Netlify
  basePath: '',
  trailingSlash: true,
}

module.exports = nextConfig