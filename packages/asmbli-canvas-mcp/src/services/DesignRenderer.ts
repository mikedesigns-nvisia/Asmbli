import { CanvasEngine } from '../canvas/CanvasEngine';
import { CanvasElement, ElementType, DesignSystem } from '../types';

interface DesignIntent {
  type: 'login' | 'dashboard' | 'landing' | 'form' | 'card' | 'list' | 'generic';
  components: string[];
  layout: 'vertical' | 'horizontal' | 'grid';
  style?: string;
}

export class DesignRenderer {
  constructor(private canvas: CanvasEngine) {}

  async renderFromDescription(
    description: string,
    designSystemId: string,
    style?: 'material3' | 'ios' | 'fluent' | 'minimal'
  ): Promise<CanvasElement[]> {
    // Parse the description to understand intent
    const intent = this.parseIntent(description);
    
    // Clear canvas for new design
    this.canvas.clear();
    
    // Render based on intent
    switch (intent.type) {
      case 'login':
        return this.renderLoginScreen();
      case 'dashboard':
        return this.renderDashboard();
      case 'landing':
        return this.renderLandingPage();
      case 'form':
        return this.renderForm(intent);
      case 'card':
        return this.renderCard(intent);
      case 'list':
        return this.renderList(intent);
      default:
        return this.renderGeneric(intent);
    }
  }

  private parseIntent(description: string): DesignIntent {
    const lower = description.toLowerCase();
    
    // Detect type
    let type: DesignIntent['type'] = 'generic';
    if (lower.includes('login') || lower.includes('sign in') || lower.includes('auth')) {
      type = 'login';
    } else if (lower.includes('dashboard') || lower.includes('analytics') || lower.includes('metrics')) {
      type = 'dashboard';
    } else if (lower.includes('landing') || lower.includes('hero') || lower.includes('homepage')) {
      type = 'landing';
    } else if (lower.includes('form') || lower.includes('input') || lower.includes('fields')) {
      type = 'form';
    } else if (lower.includes('card') || lower.includes('product') || lower.includes('item')) {
      type = 'card';
    } else if (lower.includes('list') || lower.includes('table') || lower.includes('grid')) {
      type = 'list';
    }
    
    // Detect components mentioned
    const components: string[] = [];
    if (lower.includes('button')) components.push('button');
    if (lower.includes('input') || lower.includes('field')) components.push('input');
    if (lower.includes('image') || lower.includes('photo')) components.push('image');
    if (lower.includes('text') || lower.includes('label')) components.push('text');
    if (lower.includes('card')) components.push('card');
    
    // Detect layout
    let layout: DesignIntent['layout'] = 'vertical';
    if (lower.includes('horizontal') || lower.includes('row')) {
      layout = 'horizontal';
    } else if (lower.includes('grid') || lower.includes('columns')) {
      layout = 'grid';
    }
    
    return { type, components, layout };
  }

  private renderLoginScreen(): CanvasElement[] {
    const elements: CanvasElement[] = [];
    
    // Container
    const container = this.canvas.addElement({
      type: ElementType.CONTAINER,
      x: 200,
      y: 50,
      width: 400,
      height: 500,
      style: {
        backgroundColor: '#ffffff',
        borderRadius: 16,
        padding: 32,
        boxShadow: '0 4px 16px rgba(0,0,0,0.1)',
      },
    });
    
    // Logo/Title
    this.canvas.addElement({
      type: ElementType.TEXT,
      x: 250,
      y: 100,
      width: 300,
      height: 40,
      text: 'Welcome Back',
      style: {
        fontSize: 32,
        fontWeight: 'bold',
        color: '#1a1a1a',
        textAlign: 'center',
      },
    });
    
    // Subtitle
    this.canvas.addElement({
      type: ElementType.TEXT,
      x: 250,
      y: 150,
      width: 300,
      height: 24,
      text: 'Sign in to continue',
      style: {
        fontSize: 16,
        color: '#666666',
        textAlign: 'center',
      },
    });
    
    // Email input
    this.canvas.addElement({
      type: ElementType.INPUT,
      x: 250,
      y: 220,
      width: 300,
      height: 56,
      placeholder: 'Email address',
      component: 'textField',
      variant: 'outlined',
    });
    
    // Password input
    this.canvas.addElement({
      type: ElementType.INPUT,
      x: 250,
      y: 290,
      width: 300,
      height: 56,
      placeholder: 'Password',
      component: 'textField',
      variant: 'outlined',
    });
    
    // Remember me checkbox area
    this.canvas.addElement({
      type: ElementType.TEXT,
      x: 250,
      y: 360,
      width: 150,
      height: 24,
      text: '☐ Remember me',
      style: {
        fontSize: 14,
        color: '#666666',
      },
    });
    
    // Forgot password link
    this.canvas.addElement({
      type: ElementType.TEXT,
      x: 400,
      y: 360,
      width: 150,
      height: 24,
      text: 'Forgot password?',
      style: {
        fontSize: 14,
        color: '#6750A4',
        textAlign: 'right',
      },
    });
    
    // Sign in button
    this.canvas.addElement({
      type: ElementType.BUTTON,
      x: 250,
      y: 410,
      width: 300,
      height: 48,
      text: 'Sign In',
      component: 'button',
      variant: 'filled',
    });
    
    // Divider
    this.canvas.addElement({
      type: ElementType.TEXT,
      x: 250,
      y: 480,
      width: 300,
      height: 20,
      text: '———— OR ————',
      style: {
        fontSize: 12,
        color: '#999999',
        textAlign: 'center',
      },
    });
    
    // Social login button
    this.canvas.addElement({
      type: ElementType.BUTTON,
      x: 250,
      y: 510,
      width: 300,
      height: 48,
      text: 'Continue with Google',
      component: 'button',
      variant: 'outlined',
    });
    
    return this.canvas.getState().elements;
  }

  private renderDashboard(): CanvasElement[] {
    // Sidebar
    this.canvas.addElement({
      type: ElementType.CONTAINER,
      x: 0,
      y: 0,
      width: 240,
      height: 600,
      style: {
        backgroundColor: '#f5f5f5',
        borderRight: '1px solid #e0e0e0',
      },
    });
    
    // Main content area
    this.canvas.addElement({
      type: ElementType.CONTAINER,
      x: 240,
      y: 0,
      width: 560,
      height: 600,
      style: {
        backgroundColor: '#ffffff',
        padding: 24,
      },
    });
    
    // Dashboard title
    this.canvas.addElement({
      type: ElementType.TEXT,
      x: 264,
      y: 24,
      width: 300,
      height: 36,
      text: 'Dashboard Overview',
      style: {
        fontSize: 28,
        fontWeight: 'bold',
        color: '#1a1a1a',
      },
    });
    
    // Metric cards
    const metrics = [
      { label: 'Total Users', value: '12,543', color: '#6750A4' },
      { label: 'Active Sessions', value: '3,421', color: '#625B71' },
      { label: 'Revenue', value: '$45,231', color: '#7D5260' },
    ];
    
    metrics.forEach((metric, index) => {
      this.canvas.addElement({
        type: ElementType.CARD,
        x: 264 + (index * 170),
        y: 80,
        width: 160,
        height: 100,
        component: 'card',
        variant: 'elevated',
      });
      
      this.canvas.addElement({
        type: ElementType.TEXT,
        x: 276 + (index * 170),
        y: 100,
        width: 136,
        height: 20,
        text: metric.label,
        style: {
          fontSize: 14,
          color: '#666666',
        },
      });
      
      this.canvas.addElement({
        type: ElementType.TEXT,
        x: 276 + (index * 170),
        y: 130,
        width: 136,
        height: 32,
        text: metric.value,
        style: {
          fontSize: 24,
          fontWeight: 'bold',
          color: metric.color,
        },
      });
    });
    
    // Chart placeholder
    this.canvas.addElement({
      type: ElementType.CONTAINER,
      x: 264,
      y: 200,
      width: 512,
      height: 300,
      style: {
        backgroundColor: '#f8f9fa',
        borderRadius: 8,
        border: '1px solid #e0e0e0',
      },
    });
    
    this.canvas.addElement({
      type: ElementType.TEXT,
      x: 400,
      y: 340,
      width: 240,
      height: 24,
      text: '📊 Chart Visualization Area',
      style: {
        fontSize: 16,
        color: '#999999',
        textAlign: 'center',
      },
    });
    
    return this.canvas.getState().elements;
  }

  private renderLandingPage(): CanvasElement[] {
    // Hero section
    this.canvas.addElement({
      type: ElementType.CONTAINER,
      x: 0,
      y: 0,
      width: 800,
      height: 400,
      style: {
        backgroundColor: '#6750A4',
        backgroundGradient: {
          type: 'linear',
          colors: ['#6750A4', '#8875D7'],
          angle: 135,
        },
      },
    });
    
    // Hero text
    this.canvas.addElement({
      type: ElementType.TEXT,
      x: 100,
      y: 100,
      width: 600,
      height: 60,
      text: 'Build Beautiful UIs Faster',
      style: {
        fontSize: 48,
        fontWeight: 'bold',
        color: '#ffffff',
        textAlign: 'center',
      },
    });
    
    // Subtitle
    this.canvas.addElement({
      type: ElementType.TEXT,
      x: 100,
      y: 180,
      width: 600,
      height: 30,
      text: 'Design, prototype, and ship with our visual canvas',
      style: {
        fontSize: 20,
        color: '#ffffff',
        textAlign: 'center',
        opacity: 0.9,
      },
    });
    
    // CTA buttons
    this.canvas.addElement({
      type: ElementType.BUTTON,
      x: 250,
      y: 250,
      width: 140,
      height: 48,
      text: 'Get Started',
      style: {
        backgroundColor: '#ffffff',
        color: '#6750A4',
        borderRadius: 24,
        fontSize: 16,
        fontWeight: 'bold',
      },
    });
    
    this.canvas.addElement({
      type: ElementType.BUTTON,
      x: 410,
      y: 250,
      width: 140,
      height: 48,
      text: 'Learn More',
      style: {
        backgroundColor: 'transparent',
        color: '#ffffff',
        borderRadius: 24,
        borderWidth: 2,
        borderColor: '#ffffff',
        fontSize: 16,
        fontWeight: 'bold',
      },
    });
    
    // Features section
    const features = [
      { icon: '🎨', title: 'Visual Design', desc: 'Drag and drop interface' },
      { icon: '⚡', title: 'Fast Export', desc: 'Generate production code' },
      { icon: '🎯', title: 'Design Systems', desc: 'Built-in components' },
    ];
    
    features.forEach((feature, index) => {
      const x = 100 + (index * 240);
      
      this.canvas.addElement({
        type: ElementType.CARD,
        x,
        y: 450,
        width: 200,
        height: 150,
        component: 'card',
        variant: 'outlined',
      });
      
      this.canvas.addElement({
        type: ElementType.TEXT,
        x: x + 75,
        y: 470,
        width: 50,
        height: 40,
        text: feature.icon,
        style: {
          fontSize: 32,
          textAlign: 'center',
        },
      });
      
      this.canvas.addElement({
        type: ElementType.TEXT,
        x: x + 20,
        y: 520,
        width: 160,
        height: 24,
        text: feature.title,
        style: {
          fontSize: 18,
          fontWeight: 'bold',
          textAlign: 'center',
          color: '#1a1a1a',
        },
      });
      
      this.canvas.addElement({
        type: ElementType.TEXT,
        x: x + 20,
        y: 550,
        width: 160,
        height: 20,
        text: feature.desc,
        style: {
          fontSize: 14,
          textAlign: 'center',
          color: '#666666',
        },
      });
    });
    
    return this.canvas.getState().elements;
  }

  private renderForm(intent: DesignIntent): CanvasElement[] {
    // Form container
    this.canvas.addElement({
      type: ElementType.CONTAINER,
      x: 150,
      y: 50,
      width: 500,
      height: 500,
      style: {
        backgroundColor: '#ffffff',
        borderRadius: 12,
        padding: 32,
        boxShadow: '0 2px 8px rgba(0,0,0,0.1)',
      },
    });
    
    // Form title
    this.canvas.addElement({
      type: ElementType.TEXT,
      x: 182,
      y: 82,
      width: 436,
      height: 32,
      text: 'Contact Form',
      style: {
        fontSize: 24,
        fontWeight: 'bold',
        color: '#1a1a1a',
      },
    });
    
    // Form fields
    const fields = [
      { label: 'Full Name', placeholder: 'John Doe' },
      { label: 'Email', placeholder: 'john@example.com' },
      { label: 'Phone', placeholder: '+1 (555) 123-4567' },
      { label: 'Message', placeholder: 'Your message here...' },
    ];
    
    fields.forEach((field, index) => {
      const y = 140 + (index * 80);
      
      // Label
      this.canvas.addElement({
        type: ElementType.TEXT,
        x: 182,
        y: y,
        width: 200,
        height: 20,
        text: field.label,
        style: {
          fontSize: 14,
          color: '#666666',
          fontWeight: '500',
        },
      });
      
      // Input
      this.canvas.addElement({
        type: ElementType.INPUT,
        x: 182,
        y: y + 24,
        width: 436,
        height: index === 3 ? 80 : 48,
        placeholder: field.placeholder,
        component: 'textField',
        variant: 'outlined',
      });
    });
    
    // Submit button
    this.canvas.addElement({
      type: ElementType.BUTTON,
      x: 182,
      y: 480,
      width: 200,
      height: 48,
      text: 'Submit',
      component: 'button',
      variant: 'filled',
    });
    
    return this.canvas.getState().elements;
  }

  private renderCard(intent: DesignIntent): CanvasElement[] {
    // Product card
    this.canvas.addElement({
      type: ElementType.CARD,
      x: 250,
      y: 100,
      width: 300,
      height: 400,
      component: 'card',
      variant: 'elevated',
    });
    
    // Product image placeholder
    this.canvas.addElement({
      type: ElementType.CONTAINER,
      x: 250,
      y: 100,
      width: 300,
      height: 200,
      style: {
        backgroundColor: '#f5f5f5',
        borderTopLeftRadius: 12,
        borderTopRightRadius: 12,
      },
    });
    
    this.canvas.addElement({
      type: ElementType.TEXT,
      x: 350,
      y: 180,
      width: 100,
      height: 40,
      text: '📷',
      style: {
        fontSize: 40,
        textAlign: 'center',
      },
    });
    
    // Product details
    this.canvas.addElement({
      type: ElementType.TEXT,
      x: 270,
      y: 320,
      width: 260,
      height: 24,
      text: 'Product Name',
      style: {
        fontSize: 20,
        fontWeight: 'bold',
        color: '#1a1a1a',
      },
    });
    
    this.canvas.addElement({
      type: ElementType.TEXT,
      x: 270,
      y: 350,
      width: 260,
      height: 20,
      text: 'Brief product description goes here',
      style: {
        fontSize: 14,
        color: '#666666',
      },
    });
    
    // Price
    this.canvas.addElement({
      type: ElementType.TEXT,
      x: 270,
      y: 380,
      width: 100,
      height: 28,
      text: '$99.99',
      style: {
        fontSize: 24,
        fontWeight: 'bold',
        color: '#6750A4',
      },
    });
    
    // Action button
    this.canvas.addElement({
      type: ElementType.BUTTON,
      x: 270,
      y: 430,
      width: 260,
      height: 48,
      text: 'Add to Cart',
      component: 'button',
      variant: 'filled',
    });
    
    return this.canvas.getState().elements;
  }

  private renderList(intent: DesignIntent): CanvasElement[] {
    // List container
    this.canvas.addElement({
      type: ElementType.CONTAINER,
      x: 100,
      y: 50,
      width: 600,
      height: 500,
      style: {
        backgroundColor: '#ffffff',
        borderRadius: 8,
        border: '1px solid #e0e0e0',
      },
    });
    
    // List header
    this.canvas.addElement({
      type: ElementType.CONTAINER,
      x: 100,
      y: 50,
      width: 600,
      height: 56,
      style: {
        backgroundColor: '#f5f5f5',
        borderTopLeftRadius: 8,
        borderTopRightRadius: 8,
        borderBottom: '1px solid #e0e0e0',
      },
    });
    
    this.canvas.addElement({
      type: ElementType.TEXT,
      x: 120,
      y: 68,
      width: 200,
      height: 20,
      text: 'Items List',
      style: {
        fontSize: 16,
        fontWeight: 'bold',
        color: '#1a1a1a',
      },
    });
    
    // List items
    const items = ['First Item', 'Second Item', 'Third Item', 'Fourth Item'];
    
    items.forEach((item, index) => {
      const y = 106 + (index * 72);
      
      // Item container
      this.canvas.addElement({
        type: ElementType.CONTAINER,
        x: 100,
        y: y,
        width: 600,
        height: 72,
        style: {
          backgroundColor: '#ffffff',
          borderBottom: '1px solid #f0f0f0',
        },
      });
      
      // Item content
      this.canvas.addElement({
        type: ElementType.TEXT,
        x: 120,
        y: y + 16,
        width: 400,
        height: 24,
        text: item,
        style: {
          fontSize: 16,
          color: '#1a1a1a',
        },
      });
      
      this.canvas.addElement({
        type: ElementType.TEXT,
        x: 120,
        y: y + 40,
        width: 400,
        height: 16,
        text: `Description for ${item.toLowerCase()}`,
        style: {
          fontSize: 12,
          color: '#666666',
        },
      });
      
      // Action icon
      this.canvas.addElement({
        type: ElementType.TEXT,
        x: 640,
        y: y + 26,
        width: 40,
        height: 20,
        text: '›',
        style: {
          fontSize: 20,
          color: '#999999',
          textAlign: 'center',
        },
      });
    });
    
    return this.canvas.getState().elements;
  }

  private renderGeneric(intent: DesignIntent): CanvasElement[] {
    // Create a simple layout based on detected components
    let y = 50;
    
    if (intent.components.includes('text') || intent.components.length === 0) {
      this.canvas.addElement({
        type: ElementType.TEXT,
        x: 100,
        y: y,
        width: 600,
        height: 40,
        text: 'Generated UI Design',
        style: {
          fontSize: 32,
          fontWeight: 'bold',
          color: '#1a1a1a',
          textAlign: 'center',
        },
      });
      y += 80;
    }
    
    if (intent.components.includes('card')) {
      this.canvas.addElement({
        type: ElementType.CARD,
        x: 200,
        y: y,
        width: 400,
        height: 200,
        component: 'card',
        variant: 'elevated',
      });
      y += 240;
    }
    
    if (intent.components.includes('input')) {
      this.canvas.addElement({
        type: ElementType.INPUT,
        x: 200,
        y: y,
        width: 400,
        height: 56,
        placeholder: 'Enter text...',
        component: 'textField',
        variant: 'outlined',
      });
      y += 80;
    }
    
    if (intent.components.includes('button')) {
      this.canvas.addElement({
        type: ElementType.BUTTON,
        x: 300,
        y: y,
        width: 200,
        height: 48,
        text: 'Click Me',
        component: 'button',
        variant: 'filled',
      });
    }
    
    return this.canvas.getState().elements;
  }
}