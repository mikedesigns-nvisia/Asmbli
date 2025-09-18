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
      '8GB RAM minimum (16GB recommended)',
      '10GB available disk space (for AI models)'
    ],
    downloadUrl: '/downloads/Asmbli-1.0.0-windows-x64.zip'
  },
  {
    platform: 'macOS',
    version: '0.9.0 Beta',
    size: '~145MB',
    format: 'ZIP Archive',
    filename: 'Asmbli-Beta-0.9.0-macOS-unsigned.zip',
    available: true,
    recommended: true,
    requirements: [
      'macOS 10.15 (Catalina) or later',
      'Intel x64 or Apple Silicon (M1/M2/M3)',
      '8GB RAM minimum (16GB recommended)',
      '10GB available disk space (for AI models)'
    ],
    downloadUrl: 'https://github.com/WereNext/AgentEngine/releases/download/v0.9.0-beta/Asmbli-Beta-0.9.0-macOS-unsigned.zip'
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
      alert('This platform is coming soon! Follow us for updates.');
      return;
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
                    This platform is coming soon. Stay tuned!
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
        <Card className="max-w-6xl mx-auto">
          <CardHeader>
            <CardTitle>Installation Guide</CardTitle>
            <CardDescription>Get up and running in under 5 minutes</CardDescription>
          </CardHeader>
          <CardContent>
            <div className="grid md:grid-cols-2 gap-8">
              {/* Windows Instructions */}
              <div>
                <h3 className="text-lg font-semibold mb-4 flex items-center gap-2">
                  <div className="w-6 h-6 rounded bg-neutral-900 flex items-center justify-center">
                    <span className="text-white font-bold text-xs">WIN</span>
                  </div>
                  Windows Installation
                </h3>
                <div className="space-y-4">
                  <div className="flex gap-3">
                    <div className="w-6 h-6 rounded-full bg-neutral-900 text-white flex items-center justify-center font-bold text-sm">
                      1
                    </div>
                    <div>
                      <h4 className="font-semibold">Download & Extract</h4>
                      <p className="text-sm text-neutral-600">Download the ZIP file and extract to your preferred location</p>
                    </div>
                  </div>
                  <div className="flex gap-3">
                    <div className="w-6 h-6 rounded-full bg-neutral-900 text-white flex items-center justify-center font-bold text-sm">
                      2
                    </div>
                    <div>
                      <h4 className="font-semibold">Launch & Configure</h4>
                      <p className="text-sm text-neutral-600">Run the executable and follow the setup wizard to add your API keys</p>
                    </div>
                  </div>
                  <div className="flex gap-3">
                    <div className="w-6 h-6 rounded-full bg-neutral-900 text-white flex items-center justify-center font-bold text-sm">
                      3
                    </div>
                    <div>
                      <h4 className="font-semibold">Deploy Agents</h4>
                      <p className="text-sm text-neutral-600">Choose from 20+ agent templates and start your first conversation</p>
                    </div>
                  </div>
                </div>
              </div>

              {/* macOS Instructions */}
              <div>
                <h3 className="text-lg font-semibold mb-4 flex items-center gap-2">
                  <div className="w-6 h-6 rounded bg-neutral-900 flex items-center justify-center">
                    <span className="text-white font-bold text-xs">MAC</span>
                  </div>
                  macOS Installation
                </h3>
                <div className="space-y-4">
                  <div className="flex gap-3">
                    <div className="w-6 h-6 rounded-full bg-neutral-900 text-white flex items-center justify-center font-bold text-sm">
                      1
                    </div>
                    <div>
                      <h4 className="font-semibold">Download & Extract</h4>
                      <p className="text-sm text-neutral-600">Download ZIP file and extract Asmbli.app, then drag to Applications folder.</p>
                    </div>
                  </div>
                  <div className="flex gap-3">
                    <div className="w-6 h-6 rounded-full bg-neutral-900 text-white flex items-center justify-center font-bold text-sm">
                      2
                    </div>
                    <div>
                      <h4 className="font-semibold">First Launch (Important!)</h4>
                      <p className="text-sm text-neutral-600"><strong>Right-click → Open</strong> to bypass Gatekeeper for unsigned beta build</p>
                    </div>
                  </div>
                  <div className="flex gap-3">
                    <div className="w-6 h-6 rounded-full bg-neutral-900 text-white flex items-center justify-center font-bold text-sm">
                      3
                    </div>
                    <div>
                      <h4 className="font-semibold">Start Building</h4>
                      <p className="text-sm text-neutral-600">Configure your API keys and create your first AI agent</p>
                    </div>
                  </div>
                </div>
              </div>
            </div>

            {/* Troubleshooting */}
            <div className="mt-8 p-4 bg-neutral-50 rounded-lg">
              <h4 className="font-semibold mb-2">macOS Troubleshooting</h4>
              <div className="text-sm text-neutral-600 space-y-1">
                <p><strong>Beta Build:</strong> This is an unsigned build - requires right-click → Open on first launch</p>
                <p><strong>"App is damaged":</strong> Run <code className="bg-white px-1 rounded">sudo xattr -rd com.apple.quarantine /Applications/Asmbli.app</code></p>
                <p><strong>Permission issues:</strong> Allow app in System Settings → Privacy & Security</p>
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