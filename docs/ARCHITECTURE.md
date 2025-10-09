# Asmbli Architecture - Experimental Patterns & Learnings

## Overview

Asmbli's architecture represents an exploration of patterns for agentic AI applications. Some experiments succeeded, others failed instructively. This document captures both.

## Architectural Experiments

### Experiment 1: Maximum Modularity (Failed)

**Hypothesis**: Breaking everything into services would create maximum flexibility  
**Implementation**: 110 separate services  
**Result**: Over-abstraction created cognitive overhead

```
ServiceLocator with 110+ services including:
- AgentService, AgentBusinessService, AgentContextService
- MCPBridgeService, MCPProtocolService, MCPExecutionService
- ConversationService, MessageService, ChatService
```

**Learning**: Service boundaries should match mental models, not code organization

### Experiment 2: Feature-Based Modules (Successful)

**Hypothesis**: Organizing code by user-facing features improves maintainability  
**Implementation**: 
```
features/
├── chat/          # All chat-related code
├── agents/        # Agent management
├── settings/      # Configuration
└── tools/         # MCP integrations
```

**Result**: Clear boundaries, easy to find code, good for team collaboration

### Experiment 3: Design System First (Successful)

**Hypothesis**: Building design system before features prevents inconsistency  
**Implementation**: Complete theming system with dynamic colors, components, spacing

```dart
// Theme-aware development
final colors = ThemeColors(context);
Container(color: colors.primary) // Adapts to user's theme choice
```

**Result**: Consistent UI, easy theme switching, good developer experience

### Experiment 4: Local-First Architecture (Successful)

**Hypothesis**: Privacy-preserving AI tools have demand  
**Implementation**: All data local, encrypted storage, no telemetry

**Storage Strategy**:
- SQLite for structured data (conversations, agents)
- Hive for preferences and cache
- AES-256 for API keys
- No cloud dependencies

**Result**: Strong user preference for data control

## Service Architecture Analysis

### What We Learned About Services

**Too Many Services**:
```dart
// We had separate services for related concepts
class AgentService {}
class AgentBusinessService {}
class AgentContextService {}
class AgentMCPIntegrationService {}

// Should have been:
class AgentService {
  // All agent-related functionality
}
```

**Service Categories That Worked**:
1. **Data Services**: AgentService, ConversationService
2. **Integration Services**: LLMService, MCPService  
3. **UI Services**: ThemeService, NavigationService
4. **Platform Services**: StorageService, WindowService

**Anti-Pattern**: Creating services for code organization rather than logical boundaries

### Dependency Injection Learnings

Using ServiceLocator pattern:
```dart
// Works for experiments, but creates hidden dependencies
final service = ServiceLocator.instance.get<AgentService>();

// Better for production:
// Constructor injection with interfaces
```

**Learning**: ServiceLocator good for prototyping, constructor injection better for production

## State Management Experiment

### Riverpod Patterns That Worked

```dart
// Async data loading
final conversationsProvider = FutureProvider<List<Conversation>>((ref) {
  return conversationService.getConversations();
});

// Reactive state
final selectedAgentProvider = StateProvider<Agent?>((ref) => null);

// Computed state
final filteredAgentsProvider = Provider<List<Agent>>((ref) {
  final agents = ref.watch(agentsProvider);
  final filter = ref.watch(agentFilterProvider);
  return agents.where((a) => a.category == filter).toList();
});
```

**Learning**: Riverpod excellent for reactive UIs, but easy to over-complicate

## Data Architecture Experiments

### Storage Strategy

**Local SQLite** for:
- Conversations and messages
- Agent configurations
- User settings

**Hive** for:
- Fast key-value cache
- Preferences
- Temporary data

**In-Memory** for:
- Vector embeddings
- Active conversation state
- UI state

**Learning**: Hybrid approach works well; each storage type has optimal use cases

### Data Flow Patterns

```
User Action → Riverpod Provider → Service → Storage → State Update → UI Refresh
```

This pattern worked well for most features but became complex for real-time chat.

## UI Architecture Learnings

### Component Hierarchy

```dart
// Successful pattern
AsmblCard(
  child: Column(
    children: [
      Text('Title', style: TextStyles.cardTitle),
      AsmblButton.primary(text: 'Action', onPressed: () {}),
    ],
  ),
)

// Instead of mixing custom and Flutter widgets
```

### Theme System Architecture

Dynamic theme resolution:
```dart
class ThemeColors {
  final BuildContext context;
  
  Color get primary {
    final scheme = Theme.of(context).colorScheme;
    // Custom logic for theme variants
  }
}
```

**Learning**: Context-based theme resolution enables powerful customization

## MCP Integration Architecture

### Protocol Abstraction

```
Agent Request → MCP Bridge → Protocol Handler → Transport → MCP Server
```

**Challenges**:
- Too many abstraction layers
- Complex error handling
- Difficult to debug

**Learning**: Start with direct integration, add abstraction only when needed

## Performance Patterns

### What Worked
- Lazy service initialization
- Stream-based chat updates
- Cached vector embeddings
- Efficient widget rebuilds

### What Didn't
- Over-eager service registration
- Too many providers watching same data
- Large widget trees (3000+ line files)

## Testing Architecture (Lacking)

**Experiment**: Can we retrofit tests to complex codebase?  
**Result**: Very difficult; should have tested while building

**Learning**: TDD especially important for experimental code

## Lessons for Future Architectures

### Start Simple
1. Begin with monolithic features
2. Extract services only when boundaries clear
3. Add abstraction when you have 3+ similar implementations

### Design System First
1. Build theming before features
2. Create components as you need them
3. Test with real content, not Lorem Ipsum

### Test Early
1. Write tests as you experiment
2. Integration tests more valuable than unit tests for UI
3. Visual regression tests for design systems

### Service Boundaries
1. Match user mental models
2. One service per domain concept
3. Avoid technical service boundaries

## Recommended Architecture for Production

Based on learnings, a production version might use:

```
├── core/
│   ├── theme/           # Design system
│   ├── storage/         # Data layer
│   └── platform/        # OS integration
├── domains/             # Business domains
│   ├── agents/          # Agent management
│   ├── conversations/   # Chat functionality
│   └── integrations/    # External tools
└── ui/                  # Shared UI components
```

With ~20 services instead of 110, and comprehensive test coverage.

## Summary

Asmbli's architecture taught us:
- **Over-engineering is easy** and harmful
- **Design systems are crucial** for complex UIs
- **Local-first works** and users love it
- **Testing should happen** during experimentation
- **Service boundaries matter** more than service count

The codebase serves as both a working example and a cautionary tale about balancing flexibility with simplicity.