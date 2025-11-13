import { v4 as uuidv4 } from 'uuid';
import { CanvasElement, CanvasState, ElementType, DesignSystem, ElementStyle } from '../types';

export class CanvasEngine {
  private state: CanvasState;
  private history: CanvasState[] = [];
  private historyIndex = -1;
  private maxHistory = 50;
  private designSystem?: DesignSystem;

  constructor(initialState?: Partial<CanvasState>) {
    this.state = {
      id: uuidv4(),
      name: 'Untitled Canvas',
      width: 800,
      height: 600,
      backgroundColor: '#ffffff',
      elements: [],
      selectedElements: [],
      grid: {
        enabled: true,
        size: 8,
        snap: true,
      },
      guides: {
        enabled: true,
        smart: true,
      },
      ...initialState,
    };
    this.saveToHistory();
  }

  // State Management
  getState(): CanvasState {
    return { ...this.state };
  }

  setState(updates: Partial<CanvasState>) {
    this.state = { ...this.state, ...updates };
    this.saveToHistory();
  }

  // Element Management
  addElement(element: Omit<CanvasElement, 'id'>): CanvasElement {
    const newElement: CanvasElement = {
      ...element,
      id: uuidv4(),
    };

    // Apply design system defaults if available
    if (this.designSystem && element.component) {
      const componentDef = this.designSystem.components[element.component];
      if (componentDef) {
        const variant = element.variant || componentDef.defaultVariant;
        const variantDef = componentDef.variants[variant];
        if (variantDef) {
          newElement.style = this.mergeStyles(variantDef.props, element.style);
        }
      }
    }

    // Snap to grid if enabled
    if (this.state.grid?.snap) {
      newElement.x = this.snapToGrid(newElement.x);
      newElement.y = this.snapToGrid(newElement.y);
    }

    this.state.elements.push(newElement);
    this.saveToHistory();
    return newElement;
  }

  updateElement(elementId: string, updates: Partial<CanvasElement>): boolean {
    const index = this.state.elements.findIndex(el => el.id === elementId);
    if (index === -1) return false;

    // Snap position updates to grid
    if (this.state.grid?.snap) {
      if (updates.x !== undefined) updates.x = this.snapToGrid(updates.x);
      if (updates.y !== undefined) updates.y = this.snapToGrid(updates.y);
    }

    this.state.elements[index] = {
      ...this.state.elements[index],
      ...updates,
    };

    this.saveToHistory();
    return true;
  }

  deleteElement(elementId: string): boolean {
    const index = this.state.elements.findIndex(el => el.id === elementId);
    if (index === -1) return false;

    this.state.elements.splice(index, 1);
    this.state.selectedElements = this.state.selectedElements.filter(id => id !== elementId);
    
    // Also delete children
    this.state.elements = this.state.elements.filter(el => el.parent !== elementId);
    
    this.saveToHistory();
    return true;
  }

  // Selection Management
  selectElements(elementIds: string[]) {
    this.state.selectedElements = elementIds;
  }

  clearSelection() {
    this.state.selectedElements = [];
  }

  // Design System
  loadDesignSystem(designSystem: DesignSystem) {
    this.designSystem = designSystem;
    this.state.designSystemId = designSystem.id;
    
    // Re-apply design system to existing components
    this.state.elements = this.state.elements.map(element => {
      if (element.component && this.designSystem) {
        const componentDef = this.designSystem.components[element.component];
        if (componentDef) {
          const variant = element.variant || componentDef.defaultVariant;
          const variantDef = componentDef.variants[variant];
          if (variantDef) {
            return {
              ...element,
              style: this.mergeStyles(variantDef.props, element.tokenOverrides),
            };
          }
        }
      }
      return element;
    });
    
    this.saveToHistory();
  }

  getDesignToken(path: string): any {
    if (!this.designSystem) return null;
    
    const parts = path.split('.');
    let value: any = this.designSystem.tokens;
    
    for (const part of parts) {
      value = value?.[part];
      if (value === undefined) return null;
    }
    
    return value;
  }

  // Layout Helpers
  alignElements(alignment: 'left' | 'center' | 'right' | 'top' | 'middle' | 'bottom') {
    const selected = this.state.elements.filter(el => 
      this.state.selectedElements.includes(el.id)
    );
    
    if (selected.length < 2) return;

    const bounds = this.getSelectionBounds(selected);

    selected.forEach(element => {
      switch (alignment) {
        case 'left':
          this.updateElement(element.id, { x: bounds.left });
          break;
        case 'center':
          this.updateElement(element.id, { 
            x: bounds.left + (bounds.width - element.width) / 2 
          });
          break;
        case 'right':
          this.updateElement(element.id, { 
            x: bounds.left + bounds.width - element.width 
          });
          break;
        case 'top':
          this.updateElement(element.id, { y: bounds.top });
          break;
        case 'middle':
          this.updateElement(element.id, { 
            y: bounds.top + (bounds.height - element.height) / 2 
          });
          break;
        case 'bottom':
          this.updateElement(element.id, { 
            y: bounds.top + bounds.height - element.height 
          });
          break;
      }
    });
  }

  distributeElements(direction: 'horizontal' | 'vertical') {
    const selected = this.state.elements.filter(el => 
      this.state.selectedElements.includes(el.id)
    );
    
    if (selected.length < 3) return;

    // Sort by position
    selected.sort((a, b) => 
      direction === 'horizontal' ? a.x - b.x : a.y - b.y
    );

    const first = selected[0];
    const last = selected[selected.length - 1];
    
    const totalSpace = direction === 'horizontal'
      ? last.x - first.x
      : last.y - first.y;
      
    const spacing = totalSpace / (selected.length - 1);

    selected.forEach((element, index) => {
      if (index === 0 || index === selected.length - 1) return;
      
      if (direction === 'horizontal') {
        this.updateElement(element.id, { x: first.x + spacing * index });
      } else {
        this.updateElement(element.id, { y: first.y + spacing * index });
      }
    });
  }

  // History Management
  undo(): boolean {
    if (this.historyIndex > 0) {
      this.historyIndex--;
      this.state = { ...this.history[this.historyIndex] };
      return true;
    }
    return false;
  }

  redo(): boolean {
    if (this.historyIndex < this.history.length - 1) {
      this.historyIndex++;
      this.state = { ...this.history[this.historyIndex] };
      return true;
    }
    return false;
  }

  // Private Helpers
  private saveToHistory() {
    // Remove any history after current index
    this.history = this.history.slice(0, this.historyIndex + 1);
    
    // Add new state
    this.history.push({ ...this.state });
    this.historyIndex++;
    
    // Limit history size
    if (this.history.length > this.maxHistory) {
      this.history = this.history.slice(-this.maxHistory);
      this.historyIndex = this.history.length - 1;
    }
  }

  private snapToGrid(value: number): number {
    const gridSize = this.state.grid?.size || 8;
    return Math.round(value / gridSize) * gridSize;
  }

  private mergeStyles(base: any, overrides?: any): ElementStyle {
    return { ...base, ...overrides };
  }

  private getSelectionBounds(elements: CanvasElement[]) {
    let left = Infinity, top = Infinity;
    let right = -Infinity, bottom = -Infinity;

    elements.forEach(el => {
      left = Math.min(left, el.x);
      top = Math.min(top, el.y);
      right = Math.max(right, el.x + el.width);
      bottom = Math.max(bottom, el.y + el.height);
    });

    return {
      left,
      top,
      width: right - left,
      height: bottom - top,
    };
  }

  // Clear canvas
  clear() {
    this.state.elements = [];
    this.state.selectedElements = [];
    this.saveToHistory();
  }

  // Export/Import
  toJSON(): string {
    return JSON.stringify(this.state, null, 2);
  }

  fromJSON(json: string) {
    try {
      const state = JSON.parse(json);
      this.state = state;
      this.saveToHistory();
    } catch (error) {
      throw new Error('Invalid canvas JSON');
    }
  }
}