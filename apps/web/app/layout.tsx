import type { Metadata } from 'next'
import { Space_Grotesk, Noto_Sans_JP } from 'next/font/google'
import './globals.css'

const spaceGrotesk = Space_Grotesk({ 
  subsets: ['latin'],
  display: 'swap',
  variable: '--font-space-grotesk'
})

const notoSansJP = Noto_Sans_JP({ 
  subsets: ['latin'],
  display: 'swap',
  variable: '--font-noto-sans-jp'
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
      <body className={`${spaceGrotesk.variable} ${notoSansJP.variable} font-sans`}>
        <div className="min-h-screen bg-background">
          {children}
        </div>
      </body>
    </html>
  )
}