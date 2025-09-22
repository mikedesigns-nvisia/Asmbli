# 🤖 Asmbli - Experimental AI Chat Desktop Application

**⚠️ Early-stage experimental desktop chat application for AI models with basic agent template capabilities**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Flutter](https://img.shields.io/badge/Flutter-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![MCP Compatible](https://img.shields.io/badge/MCP-Compatible-blue)](https://modelcontextprotocol.io)

---

## 🌟 Overview

**⚠️ This is an experimental project in early development. Expect bugs, incomplete features, and breaking changes.**

Asmbli is an experimental desktop chat application for AI models with basic agent template capabilities. Built with Flutter, it provides a simple interface for chatting with AI models while experimenting with very basic agent configurations. This is primarily a learning project and proof-of-concept.

### ✨ What Asmbli Actually Does (Sort Of)

- **🖥️ Basic Desktop Chat**: Flutter application that sometimes works on Windows, macOS, and Linux
- **🤖 Limited Model Support**: Chat with Claude, OpenAI, and Ollama small models (when API keys/connections work correctly)
- **📋 Agent Templates**: Very basic agent configurations that may or may not persist properly
- **📄 Document Context**: Experimental file upload that occasionally works
- **🎨 Design System**: Has a UI that looks okay but may have visual bugs
- **💾 Local Storage**: Attempts to save things locally (results may vary)
- **🔐 Credential Storage**: Tries to store API keys securely (not thoroughly tested)

### ⚠️ Major Limitations & Known Issues

- **This is Alpha Software**: Expect crashes, data loss, and broken functionality
- **Agent Reliability**: AI agents frequently hallucinate and provide inconsistent responses
- **MCP Integration**: Experimental at best, probably doesn't work with most servers
- **Context Management**: Document context system is rudimentary and unreliable
- **No Production Use**: This is a learning project, not production-ready software
- **Limited Testing**: Many features are untested and may not work as expected
- **Bugs Everywhere**: UI glitches, state management issues, and general instability
- **No Deployment**: Agents exist only within the application - no external deployment capabilities

---

## 🚀 Quick Start (If You're Feeling Brave)

**⚠️ Warning**: This software is experimental and may not work as expected. Use at your own risk.

### Prerequisites

- **Flutter**: `>=3.0.0 <4.0.0`
- **Dart**: `>=3.0.0 <4.0.0`
- **Node.js**: `>=18.0.0` (for build tools)
- **Git**: For version control

### 🖥️ Desktop Application Setup

```bash
# Clone the repository
git clone https://github.com/your-org/AgentEngine.git
cd AgentEngine

# Install Flutter dependencies
cd apps/desktop
flutter pub get

# Install core package dependencies
cd ../../packages/agent_engine_core
flutter pub get
cd ../../

# Run the desktop application
cd apps/desktop
flutter run
```

### 📱 Quick Setup (Your Mileage May Vary)

1. **Launch the desktop application** (if it starts successfully)
2. **Add API keys** - Try configuring Claude or OpenAI APIs in settings (may or may not save properly)
3. **Start a conversation** - Attempt to chat with your chosen AI model (expect possible errors)
4. **Try agent templates** - Experiment with basic agent configurations (results unpredictable)
5. **Upload documents** - Try adding context files (experimental feature, may not work)

---

## 🏗️ Architecture

### Project Structure

```
AgentEngine/
├── apps/
│   └── desktop/                    # Flutter desktop application
│       ├── lib/
│       │   ├── core/              # Core services and utilities
│       │   │   ├── design_system/ # UI components and theming
│       │   │   ├── services/      # Business logic services
│       │   │   └── constants/     # App constants and routes
│       │   ├── features/          # Feature-based modules
│       │   │   ├── chat/         # Chat interface and logic
│       │   │   ├── agents/       # Agent management
│       │   │   ├── settings/     # App configuration
│       │   │   └── onboarding/   # User onboarding flow
│       │   └── main.dart         # Application entry point
│       └── pubspec.yaml          # Flutter dependencies
├── packages/
│   └── agent_engine_core/         # Shared core package
│       ├── lib/
│       │   ├── models/           # Data models (Agent, Conversation)
│       │   └── services/         # Shared business logic
│       └── pubspec.yaml
├── src/                          # Legacy web components
├── components/                   # Legacy React components
├── docs/                        # Documentation
└── README.md                    # This file
```

### 🎨 Design System

Asmbli features a comprehensive design system with:

- **Multi-Color Schemes**: Mint Green, Cool Blue, Forest Green, Sunset Orange
- **Adaptive Theming**: Automatic light/dark mode support
- **Component Library**: 50+ reusable UI components
- **Typography**: Fustat font family with consistent text styles
- **Spacing System**: Standardized spacing tokens
- **Interactive States**: Hover, pressed, and focus states

#### Using the Design System

```dart
import 'core/design_system/design_system.dart';

// Access theme colors
final colors = ThemeColors(context);

// Use design system components
AsmblCard(
  child: Column(
    children: [
      Text('Hello World', style: TextStyles.pageTitle),
      AsmblButton.primary(
        text: 'Click Me',
        onPressed: () {},
      ),
    ],
  ),
)
```

### 🔧 Core Features

#### Chat Interface
- **Real-time conversations** with AI models
- **Message history** and conversation management
- **Streaming responses** for better user experience
- **Multi-model switching** within conversations

#### Agent Templates
- **Custom prompts** and system messages
- **Model configuration** (temperature, max tokens, etc.)
- **Template library** for common use cases
- **Save and reuse** agent configurations

#### Document Context (Beta)
- **File upload** for context (PDF, text, markdown)
- **Basic document parsing** and chunking
- **Context injection** into conversations
- **Local vector storage** (experimental)

#### MCP Integration (Experimental)
⚠️ **Note**: MCP server integration is in early development and may not work reliably.

- **Local MCP servers** - Basic filesystem operations
- **Configuration management** for MCP connections
- **Limited server compatibility** - most servers are untested

---

## 🛠️ Development

### Setting Up Development Environment

1. **Install Flutter**
   ```bash
   # Follow official Flutter installation guide
   # https://docs.flutter.dev/get-started/install
   ```

2. **Configure IDE**
   - **VS Code**: Install Flutter and Dart extensions
   - **Android Studio**: Install Flutter plugin
   - **IntelliJ IDEA**: Install Flutter plugin

3. **Set up Dependencies**
   ```bash
   # Install all dependencies
   flutter pub get
   cd packages/agent_engine_core && flutter pub get

   # For build tools (optional)
   npm install
   ```

### 🧪 Running Tests

```bash
# Run Flutter tests
flutter test

# Run specific test files
flutter test test/models/agent_test.dart

# Run with coverage
flutter test --coverage
```

### 🔧 Development Commands

```bash
# Development mode with hot reload
flutter run

# Build for specific platforms
flutter build windows
flutter build macos
flutter build linux

# Code generation (if needed)
flutter packages pub run build_runner build

# Lint and format code
flutter analyze
dart format .
```

### 📊 Database Setup

Asmbli uses SQLite for local storage with Hive for preferences:

```bash
# Database migrations are handled automatically
# Manual migration (if needed)
cd apps/desktop
flutter packages pub run build_runner build
```

---

## 🤝 Contributing

We welcome contributions from the community! Here's how to get started:

### 🐛 Reporting Issues

1. **Search existing issues** to avoid duplicates
2. **Use issue templates** provided in the repository
3. **Include reproduction steps** and system information
4. **Add relevant labels** (bug, enhancement, documentation)

### 🔄 Pull Request Process

1. **Fork the repository**
   ```bash
   git fork https://github.com/your-org/AgentEngine.git
   ```

2. **Create a feature branch**
   ```bash
   git checkout -b feature/amazing-feature
   ```

3. **Follow coding standards**
   - Use the existing design system
   - Follow Dart/Flutter conventions
   - Add tests for new features
   - Update documentation

4. **Commit with conventional commits**
   ```bash
   git commit -m "feat: add amazing new feature"
   ```

5. **Submit pull request**
   - Fill out the PR template
   - Link related issues
   - Request review from maintainers

### 📝 Coding Standards

#### Flutter/Dart Code

```dart
// ✅ Use design system components
AsmblButton.primary(text: "Save", onPressed: () {})

// ✅ Use ThemeColors for styling
final colors = ThemeColors(context);

// ✅ Follow naming conventions
class UserProfileService extends ChangeNotifier {
  // Implementation
}

// ❌ Don't use hardcoded colors
// Container(color: Color(0xFF123456)) // Wrong

// ❌ Don't ignore the design system
// ElevatedButton(...) // Use AsmblButton instead
```

#### Code Organization

- **Features**: Group related functionality together
- **Services**: Business logic separate from UI
- **Models**: Use Freezed for immutable data classes
- **Tests**: Mirror the lib/ structure in test/

### 🎯 Development Guidelines

1. **Design System First**: Always use existing components
2. **Responsive Design**: Ensure components work on all screen sizes
3. **Accessibility**: Add semantic labels and keyboard navigation
4. **Performance**: Optimize for smooth 60fps animations
5. **Security**: Never commit API keys or secrets

### 🚀 Adding New Features

#### Adding a New MCP Server Integration

1. **Define the server configuration**
   ```dart
   // In packages/agent_engine_core/lib/models/
   class NewServiceIntegration {
     final String apiKey;
     final String baseUrl;
     // Configuration properties
   }
   ```

2. **Add to integration registry**
   ```dart
   // Update integration_registry.dart
   static final Map<String, IntegrationDefinition> _integrations = {
     'new_service': IntegrationDefinition(
       id: 'new_service',
       name: 'New Service',
       // Configuration
     ),
   };
   ```

3. **Create UI components**
   ```dart
   // In features/settings/presentation/widgets/
   class NewServiceConfigWidget extends StatelessWidget {
     // Implementation using design system
   }
   ```

4. **Add tests**
   ```dart
   // test/features/settings/new_service_test.dart
   group('NewService Integration', () {
     testWidgets('should configure correctly', (tester) async {
       // Test implementation
     });
   });
   ```

---

## 📚 Documentation

### 📖 User Guides

- **[Getting Started Guide](docs/getting-started.md)** - First-time user walkthrough
- **[Agent Creation Tutorial](docs/agent-tutorial.md)** - Building your first agent
- **[MCP Integration Guide](docs/mcp-integration.md)** - Connecting external services
- **[Deployment Guide](DEPLOYMENT_GUIDE.md)** - Production deployment instructions

### 🔧 Developer Documentation

- **[Architecture Overview](docs/architecture.md)** - System design and patterns
- **[API Documentation](docs/api.md)** - Service interfaces and contracts
- **[Testing Guide](TESTING_GUIDE.md)** - Testing strategies and tools
- **[Design System Guide](docs/design-system.md)** - UI components and patterns

### 📋 Examples

```dart
// Creating a custom agent
final agent = Agent(
  id: const Uuid().v4(),
  name: 'Customer Support Bot',
  systemPrompt: 'You are a helpful customer support assistant...',
  integrations: ['slack', 'zendesk'],
  configuration: AgentConfiguration(
    model: 'claude-3-sonnet',
    temperature: 0.7,
    maxTokens: 1000,
  ),
);

// Starting a conversation
final conversation = await conversationService.createConversation(
  agentId: agent.id,
  initialMessage: 'Hello, how can I help you today?',
);
```

---

## 🔧 Configuration

### Environment Variables

Create a `.env` file in the root directory:

```bash
# API Configuration
CLAUDE_API_KEY=your_anthropic_api_key
OPENAI_API_KEY=your_openai_api_key

# Database Configuration
DATABASE_URL=sqlite:///./data/asmbli.db

# OAuth Configuration
GITHUB_CLIENT_ID=your_github_client_id
GITHUB_CLIENT_SECRET=your_github_client_secret

# Feature Flags
ENABLE_ANALYTICS=true
ENABLE_VECTOR_SEARCH=true
ENABLE_MCP_REGISTRY=true
```

### Application Settings

The desktop application stores settings in:
- **Windows**: `%APPDATA%/asmbli/`
- **macOS**: `~/Library/Application Support/asmbli/`
- **Linux**: `~/.local/share/asmbli/`

---

## 🚀 Deployment

### Desktop Application

```bash
# Build for current platform
flutter build [windows|macos|linux]

# Build installers
flutter build windows --release
flutter build macos --release
flutter build linux --release
```

### Distribution

```bash
# Create platform-specific installers
flutter build windows --release
flutter build macos --release
flutter build linux --release

# Package for distribution
# Windows: Creates .msix installer
# macOS: Creates .app bundle
# Linux: Creates AppImage or snap
```

---

## 📊 Project Status

### 🎯 Current Version: Alpha 0.1.0 (Very Early Development)

#### 🤷 What Might Work Sometimes
- 🤷 Flutter desktop application (compiles and runs, mostly)
- 🤷 Basic UI components (some visual bugs expected)
- 🤷 Chat interface (when it doesn't crash)
- 🤷 Agent templates (very basic, may not persist)
- 🤷 API key storage (seems to work but not thoroughly tested)
- 🤷 Local data storage (experimental)

#### 🚨 Major Known Issues
- 🚨 **Stability**: Frequent crashes and unexpected behavior
- 🚨 **Data Loss**: May lose conversations, settings, or configurations
- 🚨 **Agent Reliability**: AI agents frequently provide inconsistent responses
- 🚨 **MCP Integration**: Mostly non-functional, experimental at best
- 🚨 **Error Handling**: Poor error handling throughout the application
- 🚨 **Testing**: Minimal testing coverage, many untested code paths
- 🚨 **Performance**: May be slow, memory leaks possible
- 🚨 **UI Bugs**: Visual glitches, layout issues, responsive design problems
- 🚨 **Cross-Platform**: Different bugs on different operating systems

#### 🚧 In Development
- 🚧 Improved MCP server compatibility
- 🚧 Better document context management
- 🚧 Enhanced agent reliability
- 🚧 More robust error handling

#### 🔮 Future Goals
- 🔮 Agent deployment capabilities
- 🔮 Multi-user support
- 🔮 Plugin marketplace
- 🔮 Mobile applications

### 📈 Current State

- **Primary Use Case**: Learning project for Flutter and AI integration
- **Stability**: Alpha - expect crashes, bugs, and broken functionality
- **Supported Platforms**: Windows, macOS, Linux (with varying degrees of brokenness)
- **AI Models**: Claude, OpenAI, Ollama small models (when the API integration works)
- **Best For**: Educational purposes, code examples, and very patient developers who like fixing things
- **Not Suitable For**: Any production use, serious projects, or users who expect working software

---

## 🙏 Acknowledgments

### 🏆 Built With

- **[Flutter](https://flutter.dev)** - Cross-platform UI framework
- **[Riverpod](https://riverpod.dev)** - State management
- **[Go Router](https://pub.dev/packages/go_router)** - Navigation
- **[Hive](https://hivedb.dev)** - Local database
- **[Model Context Protocol](https://modelcontextprotocol.io)** - AI agent integration standard

### 🤝 Contributors

- **Core Team**: [List core maintainers]
- **Community Contributors**: [Auto-generated from git history]
- **Special Thanks**: Anthropic for Claude API, ModelContextProtocol.io community

### 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 📞 Support & Community

### 💬 Getting Help

- **📖 Documentation**: [Full documentation site](https://docs.asmbli.dev)
- **💬 Discord**: [Join our community](https://discord.gg/asmbli)
- **🐛 Issues**: [GitHub Issues](https://github.com/your-org/AgentEngine/issues)
- **📧 Email**: support@asmbli.dev

### 🗺️ Roadmap

See our [public roadmap](https://github.com/your-org/AgentEngine/projects) for upcoming features and releases.

### 📊 Analytics

This project uses anonymous analytics to understand usage patterns and improve the product. You can opt out in the application settings.

---

**💬 Ready to experiment with an unstable AI chat application that may or may not work? [Proceed at your own risk!](#-quick-start-if-youre-feeling-brave)**

---

*Last updated: 2025-09-18*