# Penpot Migration Requirements

**Date**: 2025-11-15
**Project**: Excalidraw → Penpot Canvas Migration
**Approach**: Spec-Driven Development (Kiro-Style)
**Status**: Phase 1 - Requirements

---

## Executive Summary

This document defines the requirements for migrating from Excalidraw to Penpot as the canvas backend for Asmbli's AI-powered design agent. The migration enables full design tool capabilities including components, design systems, auto-layout, and production-quality mockups.

---

## R1: Penpot WebView Integration

**As a** developer integrating Penpot
**I want** Penpot embedded in the Flutter desktop app via WebView
**So that** users can interact with professional design tools directly in Asmbli

### Acceptance Criteria:
- **GIVEN** the Canvas Library screen is opened
- **WHEN** the Penpot canvas view is selected
- **THEN** the Penpot web app loads within a Flutter WebView
- **AND** the WebView supports full JavaScript execution
- **AND** users can manually create/edit designs in Penpot
- **AND** the Penpot UI is fully interactive (pan, zoom, select, edit)

### Technical Requirements:
- WebView widget: `webview_flutter` package
- JavaScript mode: Unrestricted
- Target URL: `https://design.penpot.app` (cloud) or `http://localhost:9001` (self-hosted)
- Dimensions: Full screen within canvas area
- Performance: 60fps canvas interaction

### Visual Requirements:
- Penpot UI fills canvas area (no borders/padding)
- Smooth integration with Asmbli's design system
- Loading state while Penpot initializes

---

## R2: Penpot Plugin Bridge for Agent Control

**As an** AI agent
**I want** to programmatically create shapes and components in Penpot
**So that** I can execute design tasks without manual user input

### Acceptance Criteria:
- **GIVEN** a Penpot plugin is installed
- **WHEN** the agent sends a create command (e.g., "create_dashboard")
- **THEN** the plugin receives the command via JavaScript bridge
- **AND** the plugin creates the requested elements using Penpot Plugin API
- **AND** the elements appear on the canvas in real-time
- **AND** the agent receives confirmation of success/failure

### Technical Requirements:
- Penpot plugin written in TypeScript
- Plugin manifest with `content:write` permission
- JavaScript bridge: `window.postMessage()` for Flutter → Plugin communication
- `window.addEventListener('message')` for Plugin → Flutter responses
- Command format: JSON with `{ source: 'asmbli-agent', type: string, params: object }`

### Functional Requirements:
- Plugin commands supported:
  - `create_board` - Create Penpot board (frame)
  - `create_rectangle` - Create rectangle shape
  - `create_text` - Create text element
  - `create_component` - Create reusable component
  - `apply_layout` - Apply auto-layout constraints
  - `set_fills` - Apply colors/gradients
  - `set_strokes` - Apply borders
  - `get_board_state` - Read current canvas state

### Validation Criteria:
- Command execution time: <500ms per element
- Error handling: All plugin errors return to agent with details
- State consistency: Canvas state matches agent's expected result

---

## R3: MCP Server for Penpot Integration

**As a** developer building the agent-canvas bridge
**I want** an MCP server that translates agent requests into Penpot plugin commands
**So that** the agent can interact with Penpot using the existing MCP architecture

### Acceptance Criteria:
- **GIVEN** the MCP Penpot server is initialized
- **WHEN** the agent calls an MCP tool (e.g., `create_element`)
- **THEN** the MCP server formats the request for the Penpot plugin
- **AND** sends the command via the JavaScript bridge
- **AND** waits for the plugin response
- **AND** returns the result to the agent in MCP format

### Technical Requirements:
- Service: `MCPPenpotServer` (Dart)
- Location: `apps/desktop/lib/core/services/mcp_penpot_server.dart`
- MCP tools to implement:
  - `create_board({ name, width, height, background })`
  - `create_element({ type, x, y, width, height, properties })`
  - `create_component({ type, elements, variants })`
  - `apply_design_tokens({ elementId, tokens })`
  - `create_template({ template, x, y })`
  - `get_canvas_state()`
  - `export_to_code({ format })`

### Integration Requirements:
- Register with ServiceLocator
- Initialize on app startup
- Access to PenpotCanvasState for JavaScript bridge
- Error propagation to agent chat

### MCP Response Format:
```json
{
  "success": true,
  "elementId": "uuid-1234",
  "type": "rectangle",
  "properties": {
    "x": 100,
    "y": 200,
    "width": 300,
    "height": 150
  }
}
```

---

## R4: Spec-Driven Design Workflow Integration

**As an** AI agent
**I want** to follow a structured 4-phase design workflow
**So that** I create intentional, requirements-driven designs instead of random "vibe designing"

### Acceptance Criteria:
- **GIVEN** a user requests a design (e.g., "create a dashboard")
- **WHEN** the agent begins the task
- **THEN** the agent generates a requirements document (Phase 1)
- **AND** presents it to the user for review/approval
- **AND** upon approval, generates a design specification (Phase 2)
- **AND** presents it to the user for review/approval
- **AND** upon approval, generates a task breakdown (Phase 3)
- **AND** presents it to the user for review/approval
- **AND** upon approval, executes tasks sequentially (Phase 4)
- **AND** validates each task against acceptance criteria

### Workflow Requirements:

#### Phase 1: Requirements (`design_requirements.md`)
- User story format: "As a... I want... So that..."
- Acceptance criteria: GIVEN/WHEN/THEN format
- Visual requirements: specific sizes, colors, layouts
- Agent asks 3-5 clarifying questions before generating
- User can iterate/approve before moving to Phase 2

#### Phase 2: Design Specification (`design_spec.md`)
- Component architecture (ASCII diagram)
- Design token mappings (from session context)
- Component specifications (sizes, states, variants)
- Implementation approach (step-by-step)
- Research integration: Agent searches "2025 {design_type} design patterns"
- User can iterate/approve before moving to Phase 3

#### Phase 3: Implementation Tasks (`design_tasks.md`)
- 5-10 atomic tasks
- Each task maps to requirements (R1, R2, etc.)
- MCP commands listed for each task
- Validation criteria defined
- User can iterate/approve before moving to Phase 4

#### Phase 4: Execution
- Agent executes tasks sequentially
- Validates each task after completion
- Reports progress in real-time
- Final validation against all requirements
- Offers code export upon completion

### System Prompt Requirements:
- Agent MUST follow 4-phase workflow (no skipping)
- Agent NEVER "vibe designs" (no random shapes)
- Agent ALWAYS traces elements to requirements
- Agent ALWAYS waits for user approval between phases

### File Output Requirements:
```
canvas_projects/
└── {project_name}/
    ├── design_requirements.md   # Phase 1 output
    ├── design_spec.md           # Phase 2 output
    ├── design_tasks.md          # Phase 3 output
    ├── {project_name}.penpot    # Phase 4 output
    └── exports/                 # Optional code exports
```

---

## R5: Context Library Integration (User-Controlled)

**As a** user preparing to create a design
**I want** to add brand guidelines and design tokens to my chat session
**So that** the agent uses my exact brand values instead of making assumptions

### Acceptance Criteria:
- **GIVEN** I have brand guidelines and design tokens
- **WHEN** I add them to the chat session via the Agent Panel UI
- **THEN** the agent can read this context via MCP tools
- **AND** the agent uses exact values from my design tokens
- **AND** the agent follows my brand guidelines
- **AND** the agent never searches or loads context automatically

### User Flow:
1. User opens Agent Panel
2. User clicks [+ Add Context]
3. User selects from Context Library or uploads new file
4. Context appears in session (visible to user and agent)
5. Agent reads context passively when generating designs

### MCP Tools Required:
```dart
// Read-only access to user-added context
getSessionContext() → {
  documents: [
    { title, category, content, added_at }
  ],
  total: int
}

// Read design tokens from session or app defaults
getDesignTokens() → {
  colors: { primary, accent, background, ... },
  spacing: { xs, sm, md, lg, xl, ... },
  typography: { families, sizes, weights, ... },
  borderRadius: { sm, md, lg, xl },
}
```

### Agent Behavior Requirements:
- Agent calls `getSessionContext()` at start of Phase 1
- Agent uses exact token values (no approximations)
- Agent mentions which context documents informed decisions
- Agent NEVER searches context library autonomously
- Agent informs user if required context is missing

### Example Agent Message:
> "I see you've added 'Brand Guidelines v2.1' and 'Design Tokens 2024'. I'll use your primary color #4ecdc4 and Space Grotesk typography as specified. Let me generate requirements..."

---

## R6: Template System for Common Designs

**As an** AI agent
**I want** pre-built templates for common design patterns
**So that** I can quickly scaffold dashboards, forms, and wireframes

### Acceptance Criteria:
- **GIVEN** the agent needs to create a common design type
- **WHEN** the agent calls `create_template({ template: 'dashboard' })`
- **THEN** the MCP server creates a complete layout using Penpot components
- **AND** the template follows the user's design tokens (if provided)
- **AND** the template uses modern 2025 design patterns
- **AND** the template is fully editable by the agent and user

### Templates Required:
1. **Dashboard Template**:
   - Header with branding area
   - 2x2 metric cards (KPI display)
   - Chart area (line/bar chart placeholder)
   - Table area (data grid placeholder)
   - Responsive layout with auto-layout constraints

2. **Form Template**:
   - Form header with title
   - Input fields (text, email, password)
   - Dropdown selectors
   - Radio buttons / checkboxes
   - Primary action button (submit)
   - Secondary action button (cancel)

3. **Wireframe Template**:
   - Navigation bar
   - Sidebar
   - Main content area
   - Footer
   - Grayscale/low-fidelity aesthetic

4. **Mobile App Template**:
   - Mobile frame (375x812px)
   - Status bar
   - Navigation bar
   - Content area
   - Bottom tab bar

### Design Token Integration:
- Templates use `getDesignTokens()` for colors, spacing, typography
- Fallback to Asmbli design system if no user tokens provided
- All templates customizable via MCP commands

---

## R7: Real-Time Canvas State Visibility

**As an** agent creating designs
**I want** to read the current canvas state
**So that** I can make informed decisions about element placement and avoid overlaps

### Acceptance Criteria:
- **GIVEN** elements exist on the Penpot canvas
- **WHEN** the agent calls `get_canvas_state()`
- **THEN** the MCP server requests state from the Penpot plugin
- **AND** the plugin returns all boards, elements, and their properties
- **AND** the agent receives element positions, sizes, types, and IDs

### Canvas State Format:
```json
{
  "boards": [
    {
      "id": "board-1",
      "name": "Dashboard",
      "width": 1440,
      "height": 900,
      "elements": [
        {
          "id": "element-1",
          "type": "rectangle",
          "x": 100,
          "y": 200,
          "width": 300,
          "height": 150,
          "fills": [{ "fillColor": "#4ecdc4" }],
          "name": "Header"
        }
      ]
    }
  ],
  "totalElements": 1
}
```

### Agent Use Cases:
- Check if canvas is empty before creating first element
- Find available space for new elements
- Identify existing components to reuse
- Validate task completion (expected elements exist)

---

## R8: Production-Quality Design Output

**As a** user creating designs
**I want** the agent to produce hi-fidelity, production-ready mockups
**So that** I can use them for client presentations, developer handoff, or direct export to code

### Acceptance Criteria:
- **GIVEN** the agent completes a design
- **WHEN** I review the Penpot canvas
- **THEN** all elements are properly styled (colors, borders, shadows)
- **AND** typography is correctly applied (font family, size, weight)
- **AND** spacing follows 8pt grid system
- **AND** components are reusable (created as Penpot components)
- **AND** auto-layout constraints are applied where appropriate
- **AND** the design matches modern 2025 aesthetic standards

### Quality Standards:
- **Accessibility**: Contrast ratio ≥ 4.5:1 for text
- **Consistency**: All similar elements use same component
- **Alignment**: Elements snap to 8pt grid
- **Hierarchy**: Clear visual hierarchy (size, weight, color)
- **Polish**: Rounded corners, subtle shadows, gradient backgrounds

### Code Export:
- Agent offers code export after design completion
- Export formats: Flutter widgets, React components, HTML/CSS
- Exported code uses design tokens (not hardcoded values)

---

## R9: Migration Completeness (Remove Excalidraw Dependencies)

**As a** developer completing the migration
**I want** all Excalidraw code and dependencies removed
**So that** the codebase is clean and maintainable

### Acceptance Criteria:
- **GIVEN** Penpot integration is complete and tested
- **WHEN** the migration is finalized
- **THEN** all Excalidraw-related code is removed:
  - `mcp_excalidraw_server.dart`
  - `mcp_excalidraw_bridge_service.dart`
  - `excalidraw_canvas.dart` widget
  - Excalidraw assets in `assets/excalidraw/`
- **AND** all references to Excalidraw are updated to Penpot
- **AND** service locator registrations are updated
- **AND** no unused imports remain
- **AND** `flutter analyze` passes with no warnings

### Cleanup Checklist:
- [ ] Remove Excalidraw services
- [ ] Remove Excalidraw widgets
- [ ] Remove Excalidraw assets
- [ ] Update ServiceLocator
- [ ] Update imports
- [ ] Update documentation
- [ ] Run `flutter analyze`
- [ ] Run `flutter test`

---

## R10: Testing and Validation

**As a** developer ensuring quality
**I want** comprehensive tests for the Penpot integration
**So that** the migration is stable and reliable

### Acceptance Criteria:
- **GIVEN** the Penpot integration is complete
- **WHEN** tests are run
- **THEN** all test suites pass:
  - Unit tests for MCPPenpotServer
  - Widget tests for PenpotCanvas
  - Integration tests for end-to-end agent workflows
- **AND** test coverage is ≥ 40% for new code

### Test Cases Required:

#### Unit Tests (`test/unit/services/mcp_penpot_server_test.dart`):
- [ ] `create_board()` formats command correctly
- [ ] `create_element()` sends to plugin via bridge
- [ ] `get_canvas_state()` parses plugin response
- [ ] Error handling for plugin failures
- [ ] Design token retrieval from session context

#### Widget Tests (`test/widget/penpot_canvas_test.dart`):
- [ ] PenpotCanvas loads WebView
- [ ] JavaScript bridge sends messages
- [ ] Plugin responses received correctly

#### Integration Tests (`test/integration/penpot_workflow_test.dart`):
- [ ] Agent creates dashboard end-to-end
- [ ] Spec-driven workflow completes all 4 phases
- [ ] Context library integration works
- [ ] Templates create expected layouts

---

## Success Metrics

Upon completion of this migration, the following must be true:

✅ **Functional Success**:
- Agent can create dashboards, forms, wireframes, and mobile mockups
- All 4 phases of spec-driven workflow function correctly
- Context library integration provides design tokens to agent
- Penpot plugin receives and executes all agent commands
- Canvas state is readable by agent

✅ **Quality Success**:
- Designs are production-quality (hi-fidelity mockups)
- Designs follow user's brand guidelines and design tokens
- Designs match modern 2025 aesthetic standards
- Every element traces to a requirement
- No "vibe designing" - all designs are spec-driven

✅ **Technical Success**:
- All Excalidraw code removed
- Test coverage ≥ 40% for new code
- `flutter analyze` passes with no warnings
- Performance: 60fps canvas interaction, <500ms command execution

✅ **User Experience Success**:
- Users can review/approve at each phase
- Users add context via UI (not agent-driven)
- Designs match user expectations on first try (not trial-and-error)
- Code export provides usable Flutter/React code

---

## Non-Requirements (Out of Scope)

The following are explicitly NOT part of this migration:

❌ Self-hosted Penpot deployment (use cloud for now)
❌ Offline canvas editing (requires internet connection)
❌ Real-time collaboration (single user only)
❌ Version control for designs (manual save only)
❌ Advanced Penpot features (animations, prototyping)
❌ Mobile app support (desktop only)

---

## Dependencies

This migration depends on:

1. **Penpot Account**: User must create account at design.penpot.app
2. **Penpot API Token**: User must generate access token with `content:write` permission
3. **Flutter WebView Package**: `webview_flutter` ≥ 4.0.0
4. **Penpot Plugin System**: Requires Penpot version with Plugin API support (2024+)
5. **Existing MCP Architecture**: ServiceLocator, MCPBridgeService must be functional
6. **Design System**: Asmbli design tokens available for fallback

---

## Timeline and Phases

### Week 1: Setup and Proof of Concept
- **R1**: Penpot WebView Integration ✓
- **R2**: Basic Penpot Plugin (create rectangle only) ✓
- **R3**: MCPPenpotServer skeleton ✓

### Week 2: Plugin Development
- **R2**: Full plugin command set ✓
- **R6**: Template system (dashboard template) ✓
- **R7**: Canvas state reading ✓

### Week 3: Flutter Integration
- **R3**: Complete MCPPenpotServer ✓
- JavaScript bridge bidirectional communication ✓
- Error handling and retries ✓

### Week 4: Agent Integration
- **R4**: Spec-driven workflow integration ✓
- **R5**: Context library integration ✓
- **R8**: Production-quality output validation ✓

### Week 5: Migration and Cleanup
- **R9**: Remove Excalidraw dependencies ✓
- **R10**: Testing and validation ✓
- Documentation updates ✓

---

## Approval

**User Review**: ⏳ Pending
**Ready for Phase 2**: ❌ No (awaiting approval)

**Questions for User**:
1. Are there any additional design templates needed beyond dashboard/form/wireframe/mobile?
2. Should we support self-hosted Penpot deployment in Phase 1, or start with cloud-only?
3. Are there specific code export formats needed (Flutter only, or also React/Vue/HTML)?
4. Should templates support dark mode variants automatically?

---

**Next Phase**: Upon approval, proceed to Phase 2 (Design Specification) to define the technical architecture and implementation approach.
