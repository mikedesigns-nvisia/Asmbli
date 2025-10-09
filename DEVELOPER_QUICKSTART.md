# Developer Quick Start

Get up and running with Asmbli in 10 minutes.

## Prerequisites

- Flutter 3.0+ ([install guide](https://docs.flutter.dev/get-started/install))
- Git
- VS Code or Android Studio with Flutter plugins

## Setup (5 minutes)

```bash
# 1. Clone the repo
git clone https://github.com/your-org/Asmbli.git
cd Asmbli

# 2. Install dependencies
cd apps/desktop
flutter pub get

# 3. Run the app
flutter run
```

That's it! The app should launch on your desktop.

## First Steps in the App

1. **Complete onboarding** - Quick setup wizard
2. **Add an API key** - Settings → API Configuration → Add Claude/OpenAI key
3. **Start chatting** - Click "Start Chat" from home screen
4. **Create an agent** - Click "Build Agent" and use a template

## Understanding the Codebase

### Key Files to Start
- `lib/main.dart` - App entry point
- `lib/core/constants/routes.dart` - All app routes
- `CLAUDE.md` - Detailed codebase guide (READ THIS!)

### Project Structure
```
apps/desktop/lib/
├── features/     # Feature modules (start here)
│   ├── chat/     # Chat implementation
│   └── agents/   # Agent management
├── core/         # Shared infrastructure
└── providers/    # State management
```

### Quick Tips

1. **Use the design system**
   ```dart
   // ✅ Good
   final colors = ThemeColors(context);
   AsmblButton.primary(text: "Save", onPressed: () {})
   
   // ❌ Bad  
   ElevatedButton(...)
   Container(color: Colors.blue)
   ```

2. **Don't create new services**
   - We have 110+ already
   - Find and extend existing ones

3. **Follow existing patterns**
   - Look at similar features
   - Copy their structure

## Common Tasks

### Add a new screen
1. Create in `features/[feature]/presentation/screens/`
2. Add route in `routes.dart`
3. Use `AppNavigationBar` and standard layout

### Modify chat behavior
- See `features/chat/presentation/screens/chat_screen.dart`
- Chat logic in `ConversationService`

### Add new LLM provider
- Implement `LLMProvider` interface
- Add to `UnifiedLLMService`
- Create config UI in settings

### Run tests
```bash
flutter test
flutter analyze  # Check code quality
```

## Debugging

### Common Issues

**App won't start**
- Check Flutter doctor: `flutter doctor`
- Clean and rebuild: `flutter clean && flutter pub get`

**API calls failing**
- Check API key configuration
- Look at network logs in console

**State not updating**
- Check Riverpod providers
- Use `ref.invalidate()` to force refresh

### Useful Commands
```bash
# Hot reload while running
r

# Hot restart 
R

# See all logs
flutter logs

# Performance profiling
flutter run --profile
```

## Architecture TL;DR

- **UI Layer**: Flutter widgets + Riverpod
- **Service Layer**: Business logic (via ServiceLocator)
- **Storage**: SQLite + Hive
- **External**: LLM APIs + MCP servers

Data flows: UI → Provider → Service → Storage/API

## Getting Help

1. Read `CLAUDE.md` for detailed guidance
2. Check existing code for patterns
3. Open an issue on GitHub
4. Join Discord community

## What to Work On

High priority:
- Add tests (we're at 9% coverage)
- Fix bugs in GitHub issues
- Improve documentation

Good first issues:
- UI polish
- Error message improvements
- Adding tests
- Small feature enhancements

## Next Steps

1. Pick an issue from GitHub
2. Create a branch
3. Make changes following patterns
4. Submit PR with description
5. Wait for review

Welcome to Asmbli! 🚀