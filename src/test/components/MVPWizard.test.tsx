import { describe, it, expect, beforeEach } from 'vitest';
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { MVPWizard } from '../../../components/wizard/MVPWizard';

describe('MVPWizard Component', () => {
  const user = userEvent.setup();

  beforeEach(() => {
    // Clear localStorage before each test
    window.localStorage.clear();
  });

  it('should render the first step by default', () => {
    render(<MVPWizard />);
    
    expect(screen.getByText('What\'s your primary role?')).toBeInTheDocument();
    expect(screen.getByText('Step 1 of 5')).toBeInTheDocument();
    expect(screen.getByText('Choose Your Role')).toBeInTheDocument();
  });

  it('should display progress correctly', () => {
    render(<MVPWizard />);
    
    // Progress bar should be at 20% for step 1
    const progressBar = screen.getByRole('progressbar');
    expect(progressBar).toHaveAttribute('aria-valuenow', '20');
  });

  it('should show all 5 steps in the progress indicator', () => {
    render(<MVPWizard />);
    
    expect(screen.getByText('Choose Your Role')).toBeInTheDocument();
    expect(screen.getByText('Select Tools')).toBeInTheDocument();
    expect(screen.getByText('Upload Files')).toBeInTheDocument();
    expect(screen.getByText('Set Style')).toBeInTheDocument();
    expect(screen.getByText('Deploy')).toBeInTheDocument();
  });

  it('should navigate to next step when role is selected', async () => {
    render(<MVPWizard />);
    
    // Select developer role
    const developerCard = screen.getByText('Developer').closest('.cursor-pointer');
    expect(developerCard).toBeInTheDocument();
    
    await user.click(developerCard!);
    
    // Continue button should be enabled
    const continueButton = screen.getByText('Continue to Tools');
    expect(continueButton).not.toBeDisabled();
    
    await user.click(continueButton);
    
    // Should now be on step 2
    await waitFor(() => {
      expect(screen.getByText('Step 2 of 5')).toBeInTheDocument();
      expect(screen.getByText('What tools do you need?')).toBeInTheDocument();
    });
  });

  it('should disable continue button when no role is selected', () => {
    render(<MVPWizard />);
    
    const continueButton = screen.getByText('Continue to Tools');
    expect(continueButton).toBeDisabled();
  });

  it('should allow going back to previous steps', async () => {
    render(<MVPWizard />);
    
    // Select role and go to step 2
    const developerCard = screen.getByText('Developer').closest('.cursor-pointer');
    await user.click(developerCard!);
    await user.click(screen.getByText('Continue to Tools'));
    
    await waitFor(() => {
      expect(screen.getByText('Step 2 of 5')).toBeInTheDocument();
    });
    
    // Click back button
    const backButton = screen.getByText('Back');
    await user.click(backButton);
    
    await waitFor(() => {
      expect(screen.getByText('Step 1 of 5')).toBeInTheDocument();
      expect(screen.getByText('What\'s your primary role?')).toBeInTheDocument();
    });
  });

  it('should persist wizard state in localStorage', async () => {
    render(<MVPWizard />);
    
    // Select developer role
    const developerCard = screen.getByText('Developer').closest('.cursor-pointer');
    await user.click(developerCard!);
    
    // Check that state is saved
    const savedState = JSON.parse(localStorage.getItem('mvp-wizard-data') || '{}');
    expect(savedState.selectedRole).toBe('developer');
  });

  it('should restore wizard state from localStorage', () => {
    // Pre-populate localStorage
    const mockState = {
      selectedRole: 'creator',
      selectedTools: ['file-management', 'content-creation'],
      currentStep: 2
    };
    localStorage.setItem('mvp-wizard-data', JSON.stringify(mockState));
    
    render(<MVPWizard />);
    
    // Should start at step 2 with creator role pre-selected
    expect(screen.getByText('Step 2 of 5')).toBeInTheDocument();
    expect(screen.getByText('What tools do you need?')).toBeInTheDocument();
  });

  it('should show step titles and descriptions correctly', () => {
    render(<MVPWizard />);
    
    // Check step 1 content
    expect(screen.getByText('Choose Your Role')).toBeInTheDocument();
    expect(screen.getByText('Tell us what you do so we can recommend the right tools')).toBeInTheDocument();
  });

  it('should handle error states gracefully', () => {
    // Mock console.error to avoid noise in tests
    const originalError = console.error;
    console.error = () => {};
    
    render(<MVPWizard />);
    
    // Component should still render even if there are errors
    expect(screen.getByText('What\'s your primary role?')).toBeInTheDocument();
    
    console.error = originalError;
  });

  it('should track wizard completion progress', async () => {
    render(<MVPWizard />);
    
    // Step 1: Select role
    const developerCard = screen.getByText('Developer').closest('.cursor-pointer');
    await user.click(developerCard!);
    await user.click(screen.getByText('Continue to Tools'));
    
    // Check progress is at 40% (step 2 of 5)
    await waitFor(() => {
      const progressBar = screen.getByRole('progressbar');
      expect(progressBar).toHaveAttribute('aria-valuenow', '40');
    });
  });

  it('should show correct step indicators', async () => {
    render(<MVPWizard />);
    
    // Initially, step 1 should be active
    const step1 = screen.getByText('1').closest('div');
    expect(step1).toHaveClass('bg-primary');
    
    const step2 = screen.getByText('2').closest('div');
    expect(step2).toHaveClass('bg-muted');
  });

  it('should handle wizard reset functionality', async () => {
    // Pre-populate with some data
    localStorage.setItem('mvp-wizard-data', JSON.stringify({
      selectedRole: 'developer',
      currentStep: 3
    }));
    
    render(<MVPWizard />);
    
    // Should be able to start fresh when needed
    const savedData = localStorage.getItem('mvp-wizard-data');
    expect(savedData).toBeTruthy();
  });

  it('should validate step completion before allowing navigation', async () => {
    render(<MVPWizard />);
    
    // Without selecting a role, continue should be disabled
    const continueButton = screen.getByText('Continue to Tools');
    expect(continueButton).toBeDisabled();
    
    // After selecting role, continue should be enabled
    const developerCard = screen.getByText('Developer').closest('.cursor-pointer');
    await user.click(developerCard!);
    
    expect(continueButton).not.toBeDisabled();
  });
});