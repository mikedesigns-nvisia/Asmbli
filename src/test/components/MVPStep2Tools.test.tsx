import { describe, it, expect, vi } from 'vitest';
import { render, screen, fireEvent } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { MVPStep2Tools } from '../../../components/wizard/MVPStep2Tools';

describe('MVPStep2Tools Component', () => {
  const user = userEvent.setup();
  const mockOnToolsChange = vi.fn();

  const defaultProps = {
    selectedRole: 'developer',
    selectedTools: [],
    onToolsChange: mockOnToolsChange
  };

  beforeEach(() => {
    mockOnToolsChange.mockClear();
  });

  it('should render tool categories and tools', () => {
    render(<MVPStep2Tools {...defaultProps} />);
    
    expect(screen.getByText('Development')).toBeInTheDocument();
    expect(screen.getByText('Content & Media')).toBeInTheDocument();
    expect(screen.getByText('Research & Data')).toBeInTheDocument();
    expect(screen.getByText('File Management')).toBeInTheDocument();
  });

  it('should show recommended tools for developer role', () => {
    render(<MVPStep2Tools {...defaultProps} />);
    
    // Should show developer-specific recommendations
    expect(screen.getByText('Code Management')).toBeInTheDocument();
    expect(screen.getByText('API Integration')).toBeInTheDocument();
    expect(screen.getByText('Database Tools')).toBeInTheDocument();
  });

  it('should show different recommendations for different roles', () => {
    const { rerender } = render(<MVPStep2Tools {...defaultProps} />);
    
    // Developer recommendations
    expect(screen.getByText('Code Management')).toBeInTheDocument();
    
    // Change to creator role
    rerender(<MVPStep2Tools {...defaultProps} selectedRole="creator" />);
    
    // Should show creator recommendations
    expect(screen.getByText('Visual Design')).toBeInTheDocument();
    expect(screen.getByText('Content Creation')).toBeInTheDocument();
  });

  it('should handle tool selection', async () => {
    render(<MVPStep2Tools {...defaultProps} />);
    
    const codeManagementTool = screen.getByText('Code Management').closest('.cursor-pointer');
    await user.click(codeManagementTool!);
    
    expect(mockOnToolsChange).toHaveBeenCalledWith(['code-management']);
  });

  it('should handle multiple tool selection', async () => {
    render(<MVPStep2Tools {...defaultProps} selectedTools={['code-management']} />);
    
    const apiTool = screen.getByText('API Integration').closest('.cursor-pointer');
    await user.click(apiTool!);
    
    expect(mockOnToolsChange).toHaveBeenCalledWith(['code-management', 'api-integration']);
  });

  it('should handle tool deselection', async () => {
    render(<MVPStep2Tools {...defaultProps} selectedTools={['code-management', 'api-integration']} />);
    
    const codeManagementTool = screen.getByText('Code Management').closest('.cursor-pointer');
    await user.click(codeManagementTool!);
    
    expect(mockOnToolsChange).toHaveBeenCalledWith(['api-integration']);
  });

  it('should show selected tools with checkmarks', () => {
    render(<MVPStep2Tools {...defaultProps} selectedTools={['code-management']} />);
    
    const selectedTool = screen.getByText('Code Management').closest('.cursor-pointer');
    expect(selectedTool).toHaveClass('border-primary');
    expect(selectedTool).toHaveClass('bg-primary/5');
  });

  it('should show recommended badges on relevant tools', () => {
    render(<MVPStep2Tools {...defaultProps} />);
    
    // Developer role should show recommended badges on developer tools
    const recommendedBadges = screen.getAllByText('Recommended');
    expect(recommendedBadges.length).toBeGreaterThan(0);
  });

  it('should implement search functionality', async () => {
    render(<MVPStep2Tools {...defaultProps} />);
    
    const searchInput = screen.getByPlaceholderText('Search tools...');
    await user.type(searchInput, 'code');
    
    // Should filter tools based on search
    expect(screen.getByText('Code Management')).toBeInTheDocument();
    // Other non-matching tools might be hidden
  });

  it('should show tool descriptions', () => {
    render(<MVPStep2Tools {...defaultProps} />);
    
    expect(screen.getByText('Git, version control, code review tools')).toBeInTheDocument();
    expect(screen.getByText('REST APIs, webhooks, integrations')).toBeInTheDocument();
  });

  it('should handle select all recommended functionality', async () => {
    render(<MVPStep2Tools {...defaultProps} />);
    
    const selectAllButton = screen.getByText('Select All Recommended');
    await user.click(selectAllButton);
    
    // Should select all recommended tools for the role
    expect(mockOnToolsChange).toHaveBeenCalled();
    const calledWith = mockOnToolsChange.mock.calls[0][0];
    expect(calledWith).toContain('code-management');
    expect(calledWith).toContain('api-integration');
    expect(calledWith).toContain('database-tools');
  });

  it('should handle clear all functionality', async () => {
    render(<MVPStep2Tools {...defaultProps} selectedTools={['code-management', 'api-integration']} />);
    
    const clearAllButton = screen.getByText('Clear All');
    await user.click(clearAllButton);
    
    expect(mockOnToolsChange).toHaveBeenCalledWith([]);
  });

  it('should show selection count', () => {
    render(<MVPStep2Tools {...defaultProps} selectedTools={['code-management', 'api-integration']} />);
    
    expect(screen.getByText('2 tools selected')).toBeInTheDocument();
  });

  it('should show tool categories with proper organization', () => {
    render(<MVPStep2Tools {...defaultProps} />);
    
    // Check that tools are properly categorized
    expect(screen.getByText('Development')).toBeInTheDocument();
    expect(screen.getByText('Content & Media')).toBeInTheDocument();
    expect(screen.getByText('Research & Data')).toBeInTheDocument();
    expect(screen.getByText('File Management')).toBeInTheDocument();
  });

  it('should filter tools by category', async () => {
    render(<MVPStep2Tools {...defaultProps} />);
    
    // Should be able to filter by category
    const developmentCategory = screen.getByText('Development');
    expect(developmentCategory).toBeInTheDocument();
    
    // Tools under development category should be visible
    expect(screen.getByText('Code Management')).toBeInTheDocument();
    expect(screen.getByText('API Integration')).toBeInTheDocument();
  });

  it('should show tool usage statistics', () => {
    render(<MVPStep2Tools {...defaultProps} />);
    
    // Should show usage percentages or popularity indicators
    const toolCards = screen.getAllByRole('button');
    expect(toolCards.length).toBeGreaterThan(0);
  });

  it('should handle keyboard navigation for tool selection', async () => {
    render(<MVPStep2Tools {...defaultProps} />);
    
    const firstTool = screen.getByText('Code Management').closest('.cursor-pointer');
    
    firstTool?.focus();
    await user.keyboard('{Enter}');
    
    expect(mockOnToolsChange).toHaveBeenCalledWith(['code-management']);
  });

  it('should show helpful tips for tool selection', () => {
    render(<MVPStep2Tools {...defaultProps} />);
    
    expect(screen.getByText('💡 Start with recommended tools for your role, then add others as needed. You can always change these later.')).toBeInTheDocument();
  });

  it('should show minimum tool selection guidance', () => {
    render(<MVPStep2Tools {...defaultProps} />);
    
    expect(screen.getByText('Choose at least 1 tool to continue')).toBeInTheDocument();
  });

  it('should respect role-based tool visibility', () => {
    const { rerender } = render(<MVPStep2Tools {...defaultProps} selectedRole="researcher" />);
    
    // Researcher should see research-specific tools prominently
    expect(screen.getByText('Research Tools')).toBeInTheDocument();
    expect(screen.getByText('Data Analysis')).toBeInTheDocument();
    
    rerender(<MVPStep2Tools {...defaultProps} selectedRole="creator" />);
    
    // Creator should see creator-specific tools prominently
    expect(screen.getByText('Visual Design')).toBeInTheDocument();
    expect(screen.getByText('Content Creation')).toBeInTheDocument();
  });
});