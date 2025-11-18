# Canvas Design System Migration

**Date**: 2025-11-15
**Status**: Ready to Begin
**Migration**: Excalidraw → Penpot

---

## Executive Summary

Excalidraw was attempted as a canvas solution but proved unsuitable for a full design tool vision. We're migrating to **Penpot** - an open-source Figma alternative with full design capabilities, component libraries, and a Plugin API for agent control.

---

## Why Penpot?

| Feature | Excalidraw | Penpot |
|---------|-----------|---------|
| **Use Case** | Sketches/wireframes | Full UI design |
| **Components** | ❌ No | ✅ Yes |
| **Design Systems** | ❌ No | ✅ Yes |
| **Auto-Layout** | ❌ No | ✅ Yes (Figma-like) |
| **Agent Control** | Limited API | ✅ Plugin API |
| **Production Mockups** | ❌ No | ✅ Yes |
| **Code Export** | ❌ No | ✅ Flutter/React/etc |

---

## Planning Documents

### Core Plans
1. **[PENPOT_INTEGRATION_PLAN.md](PENPOT_INTEGRATION_PLAN.md)** - 5-week migration timeline
   - Week 1: Setup Penpot account & API testing
   - Week 2: Build Penpot Plugin bridge
   - Week 3: Flutter WebView integration
   - Week 4: Agent integration & testing
   - Week 5: Migration & cleanup

2. **[SPEC_DRIVEN_DESIGN_WORKFLOW.md](SPEC_DRIVEN_DESIGN_WORKFLOW.md)** - Kiro-style structured design
   - Phase 1: Requirements (user stories with visual criteria)
   - Phase 2: Design Spec (technical architecture)
   - Phase 3: Tasks (sequential implementation)
   - Phase 4: Execution (Penpot canvas creation)

3. **[CONTEXT_LIBRARY_INTEGRATION.md](CONTEXT_LIBRARY_INTEGRATION.md)** - Brand guidelines & design tokens
   - User-controlled context (brand guidelines, design tokens)
   - MCP tools for reading session context
   - Agent uses exact values from tokens

### Supporting Documents
4. **[DESIGN_AGENT_MCP_INTEGRATION.md](DESIGN_AGENT_MCP_INTEGRATION.md)** - MCP architecture
5. **[design_agent_system_prompt.md](../apps/desktop/lib/core/agents/design_agent_system_prompt.md)** - Agent intelligence

---

## The Complete Vision

### User Experience

```
1. User adds context to session:
   [+ Brand Guidelines]
   [+ Design Tokens]

2. User: "Create a pricing page"

3. Agent (Phase 1 - Requirements):
   "I see your brand values transparency.
    What pricing tiers? (Free, Pro, Enterprise?)"

4. Agent (Phase 2 - Design Spec):
   [Researches 2025 pricing page trends]
   [Uses #4ecdc4 from your design tokens]
   [Creates component architecture]
   "Here's the plan. Approve?"

5. Agent (Phase 3 - Tasks):
   [Generates 7-task checklist]
   "Execute this plan?"

6. Agent (Phase 4 - Penpot Execution):
   [Creates professional design in Penpot]
   [Uses components, auto-layout, design system]
   "Done! Export to Flutter code?"
```

### Technical Architecture

```
User Chat
    ↓
Agent (with system prompt + context)
    ↓
Spec-Driven Workflow (4 phases)
    ↓
MCP Penpot Server (Dart)
    ↓
Penpot Plugin Bridge (TypeScript)
    ↓
Penpot WebView (Embedded in Flutter)
    ↓
Production-Ready Design
```

---

## Key Features

### 1. Spec-Driven (Not "Vibe Designed")
- Structured requirements before implementation
- Clear acceptance criteria
- Traceable decisions
- Validation at each phase

### 2. Context-Aware
- Uses brand guidelines from context library
- Applies exact design tokens (no guessing)
- Follows component library patterns
- Maintains brand consistency

### 3. Research-Powered
- Web search for current design trends
- Applies best practices automatically
- Adapts to target audience
- Stays up-to-date

### 4. Production-Quality Output
- Hi-fidelity mockups (not sketches)
- Reusable components
- Exports to code (Flutter, React, etc.)
- Design system compliant

---

## Timeline

### Week 1: Penpot Setup (You)
- Create Penpot account at design.penpot.app
- Generate API token
- Test basic API access
- Study Penpot plugin examples

### Week 2: Plugin Development (Together)
- Create Penpot plugin project
- Implement shape creation functions
- Build agent command handler
- Test plugin in Penpot

### Week 3: Flutter Integration (Together)
- Create PenpotCanvas WebView widget
- Implement JavaScript bridge
- Build MCPPenpotServer
- Connect to service locator

### Week 4: Agent Integration (Together)
- Update AgentCanvasTools for Penpot
- Integrate with agent chat
- Test dashboard/wireframe creation
- Polish and bug fixes

### Week 5: Migration (Together)
- Migrate existing canvas features
- Remove Excalidraw dependencies
- Final testing
- Documentation

---

## What Was Learned from Excalidraw

### What Didn't Work
- ❌ Excalidraw never displayed agent-created elements
- ❌ Limited to hand-drawn aesthetic
- ❌ No component system
- ❌ No design tokens support
- ❌ Can't create production mockups

### What We're Keeping
- ✅ MCP architecture (works great)
- ✅ Agent system prompt (intelligent behavior)
- ✅ Spec-driven workflow (prevents vibe designing)
- ✅ Context library integration (brand consistency)

### Lessons Applied to Penpot
1. **Test early**: Penpot proof-of-concept before full migration
2. **Direct control**: Plugin API gives us guaranteed control
3. **Validation**: Clear acceptance criteria at each phase
4. **Documentation**: Comprehensive plans before coding

---

## Archived Documentation

Previous Excalidraw fix attempts are archived in `docs/archive/`:
- CANVAS_AGENT_FIX_PLAN.md
- DISPLAY_BUG_FIXES_IMPLEMENTED.md
- FINAL_BUG_DIAGNOSIS.md
- PHASE_1_INTELLIGENT_LAYOUT_COMPLETE.md
- TEMPLATES_UPGRADED_TO_INTELLIGENT_LAYOUTS.md
- (and more...)

These are kept for reference but superseded by the Penpot migration.

---

## Next Steps

**Ready to start?**

1. Review [PENPOT_INTEGRATION_PLAN.md](PENPOT_INTEGRATION_PLAN.md)
2. Create Penpot account at https://design.penpot.app
3. Generate API token (Profile → Access Tokens)
4. Let me know when ready and we'll begin Week 1!

---

## Questions?

- **Why not fix Excalidraw?** - It's fundamentally limited to wireframing, can't support full design vision
- **Why Penpot over Figma?** - Open source, self-hostable, Plugin API for agent control
- **How long will migration take?** - 5 weeks, but you'll have working proof-of-concept in Week 2
- **Will existing code work?** - MCP architecture is reusable, just swapping canvas backend

---

**Status**: ✅ Plans Complete - Ready to Begin

**Next Action**: User creates Penpot account and generates API token
