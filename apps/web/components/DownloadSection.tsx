'use client';

import React from 'react';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { CheckCircle, Download, Shield, Zap, Users, Settings } from 'lucide-react';

interface DownloadOption {
  platform: string;
  version: string;
  size: string;
  format: string;
  filename: string;
  available: boolean;
  recommended?: boolean;
  requirements: string[];
  downloadUrl?: string;
}

const downloads: DownloadOption[] = [
  {
    platform: 'Windows',
    version: '1.0.0',
    size: '~25MB',
    format: 'ZIP Archive',
    filename: 'Asmbli-1.0.0-windows-x64.zip',
    available: true,
    recommended: true,
    requirements: [
      'Windows 10 64-bit or Windows 11',
      '4GB RAM (8GB recommended)',
      '200MB available disk space'
    ],
    downloadUrl: '/downloads/Asmbli-1.0.0-windows-x64.zip'
  },
  {
    platform: 'macOS',
    version: '1.0.0',
    size: '~53MB',
    format: 'DMG Installer',
    filename: 'AgentEngine-1.0.0-macOS-Debug.dmg',
    available: true,
    recommended: true,
    requirements: [
      'macOS 11.0 (Big Sur) or later',
      'Intel x64 or Apple Silicon (M1/M2/M3)',
      '4GB RAM (8GB recommended)',
      '200MB available disk space'
    ],
    downloadUrl: '/downloads/AgentEngine-1.0.0-macOS-Debug.dmg'
  }
];

const features = [
  {
    icon: Users,
    title: '20+ Specialized Agents',
    description: 'Ready-to-deploy agents for development, research, security, and more'
  },
  {
    icon: Zap,
    title: 'MCP Integration',
    description: '40+ professional tools including Git, databases, cloud services'
  },
  {
    icon: Shield,
    title: 'Professional Security',
    description: 'Local data processing, encrypted storage, enterprise-grade privacy'
  },
  {
    icon: Settings,
    title: 'Full Customization',
    description: 'Configure agents, contexts, and integrations to match your workflow'
  }
];

export default function DownloadSection() {
  const handleDownload = (download: DownloadOption) => {
    if (!download.available) {
      // Could show coming soon modal or newsletter signup
      alert('macOS version coming soon! Follow us for updates.');
      return;
    }
    
    // Check for beta access (simplified - in production, this would be server-side)
    const hasAccess = (typeof window !== 'undefined' && 
                      (localStorage.getItem('beta_access') === 'true' || 
                       new URLSearchParams(window.location.search).get('access') === 'beta'));
    
    if (!hasAccess) {
      if (confirm('Beta access required. Would you like to sign up for the beta program?')) {
        window.location.href = '/#beta-signup';
        return;
      } else {
        return;
      }
    }
    
    // Track download analytics
    if (typeof window !== 'undefined' && (window as any).gtag) {
      (window as any).gtag('event', 'download', {
        event_category: 'software',
        event_label: download.platform,
        value: 1
      });
    }
    
    // Trigger download
    const link = document.createElement('a');
    link.href = download.downloadUrl || '#';
    link.download = download.filename;
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
  };

  return (
    <div className="py-24 bg-gradient-to-b from-neutral-50 to-white">
      <div className="container mx-auto px-4">
        {/* Header */}
        <div className="text-center mb-16">
          <h2 className="text-4xl font-bold text-neutral-900 mb-4">
            Download Asmbli
          </h2>
          <p className="text-xl text-neutral-600 max-w-2xl mx-auto mb-6">
            Professional AI agent deployment platform. Start building and deploying 
            specialized AI agents in minutes.
          </p>
          <div className="bg-amber-50 border border-amber-200 rounded-lg p-4 max-w-xl mx-auto">
            <p className="text-sm text-amber-800">
              <strong>Beta Access Required:</strong> Downloads are currently restricted to beta users. 
              <a href="/#beta-signup" className="underline hover:no-underline font-medium">
                Sign up for beta access
              </a> to download.
            </p>
          </div>
        </div>

        {/* Download Cards */}
        <div className="grid md:grid-cols-2 gap-8 mb-16 max-w-4xl mx-auto">
          {downloads.map((download) => (
            <Card key={download.platform} className={`relative ${
              download.recommended ? 'ring-2 ring-amber-400' : ''
            }`}>
              {download.recommended && (
                <Badge className="absolute -top-3 left-6 bg-amber-400 text-amber-900">
                  Recommended
                </Badge>
              )}
              
              <CardHeader>
                <CardTitle className="flex items-center gap-3">
                  <div className="w-12 h-12 rounded-lg bg-neutral-900 flex items-center justify-center">
                    <span className="text-white font-bold text-sm">
                      {download.platform === 'Windows' ? 'WIN' : 'MAC'}
                    </span>
                  </div>
                  {download.platform}
                </CardTitle>
                <CardDescription>
                  Version {download.version} • {download.size} • {download.format}
                </CardDescription>
              </CardHeader>

              <CardContent className="space-y-4">
                <div>
                  <h4 className="font-semibold text-sm text-neutral-700 mb-2">
                    System Requirements:
                  </h4>
                  <ul className="space-y-1">
                    {download.requirements.map((req, index) => (
                      <li key={index} className="flex items-center gap-2 text-sm text-neutral-600">
                        <CheckCircle className="w-4 h-4 text-green-500 flex-shrink-0" />
                        {req}
                      </li>
                    ))}
                  </ul>
                </div>

                <Button 
                  onClick={() => handleDownload(download)}
                  disabled={!download.available}
                  className={`w-full ${
                    download.available 
                      ? 'bg-neutral-900 hover:bg-neutral-800' 
                      : 'bg-neutral-300 cursor-not-allowed'
                  }`}
                >
                  <Download className="w-4 h-4 mr-2" />
                  {download.available ? `Download for ${download.platform}` : 'Coming Soon'}
                </Button>

                {!download.available && (
                  <p className="text-xs text-neutral-500 text-center">
                    macOS build requires macOS development environment. Stay tuned!
                  </p>
                )}
              </CardContent>
            </Card>
          ))}
        </div>

        {/* Features Grid */}
        <div className="mb-16">
          <h3 className="text-2xl font-bold text-center text-neutral-900 mb-8">
            What's Included
          </h3>
          <div className="grid md:grid-cols-2 lg:grid-cols-4 gap-6">
            {features.map((feature, index) => (
              <div key={index} className="text-center">
                <div className="w-12 h-12 rounded-lg bg-neutral-100 flex items-center justify-center mx-auto mb-4">
                  <feature.icon className="w-6 h-6 text-neutral-700" />
                </div>
                <h4 className="font-semibold text-neutral-900 mb-2">{feature.title}</h4>
                <p className="text-sm text-neutral-600">{feature.description}</p>
              </div>
            ))}
          </div>
        </div>

        {/* Installation Instructions */}
        <Card className="max-w-4xl mx-auto">
          <CardHeader>
            <CardTitle>Quick Start Guide</CardTitle>
            <CardDescription>Get up and running in under 5 minutes</CardDescription>
          </CardHeader>
          <CardContent>
            <div className="grid md:grid-cols-3 gap-6">
              <div className="text-center">
                <div className="w-8 h-8 rounded-full bg-neutral-900 text-white flex items-center justify-center mx-auto mb-3 font-bold">
                  1
                </div>
                <h4 className="font-semibold mb-2">Download & Extract</h4>
                <p className="text-sm text-neutral-600">
                  Download the ZIP file and extract to your preferred location
                </p>
              </div>
              <div className="text-center">
                <div className="w-8 h-8 rounded-full bg-neutral-900 text-white flex items-center justify-center mx-auto mb-3 font-bold">
                  2
                </div>
                <h4 className="font-semibold mb-2">Launch & Configure</h4>
                <p className="text-sm text-neutral-600">
                  Run the executable and follow the setup wizard to add your API keys
                </p>
              </div>
              <div className="text-center">
                <div className="w-8 h-8 rounded-full bg-neutral-900 text-white flex items-center justify-center mx-auto mb-3 font-bold">
                  3
                </div>
                <h4 className="font-semibold mb-2">Deploy Agents</h4>
                <p className="text-sm text-neutral-600">
                  Choose from 20+ agent templates and start your first conversation
                </p>
              </div>
            </div>
          </CardContent>
        </Card>

        {/* Security Notice */}
        <div className="mt-16 text-center">
          <div className="inline-flex items-center gap-2 px-4 py-2 bg-green-50 rounded-full">
            <Shield className="w-4 h-4 text-green-600" />
            <span className="text-sm text-green-700 font-medium">
              Verified Safe • No Malware • Open Source
            </span>
          </div>
          <p className="text-xs text-neutral-500 mt-2">
            All downloads are scanned for security and digitally signed for your protection.
          </p>
        </div>
      </div>
    </div>
  );
}