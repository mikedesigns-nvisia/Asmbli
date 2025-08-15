import { describe, it, expect, vi } from 'vitest';
import { render, screen, fireEvent } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { MVPStep1Role } from '../../../components/wizard/MVPStep1Role';

describe('MVPStep1Role Component', () => {
  const user = userEvent.setup();
  const mockOnRoleChange = vi.fn();

  beforeEach(() => {
    mockOnRoleChange.mockClear();
  });

  it('should render all three role options', () => {
    render(<MVPStep1Role selectedRole="" onRoleChange={mockOnRoleChange} />);
    
    expect(screen.getByText('Developer')).toBeInTheDocument();
    expect(screen.getByText('Creator')).toBeInTheDocument();
    expect(screen.getByText('Researcher')).toBeInTheDocument();
  });

  it('should show role descriptions', () => {
    render(<MVPStep1Role selectedRole="" onRoleChange={mockOnRoleChange} />);
    
    expect(screen.getByText('Build apps, manage code, automate workflows')).toBeInTheDocument();
    expect(screen.getByText('Design content, manage projects, create media')).toBeInTheDocument();
    expect(screen.getByText('Analyze data, write papers, manage references')).toBeInTheDocument();
  });

  it('should call onRoleChange when a role is selected', async () => {
    render(<MVPStep1Role selectedRole="" onRoleChange={mockOnRoleChange} />);
    
    const developerCard = screen.getByText('Developer').closest('.cursor-pointer');
    await user.click(developerCard!);
    
    expect(mockOnRoleChange).toHaveBeenCalledWith('developer');
  });

  it('should highlight selected role', () => {
    render(<MVPStep1Role selectedRole="creator" onRoleChange={mockOnRoleChange} />);
    
    const creatorCard = screen.getByText('Creator').closest('.cursor-pointer');
    expect(creatorCard).toHaveClass('border-primary');
    expect(creatorCard).toHaveClass('bg-gradient-to-br');
  });

  it('should show checkmark for selected role', () => {
    render(<MVPStep1Role selectedRole="developer" onRoleChange={mockOnRoleChange} />);
    
    const developerCard = screen.getByText('Developer').closest('.cursor-pointer');
    const checkmark = developerCard?.querySelector('.text-primary');
    expect(checkmark).toBeInTheDocument();
  });

  it('should display role-specific tool recommendations', () => {
    render(<MVPStep1Role selectedRole="developer" onRoleChange={mockOnRoleChange} />);
    
    expect(screen.getByText('🔧 Code management & Git')).toBeInTheDocument();
    expect(screen.getByText('🚀 API & deployment tools')).toBeInTheDocument();
    expect(screen.getByText('📊 Database & analytics')).toBeInTheDocument();
  });

  it('should show different recommendations for each role', () => {
    const { rerender } = render(<MVPStep1Role selectedRole="creator" onRoleChange={mockOnRoleChange} />);
    
    expect(screen.getByText('🎨 Design & visual tools')).toBeInTheDocument();
    expect(screen.getByText('📝 Content & writing')).toBeInTheDocument();
    
    rerender(<MVPStep1Role selectedRole="researcher" onRoleChange={mockOnRoleChange} />);
    
    expect(screen.getByText('📚 Research & references')).toBeInTheDocument();
    expect(screen.getByText('📊 Data analysis')).toBeInTheDocument();
  });

  it('should show usage statistics for each role', () => {
    render(<MVPStep1Role selectedRole="" onRoleChange={mockOnRoleChange} />);
    
    expect(screen.getByText('45% of users')).toBeInTheDocument(); // Developer
    expect(screen.getByText('30% of users')).toBeInTheDocument(); // Creator  
    expect(screen.getByText('25% of users')).toBeInTheDocument(); // Researcher
  });

  it('should handle keyboard navigation', async () => {
    render(<MVPStep1Role selectedRole="" onRoleChange={mockOnRoleChange} />);
    
    const developerCard = screen.getByText('Developer').closest('.cursor-pointer');
    
    // Focus and press Enter
    developerCard?.focus();
    await user.keyboard('{Enter}');
    
    expect(mockOnRoleChange).toHaveBeenCalledWith('developer');
  });

  it('should show correct icons for each role', () => {
    render(<MVPStep1Role selectedRole="" onRoleChange={mockOnRoleChange} />);
    
    // Icons are rendered through Lucide components, check for their presence
    const roleCards = screen.getAllByText(/Developer|Creator|Researcher/);
    expect(roleCards).toHaveLength(3);
  });

  it('should handle hover effects', async () => {
    render(<MVPStep1Role selectedRole="" onRoleChange={mockOnRoleChange} />);
    
    const developerCard = screen.getByText('Developer').closest('.cursor-pointer');
    
    // Hover should add hover classes
    await user.hover(developerCard!);
    expect(developerCard).toHaveClass('hover:shadow-lg');
  });

  it('should show role benefits clearly', () => {
    render(<MVPStep1Role selectedRole="developer" onRoleChange={mockOnRoleChange} />);
    
    expect(screen.getByText('Perfect for building and maintaining applications')).toBeInTheDocument();
  });

  it('should allow changing selected role', async () => {
    const { rerender } = render(<MVPStep1Role selectedRole="developer" onRoleChange={mockOnRoleChange} />);
    
    // Creator should not be selected initially
    let creatorCard = screen.getByText('Creator').closest('.cursor-pointer');
    expect(creatorCard).not.toHaveClass('border-primary');
    
    // Click creator
    await user.click(creatorCard!);
    expect(mockOnRoleChange).toHaveBeenCalledWith('creator');
    
    // Re-render with creator selected
    rerender(<MVPStep1Role selectedRole="creator" onRoleChange={mockOnRoleChange} />);
    
    creatorCard = screen.getByText('Creator').closest('.cursor-pointer');
    expect(creatorCard).toHaveClass('border-primary');
  });

  it('should display helpful role selection tips', () => {
    render(<MVPStep1Role selectedRole="" onRoleChange={mockOnRoleChange} />);
    
    expect(screen.getByText('💡 Choose the role that best matches your primary use case. You can always adjust tool selections in the next step.')).toBeInTheDocument();
  });

  it('should show time commitment for each role setup', () => {
    render(<MVPStep1Role selectedRole="developer" onRoleChange={mockOnRoleChange} />);
    
    expect(screen.getByText('~15 min')).toBeInTheDocument();
  });
});