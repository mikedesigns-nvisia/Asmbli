import React, { useState } from 'react';
import { Building2, User, Settings, Download, Play, ChevronDown, Search, Menu, X } from 'lucide-react';
import { Button } from './ui/button';
import { Avatar, AvatarFallback, AvatarImage } from './ui/avatar';
import { Badge } from './ui/badge';

interface LayoutProps {
  children: React.ReactNode;
  sidebar: React.ReactNode;
  rightPanel: React.ReactNode;
  selectionTracker?: React.ReactNode;
}

export function Layout({ children, sidebar, rightPanel, selectionTracker }: LayoutProps) {
  const [sidebarOpen, setSidebarOpen] = useState(false);
  const [rightPanelOpen, setRightPanelOpen] = useState(false);

  return (
    <div className="min-h-screen bg-background">
      {/* Header */}
      <header className="h-16 border-b border-border backdrop-blur-xl sticky top-0 z-50" style={{
        background: 'rgba(24, 24, 27, 0.8)',
        boxShadow: '0 0 0 1px rgba(255, 255, 255, 0.05)'
      }}>
        <div className="max-w-[1440px] mx-auto h-full px-4 lg:px-6 flex items-center justify-between">
          {/* Mobile sidebar toggle */}
          <Button 
            variant="ghost" 
            size="sm" 
            className="lg:hidden" 
            onClick={() => setSidebarOpen(!sidebarOpen)}
          >
            <Menu className="w-5 h-5" />
          </Button>

          {/* Left: Logo and navigation */}
          <div className="flex items-center space-x-2 lg:space-x-8">
            <div className="flex items-center space-x-3">
              <div>
                <h1 className="text-lg font-normal text-[rgba(203,203,211,1)] font-[Noto_Sans_JP] text-[20px] italic no-underline">Agent/Engine</h1>
                <div className="flex items-center space-x-2">
                </div>
              </div>
            </div>

            {/* Team workspace selector */}

            {/* Environment selector */}
            <div className="hidden lg:flex items-center space-x-1">
              <div className="w-2 h-2 bg-success rounded-full"></div>
              <span className="text-xs text-muted-foreground">Proto</span>
            </div>
          </div>

          {/* Center: Search */}
          <div className="hidden lg:flex flex-1 max-w-md mx-8">
            <div className="relative w-full">
              <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 w-4 h-4 text-muted-foreground" />
              <input
                type="text"
                placeholder="Search prompts, templates... (⌘K)"
                className="w-full pl-10 pr-4 py-2 bg-muted/50 border border-border rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-primary/50 focus:border-primary/50"
              />
            </div>
          </div>

          {/* Right: Actions and profile */}
          <div className="flex items-center space-x-2 lg:space-x-4">
            <Button variant="ghost" size="sm" className="hidden lg:flex text-muted-foreground">
              <Settings className="w-4 h-4 mr-2" />
              Settings
            </Button>
            
            <Button variant="secondary" size="sm" className="hidden md:flex">
              <Download className="w-4 h-4 lg:mr-2" />
              <span className="hidden lg:inline">Export</span>
            </Button>

            {/* Mobile right panel toggle */}
            <Button 
              variant="ghost" 
              size="sm" 
              className="xl:hidden" 
              onClick={() => setRightPanelOpen(!rightPanelOpen)}
            >
              <Settings className="w-5 h-5" />
            </Button>

            <div className="hidden lg:block w-px h-6 bg-border"></div>

            <div className="flex items-center space-x-3">
              <Avatar className="w-8 h-8">
                <AvatarImage src="/api/placeholder/32/32" />
                <AvatarFallback className="bg-primary text-primary-foreground text-xs">
                  MD
                </AvatarFallback>
              </Avatar>
              <div className="hidden lg:block text-right">
                <div className="text-sm font-medium font-[Noto_Serif_JP]">Mike Designs</div>
                <div className="text-xs text-muted-foreground">heyhey@mike.com</div>
              </div>
            </div>
          </div>
        </div>
      </header>

      {/* Main layout */}
      <div className="max-w-[1440px] mx-auto flex relative">
        {/* Mobile sidebar overlay */}
        {sidebarOpen && (
          <div className="fixed inset-0 z-50 lg:hidden">
            <div className="absolute inset-0 bg-black/50" onClick={() => setSidebarOpen(false)} />
            <aside className="absolute left-0 top-0 w-60 h-full border-r border-border backdrop-blur-xl" style={{
              background: 'rgba(24, 24, 27, 0.95)',
              boxShadow: '0 0 0 1px rgba(255, 255, 255, 0.05)'
            }}>
              <div className="flex items-center justify-between p-4 border-b border-border">
                <span className="font-medium">Navigation</span>
                <Button variant="ghost" size="sm" onClick={() => setSidebarOpen(false)}>
                  <X className="w-4 h-4" />
                </Button>
              </div>
              {sidebar}
            </aside>
          </div>
        )}

        {/* Desktop sidebar */}
        <aside className="w-60 min-w-[240px] min-h-[calc(100vh-4rem)] border-r border-border backdrop-blur-xl hidden lg:block" style={{
          background: 'rgba(24, 24, 27, 0.8)',
          boxShadow: '0 0 0 1px rgba(255, 255, 255, 0.05)'
        }}>
          {sidebar}
        </aside>

        {/* Main content */}
        <main className="flex-1 min-h-[calc(100vh-4rem)] max-w-none lg:max-w-[calc(1440px-560px)] xl:max-w-[calc(1440px-560px)] overflow-x-auto">
          {/* Selection Tracker */}
          {selectionTracker && (
            <div className="sticky top-0 z-40">
              {selectionTracker}
            </div>
          )}
          
          <div className="max-w-4xl mx-auto px-4 lg:px-8 py-6 lg:py-8">
            {children}
          </div>
        </main>

        {/* Mobile right panel overlay */}
        {rightPanelOpen && (
          <div className="fixed inset-0 z-50 xl:hidden">
            <div className="absolute inset-0 bg-black/50" onClick={() => setRightPanelOpen(false)} />
            <aside className="absolute right-0 top-0 w-80 h-full border-l border-border backdrop-blur-xl" style={{
              background: 'rgba(24, 24, 27, 0.95)',
              boxShadow: '0 0 0 1px rgba(255, 255, 255, 0.05)'
            }}>
              <div className="flex items-center justify-between p-4 border-b border-border">
                <span className="font-medium">Configuration</span>
                <Button variant="ghost" size="sm" onClick={() => setRightPanelOpen(false)}>
                  <X className="w-4 h-4" />
                </Button>
              </div>
              {rightPanel}
            </aside>
          </div>
        )}

        {/* Desktop right panel */}
        <aside className="w-80 min-w-[320px] min-h-[calc(100vh-4rem)] border-l border-border backdrop-blur-xl hidden xl:block" style={{
          background: 'rgba(24, 24, 27, 0.8)',
          boxShadow: '0 0 0 1px rgba(255, 255, 255, 0.05)'
        }}>
          {rightPanel}
        </aside>
      </div>
    </div>
  );
}