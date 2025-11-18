# Penpot Integration - Future Roadmap

**Status**: Planning (Week 4+)
**Date**: 2025-11-15
**Current State**: Week 3 Complete (23 MCP tools)

---

## Overview

This document outlines future enhancement options for the Penpot integration beyond Week 3. These are organized by priority and impact, with Options 1 & 2 selected for Week 4 implementation.

---

## 🎯 Week 4: SELECTED - Element Manipulation & Interactive Workflows

### Option 1: Element Manipulation & Updates
**Status**: ✅ Selected for Week 4
**Priority**: High
**Estimated Tasks**: 26-32

**Objective**: Enable agents to modify, transform, and manage existing canvas elements.

#### Planned MCP Tools (7 new tools)

1. **`penpot_update_element`** - Modify existing element properties
   - Update position (x, y)
   - Update size (width, height)
   - Update styles (fill, stroke, opacity, etc.)
   - Update text content
   - Supports batch updates

2. **`penpot_transform_element`** - Apply transformations
   - Rotate (angle in degrees)
   - Scale (uniform or non-uniform)
   - Skew (x and y axis)
   - Flip (horizontal/vertical)

3. **`penpot_delete_element`** - Remove elements
   - Delete by element ID
   - Supports batch deletion
   - Optional: Move to trash vs permanent delete

4. **`penpot_duplicate_element`** - Clone elements
   - Duplicate with offset
   - Deep clone (including children)
   - Preserve or break component links

5. **`penpot_group_elements`** - Create element groups
   - Group multiple elements
   - Named groups
   - Nested grouping support

6. **`penpot_ungroup_elements`** - Ungroup elements
   - Dissolve group
   - Preserve element properties

7. **`penpot_reorder_elements`** - Change layer order
   - Bring to front
   - Send to back
   - Bring forward
   - Send backward
   - Specific z-index positioning

#### Implementation Details

**Models to Create**:
- `ElementUpdate` - Update operation model
- `ElementTransform` - Transformation parameters
- `LayerOperation` - Reordering operations

**Services to Extend**:
- `MCPPenpotServer` - Add new tool methods
- `DesignHistoryService` - Track update/delete/transform actions

**Benefits**:
- ✅ Iterative design refinement
- ✅ Agent-driven edits and corrections
- ✅ Complete CRUD operations (Create ✅, Read ✅, Update 🆕, Delete 🆕)
- ✅ Professional layer management

---

### Option 2: Interactive Design Workflows
**Status**: ✅ Selected for Week 4
**Priority**: High
**Estimated Tasks**: 33-36

**Objective**: Create collaborative human-AI design experience with real-time canvas updates.

#### Planned Features

1. **Real-Time Agent Canvas Updates**
   - Stream design changes to UI as agent works
   - WebView bridge for live updates
   - Progress indicators during design creation

2. **Visual Feedback System**
   - Highlight elements being created/modified
   - Show agent "cursor" or focus area
   - Animate element creation

3. **Watch Mode UI**
   - Toggle "Watch Agent Work" mode
   - Speed controls (1x, 2x, 4x, instant)
   - Pause/resume agent operations
   - Step-through mode for debugging

4. **Context-Aware Agent Decisions**
   - Agent queries canvas state before operations
   - Smart placement (avoid overlaps, align to grid)
   - Style inheritance from nearby elements
   - Responsive layout adjustments

5. **Interactive Design Critique**
   - Agent analyzes canvas and suggests improvements
   - Visual annotations on canvas
   - Before/after comparison view
   - Accept/reject agent suggestions

#### Implementation Details

**UI Components to Create**:
- `AgentWatchPanel` - Watch mode controls
- `CanvasProgressOverlay` - Show agent progress
- `DesignCritiquePanel` - Display agent suggestions

**Services to Create**:
- `AgentCanvasStreamService` - Real-time update streaming
- `DesignCritiqueService` - Analysis and suggestions

**Canvas Library Enhancements**:
- Add "Watch Mode" toggle to Design Agent tab
- Real-time activity feed
- Agent operation log with timestamps

**Benefits**:
- ✅ Transparent AI collaboration
- ✅ Learn from agent design decisions
- ✅ Catch mistakes in real-time
- ✅ Educational: See design best practices in action

---

## 📐 Option 3: Advanced Layout Systems

**Status**: Future consideration
**Priority**: Medium
**Estimated Tasks**: 37-44

**Objective**: Professional-grade layout automation and responsive design.

### Planned MCP Tools (8 new tools)

1. **`penpot_create_grid`** - Grid layout system
   - Column/row count
   - Gutter spacing
   - Grid alignment
   - Responsive breakpoints

2. **`penpot_create_auto_layout`** - Flexbox container
   - Horizontal/vertical direction
   - Gap spacing
   - Alignment (start, center, end, stretch)
   - Wrap behavior

3. **`penpot_apply_constraints`** - Responsive constraints
   - Pin to edges (top, right, bottom, left)
   - Fixed/proportional sizing
   - Center constraints
   - Min/max dimensions

4. **`penpot_create_breakpoint`** - Responsive breakpoints
   - Mobile, tablet, desktop sizes
   - Breakpoint-specific overrides
   - Preview at different sizes

5. **`penpot_distribute_elements`** - Smart distribution
   - Horizontal/vertical spacing
   - Equal distribution
   - Align to container edges

6. **`penpot_align_elements`** - Alignment operations
   - Align left/center/right
   - Align top/middle/bottom
   - Distribute spacing

7. **`penpot_create_layout_grid`** - Layout grid overlay
   - 8px/12-column grids
   - Custom grid systems
   - Snap-to-grid behavior

8. **`penpot_instantiate_template`** - Complete Task 20
   - Use DesignTemplate models
   - Variable substitution
   - Smart positioning
   - Template library management

### Benefits
- Professional responsive design
- Automated layout systems
- Design consistency at scale
- Faster iteration with templates

---

## 🎨 Option 4: Design System Management

**Status**: Future consideration
**Priority**: Medium-Low
**Estimated Tasks**: 45-52

**Objective**: Enterprise-level design system creation and management.

### Planned Features

1. **Component Library Management**
   - Create/update/delete component libraries
   - Component variants (size, state, theme)
   - Component documentation
   - Usage tracking across designs

2. **Style Guide Generation**
   - Auto-generate style documentation
   - Color palette documentation
   - Typography scale documentation
   - Spacing system documentation
   - Export as markdown/PDF

3. **Design System Documentation**
   - Component usage examples
   - Design principles documentation
   - Accessibility guidelines
   - Code snippets for developers

4. **Brand Kit Management**
   - Multiple brand profiles
   - Logo management
   - Image asset library
   - Icon sets
   - Illustration library

5. **Multi-Theme Support**
   - Light/dark mode themes
   - Brand-specific themes
   - Seasonal themes
   - A/B testing themes

### Benefits
- Consistent brand identity
- Reduced design debt
- Faster onboarding for designers
- Design-development handoff

---

## 📤 Option 5: Collaboration & Export Enhancements

**Status**: Future consideration
**Priority**: Low
**Estimated Tasks**: 53-60

**Objective**: Production-ready workflows and developer handoff.

### Planned Features

1. **Export Presets**
   - Social media sizes (Instagram, Twitter, LinkedIn)
   - App icons (iOS, Android)
   - Favicon sizes
   - Email templates
   - Print sizes

2. **Batch Export Operations**
   - Export all artboards
   - Export by tag/category
   - Automated naming conventions
   - Bulk resolution settings

3. **Design Versioning**
   - Canvas snapshots
   - Version comparison
   - Rollback to previous versions
   - Branch/merge designs

4. **Export to Code**
   - Generate Flutter widgets
   - Generate React components
   - Generate HTML/CSS
   - Generate design tokens JSON

5. **Design Handoff**
   - Developer annotations
   - Specs overlay (dimensions, spacing, colors)
   - Asset package generation
   - Implementation notes

6. **Collaboration Features**
   - Comments on canvas
   - Design review workflows
   - Approval system
   - Activity tracking

### Benefits
- Streamlined design-to-development
- Reduced handoff friction
- Version control for designs
- Team collaboration

---

## Implementation Priority

### Phase 1: Week 4 (CURRENT)
- ✅ **Option 1**: Element Manipulation (Tasks 26-32)
- ✅ **Option 2**: Interactive Workflows (Tasks 33-36)
- **Total**: 11 tasks, ~7 new MCP tools

### Phase 2: Week 5-6
- **Option 3**: Advanced Layout Systems (Tasks 37-44)
- **Total**: 8 tasks, ~8 new MCP tools

### Phase 3: Week 7-8
- **Option 4**: Design System Management (Tasks 45-52)
- **Total**: 8 tasks, ~5 new MCP tools

### Phase 4: Week 9-10
- **Option 5**: Collaboration & Export (Tasks 53-60)
- **Total**: 8 tasks, ~6 new MCP tools

---

## Projected Final State

**Total MCP Tools**: ~49 tools
- Week 1: 6 tools (foundation)
- Week 2: 7 tools (advanced features)
- Week 3: 10 tools (professional capabilities)
- Week 4: 7 tools (element manipulation + interactive)
- Week 5-6: 8 tools (layout systems)
- Week 7-8: 5 tools (design systems)
- Week 9-10: 6 tools (collaboration & export)

**Architecture**:
- Fully embedded MCP server
- Real-time canvas collaboration
- Complete CRUD operations
- Professional design workflows
- Enterprise-ready design systems
- Developer handoff automation

---

## Success Metrics

### Week 4 Goals
- [ ] Agents can modify existing elements
- [ ] Agents can delete and duplicate elements
- [ ] Layer management fully functional
- [ ] Real-time UI updates during agent work
- [ ] Watch mode operational
- [ ] Design critique system functional

### Long-Term Vision
- Complete design-to-code pipeline
- Zero-friction AI collaboration
- Professional design system management
- Enterprise-ready workflows
- Best-in-class MCP design tool integration

---

## Notes

- Options are flexible and can be re-prioritized based on user feedback
- Each option can be implemented incrementally
- Focus on production-ready, well-documented features
- Maintain backward compatibility with existing 23 tools
- Continue MCP-compliant architecture

**Last Updated**: 2025-11-15
