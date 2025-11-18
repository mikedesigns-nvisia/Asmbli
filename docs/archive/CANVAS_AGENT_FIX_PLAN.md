# Canvas Agent Fix Plan

**Date**: 2025-11-14
**Status**: CRITICAL - Both display AND intelligence broken
**Your Feedback**: "the agent pipeline should be, receives command, figures it out, then sees if it needs more info"

---

## You Were Right

The current system has **TWO major problems**:

### Problem 1: Not Intelligent ❌
The agent doesn't:
- Ask clarifying questions
- Research what "dashboard" means
- Understand wireframe vs hi-fi differences
- Adapt based on context

**Current behavior**: Scripted response triggering hardcoded templates

### Problem 2: Doesn't Display Anything ❌
Even the scripted templates don't show up because:
- Operations get queued but never processed
- Canvas WebView never receives elements
- Display layer completely disconnected

---

## Root Cause Analysis

### Display Bug

```
Agent Request → MCP Server → CanvasStateController → OperationQueue → ❌ STOPS
                                                                      ↓
                                                           Never reaches WebView
```

**Why it fails**:
1. `CanvasStateController.addElement()` queues operations ✅
2. `CanvasOperationQueue._processQueue()` exists ✅
3. BUT: Queue processing requires `_canvas != null` ⚠️
4. The canvas IS connected (`🔗 Canvas operation queue connected`) ✅
5. **HOWEVER**: No "⚡ Starting queue processing" logs appear ❌
6. **The queue silently fails to process elements**

### Intelligence Bug

The agent should:
1. **Receive** "Create a dashboard"
2. **Analyze**: What does the user mean?
   - Business metrics dashboard?
   - Analytics dashboard?
   - Admin dashboard?
   - Car dashboard mockup?
3. **Research**: Look at examples (Figma, Lovable workflows)
4. **Ask**: "What type of dashboard? What metrics should I show?"
5. **Create**: Based on understanding, not hardcoded templates

**Current flow**: Directly jumps to hardcoded template without thinking

---

## The Fix Plan

### Phase 1: Fix the Display (URGENT - 2 hours)

**Goal**: Make existing templates actually appear on canvas

#### Step 1: Debug Why Queue Doesn't Process
1. Add more logging to `CanvasOperationQueue._processQueue()`
2. Check if `_canvas` is actually set
3. Verify `_processQueue()` is being called
4. Check for race conditions (canvas not ready when operations added)

#### Step 2: Bypass Queue for MCP Templates (Quick Win)
```dart
// In MCPExcalidrawBridgeService
_mcpServer.onCanvasElementAdded = (element) async {
  // TEMP FIX: Send directly to WebView instead of queuing
  final canvas = _getCanvasWidget();
  await canvas?._addElementDirectly(element);
};
```

This gets templates showing immediately while we fix the proper queue system.

#### Step 3: Fix Operation Queue Processing
- Ensure queue processor runs on every `addOperation()`
- Add retry logic if canvas not ready
- Implement proper async/await handling

---

### Phase 2: Make Agent Intelligent (1-2 days)

**Goal**: Agent asks questions, researches, understands context

#### Step 1: Add Conversation Layer

```dart
// New: AgentConversationService
class DesignAgentConversation {
  Future<AgentResponse> processUserRequest(String request) async {
    // 1. Parse intent
    final intent = await _parseIntent(request);

    // 2. Check if clarification needed
    if (intent.needsClarification) {
      return AgentResponse.question(
        "I can create a dashboard for you! What type:\n"
        "1. Analytics dashboard (charts, metrics)\n"
        "2. Admin dashboard (user management)\n"
        "3. Business metrics (KPIs, sales)\n"
        "4. Or describe what you need?"
      );
    }

    // 3. Research if needed
    if (intent.needsResearch) {
      await _researchExamples(intent.type);
    }

    // 4. Create with understanding
    return await _createIntelligently(intent);
  }
}
```

#### Step 2: Add Research Capability

The agent should web search for:
- "Figma dashboard examples"
- "Lovable.dev dashboard workflow"
- "Modern dashboard UI patterns"
- "Wireframe vs hi-fidelity design"

Then extract common patterns and apply them.

#### Step 3: Make Templates Dynamic

Instead of hardcoded templates, generate based on:
- User's stated needs
- Researched patterns
- Project context
- Design system tokens

---

### Phase 3: Context-Aware Generation (3-5 days)

**Goal**: Agent understands project context and adapts

```dart
class IntelligentDesignAgent {
  // Analyze existing canvas
  Future<CanvasContext> analyzeContext() async {
    final elements = await getCanvasElements();
    final colorScheme = detectColorScheme(elements);
    final spacingPattern = detectSpacingPattern(elements);
    final layoutStyle = detectLayoutStyle(elements);

    return CanvasContext(
      dominantColors: colorScheme,
      spacing: spacingPattern,
      style: layoutStyle,
      complexity: calculateComplexity(elements),
    );
  }

  // Generate that matches context
  Future<void> generateDashboard() async {
    final context = await analyzeContext();

    // Use detected patterns
    final dashboard = DashboardGenerator(
      colorScheme: context.dominantColors,
      spacing: context.spacing,
      complexity: context.targetComplexity,
    ).generate();

    // Create elements that fit
    await createElements(dashboard.elements);
  }
}
```

---

## Immediate Next Steps

### Right Now (You can test):
1. **I'll fix the queue processing** so templates actually show
2. **I'll add direct WebView communication** as backup
3. **You test if templates appear** after hot reload

### Tomorrow:
1. **Add conversation layer** - agent asks questions
2. **Integrate web research** - agent looks at Figma examples
3. **Make templates dynamic** - based on user needs

### This Week:
1. **Full intelligent pipeline**
2. **Context-aware generation**
3. **Learning from examples**

---

## Your Vision (What We're Building Toward)

```
User: "Create a dashboard"
  ↓
Agent: "I'd be happy to help! What kind of dashboard are you thinking?"
       "• Analytics (charts, graphs, metrics)"
       "• Admin panel (user management, settings)"
       "• Business metrics (sales, KPIs, revenue)"
       "• Something else? Describe your needs"
  ↓
User: "Business metrics dashboard with sales and revenue"
  ↓
Agent: "Got it! Let me research modern business dashboard patterns..."
       *searches Figma, Lovable, design systems*
       "I see dashboards typically show:"
       "• Revenue chart (line/bar)"
       "• Sales numbers (big and bold)"
       "• Growth percentage (with trend indicator)"
       "• Time period selector"
       "Should I include all of these?"
  ↓
User: "Yes, that looks good"
  ↓
Agent: "Perfect! Creating your business metrics dashboard now..."
       *analyzes existing canvas colors/spacing*
       *generates matching the current design*
       *creates actual visual elements*
  ↓
Canvas: **Professional dashboard appears with:**
       - Revenue line chart matching canvas colors
       - Sales cards with actual formatting
       - Growth indicators with green/red colors
       - Time selector matching button style
```

**That's what we're building.**

---

## Current Status vs Target

| Feature | Current | Target |
|---------|---------|--------|
| **Template Display** | ❌ Broken | ✅ Working |
| **Agent Intelligence** | ❌ Scripted | ✅ Conversational |
| **Clarifying Questions** | ❌ None | ✅ Asks before creating |
| **Research** | ❌ None | ✅ Searches examples |
| **Context Awareness** | ❌ None | ✅ Matches existing design |
| **Dynamic Generation** | ❌ Hardcoded | ✅ Generated per request |
| **Understanding** | ❌ Keyword matching | ✅ Semantic understanding |

---

## Let's Fix It

**Immediate Priority**: Fix the display bug so you can see SOMETHING
**Next Priority**: Make the agent actually intelligent
**Final Goal**: Full conversational design assistant

Ready to start with Phase 1 (fixing display)?
