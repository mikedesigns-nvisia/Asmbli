/**
 * MCP Tool Registry
 * Manages and executes MCP tools for PenPOT canvas operations
 */

import type {
  CreateRectangleParams,
  CreateEllipseParams,
  CreateTextParams,
  CreateFrameParams,
  UpdateElementParams,
  QueryElementsParams,
  GetElementDetailsParams,
  RotateElementParams,
  ScaleElementParams,
  FlipElementParams,
  DeleteElementParams,
  DuplicateElementParams,
  GroupElementsParams,
  UngroupElementsParams,
  ReorderElementParams,
  AlignElementsParams,
  DistributeElementsParams,
  SetConstraintsParams,
  CreateComponentParams,
  DetachComponentParams,
  CreateComponentInstanceParams,
  ExportElementParams,
  ExportPageParams,
  ExportSelectionParams,
} from '../types/mcp';

export class MCPToolRegistry {
  private tools: Map<string, (params: any) => Promise<any>>;

  constructor() {
    this.tools = new Map();
    this.registerTools();
  }

  private registerTools() {
    // CREATE operations
    this.tools.set('createRectangle', this.createRectangle.bind(this));
    this.tools.set('createEllipse', this.createEllipse.bind(this));
    this.tools.set('createText', this.createText.bind(this));
    this.tools.set('createFrame', this.createFrame.bind(this));
    this.tools.set('clearCanvas', this.clearCanvas.bind(this));

    // UPDATE operations
    this.tools.set('updateElement', this.updateElement.bind(this));

    // QUERY operations
    this.tools.set('queryElements', this.queryElements.bind(this));
    this.tools.set('getCanvasState', this.getCanvasState.bind(this));
    this.tools.set('getElementDetails', this.getElementDetails.bind(this));

    // TRANSFORM operations
    this.tools.set('rotateElement', this.rotateElement.bind(this));
    this.tools.set('scaleElement', this.scaleElement.bind(this));
    this.tools.set('flipHorizontal', this.flipHorizontal.bind(this));
    this.tools.set('flipVertical', this.flipVertical.bind(this));

    // DELETE operations
    this.tools.set('deleteElement', this.deleteElement.bind(this));

    // DUPLICATE operations
    this.tools.set('duplicateElement', this.duplicateElement.bind(this));

    // GROUP operations
    this.tools.set('groupElements', this.groupElements.bind(this));
    this.tools.set('ungroupElements', this.ungroupElements.bind(this));

    // REORDER operations
    this.tools.set('bringToFront', this.bringToFront.bind(this));
    this.tools.set('sendToBack', this.sendToBack.bind(this));
    this.tools.set('bringForward', this.bringForward.bind(this));
    this.tools.set('sendBackward', this.sendBackward.bind(this));

    // HISTORY operations
    this.tools.set('undo', this.undo.bind(this));
    this.tools.set('redo', this.redo.bind(this));

    // LAYOUT operations
    this.tools.set('alignElements', this.alignElements.bind(this));
    this.tools.set('distributeElements', this.distributeElements.bind(this));
    this.tools.set('setConstraints', this.setConstraints.bind(this));

    // COMPONENT operations
    this.tools.set('createComponent', this.createComponent.bind(this));
    this.tools.set('detachComponent', this.detachComponent.bind(this));
    this.tools.set('createComponentInstance', this.createComponentInstance.bind(this));

    // EXPORT operations
    this.tools.set('exportElement', this.exportElement.bind(this));
    this.tools.set('exportPage', this.exportPage.bind(this));
    this.tools.set('exportSelection', this.exportSelection.bind(this));
  }

  async executeTool(toolName: string, parameters: any): Promise<any> {
    const tool = this.tools.get(toolName);

    if (!tool) {
      throw new Error(`Unknown tool: ${toolName}`);
    }

    return await tool(parameters);
  }

  getToolCount(): number {
    return this.tools.size;
  }

  // CREATE TOOLS

  private async createRectangle(params: CreateRectangleParams): Promise<any> {
    const { x, y, width, height, fillColor, strokeColor, strokeWidth, borderRadius } = params;

    // Create rectangle using PenPOT Plugin API
    const rect = penpot.createRectangle();

    // Set position and size
    rect.x = x;
    rect.y = y;
    rect.resize(width, height);

    // Set fill color
    if (fillColor) {
      rect.fills = [{ fillColor, fillOpacity: 1 }];
    }

    // Set stroke
    if (strokeColor && strokeWidth) {
      rect.strokes = [
        {
          strokeColor,
          strokeWidth,
          strokeAlignment: 'center',
        },
      ];
    }

    // Set border radius
    if (borderRadius) {
      rect.borderRadius = borderRadius;
    }

    return {
      elementId: rect.id,
      type: 'rectangle',
      x: rect.x,
      y: rect.y,
      width: rect.width,
      height: rect.height,
    };
  }

  private async createEllipse(params: CreateEllipseParams): Promise<any> {
    const { x, y, width, height, fillColor, strokeColor, strokeWidth } = params;

    // Create ellipse using PenPOT Plugin API
    const ellipse = penpot.createEllipse();

    // Set position and size
    ellipse.x = x;
    ellipse.y = y;
    ellipse.resize(width, height);

    // Set fill color
    if (fillColor) {
      ellipse.fills = [{ fillColor, fillOpacity: 1 }];
    }

    // Set stroke
    if (strokeColor && strokeWidth) {
      ellipse.strokes = [
        {
          strokeColor,
          strokeWidth,
          strokeAlignment: 'center',
        },
      ];
    }

    return {
      elementId: ellipse.id,
      type: 'ellipse',
      x: ellipse.x,
      y: ellipse.y,
      width: ellipse.width,
      height: ellipse.height,
    };
  }

  private async createText(params: CreateTextParams): Promise<any> {
    const { x, y, content, fontSize, fontFamily, fontWeight, color, align } = params;

    // Create text using PenPOT Plugin API
    const text = penpot.createText(content);

    // Set position
    text.x = x;
    text.y = y;

    // Set text properties
    if (fontSize) {
      text.fontSize = String(fontSize);
    }

    if (fontFamily) {
      text.fontFamily = fontFamily;
    }

    if (fontWeight) {
      text.fontWeight = fontWeight;
    }

    if (color) {
      text.fills = [{ fillColor: color, fillOpacity: 1 }];
    }

    if (align) {
      text.align = align;
    }

    return {
      elementId: text.id,
      type: 'text',
      x: text.x,
      y: text.y,
      content: text.characters,
      width: text.width,
      height: text.height,
    };
  }

  private async createFrame(params: CreateFrameParams): Promise<any> {
    const { x, y, width, height, name, backgroundColor } = params;

    // Create frame using PenPOT Plugin API
    const frame = penpot.createFrame();

    // Set position and size
    frame.x = x;
    frame.y = y;
    frame.resize(width, height);

    // Set name
    if (name) {
      frame.name = name;
    }

    // Set background color
    if (backgroundColor) {
      frame.fills = [{ fillColor: backgroundColor, fillOpacity: 1 }];
    }

    return {
      elementId: frame.id,
      type: 'frame',
      x: frame.x,
      y: frame.y,
      width: frame.width,
      height: frame.height,
      name: frame.name,
    };
  }

  private async clearCanvas(): Promise<any> {
    // Get current page
    const page = penpot.currentPage;

    if (!page) {
      throw new Error('No active page');
    }

    // Remove all elements from the page
    const children = page.children;
    for (const child of children) {
      penpot.removeShape(child);
    }

    return {
      message: 'Canvas cleared successfully',
      elementsRemoved: children.length,
    };
  }

  // UPDATE TOOLS

  private async updateElement(params: UpdateElementParams): Promise<any> {
    const { elementId, properties } = params;

    const element = penpot.getShapeById(elementId);
    if (!element) {
      throw new Error(`Element not found: ${elementId}`);
    }

    // Update position
    if (properties.x !== undefined) element.x = properties.x;
    if (properties.y !== undefined) element.y = properties.y;

    // Update size
    if (properties.width !== undefined || properties.height !== undefined) {
      const width = properties.width ?? element.width;
      const height = properties.height ?? element.height;
      element.resize(width, height);
    }

    // Update fill color
    if (properties.fillColor) {
      element.fills = [{ fillColor: properties.fillColor, fillOpacity: 1 }];
    }

    // Update stroke
    if (properties.strokeColor || properties.strokeWidth) {
      const existingStrokes = element.strokes || [];
      const stroke = existingStrokes[0] || {};
      element.strokes = [
        {
          strokeColor: properties.strokeColor || stroke.strokeColor || '#000000',
          strokeWidth: properties.strokeWidth ?? stroke.strokeWidth ?? 1,
          strokeAlignment: 'center',
        },
      ];
    }

    // Update text content
    if (properties.content && 'characters' in element) {
      element.characters = properties.content;
    }

    // Update text styles
    if (properties.fontSize && 'fontSize' in element) {
      element.fontSize = String(properties.fontSize);
    }
    if (properties.fontFamily && 'fontFamily' in element) {
      element.fontFamily = properties.fontFamily;
    }

    return {
      elementId: element.id,
      message: 'Element updated successfully',
      updatedProperties: Object.keys(properties),
    };
  }

  // QUERY TOOLS

  private async queryElements(params: QueryElementsParams): Promise<any> {
    const page = penpot.currentPage;
    if (!page) {
      throw new Error('No active page');
    }

    let elements = page.children;

    // Filter by type if specified
    if (params.type) {
      elements = elements.filter((el: any) => el.type === params.type);
    }

    // Filter by name if specified
    if (params.name) {
      elements = elements.filter((el: any) => el.name?.includes(params.name!));
    }

    return {
      count: elements.length,
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

  private async getCanvasState(): Promise<any> {
    const page = penpot.currentPage;
    if (!page) {
      throw new Error('No active page');
    }

    const selection = penpot.selection;

    return {
      pageName: page.name,
      elementsCount: page.children.length,
      selectedCount: selection.length,
      elements: page.children.map((el: any) => ({
        id: el.id,
        type: el.type,
        name: el.name,
        x: el.x,
        y: el.y,
        width: el.width,
        height: el.height,
      })),
      selectedElements: selection.map((el: any) => el.id),
    };
  }

  private async getElementDetails(params: GetElementDetailsParams): Promise<any> {
    const element = penpot.getShapeById(params.elementId);
    if (!element) {
      throw new Error(`Element not found: ${params.elementId}`);
    }

    const details: any = {
      id: element.id,
      type: element.type,
      name: element.name,
      x: element.x,
      y: element.y,
      width: element.width,
      height: element.height,
      rotation: element.rotation,
      fills: element.fills,
      strokes: element.strokes,
    };

    // Add text-specific details
    if ('characters' in element) {
      details.content = element.characters;
      details.fontSize = element.fontSize;
      details.fontFamily = element.fontFamily;
      details.fontWeight = element.fontWeight;
    }

    return details;
  }

  // TRANSFORM TOOLS

  private async rotateElement(params: RotateElementParams): Promise<any> {
    const element = penpot.getShapeById(params.elementId);
    if (!element) {
      throw new Error(`Element not found: ${params.elementId}`);
    }

    element.rotation = params.degrees;

    return {
      elementId: element.id,
      rotation: element.rotation,
      message: 'Element rotated successfully',
    };
  }

  private async scaleElement(params: ScaleElementParams): Promise<any> {
    const element = penpot.getShapeById(params.elementId);
    if (!element) {
      throw new Error(`Element not found: ${params.elementId}`);
    }

    const scaleY = params.scaleY ?? params.scaleX;
    const newWidth = element.width * params.scaleX;
    const newHeight = element.height * scaleY;

    element.resize(newWidth, newHeight);

    return {
      elementId: element.id,
      width: element.width,
      height: element.height,
      message: 'Element scaled successfully',
    };
  }

  private async flipHorizontal(params: FlipElementParams): Promise<any> {
    const element = penpot.getShapeById(params.elementId);
    if (!element) {
      throw new Error(`Element not found: ${params.elementId}`);
    }

    element.flipX = !element.flipX;

    return {
      elementId: element.id,
      flippedX: element.flipX,
      message: 'Element flipped horizontally',
    };
  }

  private async flipVertical(params: FlipElementParams): Promise<any> {
    const element = penpot.getShapeById(params.elementId);
    if (!element) {
      throw new Error(`Element not found: ${params.elementId}`);
    }

    element.flipY = !element.flipY;

    return {
      elementId: element.id,
      flippedY: element.flipY,
      message: 'Element flipped vertically',
    };
  }

  // DELETE TOOLS

  private async deleteElement(params: DeleteElementParams): Promise<any> {
    const element = penpot.getShapeById(params.elementId);
    if (!element) {
      throw new Error(`Element not found: ${params.elementId}`);
    }

    penpot.removeShape(element);

    return {
      elementId: params.elementId,
      message: 'Element deleted successfully',
    };
  }

  // DUPLICATE TOOLS

  private async duplicateElement(params: DuplicateElementParams): Promise<any> {
    const element = penpot.getShapeById(params.elementId);
    if (!element) {
      throw new Error(`Element not found: ${params.elementId}`);
    }

    const clone = element.clone();

    // Apply offset if specified
    if (params.offsetX !== undefined) {
      clone.x += params.offsetX;
    }
    if (params.offsetY !== undefined) {
      clone.y += params.offsetY;
    }

    return {
      originalId: element.id,
      duplicateId: clone.id,
      message: 'Element duplicated successfully',
    };
  }

  // GROUP TOOLS

  private async groupElements(params: GroupElementsParams): Promise<any> {
    const elements = params.elementIds
      .map((id) => penpot.getShapeById(id))
      .filter((el) => el !== null);

    if (elements.length === 0) {
      throw new Error('No valid elements found to group');
    }

    const group = penpot.group(elements);

    if (params.name) {
      group.name = params.name;
    }

    return {
      groupId: group.id,
      elementCount: elements.length,
      message: 'Elements grouped successfully',
    };
  }

  private async ungroupElements(params: UngroupElementsParams): Promise<any> {
    const group = penpot.getShapeById(params.groupId);
    if (!group) {
      throw new Error(`Group not found: ${params.groupId}`);
    }

    const children = 'children' in group ? group.children : [];
    penpot.ungroup(group);

    return {
      ungroupedCount: children.length,
      message: 'Group ungrouped successfully',
    };
  }

  // REORDER TOOLS

  private async bringToFront(params: ReorderElementParams): Promise<any> {
    const element = penpot.getShapeById(params.elementId);
    if (!element) {
      throw new Error(`Element not found: ${params.elementId}`);
    }

    element.bringToFront();

    return {
      elementId: element.id,
      message: 'Element brought to front',
    };
  }

  private async sendToBack(params: ReorderElementParams): Promise<any> {
    const element = penpot.getShapeById(params.elementId);
    if (!element) {
      throw new Error(`Element not found: ${params.elementId}`);
    }

    element.sendToBack();

    return {
      elementId: element.id,
      message: 'Element sent to back',
    };
  }

  private async bringForward(params: ReorderElementParams): Promise<any> {
    const element = penpot.getShapeById(params.elementId);
    if (!element) {
      throw new Error(`Element not found: ${params.elementId}`);
    }

    element.bringForward();

    return {
      elementId: element.id,
      message: 'Element brought forward',
    };
  }

  private async sendBackward(params: ReorderElementParams): Promise<any> {
    const element = penpot.getShapeById(params.elementId);
    if (!element) {
      throw new Error(`Element not found: ${params.elementId}`);
    }

    element.sendBackward();

    return {
      elementId: element.id,
      message: 'Element sent backward',
    };
  }

  // HISTORY TOOLS

  private async undo(): Promise<any> {
    penpot.history.undo();

    return {
      message: 'Undo performed successfully',
    };
  }

  private async redo(): Promise<any> {
    penpot.history.redo();

    return {
      message: 'Redo performed successfully',
    };
  }

  // LAYOUT TOOLS

  private async alignElements(params: AlignElementsParams): Promise<any> {
    const elements = params.elementIds
      .map((id) => penpot.getShapeById(id))
      .filter((el) => el !== null);

    if (elements.length === 0) {
      throw new Error('No valid elements found to align');
    }

    // Calculate bounds
    const bounds = {
      left: Math.min(...elements.map((el: any) => el.x)),
      right: Math.max(...elements.map((el: any) => el.x + el.width)),
      top: Math.min(...elements.map((el: any) => el.y)),
      bottom: Math.max(...elements.map((el: any) => el.y + el.height)),
    };

    const centerX = (bounds.left + bounds.right) / 2;
    const centerY = (bounds.top + bounds.bottom) / 2;

    // Apply alignment
    elements.forEach((el: any) => {
      switch (params.alignment) {
        case 'left':
          el.x = bounds.left;
          break;
        case 'center':
          el.x = centerX - el.width / 2;
          break;
        case 'right':
          el.x = bounds.right - el.width;
          break;
        case 'top':
          el.y = bounds.top;
          break;
        case 'middle':
          el.y = centerY - el.height / 2;
          break;
        case 'bottom':
          el.y = bounds.bottom - el.height;
          break;
      }
    });

    return {
      message: `Elements aligned to ${params.alignment}`,
      elementCount: elements.length,
      alignment: params.alignment,
    };
  }

  private async distributeElements(params: DistributeElementsParams): Promise<any> {
    const elements = params.elementIds
      .map((id) => penpot.getShapeById(id))
      .filter((el) => el !== null);

    if (elements.length < 3) {
      throw new Error('Need at least 3 elements to distribute');
    }

    if (params.direction === 'horizontal') {
      // Sort by x position
      elements.sort((a: any, b: any) => a.x - b.x);

      if (params.spacing !== undefined) {
        // Fixed spacing
        let currentX = elements[0].x + elements[0].width;
        for (let i = 1; i < elements.length - 1; i++) {
          elements[i].x = currentX + params.spacing;
          currentX = elements[i].x + elements[i].width;
        }
      } else {
        // Even distribution
        const first = elements[0];
        const last = elements[elements.length - 1];
        const totalSpace = last.x - (first.x + first.width);
        const elementWidths = elements.slice(1, -1).reduce((sum: number, el: any) => sum + el.width, 0);
        const spacing = (totalSpace - elementWidths) / (elements.length - 1);

        let currentX = first.x + first.width;
        for (let i = 1; i < elements.length - 1; i++) {
          elements[i].x = currentX + spacing;
          currentX = elements[i].x + elements[i].width;
        }
      }
    } else {
      // Vertical distribution
      elements.sort((a: any, b: any) => a.y - b.y);

      if (params.spacing !== undefined) {
        // Fixed spacing
        let currentY = elements[0].y + elements[0].height;
        for (let i = 1; i < elements.length - 1; i++) {
          elements[i].y = currentY + params.spacing;
          currentY = elements[i].y + elements[i].height;
        }
      } else {
        // Even distribution
        const first = elements[0];
        const last = elements[elements.length - 1];
        const totalSpace = last.y - (first.y + first.height);
        const elementHeights = elements.slice(1, -1).reduce((sum: number, el: any) => sum + el.height, 0);
        const spacing = (totalSpace - elementHeights) / (elements.length - 1);

        let currentY = first.y + first.height;
        for (let i = 1; i < elements.length - 1; i++) {
          elements[i].y = currentY + spacing;
          currentY = elements[i].y + elements[i].height;
        }
      }
    }

    return {
      message: `Elements distributed ${params.direction}ly`,
      elementCount: elements.length,
      direction: params.direction,
      spacing: params.spacing,
    };
  }

  private async setConstraints(params: SetConstraintsParams): Promise<any> {
    const element = penpot.getShapeById(params.elementId);
    if (!element) {
      throw new Error(`Element not found: ${params.elementId}`);
    }

    // Note: PenPOT Plugin API may have limited constraint support
    // This is a placeholder implementation that would need PenPOT API support
    return {
      elementId: element.id,
      message: 'Constraints set (Note: Full constraint support depends on PenPOT API)',
      constraints: params.constraints,
    };
  }

  // COMPONENT TOOLS

  private async createComponent(params: CreateComponentParams): Promise<any> {
    const elements = params.elementIds
      .map((id) => penpot.getShapeById(id))
      .filter((el) => el !== null);

    if (elements.length === 0) {
      throw new Error('No valid elements found to create component');
    }

    // Create component using PenPOT API
    const component = penpot.createComponent(elements);

    if (params.name) {
      component.name = params.name;
    }

    return {
      componentId: component.id,
      name: component.name,
      elementCount: elements.length,
      message: 'Component created successfully',
    };
  }

  private async detachComponent(params: DetachComponentParams): Promise<any> {
    const instance = penpot.getShapeById(params.instanceId);
    if (!instance) {
      throw new Error(`Component instance not found: ${params.instanceId}`);
    }

    // Detach component instance
    penpot.detachInstance(instance);

    return {
      instanceId: params.instanceId,
      message: 'Component instance detached successfully',
    };
  }

  private async createComponentInstance(params: CreateComponentInstanceParams): Promise<any> {
    const component = penpot.getShapeById(params.componentId);
    if (!component) {
      throw new Error(`Component not found: ${params.componentId}`);
    }

    // Create instance of component
    const instance = penpot.createInstance(component);
    instance.x = params.x;
    instance.y = params.y;

    return {
      instanceId: instance.id,
      componentId: params.componentId,
      x: instance.x,
      y: instance.y,
      message: 'Component instance created successfully',
    };
  }

  // EXPORT TOOLS

  private async exportElement(params: ExportElementParams): Promise<any> {
    const element = penpot.getShapeById(params.elementId);
    if (!element) {
      throw new Error(`Element not found: ${params.elementId}`);
    }

    // Note: PenPOT export functionality may require different API
    // This is a placeholder that would need proper export API integration
    return {
      elementId: params.elementId,
      format: params.format,
      scale: params.scale || 1,
      message: `Export initiated for element (format: ${params.format})`,
      note: 'Export functionality requires PenPOT export API integration',
    };
  }

  private async exportPage(params: ExportPageParams): Promise<any> {
    const page = penpot.currentPage;
    if (!page) {
      throw new Error('No active page');
    }

    return {
      pageName: page.name,
      format: params.format,
      scale: params.scale || 1,
      message: `Export initiated for page (format: ${params.format})`,
      note: 'Export functionality requires PenPOT export API integration',
    };
  }

  private async exportSelection(params: ExportSelectionParams): Promise<any> {
    const selection = penpot.selection;
    if (selection.length === 0) {
      throw new Error('No elements selected');
    }

    return {
      selectedCount: selection.length,
      format: params.format,
      scale: params.scale || 1,
      message: `Export initiated for ${selection.length} selected elements (format: ${params.format})`,
      note: 'Export functionality requires PenPOT export API integration',
    };
  }
}
