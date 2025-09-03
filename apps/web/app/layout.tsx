import type { Metadata } from 'next'
import './globals.css'

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
      <head>
        <link rel="preconnect" href="https://fonts.googleapis.com" />
        <link rel="preconnect" href="https://fonts.gstatic.com" crossOrigin="" />
        <link
          href="https://fonts.googleapis.com/css2?family=Fustat:wght@200..800&display=swap"
          rel="stylesheet"
        />
      </head>
      <body className="font-fustat">
        <div className="min-h-screen bg-background">
          {children}
        </div>
      </body>
    </html>
  )
}