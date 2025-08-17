import React, { useState } from 'react';
import { Button } from '../ui/button';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '../ui/card';
import { Dialog, DialogContent, DialogDescription, DialogHeader, DialogTitle, DialogTrigger } from '../ui/dialog';
import { Input } from '../ui/input';
import { Label } from '../ui/label';
import { Textarea } from '../ui/textarea';
import { Badge } from '../ui/badge';
import { toast } from 'sonner';
import { 
  Share2, 
  Download, 
  Link, 
  QrCode, 
  Mail, 
  Copy, 
  Check, 
  FileDown,
  GitBranch,
  Package,
  Clipboard,
  ExternalLink
} from 'lucide-react';
import { CopyToClipboard } from 'react-copy-to-clipboard';
import JSZip from 'jszip';
import QRCodeLib from 'qrcode';
import { generateChatMCPConfigs } from '../../utils/chatmcpGenerator';

interface ShareExportProps {
  wizardData: any;
  className?: string;
}

interface ShareableLink {
  id: string;
  url: string;
  createdAt: string;
  expiresAt?: string;
  views: number;
  maxViews?: number;
}

export function ShareExportSystem({ wizardData, className = '' }: ShareExportProps) {
  const [isShareDialogOpen, setIsShareDialogOpen] = useState(false);
  const [isExportDialogOpen, setIsExportDialogOpen] = useState(false);
  const [shareableLink, setShareableLink] = useState<string>('');
  const [qrCodeDataUrl, setQrCodeDataUrl] = useState<string>('');
  const [emailRecipient, setEmailRecipient] = useState('');
  const [exportFormat, setExportFormat] = useState<'json' | 'yaml' | 'zip'>('json');
  const [isGenerating, setIsGenerating] = useState(false);
  const [copySuccess, setCopySuccess] = useState<{ [key: string]: boolean }>({});

  // Generate shareable URL with encoded configuration
  const generateShareableLink = () => {
    try {
      const config = {
        role: wizardData.role,
        tools: wizardData.tools,
        style: wizardData.style,
        deployment: wizardData.deployment,
        timestamp: new Date().toISOString()
      };

      const encodedConfig = btoa(JSON.stringify(config));
      const baseUrl = window.location.origin + window.location.pathname;
      const shareUrl = `${baseUrl}?config=${encodedConfig}`;
      
      setShareableLink(shareUrl);
      
      // Generate QR code
      QRCodeLib.toDataURL(shareUrl, {
        width: 256,
        margin: 2,
        color: {
          dark: '#000000',
          light: '#FFFFFF'
        }
      }).then(setQrCodeDataUrl);

      // Save to local storage for tracking
      const shares = JSON.parse(localStorage.getItem('shared_configs') || '[]');
      shares.push({
        id: `share_${Date.now()}`,
        url: shareUrl,
        createdAt: new Date().toISOString(),
        views: 0,
        config: config
      });
      localStorage.setItem('shared_configs', JSON.stringify(shares));

      return shareUrl;
    } catch (error) {
      console.error('Failed to generate shareable link:', error);
      toast.error('Failed to generate shareable link');
      return '';
    }
  };

  // Create comprehensive ChatMCP export package
  const createExportPackage = async () => {
    setIsGenerating(true);
    
    try {
      const zip = new JSZip();

      // Generate ChatMCP configurations using our new generator
      const chatmcpConfigs = generateChatMCPConfigs(wizardData);
      
      // Add all ChatMCP files to the zip
      Object.entries(chatmcpConfigs).forEach(([filename, content]) => {
        zip.file(filename, content);
      });

      // Add legacy agent configuration for compatibility
      const legacyConfig = {
        name: `${wizardData.role || 'custom'}-agent`,
        version: '1.0.0',
        description: `A custom AI agent configured for ${wizardData.role || 'general'} workflows`,
        role: wizardData.role,
        tools: wizardData.tools,
        style: wizardData.style,
        deployment: { platform: 'chatmcp', type: 'mcp' },
        metadata: {
          createdAt: new Date().toISOString(),
          exportedAt: new Date().toISOString(),
          generator: 'AgentEngine ChatMCP',
          targetPlatform: 'ChatMCP'
        }
      };
      zip.file('legacy-config.json', JSON.stringify(legacyConfig, null, 2));

      // Add ChatMCP download links file
      const downloadInfo = {
        platform: 'ChatMCP',
        description: 'Native MCP client for AI chat',
        downloads: {
          windows: 'https://github.com/daodao97/chatmcp/releases/latest/download/chatmcp-windows.exe',
          macos: 'https://github.com/daodao97/chatmcp/releases/latest/download/chatmcp-macos.dmg',
          linux: 'https://github.com/daodao97/chatmcp/releases/latest/download/chatmcp-linux.AppImage'
        },
        documentation: 'https://github.com/daodao97/chatmcp',
        setupInstructions: 'See chatmcp-setup.md for complete installation guide'
      };
      zip.file('chatmcp-downloads.json', JSON.stringify(downloadInfo, null, 2));

      // Generate agent name for filename
      const agentName = wizardData.agentName || 
                       wizardData.role ? `${wizardData.role}-agent` : 
                       'custom-agent';

      // Generate and download zip
      const content = await zip.generateAsync({ type: 'blob' });
      const url = URL.createObjectURL(content);
      const a = document.createElement('a');
      a.href = url;
      a.download = `${agentName}-chatmcp.zip`;
      document.body.appendChild(a);
      a.click();
      document.body.removeChild(a);
      URL.revokeObjectURL(url);

      toast.success('ChatMCP agent package downloaded successfully!');
    } catch (error) {
      console.error('ChatMCP export failed:', error);
      toast.error('Failed to create ChatMCP package');
    } finally {
      setIsGenerating(false);
    }
  };

  const generateDeploymentScripts = (config: any) => {
    const scripts: { [key: string]: string } = {};

    // VS Code setup
    scripts['vs-code-setup.json'] = JSON.stringify({
      'claude.agentConfig': config
    }, null, 2);

    // LM Studio setup
    scripts['lm-studio-setup.sh'] = `#!/bin/bash
# LM Studio Agent Setup
echo "Setting up ${config.name} for LM Studio..."

# Create config directory
mkdir -p ~/.lmstudio/agent-configs

# Copy configuration
cp agent-config.json ~/.lmstudio/agent-configs/${config.name}.json

echo "Setup complete! Restart LM Studio to see your new agent."
`;

    // Ollama Modelfile
    scripts['Modelfile'] = `FROM llama2
PARAMETER temperature 0.7
SYSTEM """${config.description}

Role: ${config.role}
Tools: ${config.tools.join(', ')}
Style: ${config.style?.tone || 'professional'}

You are an AI assistant specialized for ${config.role} workflows.
"""
`;

    // Docker setup
    scripts['Dockerfile'] = `FROM node:18-alpine

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm ci --only=production

# Copy application files
COPY . .

# Expose port
EXPOSE 3000

# Start the application
CMD ["npm", "start"]
`;

    scripts['docker-compose.yml'] = `version: '3.8'
services:
  ${config.name}:
    build: .
    ports:
      - "3000:3000"
    environment:
      - NODE_ENV=production
    volumes:
      - ./config:/app/config:ro
`;

    return scripts;
  };

  const generateReadme = (config: any) => {
    return `# ${config.name}

${config.description}

## Configuration

- **Role**: ${config.role}
- **Tools**: ${config.tools.join(', ')}
- **Platform**: ${config.deployment?.platform || 'Generic'}
- **Style**: ${config.style?.tone || 'Professional'}

## Quick Start

1. Choose your deployment method from the \`deployment/\` folder
2. Follow the setup instructions in \`SETUP.md\`
3. Configure the MCP servers using \`mcp-config.json\`

## Files Included

- \`agent-config.json\` - Main configuration file
- \`agent-config.yaml\` - YAML format configuration
- \`mcp-config.json\` - MCP server configuration
- \`deployment/\` - Platform-specific deployment files
- \`SETUP.md\` - Detailed setup instructions

## Generated by

This configuration was generated using [Agent Builder](${window.location.origin}) on ${new Date().toLocaleDateString()}.

## Support

For questions or issues, please visit our [documentation](${window.location.origin}/docs) or [contact support](mailto:support@agentbuilder.com).
`;
  };

  const generateSetupGuide = (config: any) => {
    return `# Setup Guide for ${config.name}

## Prerequisites

- Node.js 18+ (for MCP servers)
- Your chosen AI platform (VS Code, LM Studio, Ollama, etc.)

## Step-by-Step Setup

### 1. Install Dependencies

\`\`\`bash
npm install
\`\`\`

### 2. Configure MCP Servers

Copy the MCP configuration to your platform:

**VS Code:**
\`\`\`bash
cp deployment/vs-code-setup.json ~/.config/Code/User/settings.json
\`\`\`

**LM Studio:**
\`\`\`bash
chmod +x deployment/lm-studio-setup.sh
./deployment/lm-studio-setup.sh
\`\`\`

**Ollama:**
\`\`\`bash
ollama create ${config.name} -f deployment/Modelfile
\`\`\`

### 3. Test the Configuration

1. Start your AI platform
2. Load the ${config.name} configuration
3. Test with a simple query to verify tools are working

### 4. Customization

You can modify the configuration by editing:
- \`agent-config.json\` - Main settings
- \`mcp-config.json\` - Tool configurations

## Troubleshooting

- **Tools not working**: Check MCP server paths in \`mcp-config.json\`
- **Permission errors**: Ensure proper file permissions on setup scripts
- **Connection issues**: Verify network access for web-based tools

## Need Help?

Visit [Agent Builder Documentation](${window.location.origin}/docs) for detailed guides.
`;
  };

  const shareViaEmail = async () => {
    if (!emailRecipient || !shareableLink) return;

    const subject = `Check out my AI Agent Configuration - ${wizardData.role || 'Custom'} Agent`;
    const body = `Hi!

I've created a custom AI agent configuration using Agent Builder and wanted to share it with you.

Agent Details:
- Role: ${wizardData.role || 'Custom'}
- Tools: ${wizardData.tools?.join(', ') || 'None selected'}
- Platform: ${wizardData.deployment?.platform || 'Not specified'}

You can view and import this configuration here:
${shareableLink}

This link contains all the settings needed to replicate this agent setup.

Best regards!

---
Generated with Agent Builder: ${window.location.origin}
`;

    // Use mailto for simple email sharing
    const mailtoUrl = `mailto:${emailRecipient}?subject=${encodeURIComponent(subject)}&body=${encodeURIComponent(body)}`;
    window.open(mailtoUrl);
    
    toast.success('Email client opened with configuration details');
  };

  const handleCopy = (text: string, type: string) => {
    setCopySuccess({ ...copySuccess, [type]: true });
    setTimeout(() => {
      setCopySuccess({ ...copySuccess, [type]: false });
    }, 2000);
  };

  const shareToSocialMedia = (platform: 'twitter' | 'linkedin') => {
    const text = `Just created a custom AI agent for ${wizardData.role} workflows using Agent Builder! 🤖`;
    const url = shareableLink || window.location.href;

    const shareUrls = {
      twitter: `https://twitter.com/intent/tweet?text=${encodeURIComponent(text)}&url=${encodeURIComponent(url)}`,
      linkedin: `https://www.linkedin.com/sharing/share-offsite/?url=${encodeURIComponent(url)}`
    };

    window.open(shareUrls[platform], '_blank', 'width=600,height=400');
  };

  return (
    <div className="flex gap-2 w-full">
      {/* Share Button */}
      <Button 
        onClick={() => {
          generateShareableLink();
          setIsShareDialogOpen(true);
        }}
        className="flex items-center gap-1 flex-1 h-8 text-xs"
        size="sm"
      >
        <Share2 className="w-3 h-3" />
        Share
      </Button>
      
      {/* Export Button */}
      <Button 
        variant="outline" 
        className="flex items-center gap-1 flex-1 h-8 text-xs"
        onClick={() => setIsExportDialogOpen(true)}
        size="sm"
      >
        <Download className="w-3 h-3" />
        Export
      </Button>
      
      {/* Share Dialog */}
      <Dialog open={isShareDialogOpen} onOpenChange={setIsShareDialogOpen}>
        <DialogContent className="sm:max-w-lg">
          <DialogHeader>
            <DialogTitle className="flex items-center gap-2">
              <Share2 className="w-5 h-5" />
              Share Your Agent Configuration
            </DialogTitle>
            <DialogDescription>
              Share your agent setup with team members or save it for later.
            </DialogDescription>
          </DialogHeader>

          <div className="space-y-6">
            {/* Shareable Link */}
            {shareableLink && (
              <div className="space-y-3">
                <Label>Shareable Link</Label>
                <div className="flex gap-2">
                  <Input 
                    value={shareableLink} 
                    readOnly 
                    className="font-mono text-sm"
                  />
                  <CopyToClipboard
                    text={shareableLink}
                    onCopy={() => handleCopy(shareableLink, 'link')}
                  >
                    <Button variant="outline" size="sm">
                      {copySuccess.link ? (
                        <Check className="w-4 h-4 text-primary" />
                      ) : (
                        <Copy className="w-4 h-4" />
                      )}
                    </Button>
                  </CopyToClipboard>
                </div>
                <p className="text-xs text-muted-foreground">
                  This link contains your complete configuration and never expires.
                </p>
              </div>
            )}

            {/* QR Code */}
            {qrCodeDataUrl && (
              <div className="text-center space-y-2">
                <Label>QR Code</Label>
                <div className="flex justify-center">
                  <img 
                    src={qrCodeDataUrl} 
                    alt="Configuration QR Code" 
                    className="border rounded-lg"
                  />
                </div>
                <p className="text-xs text-muted-foreground">
                  Scan with your phone to open the configuration
                </p>
              </div>
            )}

            {/* Email Sharing */}
            <div className="space-y-3">
              <Label htmlFor="email">Email to Someone</Label>
              <div className="flex gap-2">
                <Input
                  id="email"
                  type="email"
                  placeholder="colleague@company.com"
                  value={emailRecipient}
                  onChange={(e) => setEmailRecipient(e.target.value)}
                />
                <Button 
                  onClick={shareViaEmail}
                  disabled={!emailRecipient}
                  variant="outline"
                  size="sm"
                >
                  <Mail className="w-4 h-4" />
                </Button>
              </div>
            </div>

            {/* Social Media Sharing */}
            <div className="space-y-3">
              <Label>Share on Social Media</Label>
              <div className="flex gap-2">
                <Button
                  onClick={() => shareToSocialMedia('twitter')}
                  variant="outline"
                  className="flex-1"
                >
                  Share on Twitter
                </Button>
                <Button
                  onClick={() => shareToSocialMedia('linkedin')}
                  variant="outline"
                  className="flex-1"
                >
                  Share on LinkedIn
                </Button>
              </div>
            </div>
          </div>
        </DialogContent>
      </Dialog>

      {/* Export Dialog */}
      <Dialog open={isExportDialogOpen} onOpenChange={setIsExportDialogOpen}>
        <DialogContent className="sm:max-w-md">
          <DialogHeader>
            <DialogTitle className="flex items-center gap-2">
              <Package className="w-5 h-5" />
              Export ChatMCP Agent Package
            </DialogTitle>
            <DialogDescription>
              Download a complete ChatMCP package with everything needed to deploy your agent.
            </DialogDescription>
          </DialogHeader>

          <div className="space-y-4">
            <div className="space-y-3">
              <Label>What's Included</Label>
              <div className="grid grid-cols-2 gap-2 text-sm">
                <div className="flex items-center gap-2">
                  <FileDown className="w-4 h-4 text-muted-foreground" />
                  ChatMCP config.json
                </div>
                <div className="flex items-center gap-2">
                  <GitBranch className="w-4 h-4 text-muted-foreground" />
                  Install scripts
                </div>
                <div className="flex items-center gap-2">
                  <Package className="w-4 h-4 text-muted-foreground" />
                  Setup guide
                </div>
                <div className="flex items-center gap-2">
                  <ExternalLink className="w-4 h-4 text-muted-foreground" />
                  Environment setup
                </div>
              </div>
            </div>

            <Button
              onClick={createExportPackage}
              disabled={isGenerating}
              className="w-full flex items-center gap-2"
            >
              {isGenerating ? (
                <>
                  <div className="animate-spin rounded-full h-4 w-4 border-b-2 border-white" />
                  Generating Package...
                </>
              ) : (
                <>
                  <Download className="w-4 h-4" />
                  Download ChatMCP Package
                </>
              )}
            </Button>

            <p className="text-xs text-muted-foreground text-center">
              Package includes everything needed to deploy your agent with ChatMCP.
            </p>
          </div>
        </DialogContent>
      </Dialog>
    </div>
  );
}