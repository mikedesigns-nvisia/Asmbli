// Asmbli Design Library - Flutter Components for Excalidraw
// This file contains the component library definitions and creation functions

// Component library definitions
window.asmblDesignLibrary = {
  material: {
    appBar: {
      name: "AppBar",
      description: "Material Design app bar with title and actions",
      category: "material",
      flutterWidget: "AppBar",
      excalidrawElements: ["rectangle", "text"]
    },
    floatingActionButton: {
      name: "FAB",
      description: "Circular floating action button",
      category: "material",
      flutterWidget: "FloatingActionButton",
      excalidrawElements: ["ellipse", "text"]
    },
    elevatedButton: {
      name: "Button",
      description: "Material elevated button",
      category: "material",
      flutterWidget: "ElevatedButton",
      excalidrawElements: ["rectangle", "text"]
    },
    card: {
      name: "Card",
      description: "Material Design card container",
      category: "material",
      flutterWidget: "Card",
      excalidrawElements: ["rectangle"]
    },
    listTile: {
      name: "ListTile",
      description: "Single fixed-height row",
      category: "material",
      flutterWidget: "ListTile",
      excalidrawElements: ["rectangle", "text", "ellipse"]
    }
  },
  
  layout: {
    container: {
      name: "Container",
      description: "Box model container widget",
      category: "layout",
      flutterWidget: "Container",
      excalidrawElements: ["rectangle"]
    },
    column: {
      name: "Column",
      description: "Vertical layout widget",
      category: "layout",
      flutterWidget: "Column",
      excalidrawElements: ["rectangle"]
    },
    row: {
      name: "Row",
      description: "Horizontal layout widget",
      category: "layout",
      flutterWidget: "Row",
      excalidrawElements: ["rectangle"]
    },
    stack: {
      name: "Stack",
      description: "Overlay layout widget",
      category: "layout",
      flutterWidget: "Stack",
      excalidrawElements: ["rectangle"]
    },
    gridView: {
      name: "GridView",
      description: "Scrollable grid layout",
      category: "layout",
      flutterWidget: "GridView",
      excalidrawElements: ["rectangle"]
    }
  },
  
  forms: {
    textField: {
      name: "TextField",
      description: "Text input field",
      category: "forms",
      flutterWidget: "TextField",
      excalidrawElements: ["rectangle", "text"]
    },
    checkbox: {
      name: "Checkbox",
      description: "Checkbox input",
      category: "forms",
      flutterWidget: "Checkbox",
      excalidrawElements: ["rectangle"]
    },
    radioButton: {
      name: "Radio",
      description: "Radio button input",
      category: "forms",
      flutterWidget: "Radio",
      excalidrawElements: ["ellipse"]
    },
    dropdown: {
      name: "Dropdown",
      description: "Dropdown selection",
      category: "forms",
      flutterWidget: "DropdownButton",
      excalidrawElements: ["rectangle", "text"]
    },
    slider: {
      name: "Slider",
      description: "Range slider input",
      category: "forms",
      flutterWidget: "Slider",
      excalidrawElements: ["line", "ellipse"]
    }
  },
  
  asmbli: {
    asmblButton: {
      name: "AsmblButton",
      description: "Custom Asmbli button component",
      category: "asmbli",
      flutterWidget: "AsmblButton",
      excalidrawElements: ["rectangle", "text"]
    },
    asmblCard: {
      name: "AsmblCard",
      description: "Custom Asmbli card component",
      category: "asmbli",
      flutterWidget: "AsmblCard",
      excalidrawElements: ["rectangle"]
    },
    asmblModal: {
      name: "Modal",
      description: "Asmbli modal dialog",
      category: "asmbli",
      flutterWidget: "AsmblModal",
      excalidrawElements: ["rectangle"]
    },
    asmblToast: {
      name: "Toast",
      description: "Asmbli toast notification",
      category: "asmbli",
      flutterWidget: "AsmblToast",
      excalidrawElements: ["rectangle", "text"]
    }
  }
};

// Flutter component creation functions
window.addFlutterComponent = function(componentKey, category) {
  console.log(`Creating Flutter component: ${componentKey} from ${category}`);
  
  if (!window.excalidrawAPI) {
    console.error('Excalidraw API not ready');
    return;
  }

  const component = window.asmblDesignLibrary[category]?.[componentKey];
  if (!component) {
    console.error(`Component not found: ${componentKey} in ${category}`);
    return;
  }

  const elements = [];
  const baseX = Math.random() * 400 + 100;
  const baseY = Math.random() * 400 + 100;
  const componentWidth = getComponentWidth(componentKey);
  const componentHeight = getComponentHeight(componentKey);
  
  try {
    switch (componentKey) {
      case 'appBar':
        elements.push(...createAppBarComponent(baseX, baseY, componentWidth, componentHeight));
        break;
      case 'floatingActionButton':
        elements.push(...createFABComponent(baseX, baseY, 56, 56));
        break;
      case 'elevatedButton':
        elements.push(...createButtonComponent(baseX, baseY, componentWidth, componentHeight, 'ElevatedButton'));
        break;
      case 'card':
        elements.push(...createCardComponent(baseX, baseY, componentWidth, componentHeight));
        break;
      case 'listTile':
        elements.push(...createListTileComponent(baseX, baseY, componentWidth, componentHeight));
        break;
      case 'textField':
        elements.push(...createTextFieldComponent(baseX, baseY, componentWidth, componentHeight));
        break;
      case 'checkbox':
        elements.push(...createCheckboxComponent(baseX, baseY, 24, 24));
        break;
      case 'radioButton':
        elements.push(...createRadioButtonComponent(baseX, baseY, 24, 24));
        break;
      case 'container':
      case 'column':
      case 'row':
      case 'stack':
      case 'gridView':
        elements.push(...createLayoutComponent(baseX, baseY, componentWidth, componentHeight, component.name));
        break;
      default:
        // Generic component creation
        elements.push(...createGenericComponent(baseX, baseY, componentWidth, componentHeight, component.name));
    }

    if (elements.length > 0) {
      window.excalidrawAPI.updateScene({
        elements: [...window.excalidrawAPI.getSceneElements(), ...elements]
      });
      console.log(`✅ Created Flutter ${componentKey} component with ${elements.length} elements`);
    }
  } catch (error) {
    console.error(`Error creating Flutter component ${componentKey}:`, error);
  }
};

// Component size helpers
function getComponentWidth(componentKey) {
  const widths = {
    'appBar': 320,
    'floatingActionButton': 56,
    'elevatedButton': 120,
    'card': 200,
    'listTile': 280,
    'textField': 200,
    'checkbox': 24,
    'radioButton': 24,
    'container': 150,
    'column': 120,
    'row': 200,
    'stack': 150,
    'gridView': 250
  };
  return widths[componentKey] || 120;
}

function getComponentHeight(componentKey) {
  const heights = {
    'appBar': 56,
    'floatingActionButton': 56,
    'elevatedButton': 36,
    'card': 120,
    'listTile': 56,
    'textField': 48,
    'checkbox': 24,
    'radioButton': 24,
    'container': 100,
    'column': 150,
    'row': 80,
    'stack': 120,
    'gridView': 200
  };
  return heights[componentKey] || 100;
}

// Specific component creation functions
function createAppBarComponent(x, y, width, height) {
  const elements = [];
  
  // AppBar background
  elements.push({
    type: "rectangle",
    version: 1,
    versionNonce: Math.floor(Math.random() * 1000000),
    isDeleted: false,
    id: generateId(),
    fillStyle: "solid",
    strokeWidth: 1,
    strokeStyle: "solid",
    roughness: 0,
    opacity: 100,
    angle: 0,
    x: x,
    y: y,
    strokeColor: "#2196F3",
    backgroundColor: "#2196F3",
    width: width,
    height: height,
    seed: Math.floor(Math.random() * 1000000),
    groupIds: [],
    frameId: null,
    roundness: { type: 1, value: 4 },
    boundElements: [],
    updated: 1,
    link: null,
    locked: false
  });
  
  // Title text
  elements.push({
    type: "text",
    version: 1,
    versionNonce: Math.floor(Math.random() * 1000000),
    isDeleted: false,
    id: generateId(),
    fillStyle: "solid",
    strokeWidth: 1,
    strokeStyle: "solid",
    roughness: 0,
    opacity: 100,
    angle: 0,
    x: x + 16,
    y: y + height/2 - 10,
    strokeColor: "#FFFFFF",
    backgroundColor: "transparent",
    width: 80,
    height: 20,
    seed: Math.floor(Math.random() * 1000000),
    groupIds: [],
    frameId: null,
    roundness: null,
    boundElements: [],
    updated: 1,
    link: null,
    locked: false,
    fontSize: 16,
    fontFamily: 1,
    text: "AppBar Title",
    textAlign: "left",
    verticalAlign: "middle",
    containerId: null,
    originalText: "AppBar Title",
    lineHeight: 1.25
  });
  
  return elements;
}

function createFABComponent(x, y, width, height) {
  return [{
    type: "ellipse",
    version: 1,
    versionNonce: Math.floor(Math.random() * 1000000),
    isDeleted: false,
    id: generateId(),
    fillStyle: "solid",
    strokeWidth: 2,
    strokeStyle: "solid",
    roughness: 0,
    opacity: 100,
    angle: 0,
    x: x,
    y: y,
    strokeColor: "#2196F3",
    backgroundColor: "#2196F3",
    width: width,
    height: height,
    seed: Math.floor(Math.random() * 1000000),
    groupIds: [],
    frameId: null,
    roundness: null,
    boundElements: [],
    updated: 1,
    link: null,
    locked: false
  }];
}

function createButtonComponent(x, y, width, height, buttonType) {
  return [{
    type: "rectangle",
    version: 1,
    versionNonce: Math.floor(Math.random() * 1000000),
    isDeleted: false,
    id: generateId(),
    fillStyle: "solid",
    strokeWidth: 1,
    strokeStyle: "solid",
    roughness: 0,
    opacity: 100,
    angle: 0,
    x: x,
    y: y,
    strokeColor: "#2196F3",
    backgroundColor: "#E3F2FD",
    width: width,
    height: height,
    seed: Math.floor(Math.random() * 1000000),
    groupIds: [],
    frameId: null,
    roundness: { type: 1, value: 8 },
    boundElements: [],
    updated: 1,
    link: null,
    locked: false
  }];
}

function createCardComponent(x, y, width, height) {
  return [{
    type: "rectangle",
    version: 1,
    versionNonce: Math.floor(Math.random() * 1000000),
    isDeleted: false,
    id: generateId(),
    fillStyle: "solid",
    strokeWidth: 1,
    strokeStyle: "solid",
    roughness: 0,
    opacity: 100,
    angle: 0,
    x: x,
    y: y,
    strokeColor: "#E0E0E0",
    backgroundColor: "#FFFFFF",
    width: width,
    height: height,
    seed: Math.floor(Math.random() * 1000000),
    groupIds: [],
    frameId: null,
    roundness: { type: 1, value: 8 },
    boundElements: [],
    updated: 1,
    link: null,
    locked: false
  }];
}

function createListTileComponent(x, y, width, height) {
  const elements = [];
  
  // Background
  elements.push({
    type: "rectangle",
    version: 1,
    versionNonce: Math.floor(Math.random() * 1000000),
    isDeleted: false,
    id: generateId(),
    fillStyle: "solid",
    strokeWidth: 1,
    strokeStyle: "solid",
    roughness: 0,
    opacity: 100,
    angle: 0,
    x: x,
    y: y,
    strokeColor: "#E0E0E0",
    backgroundColor: "#FAFAFA",
    width: width,
    height: height,
    seed: Math.floor(Math.random() * 1000000),
    groupIds: [],
    frameId: null,
    roundness: null,
    boundElements: [],
    updated: 1,
    link: null,
    locked: false
  });
  
  // Leading icon circle
  elements.push({
    type: "ellipse",
    version: 1,
    versionNonce: Math.floor(Math.random() * 1000000),
    isDeleted: false,
    id: generateId(),
    fillStyle: "solid",
    strokeWidth: 1,
    strokeStyle: "solid",
    roughness: 0,
    opacity: 100,
    angle: 0,
    x: x + 16,
    y: y + height/2 - 20,
    strokeColor: "#2196F3",
    backgroundColor: "#E3F2FD",
    width: 40,
    height: 40,
    seed: Math.floor(Math.random() * 1000000),
    groupIds: [],
    frameId: null,
    roundness: null,
    boundElements: [],
    updated: 1,
    link: null,
    locked: false
  });
  
  return elements;
}

function createTextFieldComponent(x, y, width, height) {
  return [{
    type: "rectangle",
    version: 1,
    versionNonce: Math.floor(Math.random() * 1000000),
    isDeleted: false,
    id: generateId(),
    fillStyle: "solid",
    strokeWidth: 2,
    strokeStyle: "solid",
    roughness: 0,
    opacity: 100,
    angle: 0,
    x: x,
    y: y,
    strokeColor: "#2196F3",
    backgroundColor: "#FFFFFF",
    width: width,
    height: height,
    seed: Math.floor(Math.random() * 1000000),
    groupIds: [],
    frameId: null,
    roundness: { type: 1, value: 4 },
    boundElements: [],
    updated: 1,
    link: null,
    locked: false
  }];
}

function createCheckboxComponent(x, y, width, height) {
  return [{
    type: "rectangle",
    version: 1,
    versionNonce: Math.floor(Math.random() * 1000000),
    isDeleted: false,
    id: generateId(),
    fillStyle: "hachure",
    strokeWidth: 2,
    strokeStyle: "solid",
    roughness: 0,
    opacity: 100,
    angle: 0,
    x: x,
    y: y,
    strokeColor: "#2196F3",
    backgroundColor: "transparent",
    width: width,
    height: height,
    seed: Math.floor(Math.random() * 1000000),
    groupIds: [],
    frameId: null,
    roundness: { type: 1, value: 2 },
    boundElements: [],
    updated: 1,
    link: null,
    locked: false
  }];
}

function createRadioButtonComponent(x, y, width, height) {
  return [{
    type: "ellipse",
    version: 1,
    versionNonce: Math.floor(Math.random() * 1000000),
    isDeleted: false,
    id: generateId(),
    fillStyle: "hachure",
    strokeWidth: 2,
    strokeStyle: "solid",
    roughness: 0,
    opacity: 100,
    angle: 0,
    x: x,
    y: y,
    strokeColor: "#2196F3",
    backgroundColor: "transparent",
    width: width,
    height: height,
    seed: Math.floor(Math.random() * 1000000),
    groupIds: [],
    frameId: null,
    roundness: null,
    boundElements: [],
    updated: 1,
    link: null,
    locked: false
  }];
}

function createLayoutComponent(x, y, width, height, componentName) {
  return [{
    type: "rectangle",
    version: 1,
    versionNonce: Math.floor(Math.random() * 1000000),
    isDeleted: false,
    id: generateId(),
    fillStyle: "hachure",
    strokeWidth: 2,
    strokeStyle: "dashed",
    roughness: 0,
    opacity: 100,
    angle: 0,
    x: x,
    y: y,
    strokeColor: "#9C27B0",
    backgroundColor: "transparent",
    width: width,
    height: height,
    seed: Math.floor(Math.random() * 1000000),
    groupIds: [],
    frameId: null,
    roundness: { type: 1, value: 4 },
    boundElements: [],
    updated: 1,
    link: null,
    locked: false
  }];
}

function createGenericComponent(x, y, width, height, componentName) {
  return [{
    type: "rectangle",
    version: 1,
    versionNonce: Math.floor(Math.random() * 1000000),
    isDeleted: false,
    id: generateId(),
    fillStyle: "solid",
    strokeWidth: 2,
    strokeStyle: "solid",
    roughness: 0,
    opacity: 100,
    angle: 0,
    x: x,
    y: y,
    strokeColor: "#4CAF50",
    backgroundColor: "#E8F5E8",
    width: width,
    height: height,
    seed: Math.floor(Math.random() * 1000000),
    groupIds: [],
    frameId: null,
    roundness: { type: 1, value: 4 },
    boundElements: [],
    updated: 1,
    link: null,
    locked: false
  }];
}

// Flutter screen template functions
window.addFlutterScreenTemplate = function(templateType) {
  console.log(`Creating Flutter screen template: ${templateType}`);
  
  if (!window.excalidrawAPI) {
    console.error('Excalidraw API not ready');
    return;
  }

  const elements = [];
  
  try {
    switch (templateType) {
      case 'dashboard':
        elements.push(...createDashboardTemplate());
        break;
      case 'list':
        elements.push(...createListTemplate());
        break;
      case 'form':
        elements.push(...createFormTemplate());
        break;
      default:
        console.error(`Unknown template type: ${templateType}`);
        return;
    }

    if (elements.length > 0) {
      window.excalidrawAPI.updateScene({
        elements: [...window.excalidrawAPI.getSceneElements(), ...elements]
      });
      console.log(`✅ Created Flutter ${templateType} template with ${elements.length} elements`);
    }
  } catch (error) {
    console.error(`Error creating Flutter template ${templateType}:`, error);
  }
};

function createDashboardTemplate() {
  const elements = [];
  const baseX = 50;
  const baseY = 50;
  
  // AppBar
  elements.push(...createAppBarComponent(baseX, baseY, 320, 56));
  
  // Stats cards row
  for (let i = 0; i < 3; i++) {
    elements.push(...createCardComponent(baseX + i * 110, baseY + 80, 100, 80));
  }
  
  // Main content area
  elements.push(...createCardComponent(baseX, baseY + 180, 320, 200));
  
  return elements;
}

function createListTemplate() {
  const elements = [];
  const baseX = 50;
  const baseY = 50;
  
  // AppBar
  elements.push(...createAppBarComponent(baseX, baseY, 320, 56));
  
  // List items
  for (let i = 0; i < 6; i++) {
    elements.push(...createListTileComponent(baseX, baseY + 80 + i * 60, 320, 56));
  }
  
  return elements;
}

function createFormTemplate() {
  const elements = [];
  const baseX = 50;
  const baseY = 50;
  
  // AppBar
  elements.push(...createAppBarComponent(baseX, baseY, 320, 56));
  
  // Form fields
  const fieldSpacing = 70;
  for (let i = 0; i < 4; i++) {
    elements.push(...createTextFieldComponent(baseX + 20, baseY + 80 + i * fieldSpacing, 280, 48));
  }
  
  // Submit button
  elements.push(...createButtonComponent(baseX + 20, baseY + 80 + 4 * fieldSpacing + 20, 280, 48, 'Submit'));
  
  return elements;
}

// Utility function for generating element IDs
function generateId() {
  return Date.now().toString(36) + Math.random().toString(36).substr(2);
}

console.log('🎨 Asmbli Design Library loaded with', Object.keys(window.asmblDesignLibrary).length, 'categories');