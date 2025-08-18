'use client'

import Link from 'next/link'
import { usePathname } from 'next/navigation'

interface NavigationProps {
  showBackButton?: boolean
  backHref?: string
  backLabel?: string
}

export function Navigation({ showBackButton = false, backHref = '/', backLabel = 'Home' }: NavigationProps) {
  const pathname = usePathname()
  
  const isActive = (path: string) => pathname === path

  return (
    <header className="border-b bg-background/95 backdrop-blur supports-[backdrop-filter]:bg-background/60">
      <div className="container mx-auto px-4 py-4 flex justify-between items-center">
        <div className="flex items-center gap-4">
          {showBackButton && (
            <Link href={backHref} className="text-muted-foreground hover:text-foreground text-sm">
              ← {backLabel}
            </Link>
          )}
          <Link href="/" className="text-2xl font-bold italic">
            Asmbli
          </Link>
        </div>
        <nav className="flex gap-6 items-center">
          <Link 
            href="/templates" 
            className={`hover:underline text-sm ${isActive('/templates') ? 'font-semibold text-foreground' : 'text-muted-foreground'}`}
          >
            Templates
          </Link>
          <Link 
            href="/mcp-servers" 
            className={`hover:underline text-sm ${isActive('/mcp-servers') ? 'font-semibold text-foreground' : 'text-muted-foreground'}`}
          >
            Library
          </Link>
          <Link 
            href="/dashboard" 
            className={`hover:underline text-sm ${isActive('/dashboard') ? 'font-semibold text-foreground' : 'text-muted-foreground'}`}
          >
            Dashboard
          </Link>
          <Link 
            href="/chat" 
            className={`hover:underline text-sm ${isActive('/chat') ? 'font-semibold text-foreground' : 'text-muted-foreground'}`}
          >
            Chat
          </Link>
        </nav>
      </div>
    </header>
  )
}