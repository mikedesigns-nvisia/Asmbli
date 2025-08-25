import React from 'react';
import DownloadSection from '@/components/DownloadSection';
import { Metadata } from 'next';

export const metadata: Metadata = {
  title: 'Download Asmbli - Professional AI Agent Platform',
  description: 'Download Asmbli for Windows and macOS. Deploy specialized AI agents with MCP integration, professional tools, and enterprise-grade security.',
  keywords: 'AI agent, download, Windows, macOS, MCP, agent platform, AI tools',
  openGraph: {
    title: 'Download Asmbli - AI Agents Made Easy',
    description: 'Professional AI agent deployment platform with 20+ specialized agents and 40+ professional tools.',
    type: 'website',
    url: 'https://asmbli.ai/download',
  },
  twitter: {
    card: 'summary_large_image',
    title: 'Download Asmbli - AI Agents Made Easy', 
    description: 'Professional AI agent deployment platform for Windows and macOS.',
  }
};

export default function DownloadPage() {
  return (
    <div className="min-h-screen">
      {/* Hero Section */}
      <div className="bg-gradient-to-br from-neutral-900 via-neutral-800 to-neutral-900 text-white py-20">
        <div className="container mx-auto px-4 text-center">
          <h1 className="text-5xl font-bold mb-6">
            Download Asmbli
          </h1>
          <p className="text-xl text-neutral-300 max-w-3xl mx-auto mb-8">
            Professional AI agent deployment platform. Build, deploy, and manage 
            specialized AI agents with enterprise-grade tools and security.
          </p>
          <div className="flex justify-center gap-6 text-sm text-neutral-400">
            <span>✓ 20+ Agent Templates</span>
            <span>✓ MCP Integration</span>
            <span>✓ Professional Tools</span>
            <span>✓ Enterprise Security</span>
          </div>
        </div>
      </div>

      {/* Download Section */}
      <DownloadSection />

      {/* FAQ Section */}
      <div className="py-16 bg-neutral-50">
        <div className="container mx-auto px-4 max-w-4xl">
          <h2 className="text-3xl font-bold text-center text-neutral-900 mb-12">
            Frequently Asked Questions
          </h2>
          
          <div className="space-y-8">
            <div>
              <h3 className="text-lg font-semibold text-neutral-900 mb-2">
                Is Asmbli free to use?
              </h3>
              <p className="text-neutral-600">
                Asmbli itself is free and open source. You'll need to provide your own AI API keys 
                (Claude, OpenAI, etc.) which have their own pricing models.
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
                When will the macOS version be available?
              </h3>
              <p className="text-neutral-600">
                The macOS version requires a macOS development environment for building. 
                We're working on setting up proper macOS builds and expect to release it soon. 
                Follow our GitHub for updates.
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
    </div>
  );
}