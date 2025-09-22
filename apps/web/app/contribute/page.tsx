'use client'

import Link from 'next/link'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import { ArrowRight, Bot, Code, Zap, Users, Server, FileText, GitBranch, Bug, Lightbulb, Heart, ExternalLink, CheckCircle, AlertTriangle } from 'lucide-react'
import { Navigation } from '@/components/Navigation'
import { Footer } from '@/components/Footer'

export default function ContributePage() {
  return (
    <div className="flex flex-col min-h-screen">
      {/* Navigation */}
      <Navigation />

      {/* Hero Section */}
      <section className="py-12 sm:py-16 lg:py-20 px-4 bg-gradient-to-br from-green-50/20 to-background">
        <div className="container mx-auto max-w-4xl text-center">
          <h1 className="text-3xl sm:text-4xl lg:text-5xl font-bold italic mb-4 sm:mb-6 font-display leading-tight">
            Become a Contributor
          </h1>
          <p className="text-lg sm:text-xl text-muted-foreground mb-6 sm:mb-8 max-w-3xl mx-auto px-4">
            Help us build the most honest and useful AI chat application. We welcome contributions of all kinds -
            from bug reports to new features, documentation to design improvements.
          </p>

          <div className="flex flex-col sm:flex-row gap-3 sm:gap-4 justify-center px-4">
            <Link href="https://github.com/asmbli/asmbli" target="_blank" rel="noopener noreferrer">
              <Button size="lg" className="w-full sm:w-auto bg-green-500 hover:bg-green-600 text-white">
                <GitBranch className="mr-2 h-5 w-5" />
                View on GitHub
              </Button>
            </Link>
            <Link href="https://github.com/asmbli/asmbli/issues/new" target="_blank" rel="noopener noreferrer">
              <Button size="lg" variant="outline" className="w-full sm:w-auto">
                Report an Issue
              </Button>
            </Link>
          </div>
        </div>
      </section>

      {/* Ways to Contribute */}
      <section className="py-12 sm:py-16 lg:py-20 px-4">
        <div className="container mx-auto">
          <div className="text-center mb-8 sm:mb-12">
            <h2 className="text-2xl sm:text-3xl font-bold mb-4 font-display">
              Ways to Contribute
            </h2>
            <p className="text-base sm:text-lg text-muted-foreground max-w-2xl mx-auto px-4">
              Every contribution matters, whether you're fixing a typo or adding a major feature
            </p>
          </div>

          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-6 max-w-6xl mx-auto">
            <Card className="text-center border-2 hover:border-green-200 transition-colors">
              <CardHeader className="pb-6 pt-8">
                <div className="w-12 h-12 bg-red-100 rounded-full flex items-center justify-center mx-auto mb-3">
                  <Bug className="h-6 w-6 text-red-600" />
                </div>
                <CardTitle className="text-lg">Report Bugs</CardTitle>
                <CardDescription>
                  Found a bug? Help us fix it! Create detailed bug reports with steps to reproduce.
                </CardDescription>
              </CardHeader>
              <CardContent>
                <Link href="https://github.com/asmbli/asmbli/issues/new?template=bug_report.md" target="_blank" rel="noopener noreferrer">
                  <Button variant="outline" size="sm" className="w-full">
                    Report Bug
                    <ExternalLink className="ml-2 h-3 w-3" />
                  </Button>
                </Link>
              </CardContent>
            </Card>

            <Card className="text-center border-2 hover:border-green-200 transition-colors">
              <CardHeader className="pb-6 pt-8">
                <div className="w-12 h-12 bg-blue-100 rounded-full flex items-center justify-center mx-auto mb-3">
                  <Lightbulb className="h-6 w-6 text-blue-600" />
                </div>
                <CardTitle className="text-lg">Suggest Features</CardTitle>
                <CardDescription>
                  Have ideas for improvement? We'd love to hear them! Suggest realistic, useful features.
                </CardDescription>
              </CardHeader>
              <CardContent>
                <Link href="https://github.com/asmbli/asmbli/issues/new?template=feature_request.md" target="_blank" rel="noopener noreferrer">
                  <Button variant="outline" size="sm" className="w-full">
                    Suggest Feature
                    <ExternalLink className="ml-2 h-3 w-3" />
                  </Button>
                </Link>
              </CardContent>
            </Card>

            <Card className="text-center border-2 hover:border-green-200 transition-colors">
              <CardHeader className="pb-6 pt-8">
                <div className="w-12 h-12 bg-green-100 rounded-full flex items-center justify-center mx-auto mb-3">
                  <Code className="h-6 w-6 text-green-600" />
                </div>
                <CardTitle className="text-lg">Write Code</CardTitle>
                <CardDescription>
                  Flutter developer? Help us improve the chat interface, agent templates, or design system.
                </CardDescription>
              </CardHeader>
              <CardContent>
                <Link href="https://github.com/asmbli/asmbli/issues?q=is%3Aissue+is%3Aopen+label%3A%22good+first+issue%22" target="_blank" rel="noopener noreferrer">
                  <Button variant="outline" size="sm" className="w-full">
                    Good First Issues
                    <ExternalLink className="ml-2 h-3 w-3" />
                  </Button>
                </Link>
              </CardContent>
            </Card>

            <Card className="text-center border-2 hover:border-green-200 transition-colors">
              <CardHeader className="pb-6 pt-8">
                <div className="w-12 h-12 bg-purple-100 rounded-full flex items-center justify-center mx-auto mb-3">
                  <FileText className="h-6 w-6 text-purple-600" />
                </div>
                <CardTitle className="text-lg">Improve Documentation</CardTitle>
                <CardDescription>
                  Help make Asmbli more accessible with better docs, tutorials, and setup guides.
                </CardDescription>
              </CardHeader>
              <CardContent>
                <Link href="https://github.com/asmbli/asmbli/tree/main/docs" target="_blank" rel="noopener noreferrer">
                  <Button variant="outline" size="sm" className="w-full">
                    View Docs
                    <ExternalLink className="ml-2 h-3 w-3" />
                  </Button>
                </Link>
              </CardContent>
            </Card>

            <Card className="text-center border-2 hover:border-green-200 transition-colors">
              <CardHeader className="pb-6 pt-8">
                <div className="w-12 h-12 bg-orange-100 rounded-full flex items-center justify-center mx-auto mb-3">
                  <Server className="h-6 w-6 text-orange-600" />
                </div>
                <CardTitle className="text-lg">Test MCP Servers</CardTitle>
                <CardDescription>
                  Help us figure out which MCP servers actually work reliably with our integration.
                </CardDescription>
              </CardHeader>
              <CardContent>
                <Link href="https://github.com/asmbli/asmbli/issues?q=is%3Aissue+is%3Aopen+label%3Amcp" target="_blank" rel="noopener noreferrer">
                  <Button variant="outline" size="sm" className="w-full">
                    MCP Issues
                    <ExternalLink className="ml-2 h-3 w-3" />
                  </Button>
                </Link>
              </CardContent>
            </Card>

            <Card className="text-center border-2 hover:border-green-200 transition-colors">
              <CardHeader className="pb-6 pt-8">
                <div className="w-12 h-12 bg-pink-100 rounded-full flex items-center justify-center mx-auto mb-3">
                  <Heart className="h-6 w-6 text-pink-600" />
                </div>
                <CardTitle className="text-lg">Share & Support</CardTitle>
                <CardDescription>
                  Star the repo, share with others, write blog posts, or help users in discussions.
                </CardDescription>
              </CardHeader>
              <CardContent>
                <Link href="https://github.com/asmbli/asmbli/discussions" target="_blank" rel="noopener noreferrer">
                  <Button variant="outline" size="sm" className="w-full">
                    Join Discussions
                    <ExternalLink className="ml-2 h-3 w-3" />
                  </Button>
                </Link>
              </CardContent>
            </Card>
          </div>
        </div>
      </section>

      {/* Current State & Roadmap */}
      <section className="py-12 sm:py-16 lg:py-20 px-4 bg-yellow-50/10">
        <div className="container mx-auto max-w-4xl">
          <div className="text-center mb-8 sm:mb-12">
            <h2 className="text-2xl sm:text-3xl font-bold mb-4 font-display">
              Project Status & Roadmap
            </h2>
            <p className="text-base sm:text-lg text-muted-foreground px-4">
              Honest assessment of what works, what doesn't, and where we're headed
            </p>
          </div>

          <div className="grid md:grid-cols-2 gap-8">
            {/* What Works Well */}
            <Card className="border-2 border-green-300/20 bg-green-50/10">
              <CardHeader>
                <div className="flex items-center gap-3 mb-4">
                  <div className="w-10 h-10 bg-green-500/10 rounded-lg flex items-center justify-center">
                    <CheckCircle className="h-5 w-5 text-green-600" />
                  </div>
                  <CardTitle>✅ What Works Well</CardTitle>
                </div>
              </CardHeader>
              <CardContent className="space-y-3">
                <div className="flex items-start gap-2">
                  <CheckCircle className="h-4 w-4 text-green-500 mt-1 flex-shrink-0" />
                  <span className="text-sm">Multi-model chat (Claude, OpenAI, local)</span>
                </div>
                <div className="flex items-start gap-2">
                  <CheckCircle className="h-4 w-4 text-green-500 mt-1 flex-shrink-0" />
                  <span className="text-sm">Real-time streaming responses</span>
                </div>
                <div className="flex items-start gap-2">
                  <CheckCircle className="h-4 w-4 text-green-500 mt-1 flex-shrink-0" />
                  <span className="text-sm">Secure API key storage (OS keychain)</span>
                </div>
                <div className="flex items-start gap-2">
                  <CheckCircle className="h-4 w-4 text-green-500 mt-1 flex-shrink-0" />
                  <span className="text-sm">Local conversation history</span>
                </div>
                <div className="flex items-start gap-2">
                  <CheckCircle className="h-4 w-4 text-green-500 mt-1 flex-shrink-0" />
                  <span className="text-sm">Cross-platform Flutter desktop app</span>
                </div>
                <div className="flex items-start gap-2">
                  <CheckCircle className="h-4 w-4 text-green-500 mt-1 flex-shrink-0" />
                  <span className="text-sm">Beautiful multi-color design system</span>
                </div>
              </CardContent>
            </Card>

            {/* Known Issues */}
            <Card className="border-2 border-amber-300/20 bg-amber-50/10">
              <CardHeader>
                <div className="flex items-center gap-3 mb-4">
                  <div className="w-10 h-10 bg-amber-500/10 rounded-lg flex items-center justify-center">
                    <AlertTriangle className="h-5 w-5 text-amber-600" />
                  </div>
                  <CardTitle>⚠️ Known Issues</CardTitle>
                </div>
              </CardHeader>
              <CardContent className="space-y-3">
                <div className="flex items-start gap-2">
                  <AlertTriangle className="h-4 w-4 text-amber-500 mt-1 flex-shrink-0" />
                  <span className="text-sm">Agent responses can hallucinate</span>
                </div>
                <div className="flex items-start gap-2">
                  <AlertTriangle className="h-4 w-4 text-amber-500 mt-1 flex-shrink-0" />
                  <span className="text-sm">MCP integration is unreliable</span>
                </div>
                <div className="flex items-start gap-2">
                  <AlertTriangle className="h-4 w-4 text-amber-500 mt-1 flex-shrink-0" />
                  <span className="text-sm">Document context gets lost in long chats</span>
                </div>
                <div className="flex items-start gap-2">
                  <AlertTriangle className="h-4 w-4 text-amber-500 mt-1 flex-shrink-0" />
                  <span className="text-sm">No agent deployment capabilities</span>
                </div>
                <div className="flex items-start gap-2">
                  <AlertTriangle className="h-4 w-4 text-amber-500 mt-1 flex-shrink-0" />
                  <span className="text-sm">Limited error handling for API failures</span>
                </div>
                <div className="flex items-start gap-2">
                  <AlertTriangle className="h-4 w-4 text-amber-500 mt-1 flex-shrink-0" />
                  <span className="text-sm">Vector search is basic and may not scale</span>
                </div>
              </CardContent>
            </Card>
          </div>

          <div className="mt-8">
            <Card>
              <CardHeader>
                <CardTitle>🚀 Near-term Roadmap</CardTitle>
                <CardDescription>
                  Our focus areas for the next few months (in order of priority)
                </CardDescription>
              </CardHeader>
              <CardContent>
                <div className="space-y-4">
                  <div className="border-l-4 border-green-500 pl-4">
                    <h4 className="font-semibold">1. Improve Core Chat Experience</h4>
                    <p className="text-sm text-muted-foreground">Better error handling, connection stability, and message reliability</p>
                  </div>
                  <div className="border-l-4 border-blue-500 pl-4">
                    <h4 className="font-semibold">2. Fix Agent Template System</h4>
                    <p className="text-sm text-muted-foreground">Make agent configurations more reliable and less prone to hallucination</p>
                  </div>
                  <div className="border-l-4 border-purple-500 pl-4">
                    <h4 className="font-semibold">3. Document Context Improvements</h4>
                    <p className="text-sm text-muted-foreground">Better chunking, context management, and relevance in long conversations</p>
                  </div>
                  <div className="border-l-4 border-orange-500 pl-4">
                    <h4 className="font-semibold">4. MCP Server Compatibility</h4>
                    <p className="text-sm text-muted-foreground">Test and document which servers actually work reliably</p>
                  </div>
                </div>
              </CardContent>
            </Card>
          </div>
        </div>
      </section>

      {/* Getting Started as Contributor */}
      <section className="py-12 sm:py-16 lg:py-20 px-4">
        <div className="container mx-auto max-w-4xl">
          <div className="text-center mb-8 sm:mb-12">
            <h2 className="text-2xl sm:text-3xl font-bold mb-4 font-display">
              Getting Started as a Contributor
            </h2>
            <p className="text-base sm:text-lg text-muted-foreground px-4">
              Ready to contribute? Here's how to set up your development environment
            </p>
          </div>

          <Card>
            <CardHeader>
              <CardTitle>Development Setup</CardTitle>
              <CardDescription>
                Set up Asmbli for local development in a few steps
              </CardDescription>
            </CardHeader>
            <CardContent>
              <div className="space-y-6">
                <div className="flex gap-4">
                  <div className="w-8 h-8 bg-green-100 rounded-full flex items-center justify-center flex-shrink-0 mt-1">
                    <span className="text-sm font-bold text-green-700">1</span>
                  </div>
                  <div>
                    <h4 className="font-semibold mb-2">Prerequisites</h4>
                    <ul className="text-sm text-muted-foreground space-y-1 list-disc list-inside">
                      <li>Flutter SDK (&gt;=3.0.0)</li>
                      <li>Dart SDK (&gt;=3.0.0)</li>
                      <li>Git</li>
                      <li>Your favorite IDE (VS Code, Kiro, Cursor, JetBrains, Docker Compose)</li>
                    </ul>
                  </div>
                </div>

                <div className="flex gap-4">
                  <div className="w-8 h-8 bg-green-100 rounded-full flex items-center justify-center flex-shrink-0 mt-1">
                    <span className="text-sm font-bold text-green-700">2</span>
                  </div>
                  <div>
                    <h4 className="font-semibold mb-2">Clone and Setup</h4>
                    <div className="bg-gray-100 rounded-lg p-3 text-sm font-mono">
                      <p>git clone https://github.com/asmbli/asmbli.git</p>
                      <p>cd asmbli</p>
                      <p>cd apps/desktop && flutter pub get</p>
                      <p>cd ../../packages/agent_engine_core && flutter pub get</p>
                    </div>
                  </div>
                </div>

                <div className="flex gap-4">
                  <div className="w-8 h-8 bg-green-100 rounded-full flex items-center justify-center flex-shrink-0 mt-1">
                    <span className="text-sm font-bold text-green-700">3</span>
                  </div>
                  <div>
                    <h4 className="font-semibold mb-2">Run the App</h4>
                    <div className="bg-gray-100 rounded-lg p-3 text-sm font-mono">
                      <p>cd apps/desktop</p>
                      <p>flutter run</p>
                    </div>
                  </div>
                </div>

                <div className="flex gap-4">
                  <div className="w-8 h-8 bg-green-100 rounded-full flex items-center justify-center flex-shrink-0 mt-1">
                    <span className="text-sm font-bold text-green-700">4</span>
                  </div>
                  <div>
                    <h4 className="font-semibold mb-2">Read the Guidelines</h4>
                    <p className="text-sm text-muted-foreground mb-2">
                      Check out our contribution guidelines and development setup
                    </p>
                    <Link href="https://github.com/asmbli/asmbli/blob/main/CONTRIBUTING.md" target="_blank" rel="noopener noreferrer">
                      <Button variant="outline" size="sm">
                        Read CONTRIBUTING.md
                        <ExternalLink className="ml-2 h-3 w-3" />
                      </Button>
                    </Link>
                  </div>
                </div>
              </div>
            </CardContent>
          </Card>
        </div>
      </section>

      {/* Call to Action */}
      <section className="py-12 sm:py-16 lg:py-20 px-4 bg-gradient-to-br from-green-50/30 to-blue-50/30">
        <div className="container mx-auto max-w-2xl text-center">
          <h2 className="text-2xl sm:text-3xl font-bold mb-4 sm:mb-6 font-display">
            Ready to Contribute?
          </h2>
          <p className="text-base sm:text-lg text-muted-foreground mb-6 sm:mb-8 px-4">
            Join our community of contributors building the most honest AI chat application.
            Every contribution - big or small - makes a difference.
          </p>

          <div className="flex flex-col sm:flex-row gap-3 sm:gap-4 justify-center">
            <Link href="https://github.com/asmbli/asmbli" target="_blank" rel="noopener noreferrer">
              <Button size="lg" className="w-full sm:w-auto bg-green-500 hover:bg-green-600 text-white">
                <GitBranch className="mr-2 h-5 w-5" />
                Start Contributing
              </Button>
            </Link>
            <Link href="https://github.com/asmbli/asmbli/discussions" target="_blank" rel="noopener noreferrer">
              <Button size="lg" variant="outline" className="w-full sm:w-auto">
                Join Discussions
              </Button>
            </Link>
          </div>

          <div className="mt-6 sm:mt-8 flex flex-col sm:flex-row gap-3 sm:gap-6 justify-center items-center text-xs sm:text-sm text-muted-foreground">
            <div className="flex items-center gap-2">
              <CheckCircle className="h-4 w-4 text-green-500" />
              <span>MIT Licensed</span>
            </div>
            <div className="flex items-center gap-2">
              <CheckCircle className="h-4 w-4 text-green-500" />
              <span>Welcoming Community</span>
            </div>
            <div className="flex items-center gap-2">
              <CheckCircle className="h-4 w-4 text-green-500" />
              <span>All Skill Levels Welcome</span>
            </div>
          </div>
        </div>
      </section>

      {/* Footer */}
      <Footer />
    </div>
  )
}