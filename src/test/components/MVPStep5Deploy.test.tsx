import { describe, it, expect, vi, beforeEach } from 'vitest';
import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { MVPStep5Deploy } from '../../../components/wizard/MVPStep5Deploy';

// Mock the deployment generator
vi.mock('../../../utils/deploymentGenerator', () => ({
  generateDeploymentConfigs: vi.fn(() => ({
    'lm-studio': '{"mcpServers": {"test": {"command": "node", "args": ["server.js"]}}}',
    'lm-studio-setup.md': '# Setup Guide for LM Studio\n\n1. Install LM Studio\n2. Configure MCP\n3. Start using your agent'
  }))
}));

describe('MVPStep5Deploy Component', () => {
  const user = userEvent.setup();
  const mockOnDeploymentChange = vi.fn();
  const mockOnGenerate = vi.fn();

  const mockWizardData = {
    selectedRole: 'developer',
    selectedTools: ['code-management', 'api-integration'],
    style: {
      tone: 'technical',
      responseLength: 'balanced',
      constraints: ['Always include code examples when relevant']
    }
  };

  const defaultProps = {
    wizardData: mockWizardData,
    deployment: { platform: '', configuration: {} },
    onDeploymentChange: mockOnDeploymentChange,
    onGenerate: mockOnGenerate
  };

  beforeEach(() => {
    mockOnDeploymentChange.mockClear();
    mockOnGenerate.mockClear();
    // Mock download functionality
    global.URL.createObjectURL = vi.fn(() => 'mock-blob-url');
    global.URL.revokeObjectURL = vi.fn();
    
    // Mock document methods
    const mockAnchor = {
      click: vi.fn(),
      setAttribute: vi.fn()
    };
    vi.spyOn(document, 'createElement').mockReturnValue(mockAnchor as any);
    vi.spyOn(document.body, 'appendChild').mockImplementation(() => mockAnchor as any);
    vi.spyOn(document.body, 'removeChild').mockImplementation(() => mockAnchor as any);
  });

  afterEach(() => {
    vi.restoreAllMocks();
  });

  it('should render platform selection interface', () => {
    render(<MVPStep5Deploy {...defaultProps} />);
    
    expect(screen.getByText('Where should your agent run?')).toBeInTheDocument();
    expect(screen.getByText('Free Deployment Options')).toBeInTheDocument();
    expect(screen.getByText('Zero Cost')).toBeInTheDocument();
  });

  it('should show all three platform options', () => {
    render(<MVPStep5Deploy {...defaultProps} />);
    
    expect(screen.getByText('LM Studio')).toBeInTheDocument();
    expect(screen.getByText('Local AI with complete privacy control')).toBeInTheDocument();
    
    expect(screen.getByText('Ollama')).toBeInTheDocument();
    expect(screen.getByText('Lightweight local AI for developers')).toBeInTheDocument();
    
    expect(screen.getByText('VS Code + Copilot')).toBeInTheDocument();
    expect(screen.getByText('Integrated into your development workflow')).toBeInTheDocument();
  });

  it('should show platform difficulty and setup time', () => {
    render(<MVPStep5Deploy {...defaultProps} />);
    
    expect(screen.getByText('Easy')).toBeInTheDocument(); // LM Studio
    expect(screen.getByText('5 minutes')).toBeInTheDocument();
    expect(screen.getByText('Medium')).toBeInTheDocument(); // Ollama
    expect(screen.getByText('10 minutes')).toBeInTheDocument();
  });

  it('should handle platform selection', async () => {
    render(<MVPStep5Deploy {...defaultProps} />);
    
    const lmStudioCard = screen.getByText('LM Studio').closest('.cursor-pointer');
    await user.click(lmStudioCard!);
    
    // Should show selected state
    await waitFor(() => {
      expect(lmStudioCard).toHaveClass('border-primary');
      expect(lmStudioCard).toHaveClass('bg-gradient-to-br');
    });
  });

  it('should generate configuration when platform is selected', async () => {
    render(<MVPStep5Deploy {...defaultProps} />);
    
    const lmStudioCard = screen.getByText('LM Studio').closest('.cursor-pointer');
    await user.click(lmStudioCard!);
    
    // Should call onDeploymentChange with generated config
    await waitFor(() => {
      expect(mockOnDeploymentChange).toHaveBeenCalledWith({
        platform: 'lm-studio',
        configuration: expect.any(String)
      });
    });
  });

  it('should show configuration panel when platform is selected', async () => {
    const propsWithPlatform = {
      ...defaultProps,
      deployment: { platform: 'lm-studio', configuration: {} }
    };
    
    render(<MVPStep5Deploy {...propsWithPlatform} />);
    
    await waitFor(() => {
      expect(screen.getByText('LM Studio Configuration')).toBeInTheDocument();
      expect(screen.getByText('Ready-to-deploy setup for lm studio')).toBeInTheDocument();
    });
  });

  it('should show configuration tabs', async () => {
    const propsWithPlatform = {
      ...defaultProps,
      deployment: { platform: 'lm-studio', configuration: {} }
    };
    
    render(<MVPStep5Deploy {...propsWithPlatform} />);
    
    await waitFor(() => {
      expect(screen.getByText('Configuration')).toBeInTheDocument();
      expect(screen.getByText('Setup Guide')).toBeInTheDocument();
      expect(screen.getByText('Features')).toBeInTheDocument();
    });
  });

  it('should show generated configuration code', async () => {
    const propsWithPlatform = {
      ...defaultProps,
      deployment: { platform: 'lm-studio', configuration: {} }
    };
    
    render(<MVPStep5Deploy {...propsWithPlatform} />);
    
    await waitFor(() => {
      expect(screen.getByText('Generated Configuration')).toBeInTheDocument();
    });
    
    // Wait for generation to complete
    await waitFor(() => {
      expect(screen.getByText('Download Config')).toBeInTheDocument();
    }, { timeout: 2000 });
  });

  it('should handle configuration download', async () => {
    const propsWithPlatform = {
      ...defaultProps,
      deployment: { platform: 'lm-studio', configuration: {} }
    };
    
    render(<MVPStep5Deploy {...propsWithPlatform} />);
    
    await waitFor(() => {
      const downloadButton = screen.getByText('Download Config');
      expect(downloadButton).toBeInTheDocument();
    }, { timeout: 2000 });
    
    const downloadButton = screen.getByText('Download Config');
    await user.click(downloadButton);
    
    expect(document.createElement).toHaveBeenCalledWith('a');
    expect(global.URL.createObjectURL).toHaveBeenCalled();
  });

  it('should handle setup guide download', async () => {
    const propsWithPlatform = {
      ...defaultProps,
      deployment: { platform: 'lm-studio', configuration: {} }
    };
    
    render(<MVPStep5Deploy {...propsWithPlatform} />);
    
    await waitFor(() => {
      const setupGuideButton = screen.getByText('Download Setup Guide');
      expect(setupGuideButton).toBeInTheDocument();
    }, { timeout: 2000 });
    
    const setupGuideButton = screen.getByText('Download Setup Guide');
    await user.click(setupGuideButton);
    
    expect(document.createElement).toHaveBeenCalledWith('a');
  });

  it('should show setup steps in setup guide tab', async () => {
    const propsWithPlatform = {
      ...defaultProps,
      deployment: { platform: 'lm-studio', configuration: {} }
    };
    
    render(<MVPStep5Deploy {...propsWithPlatform} />);
    
    await waitFor(() => {
      const setupTab = screen.getByText('Setup Guide');
      user.click(setupTab);
    });
    
    await waitFor(() => {
      expect(screen.getByText('Quick Setup Steps')).toBeInTheDocument();
      expect(screen.getByText('Install LM Studio v0.3.17+')).toBeInTheDocument();
      expect(screen.getByText('Install Node.js installed')).toBeInTheDocument();
    });
  });

  it('should show platform features in features tab', async () => {
    const propsWithPlatform = {
      ...defaultProps,
      deployment: { platform: 'lm-studio', configuration: {} }
    };
    
    render(<MVPStep5Deploy {...propsWithPlatform} />);
    
    await waitFor(() => {
      const featuresTab = screen.getByText('Features');
      user.click(featuresTab);
    });
    
    await waitFor(() => {
      expect(screen.getByText('What You Get')).toBeInTheDocument();
      expect(screen.getByText('Core Features')).toBeInTheDocument();
      expect(screen.getByText('Key Benefits')).toBeInTheDocument();
    });
  });

  it('should show platform benefits and features', () => {
    render(<MVPStep5Deploy {...defaultProps} />);
    
    // LM Studio benefits should be visible
    expect(screen.getByText('🔒 Your data never leaves your machine')).toBeInTheDocument();
    expect(screen.getByText('🆓 Zero ongoing costs')).toBeInTheDocument();
    expect(screen.getByText('⚡ Fast responses with good hardware')).toBeInTheDocument();
  });

  it('should show ready to deploy section when configuration is complete', async () => {
    const propsWithPlatform = {
      ...defaultProps,
      deployment: { platform: 'lm-studio', configuration: {} }
    };
    
    render(<MVPStep5Deploy {...propsWithPlatform} />);
    
    await waitFor(() => {
      expect(screen.getByText('Your Agent is Ready!')).toBeInTheDocument();
    }, { timeout: 2000 });
    
    expect(screen.getByText(/We've generated everything you need to deploy/)).toBeInTheDocument();
  });

  it('should handle final deployment generation', async () => {
    const propsWithPlatform = {
      ...defaultProps,
      deployment: { platform: 'lm-studio', configuration: {} }
    };
    
    render(<MVPStep5Deploy {...propsWithPlatform} />);
    
    await waitFor(() => {
      const deployButton = screen.getByText('Download Configuration');
      expect(deployButton).toBeInTheDocument();
    }, { timeout: 2000 });
    
    const deployButton = screen.getByText('Download Configuration');
    await user.click(deployButton);
    
    expect(mockOnGenerate).toHaveBeenCalled();
  });

  it('should show loading state during configuration generation', async () => {
    render(<MVPStep5Deploy {...defaultProps} />);
    
    const lmStudioCard = screen.getByText('LM Studio').closest('.cursor-pointer');
    await user.click(lmStudioCard!);
    
    // Should show generating state briefly
    await waitFor(() => {
      expect(screen.getByText('Generating configuration...')).toBeInTheDocument();
    });
  });

  it('should show platform requirements', () => {
    render(<MVPStep5Deploy {...defaultProps} />);
    
    // Requirements should be shown for each platform
    // This would be visible in hover states or platform details
    const lmStudioCard = screen.getByText('LM Studio').closest('.cursor-pointer');
    expect(lmStudioCard).toBeInTheDocument();
  });

  it('should show privacy and cost benefits', async () => {
    const propsWithPlatform = {
      ...defaultProps,
      deployment: { platform: 'lm-studio', configuration: {} }
    };
    
    render(<MVPStep5Deploy {...propsWithPlatform} />);
    
    await waitFor(() => {
      expect(screen.getByText('Private & Secure')).toBeInTheDocument();
      expect(screen.getByText('Completely Free')).toBeInTheDocument();
      expect(screen.getByText('Your Rules')).toBeInTheDocument();
    }, { timeout: 2000 });
  });

  it('should show helpful guidance text', () => {
    render(<MVPStep5Deploy {...defaultProps} />);
    
    expect(screen.getByText(/All these platforms run locally for complete privacy/)).toBeInTheDocument();
    expect(screen.getByText(/Need help? Each download includes detailed setup instructions/)).toBeInTheDocument();
  });
});