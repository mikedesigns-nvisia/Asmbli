import type { Metadata } from 'next'
import { Fustat } from 'next/font/google'
import './globals.css'

const fustat = Fustat({ 
  subsets: ['latin'],
  display: 'swap',
  variable: '--font-fustat'
})

export const metadata: Metadata = {
  title: 'Asmbli - AI Agent Configuration Platform',
  description: 'Build, configure, and chat with AI agents instantly',
}

export default function RootLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <html lang="en" suppressHydrationWarning>
      <body className={`${fustat.variable} font-sans`}>
        <div className="min-h-screen bg-background">
          {children}
        </div>
      </body>
    </html>
  )
}