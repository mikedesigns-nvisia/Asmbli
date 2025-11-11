// Asmbli Canvas - Advanced Design Tool
class AsmbliCanvas {
    constructor() {
        this.stage = null;
        this.layer = null;
        this.transformer = null;
        this.currentTool = 'select';
        this.selectedElements = [];
        this.designSystem = null;
        this.history = [];
        this.historyIndex = -1;
        this.isDrawing = false;
        this.zoom = 1;
        this.serverConfig = null;
        
        this.init();
    }
    
    async init() {
        try {
            // Parse server configuration
            this.serverConfig = window.SERVER_CONFIG || {
                apiUrl: '/api',
                version: '1.0.0',
                debug: false
            };
            
            console.log('🎨 Initializing Asmbli Canvas', this.serverConfig);
            
            // Initialize Konva stage
            this.initStage();
            
            // Load design system
            await this.loadDesignSystem('material3');
            
            // Setup event listeners
            this.setupEventListeners();
            
            // Setup keyboard shortcuts
            this.setupKeyboardShortcuts();
            
            // Initialize UI
            this.updateUI();
            
            this.updateStatus('Canvas initialized successfully');
            
        } catch (error) {
            console.error('❌ Canvas initialization failed:', error);
            this.updateStatus('Canvas initialization failed: ' + error.message);
        }
    }
    
    initStage() {
        const container = document.getElementById('canvas-container');
        const rect = container.getBoundingClientRect();
        
        this.stage = new Konva.Stage({
            container: 'canvas-container',
            width: rect.width,
            height: rect.height,
        });
        
        this.layer = new Konva.Layer();
        this.stage.add(this.layer);
        
        // Add transformer for selections
        this.transformer = new Konva.Transformer({
            borderStroke: '#6750A4',
            borderStrokeWidth: 2,
            anchorStroke: '#6750A4',
            anchorFill: '#ffffff',
            anchorSize: 8,
            borderRadius: 2,
        });
        this.layer.add(this.transformer);
        
        // Handle stage interactions
        this.stage.on('click tap', (e) => this.handleStageClick(e));
        this.stage.on('dragstart', () => this.handleDragStart());
        this.stage.on('dragend', () => this.handleDragEnd());
        
        // Handle window resize
        window.addEventListener('resize', () => this.handleResize());
    }
    
    setupEventListeners() {
        // Tool buttons
        document.querySelectorAll('.tool-btn').forEach(btn => {
            btn.addEventListener('click', () => {
                this.setTool(btn.dataset.tool);
            });
        });
        
        // Component buttons
        document.querySelectorAll('.component-btn').forEach(btn => {
            btn.addEventListener('click', () => {
                this.addComponent(btn.dataset.component, btn.dataset.variant);
            });
        });
        
        // Design system selector
        const designSystemSelect = document.getElementById('design-system-select');
        designSystemSelect.addEventListener('change', () => {
            this.loadDesignSystem(designSystemSelect.value);
        });
        
        // Properties panel inputs
        document.addEventListener('input', (e) => {
            if (e.target.matches('.property-input')) {
                this.updateSelectedProperties();
            }
        });
        
        // Context menu
        this.stage.on('contextmenu', (e) => this.showContextMenu(e));
        document.addEventListener('click', () => this.hideContextMenu());
    }
    
    setupKeyboardShortcuts() {
        document.addEventListener('keydown', (e) => {
            if (e.ctrlKey || e.metaKey) {
                switch (e.key) {
                    case 'z':
                        e.preventDefault();
                        if (e.shiftKey) {
                            this.redo();
                        } else {
                            this.undo();
                        }
                        break;
                    case 'y':
                        e.preventDefault();
                        this.redo();
                        break;
                    case 'd':
                        e.preventDefault();
                        this.duplicateSelected();
                        break;
                    case 'a':
                        e.preventDefault();
                        this.selectAll();
                        break;
                    case 's':
                        e.preventDefault();
                        this.saveCanvas();
                        break;
                }
            } else {
                switch (e.key) {
                    case 'Delete':
                    case 'Backspace':
                        e.preventDefault();
                        this.deleteSelected();
                        break;
                    case 'v':
                        this.setTool('select');
                        break;
                    case 'r':
                        this.setTool('rectangle');
                        break;
                    case 'c':
                        this.setTool('circle');
                        break;
                    case 't':
                        this.setTool('text');
                        break;
                    case 'b':
                        this.setTool('button');
                        break;
                    case 'i':
                        this.setTool('input');
                        break;
                    case 'Escape':
                        this.clearSelection();
                        break;
                }
            }
        });
    }
    
    setTool(tool) {
        this.currentTool = tool;
        
        // Update tool buttons
        document.querySelectorAll('.tool-btn').forEach(btn => {
            btn.classList.toggle('active', btn.dataset.tool === tool);
        });
        
        // Clear selection if switching away from select tool
        if (tool !== 'select') {
            this.clearSelection();
        }
        
        // Update cursor
        this.updateCursor();
        
        this.updateStatus(`Tool: ${tool}`);
    }
    
    updateCursor() {
        const cursors = {
            select: 'default',
            rectangle: 'crosshair',
            circle: 'crosshair',
            text: 'text',
            button: 'pointer',
            input: 'pointer',
            image: 'crosshair',
            card: 'crosshair'
        };
        
        this.stage.container().style.cursor = cursors[this.currentTool] || 'default';
    }
    
    handleStageClick(e) {
        const clickedOnEmpty = e.target === this.stage;
        
        if (clickedOnEmpty) {
            if (this.currentTool === 'select') {
                this.clearSelection();
            } else {
                this.createElementAtPosition(e.evt.offsetX, e.evt.offsetY);
            }
        } else {
            if (this.currentTool === 'select') {
                this.selectElement(e.target);
            }
        }
    }
    
    createElementAtPosition(x, y) {
        let element;
        
        switch (this.currentTool) {
            case 'rectangle':
                element = this.createRectangle(x, y);
                break;
            case 'circle':
                element = this.createCircle(x, y);
                break;
            case 'text':
                element = this.createText(x, y);
                break;
            case 'button':
                element = this.createButton(x, y);
                break;
            case 'input':
                element = this.createInput(x, y);
                break;
            case 'image':
                element = this.createImage(x, y);
                break;
            case 'card':
                element = this.createCard(x, y);
                break;
        }
        
        if (element) {
            this.layer.add(element);
            this.layer.draw();
            this.selectElement(element);
            this.saveToHistory();
            this.updateLayersList();
            this.callMCP('create_element', this.elementToMCPData(element));
        }
    }
    
    createRectangle(x, y) {
        const rect = new Konva.Rect({
            x: x - 60,
            y: y - 40,
            width: 120,
            height: 80,
            fill: this.getTokenValue('colors.primary', '#6750A4'),
            stroke: this.getTokenValue('colors.outline', '#79747E'),
            strokeWidth: 1,
            cornerRadius: this.getTokenValue('borderRadius.md', 8),
            draggable: true,
            name: 'rectangle',
            elementType: 'container'
        });
        
        this.setupElementEvents(rect);
        return rect;
    }
    
    createCircle(x, y) {
        const circle = new Konva.Circle({
            x: x,
            y: y,
            radius: 50,
            fill: this.getTokenValue('colors.secondary', '#625B71'),
            stroke: this.getTokenValue('colors.outline', '#79747E'),
            strokeWidth: 1,
            draggable: true,
            name: 'circle',
            elementType: 'container'
        });
        
        this.setupElementEvents(circle);
        return circle;
    }
    
    createText(x, y) {
        const text = new Konva.Text({
            x: x - 40,
            y: y - 10,
            text: 'Text Element',
            fontSize: this.getTokenValue('typography.bodyLarge.fontSize', 16),
            fontFamily: '-apple-system, BlinkMacSystemFont, sans-serif',
            fill: this.getTokenValue('colors.onSurface', '#1C1B1F'),
            draggable: true,
            name: 'text',
            elementType: 'text'
        });
        
        this.setupElementEvents(text);
        return text;
    }
    
    createButton(x, y) {
        const group = new Konva.Group({
            x: x - 60,
            y: y - 20,
            draggable: true,
            name: 'button',
            elementType: 'button'
        });
        
        const bg = new Konva.Rect({
            width: 120,
            height: 40,
            fill: this.getTokenValue('colors.primary', '#6750A4'),
            cornerRadius: this.getTokenValue('borderRadius.xl', 20),
        });
        
        const text = new Konva.Text({
            x: 30,
            y: 12,
            text: 'Button',
            fontSize: this.getTokenValue('typography.labelLarge.fontSize', 14),
            fontFamily: '-apple-system, BlinkMacSystemFont, sans-serif',
            fill: this.getTokenValue('colors.onPrimary', '#FFFFFF'),
            fontStyle: '500'
        });
        
        group.add(bg);
        group.add(text);
        
        this.setupElementEvents(group);
        return group;
    }
    
    createInput(x, y) {
        const group = new Konva.Group({
            x: x - 100,
            y: y - 28,
            draggable: true,
            name: 'input',
            elementType: 'input'
        });
        
        const bg = new Konva.Rect({
            width: 200,
            height: 56,
            fill: this.getTokenValue('colors.surface', '#FFFBFE'),
            stroke: this.getTokenValue('colors.outline', '#79747E'),
            strokeWidth: 1,
            cornerRadius: this.getTokenValue('borderRadius.xs', 4),
        });
        
        const placeholder = new Konva.Text({
            x: 16,
            y: 20,
            text: 'Enter text...',
            fontSize: this.getTokenValue('typography.bodyLarge.fontSize', 16),
            fontFamily: '-apple-system, BlinkMacSystemFont, sans-serif',
            fill: this.getTokenValue('colors.onSurfaceVariant', '#49454F'),
        });
        
        group.add(bg);
        group.add(placeholder);
        
        this.setupElementEvents(group);
        return group;
    }
    
    createImage(x, y) {
        const group = new Konva.Group({
            x: x - 75,
            y: y - 75,
            draggable: true,
            name: 'image',
            elementType: 'image'
        });
        
        const bg = new Konva.Rect({
            width: 150,
            height: 150,
            fill: this.getTokenValue('colors.surfaceVariant', '#E7E0EC'),
            cornerRadius: this.getTokenValue('borderRadius.md', 8),
        });
        
        const icon = new Konva.Text({
            x: 65,
            y: 65,
            text: '🖼️',
            fontSize: 24,
        });
        
        group.add(bg);
        group.add(icon);
        
        this.setupElementEvents(group);
        return group;
    }
    
    createCard(x, y) {
        const group = new Konva.Group({
            x: x - 100,
            y: y - 75,
            draggable: true,
            name: 'card',
            elementType: 'card'
        });
        
        const bg = new Konva.Rect({
            width: 200,
            height: 150,
            fill: this.getTokenValue('colors.surface', '#FFFBFE'),
            cornerRadius: this.getTokenValue('borderRadius.lg', 12),
            shadowColor: 'rgba(0,0,0,0.1)',
            shadowBlur: 8,
            shadowOffset: { x: 0, y: 2 },
        });
        
        const title = new Konva.Text({
            x: 16,
            y: 16,
            text: 'Card Title',
            fontSize: this.getTokenValue('typography.titleMedium.fontSize', 16),
            fontFamily: '-apple-system, BlinkMacSystemFont, sans-serif',
            fill: this.getTokenValue('colors.onSurface', '#1C1B1F'),
            fontStyle: '500'
        });
        
        const content = new Konva.Text({
            x: 16,
            y: 40,
            text: 'Card content goes here...',
            fontSize: this.getTokenValue('typography.bodyMedium.fontSize', 14),
            fontFamily: '-apple-system, BlinkMacSystemFont, sans-serif',
            fill: this.getTokenValue('colors.onSurfaceVariant', '#49454F'),
        });
        
        group.add(bg);
        group.add(title);
        group.add(content);
        
        this.setupElementEvents(group);
        return group;
    }
    
    addComponent(component, variant) {
        const centerX = this.stage.width() / 2;
        const centerY = this.stage.height() / 2;
        
        let element;
        
        switch (component) {
            case 'button':
                element = this.createComponentButton(centerX, centerY, variant);
                break;
            case 'card':
                element = this.createComponentCard(centerX, centerY, variant);
                break;
            case 'textField':
                element = this.createComponentTextField(centerX, centerY, variant);
                break;
        }
        
        if (element) {
            this.layer.add(element);
            this.layer.draw();
            this.selectElement(element);
            this.saveToHistory();
            this.updateLayersList();
            this.callMCP('create_element', this.elementToMCPData(element));
        }
    }
    
    createComponentButton(x, y, variant) {
        const group = new Konva.Group({
            x: x - 60,
            y: y - 20,
            draggable: true,
            name: 'button',
            elementType: 'button',
            component: 'button',
            variant: variant
        });
        
        const styles = this.getComponentStyle('button', variant);
        
        const bg = new Konva.Rect({
            width: 120,
            height: 40,
            fill: styles.backgroundColor,
            stroke: styles.borderColor,
            strokeWidth: styles.borderWidth || 0,
            cornerRadius: styles.borderRadius || 20,
        });
        
        const text = new Konva.Text({
            x: 30,
            y: 12,
            text: 'Button',
            fontSize: styles.fontSize || 14,
            fontFamily: '-apple-system, BlinkMacSystemFont, sans-serif',
            fill: styles.color,
            fontStyle: styles.fontWeight || '500'
        });
        
        group.add(bg);
        group.add(text);
        
        this.setupElementEvents(group);
        return group;
    }
    
    createComponentCard(x, y, variant) {
        // Similar to createCard but with component styling
        return this.createCard(x, y);
    }
    
    createComponentTextField(x, y, variant) {
        // Similar to createInput but with component styling
        return this.createInput(x, y);
    }
    
    setupElementEvents(element) {
        element.on('click', (e) => {
            e.cancelBubble = true;
            this.selectElement(element);
        });
        
        element.on('dragmove', () => {
            this.updatePropertiesPanel();
        });
        
        element.on('dragend', () => {
            this.saveToHistory();
        });
        
        element.on('transform', () => {
            this.updatePropertiesPanel();
        });
        
        element.on('transformend', () => {
            this.saveToHistory();
        });
    }
    
    selectElement(element) {
        if (!element) return;
        
        this.selectedElements = [element];
        this.transformer.nodes([element]);
        this.transformer.getLayer().batchDraw();
        
        this.updatePropertiesPanel();
        this.updateLayersList();
        
        // Notify Flutter about selection
        this.notifyFlutter('element_selected', {
            elementIds: [element.id()],
            elementType: element.attrs.elementType || 'unknown'
        });
    }
    
    clearSelection() {
        this.selectedElements = [];
        this.transformer.nodes([]);
        this.transformer.getLayer().batchDraw();
        
        this.updatePropertiesPanel();
        this.updateLayersList();
        
        this.notifyFlutter('element_selected', { elementIds: [] });
    }
    
    selectAll() {
        const allElements = this.layer.children.filter(child => 
            child !== this.transformer
        );
        
        this.selectedElements = allElements;
        this.transformer.nodes(allElements);
        this.transformer.getLayer().batchDraw();
        
        this.updatePropertiesPanel();
        this.updateLayersList();
    }
    
    deleteSelected() {
        if (this.selectedElements.length === 0) return;
        
        this.selectedElements.forEach(element => {
            element.destroy();
        });
        
        this.selectedElements = [];
        this.transformer.nodes([]);
        this.layer.draw();
        
        this.saveToHistory();
        this.updatePropertiesPanel();
        this.updateLayersList();
        this.updateStatus(`Deleted ${this.selectedElements.length} element(s)`);
        
        this.callMCP('delete_element', { elementIds: this.selectedElements.map(e => e.id()) });
    }
    
    duplicateSelected() {
        if (this.selectedElements.length === 0) return;
        
        const newElements = [];
        
        this.selectedElements.forEach(element => {
            const clone = element.clone({
                x: element.x() + 20,
                y: element.y() + 20,
            });
            
            this.setupElementEvents(clone);
            this.layer.add(clone);
            newElements.push(clone);
        });
        
        this.selectedElements = newElements;
        this.transformer.nodes(newElements);
        this.layer.draw();
        
        this.saveToHistory();
        this.updatePropertiesPanel();
        this.updateLayersList();
        this.updateStatus(`Duplicated ${newElements.length} element(s)`);
    }
    
    alignElements(alignment) {
        if (this.selectedElements.length < 2) return;
        
        const bounds = this.getSelectionBounds();
        
        this.selectedElements.forEach(element => {
            switch (alignment) {
                case 'left':
                    element.x(bounds.x);
                    break;
                case 'center':
                    element.x(bounds.x + (bounds.width - element.width()) / 2);
                    break;
                case 'right':
                    element.x(bounds.x + bounds.width - element.width());
                    break;
                case 'top':
                    element.y(bounds.y);
                    break;
                case 'middle':
                    element.y(bounds.y + (bounds.height - element.height()) / 2);
                    break;
                case 'bottom':
                    element.y(bounds.y + bounds.height - element.height());
                    break;
            }
        });
        
        this.layer.draw();
        this.saveToHistory();
        this.updatePropertiesPanel();
        this.updateStatus(`Aligned ${this.selectedElements.length} elements to ${alignment}`);
        
        this.callMCP('align_elements', {
            alignment: alignment,
            elementIds: this.selectedElements.map(e => e.id())
        });
    }
    
    getSelectionBounds() {
        if (this.selectedElements.length === 0) return { x: 0, y: 0, width: 0, height: 0 };
        
        let minX = Infinity, minY = Infinity;
        let maxX = -Infinity, maxY = -Infinity;
        
        this.selectedElements.forEach(element => {
            const box = element.getClientRect();
            minX = Math.min(minX, box.x);
            minY = Math.min(minY, box.y);
            maxX = Math.max(maxX, box.x + box.width);
            maxY = Math.max(maxY, box.y + box.height);
        });
        
        return {
            x: minX,
            y: minY,
            width: maxX - minX,
            height: maxY - minY
        };
    }
    
    updatePropertiesPanel() {
        const propertiesContent = document.getElementById('properties-content');
        
        if (this.selectedElements.length === 0) {
            propertiesContent.innerHTML = '<div class="no-selection">Select an element to edit properties</div>';
            return;
        }
        
        if (this.selectedElements.length === 1) {
            this.showSingleElementProperties(this.selectedElements[0]);
        } else {
            this.showMultiElementProperties();
        }
    }
    
    showSingleElementProperties(element) {
        const propertiesContent = document.getElementById('properties-content');
        const elementType = element.attrs.elementType || 'unknown';
        
        let html = `
            <div class="property-group">
                <div class="property-label">Type</div>
                <div class="property-value">${elementType}</div>
            </div>
            
            <div class="property-group">
                <div class="property-label">Position</div>
                <div class="property-row">
                    <input type="number" class="property-input" data-property="x" value="${Math.round(element.x())}" placeholder="X">
                    <input type="number" class="property-input" data-property="y" value="${Math.round(element.y())}" placeholder="Y">
                </div>
            </div>
            
            <div class="property-group">
                <div class="property-label">Size</div>
                <div class="property-row">
                    <input type="number" class="property-input" data-property="width" value="${Math.round(element.width())}" placeholder="W">
                    <input type="number" class="property-input" data-property="height" value="${Math.round(element.height())}" placeholder="H">
                </div>
            </div>
        `;
        
        // Add type-specific properties
        if (elementType === 'text' || element.children?.some(child => child.className === 'Text')) {
            html += `
                <div class="property-group">
                    <div class="property-label">Text</div>
                    <input type="text" class="property-input" data-property="text" value="${element.text?.() || element.children?.find(child => child.className === 'Text')?.text?.() || ''}" placeholder="Text content">
                </div>
                
                <div class="property-group">
                    <div class="property-label">Font Size</div>
                    <input type="number" class="property-input" data-property="fontSize" value="${element.fontSize?.() || element.children?.find(child => child.className === 'Text')?.fontSize?.() || 16}" placeholder="Size">
                </div>
            `;
        }
        
        // Add color properties
        if (element.fill || element.children?.some(child => child.fill)) {
            const fillColor = element.fill?.() || element.children?.find(child => child.fill)?.fill?.() || '#000000';
            html += `
                <div class="property-group">
                    <div class="property-label">Fill Color</div>
                    <input type="color" class="property-input color-input" data-property="fill" value="${fillColor}">
                </div>
            `;
        }
        
        if (element.stroke || element.children?.some(child => child.stroke)) {
            const strokeColor = element.stroke?.() || element.children?.find(child => child.stroke)?.stroke?.() || '#000000';
            html += `
                <div class="property-group">
                    <div class="property-label">Stroke Color</div>
                    <input type="color" class="property-input color-input" data-property="stroke" value="${strokeColor}">
                </div>
            `;
        }
        
        propertiesContent.innerHTML = html;
    }
    
    showMultiElementProperties() {
        const propertiesContent = document.getElementById('properties-content');
        
        propertiesContent.innerHTML = `
            <div class="property-group">
                <div class="property-label">Multiple Selection</div>
                <div class="property-value">${this.selectedElements.length} elements selected</div>
            </div>
            
            <div class="property-group">
                <div class="property-label">Actions</div>
                <button class="action-btn" onclick="canvas.alignElements('left')">Align Left</button>
                <button class="action-btn" onclick="canvas.alignElements('center')">Align Center</button>
                <button class="action-btn" onclick="canvas.alignElements('right')">Align Right</button>
            </div>
        `;
    }
    
    updateSelectedProperties() {
        if (this.selectedElements.length !== 1) return;
        
        const element = this.selectedElements[0];
        const inputs = document.querySelectorAll('.property-input');
        
        inputs.forEach(input => {
            const property = input.dataset.property;
            const value = input.value;
            
            switch (property) {
                case 'x':
                    element.x(parseFloat(value) || 0);
                    break;
                case 'y':
                    element.y(parseFloat(value) || 0);
                    break;
                case 'width':
                    element.width(parseFloat(value) || 0);
                    break;
                case 'height':
                    element.height(parseFloat(value) || 0);
                    break;
                case 'text':
                    if (element.text) {
                        element.text(value);
                    } else {
                        const textChild = element.children?.find(child => child.className === 'Text');
                        if (textChild) textChild.text(value);
                    }
                    break;
                case 'fontSize':
                    if (element.fontSize) {
                        element.fontSize(parseFloat(value) || 16);
                    } else {
                        const textChild = element.children?.find(child => child.className === 'Text');
                        if (textChild) textChild.fontSize(parseFloat(value) || 16);
                    }
                    break;
                case 'fill':
                    if (element.fill) {
                        element.fill(value);
                    } else {
                        const fillChild = element.children?.find(child => child.fill);
                        if (fillChild) fillChild.fill(value);
                    }
                    break;
                case 'stroke':
                    if (element.stroke) {
                        element.stroke(value);
                    } else {
                        const strokeChild = element.children?.find(child => child.stroke);
                        if (strokeChild) strokeChild.stroke(value);
                    }
                    break;
            }
        });
        
        this.layer.draw();
        this.transformer.forceUpdate();
    }
    
    updateLayersList() {
        const layersList = document.getElementById('layers-list');
        const elements = this.layer.children.filter(child => child !== this.transformer);
        
        let html = '';
        elements.forEach((element, index) => {
            const name = element.name() || `Element ${index + 1}`;
            const type = element.attrs.elementType || 'unknown';
            const isSelected = this.selectedElements.includes(element);
            
            html += `
                <div class="layer-item ${isSelected ? 'selected' : ''}" data-element-id="${element.id()}">
                    <div class="layer-icon">${this.getElementIcon(type)}</div>
                    <div class="layer-name">${name}</div>
                </div>
            `;
        });
        
        layersList.innerHTML = html || '<div class="no-selection">No elements</div>';
        
        // Add click handlers
        layersList.querySelectorAll('.layer-item').forEach(item => {
            item.addEventListener('click', () => {
                const elementId = item.dataset.elementId;
                const element = this.stage.findOne(`#${elementId}`);
                if (element) this.selectElement(element);
            });
        });
    }
    
    getElementIcon(type) {
        const icons = {
            container: '□',
            text: 'T',
            button: '⏹',
            input: '⌨',
            image: '🖼',
            card: '📄',
            unknown: '?'
        };
        
        return icons[type] || icons.unknown;
    }
    
    async loadDesignSystem(designSystemId) {
        try {
            const response = await fetch(`${this.serverConfig.apiUrl}/design-systems/load`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ designSystemId })
            });
            
            const result = await response.json();
            
            if (result.success) {
                this.designSystem = result.designSystem;
                this.updateTokensPanel();
                this.updateStatus(`Loaded design system: ${this.designSystem.name}`);
                
                // Update design system selector
                const select = document.getElementById('design-system-select');
                select.value = designSystemId;
                
                // Notify Flutter
                this.notifyFlutter('design_system_loaded', { designSystemId });
            } else {
                throw new Error(result.error);
            }
        } catch (error) {
            console.error('❌ Failed to load design system:', error);
            this.updateStatus(`Failed to load design system: ${error.message}`);
        }
    }
    
    updateTokensPanel() {
        const tokensContent = document.getElementById('tokens-content');
        
        if (!this.designSystem?.tokens) {
            tokensContent.innerHTML = '<div class="no-selection">No design tokens</div>';
            return;
        }
        
        let html = '';
        
        // Colors
        if (this.designSystem.tokens.colors) {
            html += '<div class="token-group"><div class="property-label">Colors</div>';
            Object.entries(this.designSystem.tokens.colors).forEach(([key, value]) => {
                html += `
                    <div class="token-item">
                        <span class="token-name">${key}</span>
                        <span class="token-value" style="color: ${value}">${value}</span>
                    </div>
                `;
            });
            html += '</div>';
        }
        
        // Spacing
        if (this.designSystem.tokens.spacing) {
            html += '<div class="token-group"><div class="property-label">Spacing</div>';
            Object.entries(this.designSystem.tokens.spacing).forEach(([key, value]) => {
                html += `
                    <div class="token-item">
                        <span class="token-name">${key}</span>
                        <span class="token-value">${value}px</span>
                    </div>
                `;
            });
            html += '</div>';
        }
        
        tokensContent.innerHTML = html;
    }
    
    getTokenValue(path, defaultValue) {
        if (!this.designSystem?.tokens) return defaultValue;
        
        const parts = path.split('.');
        let value = this.designSystem.tokens;
        
        for (const part of parts) {
            value = value?.[part];
            if (value === undefined) return defaultValue;
        }
        
        return value;
    }
    
    getComponentStyle(component, variant) {
        if (!this.designSystem?.components?.[component]?.variants?.[variant]) {
            return {};
        }
        
        const props = this.designSystem.components[component].variants[variant].props;
        
        // Replace token references
        const resolvedProps = {};
        Object.entries(props).forEach(([key, value]) => {
            if (typeof value === 'string' && value.startsWith('{{tokens.')) {
                const tokenPath = value.slice(9, -2); // Remove {{tokens. and }}
                resolvedProps[key] = this.getTokenValue(tokenPath, value);
            } else {
                resolvedProps[key] = value;
            }
        });
        
        return resolvedProps;
    }
    
    saveToHistory() {
        const state = this.getCanvasState();
        
        // Remove any history after current index
        this.history = this.history.slice(0, this.historyIndex + 1);
        
        // Add new state
        this.history.push(state);
        this.historyIndex++;
        
        // Limit history size
        if (this.history.length > 50) {
            this.history = this.history.slice(-50);
            this.historyIndex = this.history.length - 1;
        }
        
        this.updateElementCount();
    }
    
    undo() {
        if (this.historyIndex > 0) {
            this.historyIndex--;
            this.restoreFromHistory();
            this.updateStatus('Undo');
        }
    }
    
    redo() {
        if (this.historyIndex < this.history.length - 1) {
            this.historyIndex++;
            this.restoreFromHistory();
            this.updateStatus('Redo');
        }
    }
    
    restoreFromHistory() {
        const state = this.history[this.historyIndex];
        this.loadCanvasState(state);
    }
    
    getCanvasState() {
        const elements = this.layer.children
            .filter(child => child !== this.transformer)
            .map(element => this.elementToMCPData(element));
        
        return {
            id: 'canvas-1',
            name: 'Canvas',
            width: this.stage.width(),
            height: this.stage.height(),
            elements: elements,
            designSystemId: this.designSystem?.id
        };
    }
    
    loadCanvasState(state) {
        // Clear current elements
        this.layer.children.forEach(child => {
            if (child !== this.transformer) {
                child.destroy();
            }
        });
        
        // Recreate elements from state
        state.elements?.forEach(elementData => {
            const element = this.createElementFromData(elementData);
            if (element) {
                this.layer.add(element);
            }
        });
        
        this.layer.draw();
        this.clearSelection();
        this.updateLayersList();
        this.updateElementCount();
    }
    
    createElementFromData(data) {
        // This would recreate Konva elements from MCP data
        // Implementation depends on the element type and properties
        // For now, return null as this is complex
        return null;
    }
    
    elementToMCPData(element) {
        const base = {
            id: element.id(),
            type: element.attrs.elementType || 'container',
            x: element.x(),
            y: element.y(),
            width: element.width(),
            height: element.height(),
            rotation: element.rotation(),
            visible: element.visible(),
        };
        
        // Add type-specific properties
        if (element.fill) base.style = { backgroundColor: element.fill() };
        if (element.text) base.text = element.text();
        if (element.attrs.component) base.component = element.attrs.component;
        if (element.attrs.variant) base.variant = element.attrs.variant;
        
        return base;
    }
    
    updateUI() {
        this.updateElementCount();
        this.updateCanvasSize();
        this.updateZoomLevel();
    }
    
    updateElementCount() {
        const count = this.layer.children.filter(child => child !== this.transformer).length;
        document.getElementById('element-count').textContent = `${count} element${count !== 1 ? 's' : ''}`;
    }
    
    updateCanvasSize() {
        document.getElementById('canvas-size').textContent = `${this.stage.width()}×${this.stage.height()}`;
    }
    
    updateZoomLevel() {
        document.getElementById('zoom-level').textContent = `${Math.round(this.zoom * 100)}%`;
    }
    
    updateStatus(message) {
        document.getElementById('status-message').textContent = message;
        console.log('🎨', message);
    }
    
    handleResize() {
        const container = document.getElementById('canvas-container');
        const rect = container.getBoundingClientRect();
        
        this.stage.width(rect.width);
        this.stage.height(rect.height);
        this.stage.draw();
        
        this.updateCanvasSize();
    }
    
    showContextMenu(e) {
        e.evt.preventDefault();
        
        const menu = document.createElement('div');
        menu.className = 'context-menu';
        menu.style.left = e.evt.pageX + 'px';
        menu.style.top = e.evt.pageY + 'px';
        
        const items = [
            { text: 'Copy', action: () => this.copySelected() },
            { text: 'Paste', action: () => this.paste() },
            { text: 'Duplicate', action: () => this.duplicateSelected() },
            { text: 'Delete', action: () => this.deleteSelected() },
            { text: '-', action: null },
            { text: 'Bring to Front', action: () => this.bringToFront() },
            { text: 'Send to Back', action: () => this.sendToBack() },
        ];
        
        items.forEach(item => {
            if (item.text === '-') {
                const separator = document.createElement('div');
                separator.className = 'context-menu-separator';
                menu.appendChild(separator);
            } else {
                const button = document.createElement('button');
                button.className = 'context-menu-item';
                button.textContent = item.text;
                button.onclick = () => {
                    item.action();
                    this.hideContextMenu();
                };
                menu.appendChild(button);
            }
        });
        
        document.body.appendChild(menu);
        this.contextMenu = menu;
    }
    
    hideContextMenu() {
        if (this.contextMenu) {
            this.contextMenu.remove();
            this.contextMenu = null;
        }
    }
    
    // MCP Integration
    async callMCP(tool, args) {
        try {
            const response = await fetch(`${this.serverConfig.apiUrl}/mcp/call`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ tool, arguments: args })
            });
            
            const result = await response.json();
            
            if (!result.success) {
                throw new Error(result.error);
            }
            
            return result.result;
        } catch (error) {
            console.error('❌ MCP call failed:', error);
            throw error;
        }
    }
    
    notifyFlutter(type, data) {
        if (window.CanvasBridge) {
            window.CanvasBridge.postMessage(JSON.stringify({ type, ...data }));
        }
    }
    
    // Export/Import
    async exportCode() {
        try {
            const includeTokens = document.getElementById('include-tokens')?.checked ?? true;
            const componentize = document.getElementById('componentize')?.checked ?? true;
            
            const result = await this.callMCP('export_code', {
                format: 'flutter',
                includeTokens,
                componentize
            });
            
            document.getElementById('generated-code').textContent = result.content?.[1]?.text || 'No code generated';
            document.getElementById('export-modal').classList.add('show');
            
        } catch (error) {
            this.updateStatus(`Export failed: ${error.message}`);
        }
    }
    
    async saveCanvas() {
        try {
            const state = this.getCanvasState();
            
            const response = await fetch(`${this.serverConfig.apiUrl}/canvas/state`, {
                method: 'PUT',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify(state)
            });
            
            const result = await response.json();
            
            if (result.success) {
                this.updateStatus('Canvas saved successfully');
            } else {
                throw new Error(result.error);
            }
        } catch (error) {
            this.updateStatus(`Save failed: ${error.message}`);
        }
    }
    
    clearCanvas() {
        if (confirm('Are you sure you want to clear the canvas? This action cannot be undone.')) {
            this.layer.children.forEach(child => {
                if (child !== this.transformer) {
                    child.destroy();
                }
            });
            
            this.layer.draw();
            this.clearSelection();
            this.saveToHistory();
            this.updateLayersList();
            this.updateStatus('Canvas cleared');
            
            this.callMCP('clear_canvas', {});
        }
    }
    
    // Zoom controls
    zoomIn() {
        this.zoom = Math.min(this.zoom * 1.2, 5);
        this.applyZoom();
    }
    
    zoomOut() {
        this.zoom = Math.max(this.zoom / 1.2, 0.1);
        this.applyZoom();
    }
    
    resetZoom() {
        this.zoom = 1;
        this.applyZoom();
    }
    
    applyZoom() {
        this.stage.scale({ x: this.zoom, y: this.zoom });
        this.stage.draw();
        this.updateZoomLevel();
    }
}

// Global functions for HTML onclick handlers
let canvas;

function undoAction() { canvas?.undo(); }
function redoAction() { canvas?.redo(); }
function duplicateSelected() { canvas?.duplicateSelected(); }
function deleteSelected() { canvas?.deleteSelected(); }
function alignElements(alignment) { canvas?.alignElements(alignment); }
function exportCode() { canvas?.exportCode(); }
function saveCanvas() { canvas?.saveCanvas(); }
function clearCanvas() { canvas?.clearCanvas(); }
function zoomIn() { canvas?.zoomIn(); }
function zoomOut() { canvas?.zoomOut(); }
function resetZoom() { canvas?.resetZoom(); }

function closeExportModal() {
    document.getElementById('export-modal').classList.remove('show');
}

function copyCode() {
    const code = document.getElementById('generated-code').textContent;
    navigator.clipboard.writeText(code).then(() => {
        canvas?.updateStatus('Code copied to clipboard');
    });
}

function downloadCode() {
    const code = document.getElementById('generated-code').textContent;
    const blob = new Blob([code], { type: 'text/plain' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = 'generated_screen.dart';
    a.click();
    URL.revokeObjectURL(url);
}

// Initialize canvas when DOM is loaded
document.addEventListener('DOMContentLoaded', () => {
    canvas = new AsmbliCanvas();
});