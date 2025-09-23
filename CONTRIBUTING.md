# Contributing to Asmbli

**⚠️ Warning: This is experimental alpha software. Contributions are welcome, but expect bugs, broken features, and frequent changes.**

First off, thank you for considering contributing to this experimental project! Please understand that this is early-stage software with many rough edges.

## Code of Conduct

This project and everyone participating in it is governed by the [Asmbli Code of Conduct](CODE_OF_CONDUCT.md). By participating, you are expected to uphold this code. Please report unacceptable behavior to the project maintainers.

## How Can I Contribute?

### Reporting Bugs

Before creating bug reports, please check existing issues as you might find out that you don't need to create one. When you are creating a bug report, please include as many details as possible:

* Use a clear and descriptive title
* Describe the exact steps to reproduce the problem
* Provide specific examples to demonstrate the steps
* Describe the behavior you observed and explain why it's a problem
* Explain which behavior you expected to see instead
* Include screenshots if relevant
* Include your environment details (OS, Flutter version, etc.)

### Suggesting Enhancements

Enhancement suggestions are tracked as GitHub issues. When creating an enhancement suggestion, please include:

* Use a clear and descriptive title
* Provide a step-by-step description of the suggested enhancement
* Provide specific examples to demonstrate the steps
* Describe the current behavior and explain which behavior you expected to see instead
* Explain why this enhancement would be useful to most Asmbli users

### Your First Code Contribution

Unsure where to begin contributing? You can start by looking through these issues:

* Issues labeled `good first issue` - issues which should only require a few lines of code
* Issues labeled `help wanted` - issues which should be a bit more involved than beginner issues

### Pull Requests

1. Fork the repo and create your branch from `main`
2. If you've added code that should be tested, add tests
3. If you've changed APIs, update the documentation
4. Ensure the test suite passes
5. Make sure your code follows the existing style
6. Issue that pull request!

## Development Setup

### Prerequisites

* Flutter SDK (>=3.0.0)
* Dart SDK (>=3.0.0)
* Node.js (>=18.0.0) for build tools
* Git

### Setting Up Your Development Environment

1. **Clone your fork:**
   ```bash
   git clone https://github.com/your-username/Asmbli.git
   cd Asmbli
   ```

2. **Install dependencies:**
   ```bash
   # Flutter dependencies
   cd apps/desktop
   flutter pub get

   # Core package dependencies
   cd ../../packages/agent_engine_core
   flutter pub get

   # Node dependencies (optional, for build tools)
   cd ../..
   npm install
   ```

3. **Set up environment variables:**
   ```bash
   cp .env.example .env
   # Edit .env with your API keys
   ```

4. **Run the application:**
   ```bash
   cd apps/desktop
   flutter run
   ```

### Running Tests

```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/models/agent_test.dart

# Run with coverage
flutter test --coverage
```

### Code Style

#### Flutter/Dart Guidelines

* Follow the [Effective Dart](https://dart.dev/guides/language/effective-dart) guidelines
* Use the design system components from `lib/core/design_system/`
* Always use `ThemeColors(context)` for colors - never hardcode colors
* Follow existing naming conventions
* Add dartdoc comments for public APIs

#### Important Design System Rules

```dart
// ✅ DO: Use design system components
import 'core/design_system/design_system.dart';

final colors = ThemeColors(context);
AsmblButton.primary(text: "Save", onPressed: () {})

// ❌ DON'T: Use hardcoded colors or bypass design system
Container(color: Color(0xFF123456)) // Wrong!
ElevatedButton(...) // Use AsmblButton instead
```

#### Git Commit Messages

* Use the present tense ("Add feature" not "Added feature")
* Use the imperative mood ("Move cursor to..." not "Moves cursor to...")
* Limit the first line to 72 characters or less
* Reference issues and pull requests liberally after the first line
* Consider using [Conventional Commits](https://www.conventionalcommits.org/):
  * `feat:` New feature
  * `fix:` Bug fix
  * `docs:` Documentation changes
  * `style:` Code style changes (formatting, etc.)
  * `refactor:` Code refactoring
  * `test:` Test additions or changes
  * `chore:` Maintenance tasks

### Project Structure

```
Asmbli/
├── apps/
│   └── desktop/              # Flutter desktop application
│       ├── lib/
│       │   ├── core/        # Core services and utilities
│       │   │   ├── design_system/  # UI components (ALWAYS USE)
│       │   │   └── services/       # Business logic
│       │   └── features/    # Feature modules
│       └── test/           # Tests
├── packages/
│   └── agent_engine_core/   # Shared core package
└── docs/                    # Documentation
```

## Testing Guidelines

* Write tests for all new features
* Maintain or improve code coverage
* Test edge cases and error conditions
* Use descriptive test names
* Follow the AAA pattern (Arrange, Act, Assert)

Example test:
```dart
testWidgets('should display agent name correctly', (tester) async {
  // Arrange
  final agent = Agent(name: 'Test Agent');

  // Act
  await tester.pumpWidget(AgentCard(agent: agent));

  // Assert
  expect(find.text('Test Agent'), findsOneWidget);
});
```

## Documentation

* Update README.md if needed
* Add dartdoc comments for public APIs
* Update CLAUDE.md for development guidelines
* Include examples for complex features

## Review Process

1. A maintainer will review your PR
2. They may request changes or ask questions
3. Once approved, your PR will be merged
4. Your contribution will be part of the next release!

## Community

* Join our [Discord server](https://discord.gg/asmbli) (coming soon)
* Follow us on [Twitter](https://twitter.com/asmbli) (coming soon)
* Read our [blog](https://blog.asmbli.dev) (coming soon)

## Recognition

Contributors will be recognized in:
* The project README
* Release notes
* Our website (coming soon)

## Questions?

Feel free to open an issue with the `question` label or reach out to the maintainers.

Thank you for contributing to Asmbli! 🚀