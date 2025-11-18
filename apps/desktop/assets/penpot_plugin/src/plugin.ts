/**
 * Asmbli Penpot Plugin
 *
 * Provides programmatic control of Penpot for AI design agents via MCP protocol.
 * Communicates with Flutter app through JavaScript bridge.
 */

// Message types from agent (Flutter app)
interface AgentMessage {
  source: 'asmbli-agent';
  type: string;
  params: any;
  requestId: string;
  timestamp: string;
}

// Response types to agent
interface PluginResponse {
  source: 'asmbli-plugin';
  type: string;
  requestId: string;
  success: boolean;
  data?: any;
  error?: string;
  timestamp: string;
}

class AsmbliPenpotPlugin {
  private isInitialized = false;

  constructor() {
    this.initialize();
  }

  private initialize() {
    console.log('🚀 Asmbli Penpot Plugin initializing...');

    // Listen for messages from Flutter app
    window.addEventListener('message', this.handleMessage.bind(this));

    // Wait for Penpot API to be available
    this.waitForPenpotAPI();
  }

  private async waitForPenpotAPI() {
    // Check if Penpot plugin API is available
    const checkAPI = () => {
      if ((window as any).penpot) {
        this.isInitialized = true;
        console.log('✅ Penpot API ready');
        this.sendPluginReady();
        return true;
      }
      return false;
    };

    // Try immediately
    if (checkAPI()) return;

    // Poll for API (Penpot might still be loading)
    const pollInterval = setInterval(() => {
      if (checkAPI()) {
        clearInterval(pollInterval);
      }
    }, 100);

    // Timeout after 10 seconds
    setTimeout(() => {
      clearInterval(pollInterval);
      if (!this.isInitialized) {
        console.error('❌ Penpot API not available after 10s');
        this.sendResponse({
          type: 'plugin_error',
          requestId: 'init',
          success: false,
          error: 'Penpot API not available',
        });
      }
    }, 10000);
  }

  private sendPluginReady() {
    this.sendToBridge({
      source: 'asmbli-plugin',
      type: 'plugin_ready',
      requestId: 'init',
      success: true,
      timestamp: new Date().toISOString(),
    });
  }

  private sendToBridge(message: PluginResponse) {
    // Send to Flutter via JavaScript channel
    if ((window as any).asmbli_bridge) {
      (window as any).asmbli_bridge.postMessage(JSON.stringify(message));
    } else {
      console.warn('⚠️ asmbli_bridge not available, using postMessage fallback');
      window.postMessage(message, '*');
    }
  }

  private handleMessage(event: MessageEvent) {
    try {
      const message = event.data as AgentMessage;

      // Only handle messages from our agent
      if (message.source !== 'asmbli-agent') return;

      console.log(`📥 Received command: ${message.type}`);

      this.executeCommand(message);
    } catch (error) {
      console.error('❌ Error handling message:', error);
    }
  }

  private async executeCommand(message: AgentMessage) {
    const { type, params, requestId } = message;

    try {
      let result: any;

      switch (type) {
        case 'create_rectangle':
          result = await this.createRectangle(params);
          break;

        case 'create_text':
          result = await this.createText(params);
          break;

        case 'create_frame':
          result = await this.createFrame(params);
          break;

        case 'get_canvas_state':
          result = await this.getCanvasState();
          break;

        case 'clear_canvas':
          result = await this.clearCanvas();
          break;

        case 'create_ellipse':
          result = await this.createEllipse(params);
          break;

        case 'create_path':
          result = await this.createPath(params);
          break;

        case 'create_image':
          result = await this.createImage(params);
          break;

        case 'create_component':
          result = await this.createComponent(params);
          break;

        case 'create_color_style':
          result = await this.createColorStyle(params);
          break;

        case 'create_typography_style':
          result = await this.createTypographyStyle(params);
          break;

        case 'apply_layout_constraints':
          result = await this.applyLayoutConstraints(params);
          break;

        default:
          throw new Error(`Unknown command type: ${type}`);
      }

      this.sendResponse({
        type: `${type}_response`,
        requestId,
        success: true,
        data: result,
      });

    } catch (error: any) {
      console.error(`❌ Error executing ${type}:`, error);

      this.sendResponse({
        type: `${type}_response`,
        requestId,
        success: false,
        error: error.message || 'Unknown error',
      });
    }
  }

  private sendResponse(response: Omit<PluginResponse, 'source' | 'timestamp'>) {
    this.sendToBridge({
      ...response,
      source: 'asmbli-plugin',
      timestamp: new Date().toISOString(),
    });
  }

  // ========== PENPOT OPERATIONS ==========

  private async createRectangle(params: {
    x?: number;
    y?: number;
    width?: number;
    height?: number;
    fill?: string;
    stroke?: string;
    strokeWidth?: number;
    borderRadius?: number;
    name?: string;
  }) {
    const penpot = (window as any).penpot;
    if (!penpot) throw new Error('Penpot API not available');

    // Create rectangle using Penpot API
    const rect = penpot.createRectangle();

    // Set properties
    if (params.x !== undefined) rect.x = params.x;
    if (params.y !== undefined) rect.y = params.y;
    if (params.width !== undefined) rect.width = params.width;
    if (params.height !== undefined) rect.height = params.height;
    if (params.fill) rect.fills = [{ fillColor: params.fill }];
    if (params.stroke) rect.strokes = [{ strokeColor: params.stroke }];
    if (params.strokeWidth !== undefined) rect.strokeWidth = params.strokeWidth;
    if (params.borderRadius !== undefined) rect.borderRadius = params.borderRadius;
    if (params.name) rect.name = params.name;

    return {
      id: rect.id,
      type: 'rectangle',
      name: rect.name,
      x: rect.x,
      y: rect.y,
      width: rect.width,
      height: rect.height,
    };
  }

  private async createText(params: {
    x?: number;
    y?: number;
    content: string;
    fontSize?: number;
    fontFamily?: string;
    fontWeight?: number;
    color?: string;
    name?: string;
  }) {
    const penpot = (window as any).penpot;
    if (!penpot) throw new Error('Penpot API not available');

    const text = penpot.createText(params.content);

    if (params.x !== undefined) text.x = params.x;
    if (params.y !== undefined) text.y = params.y;
    if (params.fontSize) text.fontSize = params.fontSize;
    if (params.fontFamily) text.fontFamily = params.fontFamily;
    if (params.fontWeight) text.fontWeight = params.fontWeight;
    if (params.color) text.fills = [{ fillColor: params.color }];
    if (params.name) text.name = params.name;

    return {
      id: text.id,
      type: 'text',
      name: text.name,
      content: params.content,
      x: text.x,
      y: text.y,
    };
  }

  private async createFrame(params: {
    x?: number;
    y?: number;
    width?: number;
    height?: number;
    name?: string;
    children?: any[];
  }) {
    const penpot = (window as any).penpot;
    if (!penpot) throw new Error('Penpot API not available');

    const frame = penpot.createFrame();

    if (params.x !== undefined) frame.x = params.x;
    if (params.y !== undefined) frame.y = params.y;
    if (params.width !== undefined) frame.width = params.width;
    if (params.height !== undefined) frame.height = params.height;
    if (params.name) frame.name = params.name;

    // TODO: Handle children elements recursively

    return {
      id: frame.id,
      type: 'frame',
      name: frame.name,
      x: frame.x,
      y: frame.y,
      width: frame.width,
      height: frame.height,
    };
  }

  private async getCanvasState() {
    const penpot = (window as any).penpot;
    if (!penpot) throw new Error('Penpot API not available');

    // Get current page and all elements
    const currentPage = penpot.currentPage;
    const elements = currentPage ? currentPage.children : [];

    return {
      pageId: currentPage?.id,
      pageName: currentPage?.name,
      elementCount: elements.length,
      elements: elements.map((el: any) => ({
        id: el.id,
        type: el.type,
        name: el.name,
        x: el.x,
        y: el.y,
        width: el.width,
        height: el.height,
      })),
    };
  }

  private async clearCanvas() {
    const penpot = (window as any).penpot;
    if (!penpot) throw new Error('Penpot API not available');

    const currentPage = penpot.currentPage;
    if (!currentPage) throw new Error('No active page');

    // Remove all elements from current page
    const elements = currentPage.children || [];
    const count = elements.length;

    elements.forEach((el: any) => el.remove());

    return {
      cleared: true,
      elementsRemoved: count,
    };
  }

  // ========== WEEK 2: ADVANCED ELEMENT TYPES ==========

  private async createEllipse(params: {
    x?: number;
    y?: number;
    width?: number;
    height?: number;
    fill?: string;
    stroke?: string;
    strokeWidth?: number;
    name?: string;
  }) {
    const penpot = (window as any).penpot;
    if (!penpot) throw new Error('Penpot API not available');

    const ellipse = penpot.createEllipse();

    if (params.x !== undefined) ellipse.x = params.x;
    if (params.y !== undefined) ellipse.y = params.y;
    if (params.width !== undefined) ellipse.width = params.width;
    if (params.height !== undefined) ellipse.height = params.height;
    if (params.fill) ellipse.fills = [{ fillColor: params.fill }];
    if (params.stroke) ellipse.strokes = [{ strokeColor: params.stroke }];
    if (params.strokeWidth !== undefined) ellipse.strokeWidth = params.strokeWidth;
    if (params.name) ellipse.name = params.name;

    return {
      id: ellipse.id,
      type: 'ellipse',
      name: ellipse.name,
      x: ellipse.x,
      y: ellipse.y,
      width: ellipse.width,
      height: ellipse.height,
    };
  }

  private async createPath(params: {
    x?: number;
    y?: number;
    pathData: string;  // SVG path data
    fill?: string;
    stroke?: string;
    strokeWidth?: number;
    name?: string;
  }) {
    const penpot = (window as any).penpot;
    if (!penpot) throw new Error('Penpot API not available');

    const path = penpot.createPath();

    if (params.x !== undefined) path.x = params.x;
    if (params.y !== undefined) path.y = params.y;
    if (params.pathData) path.content = params.pathData;
    if (params.fill) path.fills = [{ fillColor: params.fill }];
    if (params.stroke) path.strokes = [{ strokeColor: params.stroke }];
    if (params.strokeWidth !== undefined) path.strokeWidth = params.strokeWidth;
    if (params.name) path.name = params.name;

    return {
      id: path.id,
      type: 'path',
      name: path.name,
      pathData: params.pathData,
    };
  }

  private async createImage(params: {
    x?: number;
    y?: number;
    width?: number;
    height?: number;
    dataUrl: string;  // Base64 data URL
    name?: string;
  }) {
    const penpot = (window as any).penpot;
    if (!penpot) throw new Error('Penpot API not available');

    const image = penpot.uploadMediaUrl(params.name || 'image', params.dataUrl);

    if (params.x !== undefined) image.x = params.x;
    if (params.y !== undefined) image.y = params.y;
    if (params.width !== undefined) image.width = params.width;
    if (params.height !== undefined) image.height = params.height;

    return {
      id: image.id,
      type: 'image',
      name: image.name,
      x: image.x,
      y: image.y,
      width: image.width,
      height: image.height,
    };
  }

  // ========== COMPONENT SYSTEM ==========

  private async createComponent(params: {
    elementIds: string[];  // IDs of elements to convert to component
    name: string;
  }) {
    const penpot = (window as any).penpot;
    if (!penpot) throw new Error('Penpot API not available');

    // Get elements by ID
    const elements = params.elementIds.map(id => penpot.getShapeById(id));

    if (elements.length === 0) {
      throw new Error('No elements found to create component');
    }

    // Create component from elements
    const component = penpot.createComponentFromShapes(elements);
    if (params.name) component.name = params.name;

    return {
      id: component.id,
      type: 'component',
      name: component.name,
      elementCount: elements.length,
    };
  }

  // ========== STYLE MANAGEMENT ==========

  private async createColorStyle(params: {
    name: string;
    color: string;  // Hex color
  }) {
    const penpot = (window as any).penpot;
    if (!penpot) throw new Error('Penpot API not available');

    const colorStyle = penpot.createColorStyle({
      name: params.name,
      color: params.color,
    });

    return {
      id: colorStyle.id,
      type: 'color_style',
      name: colorStyle.name,
      color: params.color,
    };
  }

  private async createTypographyStyle(params: {
    name: string;
    fontFamily?: string;
    fontSize?: number;
    fontWeight?: number;
    lineHeight?: number;
    letterSpacing?: number;
  }) {
    const penpot = (window as any).penpot;
    if (!penpot) throw new Error('Penpot API not available');

    const typographyStyle = penpot.createTypographyStyle({
      name: params.name,
      fontFamily: params.fontFamily || 'Inter',
      fontSize: params.fontSize || 16,
      fontWeight: params.fontWeight || 400,
      lineHeight: params.lineHeight || 1.5,
      letterSpacing: params.letterSpacing || 0,
    });

    return {
      id: typographyStyle.id,
      type: 'typography_style',
      name: typographyStyle.name,
      fontFamily: params.fontFamily,
      fontSize: params.fontSize,
    };
  }

  // ========== LAYOUT CONSTRAINTS ==========

  private async applyLayoutConstraints(params: {
    elementId: string;
    constraints?: {
      horizontal?: 'left' | 'right' | 'leftright' | 'center' | 'scale';
      vertical?: 'top' | 'bottom' | 'topbottom' | 'center' | 'scale';
    };
    layout?: {
      type?: 'flex';
      direction?: 'row' | 'column';
      align?: 'start' | 'center' | 'end' | 'stretch';
      justify?: 'start' | 'center' | 'end' | 'space-between' | 'space-around';
      gap?: number;
      padding?: number;
    };
  }) {
    const penpot = (window as any).penpot;
    if (!penpot) throw new Error('Penpot API not available');

    const element = penpot.getShapeById(params.elementId);
    if (!element) throw new Error(`Element not found: ${params.elementId}`);

    // Apply constraints
    if (params.constraints) {
      if (params.constraints.horizontal) {
        element.horizontalConstraint = params.constraints.horizontal;
      }
      if (params.constraints.vertical) {
        element.verticalConstraint = params.constraints.vertical;
      }
    }

    // Apply layout (auto-layout / flexbox)
    if (params.layout) {
      element.layoutType = params.layout.type || 'flex';
      if (params.layout.direction) element.layoutDirection = params.layout.direction;
      if (params.layout.align) element.layoutAlign = params.layout.align;
      if (params.layout.justify) element.layoutJustify = params.layout.justify;
      if (params.layout.gap !== undefined) element.layoutGap = params.layout.gap;
      if (params.layout.padding !== undefined) element.layoutPadding = params.layout.padding;
    }

    return {
      id: element.id,
      type: element.type,
      name: element.name,
      constraints: params.constraints,
      layout: params.layout,
    };
  }
}

// Initialize plugin
const plugin = new AsmbliPenpotPlugin();

// Export for potential external access
(window as any).asmbliPlugin = plugin;

console.log('✅ Asmbli Penpot Plugin loaded (Week 2 - Advanced Features)');
