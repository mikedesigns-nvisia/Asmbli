# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

---

## Project Overview

**Asmbli** is a Flutter desktop application for building and managing AI agents with MCP (Model Context Protocol) integration. This is an **experimental alpha project** with a comprehensive design system but significant architectural complexity.

**Tech Stack**: Flutter 3.0+, Dart 3.0+, Riverpod (state management), MCP integration, local storage (Hive + SQLite)

**Platforms**: Windows, macOS, Linux

---

## Development Commands

### Setup
```bash
# Install Flutter dependencies for desktop app
cd apps/desktop
flutter pub get

# Install core package dependencies
cd ../../packages/agent_engine_core
flutter pub get
```

### Running the App
```bash
cd apps/desktop

# Run on desktop (auto-detects platform)
flutter run

# Run on specific platform
flutter run -d windows
flutter run -d macos
flutter run -d linux
```

### Testing
```bash
cd apps/desktop

# Run all tests
flutter test

# Run specific test file
flutter test test/unit/services/agent_service_test.dart

# Run tests with coverage
flutter test --coverage

# Generate coverage report (requires lcov)
genhtml coverage/lcov.info -o coverage/html
```

### Code Quality
```bash
# Run static analysis
flutter analyze

# Format code
dart format .

# Run build_runner for code generation (if models changed)
flutter packages pub run build_runner build --delete-conflicting-outputs
```

### Building
```bash
# Build release version for current platform
flutter build windows --release
flutter build macos --release
flutter build linux --release
```

---

## Architecture

### High-Level Structure

```
apps/desktop/lib/
├── core/                      # Core infrastructure
│   ├── design_system/        # UI components, tokens, themes
│   ├── di/                   # ServiceLocator (dependency injection)
│   ├── services/             # 136+ business logic services
│   │   ├── desktop/          # Platform-specific services
│   │   ├── llm/              # LLM provider abstractions
│   │   ├── business/         # Business service layer
│   │   └── (46 MCP services) # MCP integration (see below)
│   ├── models/               # Data models
│   └── utils/                # Utilities
├── features/                 # Feature modules (178 files)
│   ├── chat/                 # Chat interface
│   ├── agents/               # Agent management
│   ├── settings/             # Settings & configuration
│   ├── context/              # Document context
│   └── tools/                # MCP tools/integrations
└── providers/                # Riverpod providers

packages/agent_engine_core/   # Shared models & interfaces
```

### Key Architectural Patterns

**1. Service Locator Pattern** (`lib/core/di/service_locator.dart`)
- Central dependency injection container
- Services registered at startup in `main.dart`
- Access via `ServiceLocator.instance.get<ServiceType>()`
- **110+ services** (consolidation plan in progress - see `docs/SERVICE_CONSOLIDATION_PLAN.md`)

**2. Riverpod State Management**
- 1,096+ providers across codebase
- Use `ref.watch()` to listen to state changes
- Use `ref.read()` for one-time reads
- Provider pattern: `final myProvider = StateNotifierProvider<MyNotifier, MyState>(...)`

**3. Feature-Based Organization**
- Each feature has `presentation/`, `data/`, `models/` subdirectories
- Business logic in services, UI in features
- Cross-feature communication via services or shared providers

**4. MCP Integration Architecture** (⚠️ Complex - 46 services)
MCP services are organized in layers (see `docs/SERVICE_CONSOLIDATION_PLAN.md` for consolidation roadmap):
- **Protocol Layer**: `MCPProtocolHandler`, `MCPProcessManager`, transport adapters
- **Server Management**: `MCPServerExecutionService`, `MCPBridgeService`, lifecycle managers
- **Agent Integration**: `AgentMCPIntegrationService`, `AgentTerminalManager`
- **Context**: `ContextMCPResourceService`, `MCPCatalogService`
- **Support**: `MCPErrorHandler`, `MCPHealthMonitor`, settings services

**⚠️ Current State**: Over-engineered with significant overlap. When working with MCP:
1. Start with `MCPBridgeService` for basic MCP operations
2. Use `MCPCatalogService` for server discovery
3. Use `AgentMCPIntegrationService` for agent-specific MCP features
4. Avoid creating new MCP services - extend existing ones

---

## Design System (CRITICAL)

### ⚠️ Mandatory Patterns

**ALWAYS use `ThemeColors(context)` - NEVER hardcode colors**

```dart
import 'core/design_system/design_system.dart';

// ✅ CORRECT
final colors = ThemeColors(context);
Container(color: colors.primary)

// ❌ WRONG - Will break color scheme switching
Container(color: Color(0xFF4ECDC4))
Container(color: SemanticColors.primary)  // Deprecated
```

### Multi-Color Scheme System
The app supports 5 user-selectable color schemes (Warm Neutral, Cool Blue, Forest Green, Sunset Orange, Silver Onyx). All UI must adapt dynamically.

**Available Colors**:
```dart
final colors = ThemeColors(context);

colors.background, colors.surface, colors.primary, colors.accent
colors.onSurface, colors.onSurfaceVariant, colors.border
colors.success, colors.warning, colors.error
colors.backgroundGradientStart/Middle/End
```

### Design System Components
**ALWAYS use these instead of Flutter widgets**:

```dart
// Cards
AsmblCard(child: ...)
AsmblCardEnhanced.outlined(child: ...)

// Buttons
AsmblButton.primary(text: "Save", onPressed: () {})
AsmblButton.accent(text: "Create", onPressed: () {})
AsmblButton.secondary(text: "Cancel", onPressed: () {})
AsmblButton.outline(text: "Learn More", onPressed: () {})
AsmblButton.destructive(text: "Delete", onPressed: () {})

// Typography
TextStyles.pageTitle, TextStyles.sectionTitle
TextStyles.cardTitle, TextStyles.bodyMedium

// Spacing (Golden Ratio System)
SpacingTokens.xs (4px), SpacingTokens.sm (8px), SpacingTokens.md (13px)
SpacingTokens.lg (16px), SpacingTokens.xl (21px), SpacingTokens.xxl (24px)

// Border Radius
BorderRadiusTokens.sm (2px), BorderRadiusTokens.md (6px)
BorderRadiusTokens.lg (8px), BorderRadiusTokens.xl (12px)
```

### Standard Page Layout Pattern
```dart
return Scaffold(
  body: Container(
    decoration: BoxDecoration(
      gradient: RadialGradient(
        center: Alignment.topCenter,
        radius: 1.5,
        colors: [
          colors.backgroundGradientStart,
          colors.backgroundGradientMiddle,
          colors.backgroundGradientEnd,
        ],
        stops: const [0.0, 0.6, 1.0],
      ),
    ),
    child: SafeArea(
      child: Column(
        children: [
          // Header with AppNavigationBar
          const AppNavigationBar(currentRoute: AppRoutes.myRoute),

          // Content with standard padding
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(SpacingTokens.xxl),
              child: // Your content
            ),
          ),
        ],
      ),
    ),
  ),
);
```

**Full design system reference**: `apps/desktop/lib/core/design_system/USAGE.md`

---

## Critical Anti-Patterns to AVOID

### 1. Service Proliferation
❌ **DON'T** create new services without checking if existing ones can be extended
- Currently 110+ services (target: 50)
- 46 MCP services with significant overlap
- ✅ **DO** extend existing services or merge functionality

### 2. Hardcoded Values
❌ **DON'T** use:
- `Color(0xFF...)` - Use `ThemeColors(context)`
- `EdgeInsets.all(24)` - Use `SpacingTokens.xxl`
- `TextStyle(fontSize: 16)` - Use `TextStyles.bodyMedium`
- `SemanticColors.*` - Deprecated, use `ThemeColors(context)`

### 3. Assumptions Without Investigation
❌ **DON'T**:
- Assume services exist - verify with ServiceLocator
- Guess at data flow - trace through providers
- Create parallel systems - integrate with existing architecture

✅ **DO**:
- Read related code first
- Use ServiceLocator.instance.get<T>() for services
- Check providers directory for state management
- Follow established patterns

### 4. Large Files
⚠️ Several files exceed 2,000 lines (settings_screen.dart: 3,290 lines)
- Split large files into smaller, focused components
- Extract reusable widgets
- Use composition over monolithic widgets

### 5. Missing Tests
Current coverage: ~9% (target: 40%)
- ✅ **DO** write tests for new services and business logic
- Test helpers available in `apps/desktop/test/helpers/`
- See `docs/TESTING_BOOTSTRAP.md` for testing patterns

---

## Working with MCP Servers

MCP (Model Context Protocol) integration is complex. Follow this guidance:

### Basic MCP Operations
```dart
// Get MCP catalog service
final mcpCatalog = ServiceLocator.instance.get<MCPCatalogService>();

// Get available servers
final servers = await mcpCatalog.getAvailableServers();

// Configure MCP for an agent
final agentMCPService = ServiceLocator.instance.get<AgentMCPIntegrationService>();
await agentMCPService.enableGitHubMCPTool(
  agentId: agentId,
  catalogEntryId: serverId,
);
```

### MCP Service Hierarchy
1. **MCPCatalogService** - Server discovery and registry
2. **MCPBridgeService** - Core MCP communication
3. **AgentMCPIntegrationService** - Agent-specific integration
4. **MCPServerExecutionService** - Server lifecycle management

⚠️ **Do not create new MCP services** - consolidation is in progress. Extend existing services instead.

---

## State Management with Riverpod

### Provider Patterns
```dart
// State Notifier Provider (mutable state)
final myProvider = StateNotifierProvider<MyNotifier, MyState>((ref) {
  return MyNotifier();
});

// Future Provider (async data)
final dataProvider = FutureProvider<Data>((ref) async {
  final service = ref.read(serviceProvider);
  return service.fetchData();
});

// Stream Provider (real-time data)
final streamProvider = StreamProvider<Event>((ref) {
  return someEventStream;
});
```

### Using Providers
```dart
// In widgets (ConsumerWidget or ConsumerStatefulWidget)
class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch for changes
    final state = ref.watch(myProvider);

    // Read once (no rebuild)
    final service = ref.read(serviceProvider);

    // Read notifier (to call methods)
    ref.read(myProvider.notifier).updateSomething();

    return Container();
  }
}
```

---

## Data Persistence

### Local Storage Options
1. **Hive** - Key-value storage (preferences, settings)
   - Access via `DesktopStorageService.instance`
   - Initialized in `main.dart`

2. **SQLite** - Relational data (conversations, agents)
   - Used by `DesktopAgentService`, `DesktopConversationService`

3. **Secure Storage** - Credentials, API keys
   - `SecureAuthService` for OAuth tokens
   - `MacOSKeychainService` on macOS

### Storage Patterns
```dart
// Get storage service
final storage = ServiceLocator.instance.get<DesktopStorageService>();

// Save preference
await storage.setPreference('key', value);

// Read preference
final value = storage.getPreference<String>('key');

// Agent persistence (via service)
final agentService = ServiceLocator.instance.get<AgentService>();
await agentService.createAgent(agent);
final agents = await agentService.getAgents();
```

---

## Common Development Tasks

### Adding a New Feature
1. Create feature directory in `lib/features/my_feature/`
2. Add `presentation/`, `data/`, `models/` subdirectories
3. Use design system components (`import 'core/design_system/design_system.dart'`)
4. Create Riverpod providers for state management
5. Register any new services in ServiceLocator (avoid if possible)
6. Write tests in `test/unit/features/my_feature/`

### Adding a New Service
⚠️ **Think twice** - we have 110+ services already
1. Check if existing service can be extended first
2. If truly needed, add to `lib/core/services/`
3. Register in ServiceLocator (`lib/core/di/service_locator.dart`)
4. Document in service consolidation plan if MCP-related
5. Write unit tests

### Adding a New UI Component
1. Check if design system component exists first
2. If custom needed, extend design system component
3. Use `ThemeColors(context)` and spacing tokens
4. Add to `lib/core/design_system/components/`
5. Export from `design_system.dart`
6. Test with all 5 color schemes

### Debugging MCP Issues
1. Check MCP logs: `MCPErrorHandler` outputs debug info
2. Verify server configuration in `MCPSettingsService`
3. Test server execution with `MCPServerExecutionService`
4. Check agent MCP bindings in `AgentMCPConfigurationService`

---

## Testing

### Test Structure
```
apps/desktop/test/
├── unit/           # Service and model tests
├── widget/         # Widget tests
├── integration/    # Integration tests
└── helpers/        # Test utilities and mocks
```

### Writing Tests
```dart
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MyService', () {
    late MyService service;

    setUp(() {
      service = MyService();
    });

    test('does expected operation', () {
      final result = service.doSomething();
      expect(result, expectedValue);
    });
  });
}
```

**Testing guide**: `docs/TESTING_BOOTSTRAP.md`

---

## Important Files & References

### Core Architecture
- `apps/desktop/lib/main.dart` - App entry point, service initialization
- `apps/desktop/lib/core/di/service_locator.dart` - Dependency injection
- `apps/desktop/lib/core/design_system/design_system.dart` - Design system exports
- `packages/agent_engine_core/` - Shared models and interfaces

### Documentation
- `apps/desktop/lib/core/design_system/USAGE.md` - Design system guide
- `docs/SERVICE_CONSOLIDATION_PLAN.md` - Service reduction roadmap
- `docs/TESTING_BOOTSTRAP.md` - Testing guide
- `docs/TECHNICAL_DEBT_ROADMAP.md` - Technical debt plan
- `README.md` - Project overview and setup

### Configuration
- `apps/desktop/pubspec.yaml` - Dependencies
- `analysis_options.yaml` - Linter rules (if exists)

---

## Known Issues & Technical Debt

### Current Challenges
1. **Service Proliferation**: 110 services (target: 50), 46 MCP services (target: 12)
2. **Low Test Coverage**: ~9% (target: 40%)
3. **Large Files**: Several files >2,000 lines need splitting
4. **Deprecated Patterns**: 38 files still use old `SemanticColors` (should use `ThemeColors`)
5. **Legacy Code**: Unused React/TypeScript files in `/components` and `/src`

### Active Improvements
- Service consolidation plan underway (see `docs/SERVICE_CONSOLIDATION_PLAN.md`)
- Testing bootstrap initiative (see `docs/TESTING_BOOTSTRAP.md`)
- Design system cleanup (see `docs/TECHNICAL_DEBT_ROADMAP.md`)

### Before Making Changes
1. Check consolidation plans - services may be deprecated soon
2. Write tests for new functionality
3. Use design system components
4. Verify with `flutter analyze` before committing

---

## Quality Standards

### Required Before Committing
- [ ] Code passes `flutter analyze` with no warnings
- [ ] All tests pass (`flutter test`)
- [ ] Uses `ThemeColors(context)` for colors (no hardcoded colors)
- [ ] Uses spacing tokens (no magic numbers)
- [ ] Uses design system components
- [ ] Tested with all 5 color schemes (if UI changes)
- [ ] Tests written for new services/business logic

### Code Review Checklist
- [ ] No new services created without justification
- [ ] No hardcoded colors or spacing
- [ ] Follows existing architectural patterns
- [ ] Integrates with ServiceLocator properly
- [ ] Uses Riverpod correctly for state management
- [ ] Documentation updated if needed

---

## Philosophy

**Quality over speed**: Understand the architecture before coding. This codebase has comprehensive foundations but significant complexity. Take time to investigate existing patterns, avoid creating parallel systems, and build maintainable solutions that integrate naturally.

**When in doubt**: Check if a service/component/pattern already exists. With 110+ services and 50+ design system components, the functionality you need likely exists. Extension is almost always better than creation.