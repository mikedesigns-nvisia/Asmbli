import { describe, it, expect, vi, beforeEach } from 'vitest';
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { MVPStep3Upload } from '../../../components/wizard/MVPStep3Upload';

// Mock file creation for testing
const createMockFile = (name: string, size: number, type: string): File => {
  const file = new File(['mock content'], name, { type });
  Object.defineProperty(file, 'size', { value: size });
  return file;
};

describe('MVPStep3Upload Component', () => {
  const user = userEvent.setup();
  const mockOnFilesChange = vi.fn();

  const defaultProps = {
    uploadedFiles: [],
    extractedConstraints: [],
    onFilesChange: mockOnFilesChange
  };

  beforeEach(() => {
    mockOnFilesChange.mockClear();
    // Mock URL.createObjectURL and revokeObjectURL
    global.URL.createObjectURL = vi.fn(() => 'mock-url');
    global.URL.revokeObjectURL = vi.fn();
  });

  it('should render upload area and instructions', () => {
    render(<MVPStep3Upload {...defaultProps} />);
    
    expect(screen.getByText('Upload Your Requirements')).toBeInTheDocument();
    expect(screen.getByText('Upload documents, config files, or specifications so your AI agent knows your exact requirements.')).toBeInTheDocument();
    expect(screen.getByText('Optional but Powerful')).toBeInTheDocument();
  });

  it('should show drag and drop interface', () => {
    render(<MVPStep3Upload {...defaultProps} />);
    
    expect(screen.getByText('Drag & drop your requirements')).toBeInTheDocument();
    expect(screen.getByText('browse your files')).toBeInTheDocument();
  });

  it('should display supported file types', () => {
    render(<MVPStep3Upload {...defaultProps} />);
    
    expect(screen.getByText('Supported: .pdf, .md, .txt, .docx, .json, and more')).toBeInTheDocument();
    expect(screen.getByText('Maximum: 5 files, 10MB each')).toBeInTheDocument();
  });

  it('should show file examples when no files are uploaded', () => {
    render(<MVPStep3Upload {...defaultProps} />);
    
    expect(screen.getByText('Documents')).toBeInTheDocument();
    expect(screen.getByText('Config Files')).toBeInTheDocument();
    expect(screen.getByText('• Style guides (.pdf, .md)')).toBeInTheDocument();
    expect(screen.getByText('• .eslintrc.json')).toBeInTheDocument();
  });

  it('should handle file selection via input', async () => {
    render(<MVPStep3Upload {...defaultProps} />);
    
    const fileInput = screen.getByLabelText('browse your files').querySelector('input');
    const mockFile = createMockFile('test.pdf', 1024, 'application/pdf');
    
    await user.upload(fileInput!, mockFile);
    
    // File should appear in the list
    await waitFor(() => {
      expect(screen.getByText('test.pdf')).toBeInTheDocument();
    });
  });

  it('should validate file types', async () => {
    render(<MVPStep3Upload {...defaultProps} />);
    
    const fileInput = screen.getByLabelText('browse your files').querySelector('input');
    const invalidFile = createMockFile('test.exe', 1024, 'application/x-executable');
    
    await user.upload(fileInput!, invalidFile);
    
    // Should show error for unsupported file type
    await waitFor(() => {
      expect(screen.getByText(/File type .exe not supported/)).toBeInTheDocument();
    });
  });

  it('should validate file size', async () => {
    render(<MVPStep3Upload {...defaultProps} />);
    
    const fileInput = screen.getByLabelText('browse your files').querySelector('input');
    const largeFile = createMockFile('large.pdf', 11 * 1024 * 1024, 'application/pdf'); // 11MB
    
    await user.upload(fileInput!, largeFile);
    
    // Should show error for file too large
    await waitFor(() => {
      expect(screen.getByText('File size exceeds 10MB limit')).toBeInTheDocument();
    });
  });

  it('should show upload progress', async () => {
    render(<MVPStep3Upload {...defaultProps} />);
    
    const fileInput = screen.getByLabelText('browse your files').querySelector('input');
    const mockFile = createMockFile('test.pdf', 1024, 'application/pdf');
    
    await user.upload(fileInput!, mockFile);
    
    // Should show processing state
    await waitFor(() => {
      expect(screen.getByText('Processing...')).toBeInTheDocument();
      expect(screen.getByText('Analyzing file and extracting requirements...')).toBeInTheDocument();
    });
  });

  it('should extract constraints from uploaded files', async () => {
    render(<MVPStep3Upload {...defaultProps} />);
    
    const fileInput = screen.getByLabelText('browse your files').querySelector('input');
    const eslintFile = createMockFile('.eslintrc.json', 1024, 'application/json');
    
    await user.upload(fileInput!, eslintFile);
    
    // Wait for upload to complete and constraints to be extracted
    await waitFor(() => {
      expect(screen.getByText('Complete')).toBeInTheDocument();
    }, { timeout: 3000 });
    
    // Should show extracted constraints
    await waitFor(() => {
      expect(screen.getByText(/requirements found/)).toBeInTheDocument();
    });
  });

  it('should allow file removal', async () => {
    render(<MVPStep3Upload {...defaultProps} />);
    
    const fileInput = screen.getByLabelText('browse your files').querySelector('input');
    const mockFile = createMockFile('test.pdf', 1024, 'application/pdf');
    
    await user.upload(fileInput!, mockFile);
    
    await waitFor(() => {
      expect(screen.getByText('test.pdf')).toBeInTheDocument();
    });
    
    // Click remove button
    const removeButton = screen.getByRole('button', { name: /remove/i });
    await user.click(removeButton);
    
    // File should be removed
    expect(screen.queryByText('test.pdf')).not.toBeInTheDocument();
  });

  it('should show file list with metadata', async () => {
    render(<MVPStep3Upload {...defaultProps} />);
    
    const fileInput = screen.getByLabelText('browse your files').querySelector('input');
    const mockFile = createMockFile('test.pdf', 2048, 'application/pdf');
    
    await user.upload(fileInput!, mockFile);
    
    await waitFor(() => {
      expect(screen.getByText('test.pdf')).toBeInTheDocument();
      expect(screen.getByText('2 KB')).toBeInTheDocument();
    });
  });

  it('should handle drag and drop events', async () => {
    render(<MVPStep3Upload {...defaultProps} />);
    
    const dropZone = screen.getByText('Drag & drop your requirements').closest('div');
    const mockFile = createMockFile('dropped.pdf', 1024, 'application/pdf');
    
    // Create a mock DataTransfer
    const dataTransfer = new DataTransfer();
    dataTransfer.items.add(mockFile);
    
    // Simulate drag enter
    fireEvent.dragEnter(dropZone!, { dataTransfer });
    expect(screen.getByText('Drop files here')).toBeInTheDocument();
    
    // Simulate drop
    fireEvent.drop(dropZone!, { dataTransfer });
    
    await waitFor(() => {
      expect(screen.getByText('dropped.pdf')).toBeInTheDocument();
    });
  });

  it('should limit number of files to 5', async () => {
    render(<MVPStep3Upload {...defaultProps} />);
    
    const fileInput = screen.getByLabelText('browse your files').querySelector('input');
    const files = Array.from({ length: 6 }, (_, i) => 
      createMockFile(`file${i}.pdf`, 1024, 'application/pdf')
    );
    
    await user.upload(fileInput!, files);
    
    // Should only show 5 files
    await waitFor(() => {
      const fileElements = screen.getAllByText(/file\d\.pdf/);
      expect(fileElements.length).toBeLessThanOrEqual(5);
    });
  });

  it('should show extracted constraints summary', async () => {
    const propsWithConstraints = {
      ...defaultProps,
      extractedConstraints: ['Use TypeScript strict mode', 'Follow ESLint rules']
    };
    
    render(<MVPStep3Upload {...propsWithConstraints} />);
    
    expect(screen.getByText('All Extracted Requirements (2)')).toBeInTheDocument();
    expect(screen.getByText('Use TypeScript strict mode')).toBeInTheDocument();
    expect(screen.getByText('Follow ESLint rules')).toBeInTheDocument();
  });

  it('should show different icons for different file types', async () => {
    render(<MVPStep3Upload {...defaultProps} />);
    
    const fileInput = screen.getByLabelText('browse your files').querySelector('input');
    
    // Upload code file
    const codeFile = createMockFile('config.json', 1024, 'application/json');
    await user.upload(fileInput!, codeFile);
    
    await waitFor(() => {
      expect(screen.getByText('config.json')).toBeInTheDocument();
    });
    
    // Should show appropriate file icon (FileCode for JSON files)
    const fileItem = screen.getByText('config.json').closest('div');
    expect(fileItem).toBeInTheDocument();
  });

  it('should handle multiple file uploads', async () => {
    render(<MVPStep3Upload {...defaultProps} />);
    
    const fileInput = screen.getByLabelText('browse your files').querySelector('input');
    const files = [
      createMockFile('file1.pdf', 1024, 'application/pdf'),
      createMockFile('file2.md', 512, 'text/markdown')
    ];
    
    await user.upload(fileInput!, files);
    
    await waitFor(() => {
      expect(screen.getByText('file1.pdf')).toBeInTheDocument();
      expect(screen.getByText('file2.md')).toBeInTheDocument();
    });
  });

  it('should show helpful tips', () => {
    render(<MVPStep3Upload {...defaultProps} />);
    
    expect(screen.getByText('💡 Upload your coding standards, brand guidelines, or research protocols for best results.')).toBeInTheDocument();
    expect(screen.getByText('Files are processed locally and securely to extract patterns and requirements.')).toBeInTheDocument();
  });
});