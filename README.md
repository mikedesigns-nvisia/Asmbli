# 🤖 Asmbli - AI Chat Desktop Application

**Cross-platform desktop chat application for AI models with agent template capabilities**

[![CI](https://github.com/asmbli/asmbli/workflows/CI/badge.svg)](https://github.com/asmbli/asmbli/actions)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Flutter](https://img.shields.io/badge/Flutter-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![MCP Compatible](https://img.shields.io/badge/MCP-Compatible-blue)](https://modelcontextprotocol.io)
[![GitHub Stars](https://img.shields.io/github/stars/asmbli/asmbli?style=social)](https://github.com/asmbli/asmbli/stargazers)
[![Discord](https://img.shields.io/discord/YOUR_DISCORD_ID?logo=discord&logoColor=white&label=Discord)](https://discord.gg/asmbli)
[![Contributors](https://img.shields.io/github/contributors/asmbli/asmbli)](https://github.com/asmbli/asmbli/graphs/contributors)

---

## 🌟 Overview

Asmbli is a desktop chat application for AI models with agent template capabilities. Built with Flutter, it provides a clean interface for chatting with various AI models while experimenting with basic agent configurations and document context.

### ✨ What Asmbli Actually Does

- **🖥️ Cross-Platform Desktop Chat**: Flutter application for Windows, macOS, and Linux
- **🤖 Multi-Model Support**: Chat with Claude, OpenAI, local models, and other API-based LLMs
- **📋 Agent Templates**: Create and save basic agent configurations with custom prompts and settings
- **📄 Document Context**: Upload and reference documents during conversations (basic implementation)
- **🎨 Professional UI**: Multi-color scheme design system with clean, modern interface
- **💾 Local Storage**: Save conversations, agent templates, and settings locally
- **🔐 Secure Credentials**: Safe storage of API keys using OS-native secure storage

### ⚠️ Current Limitations

- **Agent Reliability**: AI agents can hallucinate and provide inconsistent responses
- **MCP Integration**: MCP server support is experimental and may not work reliably
- **Context Management**: Document context system is basic and may lose relevance in long conversations
- **No Deployment**: Agents exist only within the application - no external deployment capabilities

---

## 🚀 Quick Start

### System Requirements

#### Hardware
- **RAM**:
  - Minimum: 8GB
  - Recommended: 16GB or more (for better performance with local AI models)
- **Storage**: 10GB free space (additional space needed for AI models)
- **Processor**: 64-bit processor with 4+ cores recommended

#### Software Prerequisites

- **Flutter**: `>=3.0.0 <4.0.0`
- **Dart**: `>=3.0.0 <4.0.0`
- **Node.js**: `>=18.0.0` (for build tools)
- **Git**: For version control
- **macOS**: 10.15 (Catalina) or later
- **Windows**: Windows 10 version 1803 or later
- **Linux**: Ubuntu 18.04 LTS or equivalent

### 🖥️ Desktop Application Setup

```bash
# Clone the repository
git clone https://github.com/asmbli/asmbli.git
cd Asmbli

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

### 📱 Quick Setup

1. **Launch the desktop application**
2. **Add API keys** - Configure Claude, OpenAI, or other AI model APIs in settings
3. **Start a conversation** - Begin chatting with your chosen AI model
4. **Try agent templates** - Experiment with different agent configurations
5. **Upload documents** - Add context files to enhance conversations (optional)

---

## 🏗️ Architecture

### Project Structure

```
Asmbli/
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
   git fork https://github.com/asmbli/asmbli.git
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

### 🎯 Current Version: Beta 0.9.0

#### ✅ What Works Well
- ✅ Cross-platform Flutter desktop application (Windows, macOS, Linux)
- ✅ Multi-color scheme design system
- ✅ Real-time chat interface with multiple AI models
- ✅ Basic agent template creation and management
- ✅ Secure API key storage
- ✅ Local conversation history
- ✅ Document upload and basic context injection

#### ⚠️ Known Issues
- ⚠️ Agent responses can be inconsistent and may hallucinate
- ⚠️ MCP server integration is unreliable and experimental
- ⚠️ Document context may lose relevance in long conversations
- ⚠️ Vector search functionality is basic and may not scale
- ⚠️ No authentication or user management system
- ⚠️ Limited error handling for API failures

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

- **Primary Use Case**: Desktop AI chat application with basic agent templates
- **Stability**: Beta - expect bugs and limitations
- **Supported Platforms**: Windows, macOS, Linux
- **AI Models**: Claude, OpenAI, local models (via API)
- **Best For**: Experimenting with AI conversations and basic agent configurations

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
- **🐛 Issues**: [GitHub Issues](https://github.com/asmbli/asmbli/issues)
- **📧 Email**: support@asmbli.dev

### 🗺️ Roadmap

See our [public roadmap](https://github.com/asmbli/asmbli/projects) for upcoming features and releases.

### 📊 Analytics

This project uses anonymous analytics to understand usage patterns and improve the product. You can opt out in the application settings.

---

**💬 Ready to try a clean AI chat interface with agent templates? [Get started now!](#-quick-start)**

---

*Last updated: 2025-09-18*