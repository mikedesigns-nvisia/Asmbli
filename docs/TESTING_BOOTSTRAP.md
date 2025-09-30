# 🧪 Testing Bootstrap Guide

**Goal**: Go from 9% → 40% test coverage in 4 weeks using existing Flutter tooling.

**No External Dependencies** - Uses only:
- `flutter_test` (already in pubspec.yaml)
- `test: ^1.25.7` (already in pubspec.yaml)
- Built-in Flutter testing tools

---

## 🎯 Coverage Goals

| Week | Target | Focus Area |
|------|--------|-----------|
| Week 1 | 15% | Critical business logic |
| Week 2 | 25% | Services layer |
| Week 3 | 35% | Widget tests for core features |
| Week 4 | 40% | Integration tests |

---

## 📁 Test Organization

```
apps/desktop/test/
├── unit/
│   ├── services/        # Service tests (Week 1-2)
│   ├── models/          # Model tests (Week 1)
│   └── utils/           # Utility tests (Week 2)
├── widget/              # Widget tests (Week 3)
│   ├── chat/
│   ├── agents/
│   └── settings/
├── integration/         # Integration tests (Week 4)
└── helpers/             # Test helpers & mocks
    ├── mock_services.dart
    ├── test_data.dart
    └── pump_app.dart
```

---

## 🚀 Quick Start

### **1. Create Test Helper** (15 minutes)

```dart
// test/helpers/pump_app.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Helper to pump widgets with necessary providers
Future<void> pumpApp(
  WidgetTester tester,
  Widget widget, {
  List<Override> overrides = const [],
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        home: widget,
      ),
    ),
  );
}

/// Pump and settle with timeout
Future<void> pumpAndSettleSafe(
  WidgetTester tester, {
  Duration timeout = const Duration(seconds: 5),
}) async {
  await tester.pumpAndSettle(timeout);
}
```

### **2. Create Mock Services** (30 minutes)

```dart
// test/helpers/mock_services.dart
import 'package:agent_engine_core/models/agent.dart';
import 'package:agent_engine_core/models/conversation.dart';
import 'package:agent_engine_core/services/agent_service.dart';
import 'package:agent_engine_core/services/conversation_service.dart';

class MockAgentService implements AgentService {
  final List<Agent> _agents = [];

  @override
  Future<Agent> createAgent(Agent agent) async {
    _agents.add(agent);
    return agent;
  }

  @override
  Future<List<Agent>> getAgents() async => _agents;

  @override
  Future<Agent?> getAgent(String id) async {
    return _agents.firstWhere((a) => a.id == id);
  }

  @override
  Future<void> updateAgent(Agent agent) async {
    final index = _agents.indexWhere((a) => a.id == agent.id);
    if (index != -1) _agents[index] = agent;
  }

  @override
  Future<void> deleteAgent(String id) async {
    _agents.removeWhere((a) => a.id == id);
  }
}

class MockConversationService implements ConversationService {
  final List<Conversation> _conversations = [];

  @override
  Future<Conversation> createConversation(Conversation conv) async {
    _conversations.add(conv);
    return conv;
  }

  @override
  Future<List<Conversation>> getConversations() async => _conversations;

  // Implement other methods...
}
```

### **3. Create Test Data Factory** (30 minutes)

```dart
// test/helpers/test_data.dart
import 'package:agent_engine_core/models/agent.dart';
import 'package:agent_engine_core/models/conversation.dart';
import 'package:agent_engine_core/models/message.dart';
import 'package:uuid/uuid.dart';

class TestData {
  static const uuid = Uuid();

  static Agent createAgent({
    String? id,
    String name = 'Test Agent',
    String systemPrompt = 'You are a helpful assistant',
    List<String> tools = const [],
  }) {
    return Agent(
      id: id ?? uuid.v4(),
      name: name,
      systemPrompt: systemPrompt,
      integrations: tools,
      configuration: AgentConfiguration(
        model: 'claude-3-sonnet',
        temperature: 0.7,
        maxTokens: 1000,
      ),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  static Conversation createConversation({
    String? id,
    String? agentId,
    String title = 'Test Conversation',
  }) {
    return Conversation(
      id: id ?? uuid.v4(),
      agentId: agentId,
      title: title,
      messages: [],
      status: ConversationStatus.active,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  static Message createMessage({
    String? id,
    String? conversationId,
    String content = 'Hello, world!',
    MessageRole role = MessageRole.user,
  }) {
    return Message(
      id: id ?? uuid.v4(),
      conversationId: conversationId ?? uuid.v4(),
      content: content,
      role: role,
      timestamp: DateTime.now(),
    );
  }
}
```

---

## 📝 Week 1: Unit Tests (Critical Paths)

### **Priority 1: Business Logic** (Day 1-2)

```dart
// test/unit/services/agent_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import '../../helpers/mock_services.dart';
import '../../helpers/test_data.dart';

void main() {
  group('AgentService', () {
    late MockAgentService service;

    setUp(() {
      service = MockAgentService();
    });

    test('creates agent successfully', () async {
      final agent = TestData.createAgent(name: 'My Agent');

      final created = await service.createAgent(agent);

      expect(created.id, isNotEmpty);
      expect(created.name, 'My Agent');
    });

    test('retrieves all agents', () async {
      await service.createAgent(TestData.createAgent(name: 'Agent 1'));
      await service.createAgent(TestData.createAgent(name: 'Agent 2'));

      final agents = await service.getAgents();

      expect(agents.length, 2);
      expect(agents[0].name, 'Agent 1');
      expect(agents[1].name, 'Agent 2');
    });

    test('updates agent', () async {
      final agent = await service.createAgent(
        TestData.createAgent(name: 'Original'),
      );

      final updated = agent.copyWith(name: 'Updated');
      await service.updateAgent(updated);

      final retrieved = await service.getAgent(agent.id);
      expect(retrieved?.name, 'Updated');
    });

    test('deletes agent', () async {
      final agent = await service.createAgent(TestData.createAgent());

      await service.deleteAgent(agent.id);

      final agents = await service.getAgents();
      expect(agents.isEmpty, true);
    });
  });
}
```

### **Priority 2: Model Tests** (Day 3)

```dart
// test/unit/models/agent_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:agent_engine_core/models/agent.dart';

void main() {
  group('Agent Model', () {
    test('creates agent with required fields', () {
      final agent = Agent(
        id: '123',
        name: 'Test Agent',
        systemPrompt: 'You are helpful',
        integrations: [],
        configuration: AgentConfiguration(
          model: 'claude-3-sonnet',
          temperature: 0.7,
          maxTokens: 1000,
        ),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(agent.id, '123');
      expect(agent.name, 'Test Agent');
    });

    test('copyWith creates new instance with updated fields', () {
      final agent = TestData.createAgent(name: 'Original');

      final updated = agent.copyWith(name: 'Updated');

      expect(agent.name, 'Original'); // Original unchanged
      expect(updated.name, 'Updated');
      expect(updated.id, agent.id); // Same ID
    });

    test('toJson/fromJson roundtrip', () {
      final agent = TestData.createAgent();

      final json = agent.toJson();
      final restored = Agent.fromJson(json);

      expect(restored.id, agent.id);
      expect(restored.name, agent.name);
      expect(restored.systemPrompt, agent.systemPrompt);
    });
  });
}
```

---

## 📱 Week 3: Widget Tests

### **Priority: Core UI Components** (Day 1-3)

```dart
// test/widget/chat/chat_message_widget_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../helpers/pump_app.dart';
import '../../helpers/test_data.dart';

void main() {
  group('ChatMessageWidget', () {
    testWidgets('displays user message', (tester) async {
      final message = TestData.createMessage(
        content: 'Hello!',
        role: MessageRole.user,
      );

      await pumpApp(
        tester,
        ChatMessageWidget(message: message),
      );

      expect(find.text('Hello!'), findsOneWidget);
      expect(find.byIcon(Icons.person), findsOneWidget);
    });

    testWidgets('displays assistant message', (tester) async {
      final message = TestData.createMessage(
        content: 'Hi there!',
        role: MessageRole.assistant,
      );

      await pumpApp(
        tester,
        ChatMessageWidget(message: message),
      );

      expect(find.text('Hi there!'), findsOneWidget);
      expect(find.byIcon(Icons.smart_toy), findsOneWidget);
    });

    testWidgets('shows timestamp on tap', (tester) async {
      final message = TestData.createMessage();

      await pumpApp(
        tester,
        ChatMessageWidget(message: message),
      );

      await tester.tap(find.byType(ChatMessageWidget));
      await tester.pumpAndSettle();

      // Verify timestamp is shown
      expect(find.textContaining('ago'), findsOneWidget);
    });
  });
}
```

---

## 🔗 Week 4: Integration Tests

```dart
// test/integration/chat_flow_test.dart
import 'package:flutter_test/flutter_test.dart';
import '../helpers/pump_app.dart';
import '../helpers/mock_services.dart';
import '../helpers/test_data.dart';

void main() {
  group('Chat Flow Integration', () {
    late MockAgentService agentService;
    late MockConversationService conversationService;

    setUp(() {
      agentService = MockAgentService();
      conversationService = MockConversationService();
    });

    testWidgets('complete chat workflow', (tester) async {
      // 1. Create agent
      final agent = await agentService.createAgent(
        TestData.createAgent(name: 'Chat Agent'),
      );

      // 2. Start conversation
      await pumpApp(
        tester,
        ChatScreen(),
        overrides: [
          agentServiceProvider.overrideWithValue(agentService),
          conversationServiceProvider.overrideWithValue(conversationService),
        ],
      );

      // 3. Send message
      await tester.enterText(
        find.byType(TextField),
        'Hello, agent!',
      );
      await tester.tap(find.byIcon(Icons.send));
      await tester.pumpAndSettle();

      // 4. Verify message appears
      expect(find.text('Hello, agent!'), findsOneWidget);

      // 5. Verify conversation created
      final conversations = await conversationService.getConversations();
      expect(conversations.length, 1);
      expect(conversations[0].messages.length, 1);
    });
  });
}
```

---

## 🎯 Running Tests

### **Run All Tests**
```bash
cd apps/desktop
flutter test
```

### **Run Specific Test**
```bash
flutter test test/unit/services/agent_service_test.dart
```

### **Run with Coverage**
```bash
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html  # View coverage report
```

### **Watch Mode** (run tests on file change)
```bash
flutter test --watch
```

---

## 📊 Coverage Tracking

Create a script to track progress:

```bash
# scripts/check_coverage.sh
#!/bin/bash

flutter test --coverage
lcov --summary coverage/lcov.info 2>&1 | grep "lines......"

# Expected output:
#   lines......: 40.2% (1234 of 3067 lines)
```

Add to `.github/workflows` or run manually each week.

---

## 🎓 Testing Best Practices

### **DO:**
✅ Test behavior, not implementation
✅ Use descriptive test names
✅ Follow Arrange-Act-Assert pattern
✅ Keep tests independent (no shared state)
✅ Mock external dependencies

### **DON'T:**
❌ Test private methods directly
❌ Hardcode magic numbers
❌ Skip setUp/tearDown
❌ Test multiple things in one test
❌ Rely on test execution order

---

## 📚 Example Test Template

```dart
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FeatureName', () {
    // Setup runs before each test
    setUp(() {
      // Initialize test dependencies
    });

    // Teardown runs after each test
    tearDown(() {
      // Clean up resources
    });

    test('should do expected behavior', () {
      // ARRANGE: Set up test data
      final input = 'test';

      // ACT: Perform action
      final result = functionUnderTest(input);

      // ASSERT: Verify result
      expect(result, expectedValue);
    });

    test('should handle edge case', () {
      // Test edge cases and error conditions
    });
  });
}
```

---

## ✅ Week-by-Week Checklist

### **Week 1: Foundation (15% coverage)**
- [ ] Create test helpers (`pump_app.dart`)
- [ ] Create mock services
- [ ] Create test data factory
- [ ] Write 10 unit tests for AgentService
- [ ] Write 10 unit tests for ConversationService
- [ ] Write 5 model tests

### **Week 2: Services (25% coverage)**
- [ ] Test MCPBridgeService
- [ ] Test ThemeService
- [ ] Test StorageService
- [ ] Test ApiConfigService
- [ ] Write 20 more unit tests

### **Week 3: Widgets (35% coverage)**
- [ ] Test AsmblButton variants
- [ ] Test AsmblCard
- [ ] Test ChatMessageWidget
- [ ] Test ConversationList
- [ ] Write 15 widget tests

### **Week 4: Integration (40% coverage)**
- [ ] Test chat flow end-to-end
- [ ] Test agent creation flow
- [ ] Test settings persistence
- [ ] Write 5 integration tests
- [ ] Generate coverage report

---

## 🚨 Common Pitfalls

### **Problem**: Test times out
```dart
// BAD
await tester.pumpAndSettle(); // Can hang

// GOOD
await tester.pumpAndSettle(Duration(seconds: 5));
```

### **Problem**: Widget not found
```dart
// BAD
await tester.tap(find.text('Button'));

// GOOD
await tester.pumpAndSettle(); // Wait for widget to appear
expect(find.text('Button'), findsOneWidget);
await tester.tap(find.text('Button'));
```

### **Problem**: Async test fails
```dart
// BAD
test('async test', () {
  functionThatReturnsF future();
});

// GOOD
test('async test', () async {
  await functionThatReturnsFuture();
});
```

---

## 📞 Need Help?

- Flutter Testing Docs: https://docs.flutter.dev/testing
- Widget Testing: https://docs.flutter.dev/cookbook/testing/widget/introduction
- Riverpod Testing: https://riverpod.dev/docs/essentials/testing

---

**Status**: 📋 Ready to implement
**Timeline**: 4 weeks
**Goal**: 9% → 40% coverage