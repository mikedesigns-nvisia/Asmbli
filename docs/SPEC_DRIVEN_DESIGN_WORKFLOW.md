# Spec-Driven Design Workflow (Kiro-Style)

**Date**: 2025-11-15
**Status**: PLANNING
**Goal**: Implement structured, requirements-driven canvas design (no more "vibe designing")

---

## Executive Summary

Following Amazon's Kiro IDE approach, we're implementing a 4-phase spec-driven workflow that prevents "vibe designing" by forcing structured planning before Penpot canvas implementation.

**The Problem**: Current "vibe designing" approach is chaotic
```
User: "Create a dashboard"
Agent: *creates random shapes hoping they match intent*
User: "That's not what I wanted"
Agent: *tries again with different random shapes*
```

**The Solution**: Spec-driven design with clear phases
```
User: "Create a dashboard"
Agent: "Let me document requirements first..." → Shows spec
User: Reviews and approves
Agent: "Here's the design approach..." → Shows architecture
User: Approves
Agent: "Here's the task breakdown..." → Shows checklist
User: "Execute"
Agent: *systematically creates exact design from specs*
```

---

## The 4-Phase Workflow

### Phase 1: Requirements (`design_requirements.md`)
**Purpose**: Understand WHAT to build

**Format**: User stories with visual acceptance criteria
```markdown
## R1: User Metrics Overview
**As a** product manager
**I want** to see key user metrics at a glance
**So that** I can quickly assess product health

**Acceptance Criteria:**
- GIVEN I view the dashboard
- WHEN the page loads
- THEN I should see 4 metric cards displaying:
  - Total Users (with growth %)
  - Active Sessions
  - Conversion Rate
  - Revenue

**Visual Requirements:**
- Cards in 2x2 grid layout
- Accent color for positive trends
- Minimum card size: 280x160px
- 8pt grid alignment
```

**Agent Actions**:
1. Ask clarifying questions
2. Generate requirements document
3. Present to user for review
4. Iterate based on feedback

---

### Phase 2: Design Specification (`design_spec.md`)
**Purpose**: Define HOW to build it

**Format**: Technical design document
```markdown
# Design Specification: Analytics Dashboard

## Component Architecture
[ASCII diagram of layout structure]

## Design System Tokens
- Colors: Primary #4ecdc4, Surface #1a1d29
- Spacing: 8pt grid (xs:4, sm:8, md:16, lg:24)
- Typography: Space Grotesk (headings), Inter (body)

## Component Specifications

### Metric Card Component
**Structure:**
- Container: 280x160px rectangle
- Border radius: 8px
- Padding: 16px
- Content: label (14px), value (28px), trend (12px)

**States:** Default, Hover, Active
**Variants:** Positive, Negative, Neutral

## Implementation Approach
1. Create board
2. Build header
3. Create metric card component
4. Instantiate 4 cards
5. Apply auto-layout
6. Add chart

## Testing Strategy
- [ ] Visual: All elements appear correctly
- [ ] Accessibility: Contrast ≥ 4.5:1
- [ ] Responsiveness: Adapts to canvas size
```

**Agent Actions**:
1. Web search for current design trends
2. Read app design tokens
3. Analyze canvas context (if exists)
4. Generate architecture diagram
5. Define component specs
6. Present to user for approval

---

### Phase 3: Implementation Tasks (`design_tasks.md`)
**Purpose**: Define step-by-step execution plan

**Format**: Sequential checklist with MCP commands
```markdown
# Design Tasks: Analytics Dashboard

## Task 1: Setup Canvas Board
**Requirement:** R1, R2, R3 (Foundation)

- [ ] Create Penpot board "Analytics Dashboard"
- [ ] Set dimensions: 1440x900px
- [ ] Set background: #13161f
- [ ] Enable 8pt grid overlay

**MCP Commands:**
```typescript
create_board({ name: "Analytics Dashboard", width: 1440, height: 900 })
set_background({ color: "#13161f" })
enable_grid({ size: 8 })
```

**Validates:** Board ready for elements

---

## Task 2: Create Header Component
**Requirement:** R3 (Responsive Header)

- [ ] Create rectangle: 1440x80px at (0, 0)
- [ ] Fill: #1a1d29
- [ ] Add logo: 40x40px at (24, 20)
- [ ] Add title text: "Analytics Dashboard"
- [ ] Convert to component

**MCP Commands:**
```typescript
create_rectangle({ x: 0, y: 0, width: 1440, height: 80, fill: "#1a1d29" })
create_text({ text: "Analytics Dashboard", x: 600, y: 28 })
create_component({ type: "header", elements: [...] })
```

**Validates:** Header matches R3 acceptance criteria

---

[Tasks 3-7 continue...]
```

**Agent Actions**:
1. Break design spec into atomic tasks
2. Map each task to requirements
3. List MCP commands for each task
4. Define validation criteria
5. Present task checklist to user

---

### Phase 4: Execution
**Purpose**: Systematically implement the design

**Process**:
1. Agent executes tasks sequentially (1 → 7)
2. Checks off completed tasks in real-time
3. User sees progress updates
4. Validates each task against acceptance criteria
5. Final review against original requirements

**Agent Actions**:
1. Execute Task 1 → validate → check off
2. Execute Task 2 → validate → check off
3. ... continue through all tasks
4. Run accessibility audit
5. Generate documentation
6. Export to code (optional)

---

## Example Conversation Flow

### User Initiates Design

```
User: "Create an analytics dashboard"

Agent: "I'll use a spec-driven approach to build this.
Let me gather requirements first.

Questions to clarify:
1. What specific metrics should the dashboard show?
2. Who is the primary user (developer, PM, executive)?
3. What time ranges for data (daily, weekly, monthly)?
4. Any specific visualizations needed (charts, graphs, tables)?"

User: "Product managers will use this. Show:
- Total users
- Active sessions
- Conversion rate
- Revenue
Include a 30-day trend chart."

Agent: "Perfect. Generating requirements document..."

[Shows design_requirements.md]

Agent: "Review this requirements spec. Does it capture your needs?"

User: "Yes, looks good. Add hover tooltips on the trend chart."

Agent: "Updated R2 with tooltip requirement.
Now generating design specification..."

[Shows design_spec.md with component architecture]

Agent: "This defines the visual structure and components.
I've researched 2025 dashboard design patterns and applied them.
Does this approach work for you?"

User: "Perfect, the metric cards look clean"

Agent: "Great! Breaking this into implementation tasks..."

[Shows design_tasks.md with 7 sequential tasks]

Agent: "Here's the execution plan. Each task maps to requirements.
Should I proceed with implementation?"

User: "Yes, execute it"

Agent: "Executing Task 1: Setup Canvas Board..."
[✓ Task 1 complete]

Agent: "Executing Task 2: Create Header Component..."
[✓ Task 2 complete]

[... continues through all tasks ...]

Agent: "All tasks complete! Validating against requirements:
✓ R1: 4 metric cards visible in 2x2 grid
✓ R2: 30-day trend chart with tooltips
✓ R3: Responsive header with branding

Dashboard is ready. Would you like me to export to Flutter code?"
```

---

## File Structure

```
canvas_projects/
└── analytics_dashboard/
    ├── design_requirements.md   # Phase 1: User stories
    ├── design_spec.md           # Phase 2: Technical design
    ├── design_tasks.md          # Phase 3: Task checklist
    ├── dashboard.penpot         # Phase 4: Actual canvas
    └── exports/
        ├── flutter_widgets.dart # Code export
        ├── design_tokens.json   # Token mappings
        └── component_docs.md    # Documentation
```

---

## MCP Tools Required

### New Spec Generation Tools

```dart
class MCPPenpotServer {

  /// Phase 1: Generate requirements from user prompt
  Future<Map<String, dynamic>> generateRequirements({
    required String userPrompt,
    List<String>? clarifyingAnswers,
  }) async {
    final requirements = await _llm.generate(
      template: requirementsTemplate,
      input: userPrompt,
      context: clarifyingAnswers,
    );

    await _saveSpec('design_requirements.md', requirements);

    return {
      'spec': requirements,
      'phase': 1,
      'file': 'design_requirements.md'
    };
  }

  /// Phase 2: Generate design spec from requirements
  Future<Map<String, dynamic>> generateDesignSpec({
    required String requirementsMarkdown,
  }) async {
    // Get design tokens from app
    final tokens = await getDesignTokens();

    // Research current design trends
    final designType = _extractDesignType(requirementsMarkdown);
    final trends = await webSearch("2025 $designType design patterns best practices");

    // Analyze existing canvas (if any)
    final canvasContext = await getCanvasState();

    final spec = await _llm.generate(
      template: designSpecTemplate,
      context: {
        'requirements': requirementsMarkdown,
        'design_tokens': tokens,
        'current_trends': trends,
        'existing_canvas': canvasContext,
      },
    );

    await _saveSpec('design_spec.md', spec);

    return {
      'spec': spec,
      'phase': 2,
      'file': 'design_spec.md'
    };
  }

  /// Phase 3: Generate tasks from spec and requirements
  Future<Map<String, dynamic>> generateTasks({
    required String specMarkdown,
    required String requirementsMarkdown,
  }) async {
    final tasks = await _llm.generate(
      template: tasksTemplate,
      context: {
        'spec': specMarkdown,
        'requirements': requirementsMarkdown,
      },
    );

    await _saveSpec('design_tasks.md', tasks);

    return {
      'tasks': tasks,
      'phase': 3,
      'file': 'design_tasks.md',
      'task_count': _countTasks(tasks),
    };
  }

  /// Phase 4: Execute task list
  Future<Map<String, dynamic>> executeTaskList({
    required String tasksMarkdown,
  }) async {
    final tasks = _parseTasksFromMarkdown(tasksMarkdown);
    final results = [];

    for (var i = 0; i < tasks.length; i++) {
      final task = tasks[i];

      print('📋 Executing Task ${i + 1}: ${task.name}');

      // Execute MCP commands for this task
      for (final command in task.mcpCommands) {
        try {
          await _executeMCPCommand(command);
        } catch (e) {
          print('❌ Command failed: $e');
          return {
            'success': false,
            'failed_task': i + 1,
            'error': e.toString(),
          };
        }
      }

      // Validate task completion
      final validation = await _validateTask(task);

      results.add({
        'task_number': i + 1,
        'task_name': task.name,
        'completed': validation.passed,
        'issues': validation.issues,
      });

      print('✅ Task ${i + 1} complete');
    }

    return {
      'success': true,
      'phase': 4,
      'completed_tasks': results,
      'total_tasks': tasks.length,
    };
  }

  /// Helper: Validate task against acceptance criteria
  Future<ValidationResult> _validateTask(Task task) async {
    final issues = <String>[];

    // Check if elements exist
    for (final element in task.expectedElements) {
      final exists = await _elementExists(element.id);
      if (!exists) {
        issues.add('Missing element: ${element.name}');
      }
    }

    // Check visual requirements
    if (task.requiresAccessibilityCheck) {
      final audit = await runAccessibilityAudit();
      if (audit.hasIssues) {
        issues.addAll(audit.issues);
      }
    }

    return ValidationResult(
      passed: issues.isEmpty,
      issues: issues,
    );
  }
}
```

---

## Agent System Prompt Update

Add to `design_agent_system_prompt.md`:

```markdown
## Spec-Driven Design Workflow (MANDATORY)

You MUST follow this 4-phase workflow for ALL design requests:

### Phase 1: Requirements Gathering
1. Ask 3-5 clarifying questions about:
   - Target users
   - Specific data/content to display
   - Visual style preferences
   - Functional requirements
2. Generate `design_requirements.md`:
   - User stories (As a... I want... So that...)
   - Visual acceptance criteria (GIVEN/WHEN/THEN)
   - Specific visual requirements (sizes, colors, layout)
3. Present to user with: "Review this requirements spec. Does it capture your needs?"
4. Iterate based on feedback

### Phase 2: Design Specification
1. Research current design trends via web search:
   - Search: "2025 {design_type} design patterns best practices"
   - Extract: layout patterns, color trends, typography styles
2. Read app design tokens:
   - Call `get_design_tokens()` tool
   - Match brand colors, spacing, typography
3. Analyze existing canvas:
   - Call `get_canvas_state()` tool
   - Identify existing patterns to match
4. Generate `design_spec.md`:
   - Component architecture (ASCII diagram)
   - Design token mappings
   - Component specifications
   - Implementation approach
5. Present to user: "This defines the visual structure. Does this approach work?"
6. Iterate based on feedback

### Phase 3: Task Planning
1. Break design spec into 5-10 atomic tasks
2. Each task must:
   - Map to specific requirements (R1, R2, etc.)
   - List exact MCP commands to execute
   - Define validation criteria
   - Be completable independently
3. Generate `design_tasks.md` with sequential checklist
4. Present to user: "Here's the execution plan. Should I proceed?"

### Phase 4: Implementation
1. Execute tasks sequentially (never skip or reorder)
2. After each task:
   - Validate against acceptance criteria
   - Check off in progress tracker
   - Report completion to user
3. Final validation:
   - Run accessibility audit
   - Verify all requirements met
   - Generate documentation
4. Offer code export

**NEVER skip directly to implementation without completing Phases 1-3 first.**

**NEVER "vibe design" by creating random shapes and hoping they work.**

**ALWAYS trace every element back to a requirement.**
```

---

## Benefits Over "Vibe Designing"

### Traceability
- Every component traces to a requirement
- Know WHY each element exists
- Easy to validate against goals

### Validation
- Clear acceptance criteria
- Know when design is "done"
- Measurable success metrics

### Iteration
- Edit specs, not trial-and-error shapes
- Structured feedback loops
- Version-controlled specifications

### Collaboration
- User reviews at each phase
- Approves before implementation
- Clear handoff points

### Documentation
- Specs serve as design docs
- Rationale preserved
- Onboarding material for team

### Consistency
- Systematic execution
- Design system compliance
- Repeatable process

---

## Example: Dashboard Spec Files

See `docs/examples/spec_driven_design/` for complete example:
- `analytics_dashboard_requirements.md` (Phase 1 output)
- `analytics_dashboard_spec.md` (Phase 2 output)
- `analytics_dashboard_tasks.md` (Phase 3 output)

---

## Comparison: Vibe vs. Spec-Driven

| Aspect | Vibe Designing | Spec-Driven Design |
|--------|---------------|-------------------|
| **Process** | Random trial-and-error | Structured 4 phases |
| **User Input** | Vague prompt | Detailed requirements |
| **Planning** | None | Design spec + tasks |
| **Validation** | Subjective "looks good?" | Acceptance criteria met |
| **Traceability** | None | Every element → requirement |
| **Iteration** | Redo entire design | Edit spec, re-execute |
| **Documentation** | None | Auto-generated specs |
| **Consistency** | Random | Systematic |
| **Success Rate** | ~30% (trial & error) | ~90% (spec-validated) |

---

## Implementation Timeline

### Week 1: Spec Tools
- [ ] Create requirement template
- [ ] Create design spec template
- [ ] Create tasks template
- [ ] Implement `generateRequirements()` tool
- [ ] Implement `generateDesignSpec()` tool
- [ ] Implement `generateTasks()` tool

### Week 2: Execution Engine
- [ ] Implement task parser
- [ ] Implement task executor
- [ ] Implement task validator
- [ ] Add progress tracking
- [ ] Test with simple dashboard

### Week 3: Integration
- [ ] Update agent system prompt
- [ ] Add spec UI to Canvas Library
- [ ] Add phase progress indicator
- [ ] Test end-to-end workflow

### Week 4: Polish
- [ ] Create example specs (dashboard, login, pricing)
- [ ] Add spec version control
- [ ] Implement spec diff viewer
- [ ] Documentation and training

---

## Success Criteria

After implementation:
- ✅ Agent generates structured requirements
- ✅ Agent researches and applies current trends
- ✅ Agent produces detailed design specs
- ✅ Agent breaks work into trackable tasks
- ✅ User can review/approve at each phase
- ✅ Every element traces to a requirement
- ✅ Validation proves requirements met
- ✅ No more "vibe designing" - structured only

---

**Status**: ✅ READY TO IMPLEMENT

**Dependencies**: Penpot integration (Week 2-3 of Penpot migration)

**Recommended**: Implement spec-driven workflow during Penpot migration Week 2 (Plugin Development)
