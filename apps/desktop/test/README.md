# Asmbli Desktop App - Test Suite

This directory contains comprehensive integration tests for all major user flows in the Asmbli desktop application.

## Test Structure

### 📁 Integration Tests
Located in `test/integration/`, these test complete user workflows from start to finish:

- **`onboarding_flow_test.dart`** - First-time user setup and API configuration
- **`chat_conversation_flow_test.dart`** - Chat functionality, message sending, conversation management
- **`agent_creation_flow_test.dart`** - Agent builder wizard, configuration, and management
- **`settings_configuration_flow_test.dart`** - App settings, theme changes, API configuration
- **`navigation_routing_flow_test.dart`** - Navigation between screens, routing, deep linking

### 📁 Test Helpers
Located in `test/test_helpers/`, these provide mock services and utilities:

- **`mock_services.dart`** - Mock implementations of core services
- **`test_app_wrapper.dart`** - Test app wrapper with controlled environment

## Running Tests

### Run All Tests
```bash
# Run complete test suite
flutter test test/test_runner_main.dart

# Run with verbose output
flutter test test/test_runner_main.dart --reporter expanded
```

### Run Individual Test Suites
```bash
# Onboarding tests
flutter test test/integration/onboarding_flow_test.dart

# Chat tests
flutter test test/integration/chat_conversation_flow_test.dart

# Agent creation tests
flutter test test/integration/agent_creation_flow_test.dart

# Settings tests
flutter test test/integration/settings_configuration_flow_test.dart

# Navigation tests
flutter test test/integration/navigation_routing_flow_test.dart
```

### Run with Coverage
```bash
# Generate test coverage
flutter test --coverage test/test_runner_main.dart

# Generate HTML coverage report (requires lcov)
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

## Test Coverage

### 🎯 Onboarding Flow (onboarding_flow_test.dart)
- ✅ New user redirect to onboarding
- ✅ Existing user skip onboarding
- ✅ Complete onboarding with API setup
- ✅ Form validation
- ✅ Onboarding completion state
- ✅ Skip onboarding option

### 💬 Chat Conversation Flow (chat_conversation_flow_test.dart)
- ✅ Empty chat state
- ✅ Create new conversation
- ✅ Send messages
- ✅ Conversation sidebar
- ✅ Switch between conversations
- ✅ Delete conversations
- ✅ Rename conversations
- ✅ Message streaming
- ✅ Sidebar collapse/expand

### 🤖 Agent Creation Flow (agent_creation_flow_test.dart)
- ✅ Agent wizard loading
- ✅ Create basic agent
- ✅ Form validation
- ✅ Template selection
- ✅ System prompt configuration
- ✅ My Agents screen
- ✅ Edit existing agent
- ✅ Delete agent
- ✅ Test agent functionality
- ✅ Advanced configuration

### ⚙️ Settings Configuration Flow (settings_configuration_flow_test.dart)
- ✅ Settings screen loading
- ✅ Theme mode changes (Light/Dark)
- ✅ Color scheme changes
- ✅ API provider configuration
- ✅ Add new API provider
- ✅ Remove API provider
- ✅ Form validation
- ✅ Integration settings
- ✅ About section
- ✅ Settings persistence

### 🧭 Navigation & Routing Flow (navigation_routing_flow_test.dart)
- ✅ Default home route
- ✅ Navigation bar presence
- ✅ All screen navigation
- ✅ Quick action navigation
- ✅ Brand title home navigation
- ✅ Deep linking with parameters
- ✅ State preservation
- ✅ Invalid route handling
- ✅ Back button behavior
- ✅ Active navigation highlighting
- ✅ Smooth transitions

## Mock Services

The test suite uses comprehensive mock services to simulate real app behavior:

- **MockDesktopStorageService** - Simulates local storage and preferences
- **MockApiConfigService** - Simulates API provider configuration
- **MockConversationService** - Simulates conversation management
- **MockAgentService** - Simulates agent creation and management
- **MockThemeService** - Simulates theme and appearance changes

## Test Environment

Tests run in a controlled environment with:
- Isolated state management
- Mock service dependencies  
- Predictable data fixtures
- Large screen size (1400x900) for desktop testing
- Proper async handling and animations

## Continuous Integration

These tests are designed to run in CI environments:
- No external dependencies
- Deterministic behavior
- Fast execution
- Comprehensive error reporting

## Adding New Tests

When adding new features, follow this pattern:

1. Create mock services in `test_helpers/mock_services.dart`
2. Add test file in appropriate `integration/` subdirectory
3. Follow existing naming conventions
4. Include in `test_runner_main.dart`
5. Update this README with new test coverage

## Test Best Practices

- Use descriptive test names that explain the user action
- Test complete user workflows, not isolated functions
- Include both positive and negative test cases
- Verify state changes and side effects
- Use proper async/await handling
- Test error conditions and edge cases
- Mock external dependencies consistently

## Troubleshooting

### Common Issues
- **Widget not found**: Ensure proper `pumpAndSettle()` calls after actions
- **Service not mocked**: Add missing mock service to test setup
- **Async timing**: Use `pumpAndSettle()` for animations and state changes
- **Screen size**: Tests require desktop screen size (1400x900)

### Debug Mode
```bash
# Run single test with debug output
flutter test test/integration/onboarding_flow_test.dart --plain-name "Complete onboarding flow"
```

For more information, see the [Flutter Testing Documentation](https://docs.flutter.dev/testing).