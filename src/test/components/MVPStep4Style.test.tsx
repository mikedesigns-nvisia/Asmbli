import { describe, it, expect, vi } from 'vitest';
import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { MVPStep4Style } from '../../../components/wizard/MVPStep4Style';

describe('MVPStep4Style Component', () => {
  const user = userEvent.setup();
  const mockOnStyleChange = vi.fn();

  const defaultStyle = {
    tone: '',
    responseLength: 'balanced',
    constraints: []
  };

  const defaultProps = {
    selectedRole: 'developer',
    style: defaultStyle,
    extractedConstraints: [],
    onStyleChange: mockOnStyleChange
  };

  beforeEach(() => {
    mockOnStyleChange.mockClear();
  });

  it('should render communication style options', () => {
    render(<MVPStep4Style {...defaultProps} />);
    
    expect(screen.getByText('How should your AI communicate?')).toBeInTheDocument();
    expect(screen.getByText('Communication Tone')).toBeInTheDocument();
    expect(screen.getByText('Response Length')).toBeInTheDocument();
  });

  it('should show role-specific tone options for developers', () => {
    render(<MVPStep4Style {...defaultProps} />);
    
    expect(screen.getByText('Technical & Precise')).toBeInTheDocument();
    expect(screen.getByText('Clear, accurate, technical language')).toBeInTheDocument();
    expect(screen.getByText('Helpful & Supportive')).toBeInTheDocument();
    expect(screen.getByText('Efficient & Direct')).toBeInTheDocument();
  });

  it('should show different tone options for different roles', () => {
    const { rerender } = render(<MVPStep4Style {...defaultProps} />);
    
    // Developer options
    expect(screen.getByText('Technical & Precise')).toBeInTheDocument();
    
    // Change to creator role
    rerender(<MVPStep4Style {...defaultProps} selectedRole="creator" />);
    
    expect(screen.getByText('Creative & Inspiring')).toBeInTheDocument();
    expect(screen.getByText('Professional & Polished')).toBeInTheDocument();
    expect(screen.getByText('Friendly & Conversational')).toBeInTheDocument();
  });

  it('should handle tone selection', async () => {
    render(<MVPStep4Style {...defaultProps} />);
    
    const technicalTone = screen.getByText('Technical & Precise').closest('.cursor-pointer');
    await user.click(technicalTone!);
    
    expect(mockOnStyleChange).toHaveBeenCalledWith({
      ...defaultStyle,
      tone: 'technical'
    });
  });

  it('should highlight selected tone', () => {
    const selectedStyle = { ...defaultStyle, tone: 'technical' };
    render(<MVPStep4Style {...defaultProps} style={selectedStyle} />);
    
    const selectedTone = screen.getByText('Technical & Precise').closest('.cursor-pointer');
    expect(selectedTone).toHaveClass('border-primary');
    expect(selectedTone).toHaveClass('bg-gradient-to-br');
  });

  it('should show checkmark for selected tone', () => {
    const selectedStyle = { ...defaultStyle, tone: 'helpful' };
    render(<MVPStep4Style {...defaultProps} style={selectedStyle} />);
    
    const selectedTone = screen.getByText('Helpful & Supportive').closest('.cursor-pointer');
    const checkmark = selectedTone?.querySelector('.text-primary');
    expect(checkmark).toBeInTheDocument();
  });

  it('should handle response length slider', async () => {
    render(<MVPStep4Style {...defaultProps} />);
    
    // Test that slider exists and can be interacted with
    const slider = screen.getByRole('slider');
    expect(slider).toBeInTheDocument();
    
    // Simulate value change event
    fireEvent.change(slider, { target: { value: 75 } });
    
    // The component should respond to slider changes
    expect(slider).toHaveAttribute('aria-valuenow');
  });

  it('should show response length labels and descriptions', () => {
    render(<MVPStep4Style {...defaultProps} />);
    
    expect(screen.getByText('Concise')).toBeInTheDocument();
    expect(screen.getByText('1-2 sentences, get to the point')).toBeInTheDocument();
    expect(screen.getByText('Balanced')).toBeInTheDocument();
    expect(screen.getByText('A paragraph, good detail')).toBeInTheDocument();
    expect(screen.getByText('Detailed')).toBeInTheDocument();
    expect(screen.getByText('Comprehensive')).toBeInTheDocument();
  });

  it('should show behavioral constraints for the selected role', () => {
    render(<MVPStep4Style {...defaultProps} />);
    
    expect(screen.getByText('Behavioral Constraints')).toBeInTheDocument();
    expect(screen.getByText('Always include code examples when relevant')).toBeInTheDocument();
    expect(screen.getByText('Explain the reasoning behind technical decisions')).toBeInTheDocument();
    expect(screen.getByText('Consider performance implications')).toBeInTheDocument();
  });

  it('should show different constraints for different roles', () => {
    const { rerender } = render(<MVPStep4Style {...defaultProps} />);
    
    // Developer constraints
    expect(screen.getByText('Always include code examples when relevant')).toBeInTheDocument();
    
    // Change to researcher role
    rerender(<MVPStep4Style {...defaultProps} selectedRole="researcher" />);
    
    expect(screen.getByText('Always cite sources when making claims')).toBeInTheDocument();
    expect(screen.getByText('Include methodology considerations')).toBeInTheDocument();
  });

  it('should handle constraint selection', async () => {
    render(<MVPStep4Style {...defaultProps} />);
    
    const constraint = screen.getByText('Always include code examples when relevant').closest('.cursor-pointer');
    await user.click(constraint!);
    
    expect(mockOnStyleChange).toHaveBeenCalledWith({
      ...defaultStyle,
      constraints: ['Always include code examples when relevant']
    });
  });

  it('should handle constraint deselection', async () => {
    const styleWithConstraints = {
      ...defaultStyle,
      constraints: ['Always include code examples when relevant', 'Consider performance implications']
    };
    
    render(<MVPStep4Style {...defaultProps} style={styleWithConstraints} />);
    
    const constraint = screen.getByText('Always include code examples when relevant').closest('.cursor-pointer');
    await user.click(constraint!);
    
    expect(mockOnStyleChange).toHaveBeenCalledWith({
      ...styleWithConstraints,
      constraints: ['Consider performance implications']
    });
  });

  it('should show recommended constraints with badges', () => {
    render(<MVPStep4Style {...defaultProps} />);
    
    const recommendedBadges = screen.getAllByText('Recommended');
    expect(recommendedBadges.length).toBeGreaterThan(0);
  });

  it('should handle select all recommended constraints', async () => {
    render(<MVPStep4Style {...defaultProps} />);
    
    const selectAllButton = screen.getByText('Select Recommended');
    await user.click(selectAllButton);
    
    expect(mockOnStyleChange).toHaveBeenCalledWith({
      ...defaultStyle,
      constraints: [
        'Always include code examples when relevant',
        'Explain the reasoning behind technical decisions',
        'Consider performance implications'
      ]
    });
  });

  it('should handle clear all constraints', async () => {
    const styleWithConstraints = {
      ...defaultStyle,
      constraints: ['Always include code examples when relevant']
    };
    
    render(<MVPStep4Style {...defaultProps} style={styleWithConstraints} />);
    
    const clearAllButton = screen.getByText('Clear All');
    await user.click(clearAllButton);
    
    expect(mockOnStyleChange).toHaveBeenCalledWith({
      ...styleWithConstraints,
      constraints: []
    });
  });

  it('should display extracted constraints from uploaded files', () => {
    const extractedConstraints = [
      'Use TypeScript strict mode',
      'Follow company coding standards'
    ];
    
    render(<MVPStep4Style {...defaultProps} extractedConstraints={extractedConstraints} />);
    
    expect(screen.getByText('From Your Uploaded Files')).toBeInTheDocument();
    expect(screen.getByText('Auto-detected')).toBeInTheDocument();
    expect(screen.getByText('Use TypeScript strict mode')).toBeInTheDocument();
    expect(screen.getByText('Follow company coding standards')).toBeInTheDocument();
  });

  it('should show personality summary when options are selected', () => {
    const selectedStyle = {
      tone: 'technical',
      responseLength: 'detailed',
      constraints: ['Always include code examples when relevant']
    };
    
    render(<MVPStep4Style {...defaultProps} style={selectedStyle} />);
    
    expect(screen.getByText('Your AI Personality Summary')).toBeInTheDocument();
    expect(screen.getByText(/Tone.*Technical & Precise/)).toBeInTheDocument();
    expect(screen.getByText(/Response Length.*Detailed/)).toBeInTheDocument();
    expect(screen.getByText(/Constraints.*1 behavioral rules/)).toBeInTheDocument();
  });

  it('should show role-specific badge', () => {
    render(<MVPStep4Style {...defaultProps} />);
    
    expect(screen.getByText('For developers')).toBeInTheDocument();
  });

  it('should show appropriate icons for each section', () => {
    render(<MVPStep4Style {...defaultProps} />);
    
    // Icons are rendered through Lucide components
    expect(screen.getByText('Communication Tone')).toBeInTheDocument();
    expect(screen.getByText('Response Length')).toBeInTheDocument();
    expect(screen.getByText('Behavioral Constraints')).toBeInTheDocument();
  });

  it('should handle response length preview', () => {
    const selectedStyle = { ...defaultStyle, responseLength: 'comprehensive' };
    render(<MVPStep4Style {...defaultProps} style={selectedStyle} />);
    
    expect(screen.getByText('Preview: Thorough explanation with examples')).toBeInTheDocument();
  });

  it('should show helpful tips', () => {
    render(<MVPStep4Style {...defaultProps} />);
    
    expect(screen.getByText('💡 These settings shape how your AI communicates. You can always adjust them later.')).toBeInTheDocument();
    expect(screen.getByText('Constraints from uploaded files are automatically applied and don\'t need to be selected.')).toBeInTheDocument();
  });

  it('should limit displayed extracted constraints', () => {
    const manyConstraints = Array.from({ length: 10 }, (_, i) => `Constraint ${i + 1}`);
    
    render(<MVPStep4Style {...defaultProps} extractedConstraints={manyConstraints} />);
    
    expect(screen.getByText('+ 5 more constraints from your files')).toBeInTheDocument();
  });

  it('should show role-specific guidance text', () => {
    render(<MVPStep4Style {...defaultProps} />);
    
    expect(screen.getByText(/These ensure your AI follows specific patterns and best practices for developers/)).toBeInTheDocument();
  });
});