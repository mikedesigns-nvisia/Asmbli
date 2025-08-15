import { describe, it, expect } from 'vitest';
import { render, screen } from '@testing-library/react';
import { MVPWizard } from '../../../components/wizard/MVPWizard';
import { MVPStep1Role } from '../../../components/wizard/MVPStep1Role';
import { MVPStep2Tools } from '../../../components/wizard/MVPStep2Tools';
import { MVPStep3Upload } from '../../../components/wizard/MVPStep3Upload';
import { MVPStep4Style } from '../../../components/wizard/MVPStep4Style';
import { MVPStep5Deploy } from '../../../components/wizard/MVPStep5Deploy';

describe('MVP Wizard Integration Tests', () => {
  it('should render the main MVPWizard component without errors', () => {
    const { container } = render(<MVPWizard />);
    expect(container).toBeTruthy();
    
    // Should show progress indicators
    expect(screen.getByText('Step 1 of 5')).toBeInTheDocument();
    expect(screen.getByText('Create Your Custom AI Agent')).toBeInTheDocument();
  });

  it('should render Step 1 - Role Selection', () => {
    const mockOnRoleChange = vi.fn();
    render(<MVPStep1Role selectedRole="" onRoleChange={mockOnRoleChange} />);
    
    expect(screen.getByText('What\'s your primary role?')).toBeInTheDocument();
    expect(screen.getByText('Developer')).toBeInTheDocument();
    expect(screen.getByText('Creator')).toBeInTheDocument();
    expect(screen.getByText('Researcher')).toBeInTheDocument();
  });

  it('should render Step 2 - Tools Selection', () => {
    const mockOnToolsChange = vi.fn();
    render(
      <MVPStep2Tools 
        selectedRole="developer" 
        selectedTools={[]} 
        onToolsChange={mockOnToolsChange} 
      />
    );
    
    expect(screen.getByText('What tools do you need?')).toBeInTheDocument();
    expect(screen.getByText('Development')).toBeInTheDocument();
    expect(screen.getByText('Content & Media')).toBeInTheDocument();
  });

  it('should render Step 3 - File Upload', () => {
    const mockOnFilesChange = vi.fn();
    render(
      <MVPStep3Upload 
        uploadedFiles={[]} 
        extractedConstraints={[]} 
        onFilesChange={mockOnFilesChange} 
      />
    );
    
    expect(screen.getByText('Upload Your Requirements')).toBeInTheDocument();
    expect(screen.getByText('Optional but Powerful')).toBeInTheDocument();
    expect(screen.getByText('Drag & drop your requirements')).toBeInTheDocument();
  });

  it('should render Step 4 - Style Configuration', () => {
    const mockOnStyleChange = vi.fn();
    const style = { tone: '', responseLength: 'balanced', constraints: [] };
    
    render(
      <MVPStep4Style 
        selectedRole="developer"
        style={style}
        extractedConstraints={[]}
        onStyleChange={mockOnStyleChange}
      />
    );
    
    expect(screen.getByText('How should your AI communicate?')).toBeInTheDocument();
    expect(screen.getByText('Communication Tone')).toBeInTheDocument();
    expect(screen.getByText('Technical & Precise')).toBeInTheDocument();
  });

  it('should render Step 5 - Deployment', () => {
    const mockOnDeploymentChange = vi.fn();
    const mockOnGenerate = vi.fn();
    const wizardData = {
      selectedRole: 'developer',
      selectedTools: ['code-management'],
      style: { tone: 'technical', responseLength: 'balanced', constraints: [] }
    };
    
    render(
      <MVPStep5Deploy 
        wizardData={wizardData}
        deployment={{ platform: '', configuration: {} }}
        onDeploymentChange={mockOnDeploymentChange}
        onGenerate={mockOnGenerate}
      />
    );
    
    expect(screen.getByText('Where should your agent run?')).toBeInTheDocument();
    expect(screen.getByText('LM Studio')).toBeInTheDocument();
    expect(screen.getByText('Ollama')).toBeInTheDocument();
    expect(screen.getByText('VS Code + Copilot')).toBeInTheDocument();
  });

  it('should show correct step progression indicators', () => {
    render(<MVPWizard />);
    
    // Should show 5 steps
    expect(screen.getByText('Your Role')).toBeInTheDocument();
    expect(screen.getByText('Your Tools')).toBeInTheDocument();
    expect(screen.getByText('Upload Specs')).toBeInTheDocument();
    expect(screen.getByText('Your Style')).toBeInTheDocument();
    expect(screen.getByText('Deploy')).toBeInTheDocument();
  });

  it('should show progress percentage', () => {
    render(<MVPWizard />);
    
    // Should show 20% complete for step 1 of 5
    expect(screen.getByText('20% Complete')).toBeInTheDocument();
  });

  it('should display proper branding and messaging', () => {
    render(<MVPWizard />);
    
    expect(screen.getByText('Create Your Custom AI Agent')).toBeInTheDocument();
    expect(screen.getByText('Get an AI that knows YOUR workflow, constraints, and preferences')).toBeInTheDocument();
  });
});