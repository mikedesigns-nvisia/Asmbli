import React from 'react';
import DownloadSection from '@/components/DownloadSection';
import { Navigation } from '@/components/Navigation';
import { Footer } from '@/components/Footer';
import { Metadata } from 'next';

export const metadata: Metadata = {
  title: 'Download Asmbli Beta - AI Agent Platform',
  description: 'Download Asmbli Beta for Windows and macOS. Early access to specialized AI agents with MCP integration, professional tools, and local processing.',
  keywords: 'AI agent, download, Windows, macOS, MCP, agent platform, AI tools',
  openGraph: {
    title: 'Download Asmbli Beta - AI Agents Made Easy',
    description: 'Beta access to AI agent platform with 20+ specialized agents and MCP integration.',
    type: 'website',
    url: 'https://asmbli.ai/download',
  },
  twitter: {
    card: 'summary_large_image',
    title: 'Download Asmbli Beta - AI Agents Made Easy',
    description: 'Beta AI agent platform for Windows and macOS - early access available.',
  }
};

export default function DownloadPage() {
  return (
    <div className="min-h-screen">
      {/* Navigation */}
      <Navigation showBackButton={true} backHref="/" backLabel="Home" />
      {/* Hero Section */}
      <div className="bg-gradient-to-br from-neutral-900 via-neutral-800 to-neutral-900 text-white py-20">
        <div className="container mx-auto px-4 text-center">
          <h1 className="text-5xl font-bold mb-6">
            Download Asmbli <span className="text-amber-400">Beta</span>
          </h1>
          <p className="text-xl text-neutral-300 max-w-3xl mx-auto mb-8">
            Early access to the AI agent platform. Build, deploy, and manage
            specialized AI agents with MCP integration and local processing.
            <br />
            <span className="text-amber-400 font-semibold">Beta builds available for Windows and macOS!</span>
          </p>
          <div className="flex justify-center gap-6 text-sm text-neutral-400">
            <span>✓ Beta Access</span>
            <span>✓ 20+ Agent Templates</span>
            <span>✓ MCP Integration</span>
            <span>✓ Local Processing</span>
          </div>
        </div>
      </div>

      {/* Download Section */}
      <DownloadSection />

      {/* FAQ Section */}
      <div className="py-16 bg-neutral-50">
        <div className="container mx-auto px-4 max-w-4xl">
          <h2 className="text-3xl font-bold text-center text-neutral-900 mb-12">
            Beta Program FAQ
          </h2>
          
          <div className="space-y-8">
            <div>
              <h3 className="text-lg font-semibold text-neutral-900 mb-2">
                Is Asmbli Beta free to use?
              </h3>
              <p className="text-neutral-600">
                Yes! Asmbli Beta is completely free during the beta period. You'll need to provide your own AI API keys
                (Claude, OpenAI, etc.) which have their own pricing models. The app itself costs nothing.
              </p>
            </div>

            <div>
              <h3 className="text-lg font-semibold text-neutral-900 mb-2">
                What AI providers are supported?
              </h3>
              <p className="text-neutral-600">
                Asmbli supports Anthropic Claude, OpenAI GPT models, and Google Gemini. 
                You can configure multiple providers and assign different agents to different models.
              </p>
            </div>

            <div>
              <h3 className="text-lg font-semibold text-neutral-900 mb-2">
                Is my data secure and private?
              </h3>
              <p className="text-neutral-600">
                Yes. Asmbli processes everything locally on your machine. Your conversations, 
                documents, and configurations never leave your computer unless you explicitly 
                send them to AI providers for processing.
              </p>
            </div>

            <div>
              <h3 className="text-lg font-semibold text-neutral-900 mb-2">
                What does "Beta" mean for Asmbli?
              </h3>
              <p className="text-neutral-600">
                Asmbli is currently in beta, meaning we're actively developing and improving features.
                You may encounter bugs or rough edges, but you get early access to cutting-edge AI agent technology.
                Your feedback helps shape the final product!
              </p>
            </div>

            <div>
              <h3 className="text-lg font-semibold text-neutral-900 mb-2">
                What's included with the professional agents?
              </h3>
              <p className="text-neutral-600">
                Each agent comes pre-configured with specialized prompts, tool access, and context. 
                For example, the DevOps agent includes Docker, Kubernetes, and cloud tools, 
                while the Research agent has web search, citation management, and memory.
              </p>
            </div>
          </div>
        </div>
      </div>

      {/* Footer */}
      <Footer />
    </div>
  );
}