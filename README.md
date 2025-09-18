# 🤖 Asmbli - Professional AI Agent Builder

**Build, deploy, and manage AI agents with ease using the Model Context Protocol (MCP)**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Flutter](https://img.shields.io/badge/Flutter-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![MCP Compatible](https://img.shields.io/badge/MCP-Compatible-blue)](https://modelcontextprotocol.io)

---

## 🌟 Overview

Asmbli is a professional-grade AI agent builder that democratizes AI agent creation for both developers and non-technical users. Built with Flutter and leveraging the Model Context Protocol (MCP), it provides a seamless cross-platform desktop experience.

### ✨ Key Features

- **🖥️ Professional Desktop Application**: Cross-platform Flutter application for Windows, macOS, and Linux
- **🔧 60+ MCP Server Integrations**: GitHub, Microsoft 365, AWS, Google Cloud, Slack, and more
- **🎨 Advanced Design System**: Multi-color scheme support with professional UI components
- **💬 Real-time Chat Interface**: Streaming conversations with context-aware responses
- **🔐 Enterprise Security**: OAuth 2.0, API key management, and secure credential storage
- **📱 Cross-Platform**: Native desktop application (Windows, macOS, Linux)
- **🎯 Agent Templates**: Pre-configured templates for common use cases
- **📊 Vector Knowledge Base**: Advanced context management and retrieval

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

### 📱 Quick Setup

1. **Launch the desktop application**
2. **Complete onboarding** - Configure your first AI model
3. **Add integrations** - Connect to your favorite services
4. **Create your first agent** - Use templates or build from scratch
5. **Start chatting** - Test your agent in real-time

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

### 🔧 MCP Integration Architecture

Asmbli integrates with 60+ MCP servers across multiple categories:

#### Core MCP Servers (11)
- **filesystem-mcp** - Local file operations
- **git-mcp** - Version control
- **github** - GitHub API integration
- **postgres-mcp** - Database operations
- **memory-mcp** - AI memory management

#### Enterprise Integrations (49+)
- **Microsoft 365 Suite** (Teams, Outlook, SharePoint, OneDrive)
- **Cloud Platforms** (AWS, Google Cloud, Azure)
- **Communication** (Slack, Discord, Telegram)
- **Productivity** (Notion, Linear, Google Analytics)
- **Design Tools** (Figma, Sketch, Storybook)

#### Platform Filtering

```typescript
// Automatic platform-based server filtering
const mcpManager = new MCPManager(isDesktop: boolean)
const availableServers = mcpManager.getAvailableServers()
// Returns only compatible servers for current platform
```

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

### 🎯 Current Version: 1.0.0

#### ✅ Completed Features
- ✅ Flutter desktop application with full feature set
- ✅ Multi-color scheme design system
- ✅ 60+ MCP server integrations
- ✅ Real-time chat interface with streaming
- ✅ Agent creation and management
- ✅ OAuth 2.0 authentication flows
- ✅ Vector knowledge base integration
- ✅ Cross-platform deployment pipeline

#### 🚧 In Progress
- 🚧 Mobile application (iOS/Android)
- 🚧 Advanced analytics dashboard
- 🚧 Multi-user collaboration features
- 🚧 Plugin marketplace

#### 🔮 Planned Features
- 🔮 Voice interface integration
- 🔮 Advanced workflow automation
- 🔮 Enterprise SSO integration
- 🔮 Custom model training interface

### 📈 Metrics

- **Lines of Code**: ~50,000 (Dart) + ~25,000 (TypeScript)
- **Test Coverage**: 85%+ target
- **Supported Platforms**: Windows, macOS, Linux
- **MCP Integrations**: 60+ services
- **UI Components**: 50+ design system components

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

**🚀 Ready to build the future of AI agents? [Get started now!](#-quick-start)**

---

*Last updated: 2025-09-18*