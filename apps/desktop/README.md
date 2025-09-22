# Asmbli Desktop

Professional agent builder for developers with local MCP server integration.

## Features

- Full wizard-based agent creation flow
- Local MCP server integration for filesystem, git, and other tools
- Advanced configuration options for power users
- Direct filesystem access for local development
- Git integration for version control
- Desktop application connections
- Template library with community contributions
- Export agents for deployment

## Setup

### Prerequisites

1. Install Flutter SDK (3.24.3 or later)
   - Download from https://flutter.dev/docs/get-started/install
   - Add Flutter to your PATH

2. Enable desktop support
   ```bash
   flutter config --enable-windows-desktop  # For Windows
   flutter config --enable-macos-desktop    # For macOS
   flutter config --enable-linux-desktop    # For Linux
   ```

### Installation

1. Navigate to the desktop app directory
   ```bash
   cd apps/desktop
   ```

2. Install dependencies
   ```bash
   flutter pub get
   ```

3. Run the application
   ```bash
   flutter run -d windows  # For Windows
   flutter run -d macos    # For macOS
   flutter run -d linux    # For Linux
   ```

### Building for Distribution

1. Build release version
   ```bash
   flutter build windows  # For Windows
   flutter build macos    # For macOS
   flutter build linux    # For Linux
   ```

2. The built application will be in:
   - Windows: `build/windows/x64/runner/Release/`
   - macOS: `build/macos/Build/Products/Release/`
   - Linux: `build/linux/x64/release/bundle/`

## Architecture

The desktop application provides:

- **Wizard Flow**: Complete agent configuration wizard from the web version
- **MCP Integration**: Direct integration with Model Context Protocol servers
- **Local Storage**: Agent configurations stored locally with cloud sync option
- **Template System**: Access to community templates and ability to create custom ones
- **Export Options**: Multiple deployment formats for different platforms

## Development

### Project Structure

```
apps/desktop/
├── lib/
│   ├── main.dart              # Application entry point
│   ├── screens/               # UI screens
│   ├── widgets/               # Reusable widgets
│   ├── services/              # API and MCP services
│   ├── models/                # Data models
│   └── utils/                 # Utility functions
├── assets/                    # Images, fonts, etc.
├── test/                      # Unit and widget tests
└── pubspec.yaml              # Dependencies
```

### API Integration

The desktop app connects to the Asmbli platform API for:
- Template library access
- Cloud synchronization
- Community sharing features

### MCP Server Support

Supported MCP servers include:
- Filesystem access
- Git operations
- GitHub integration
- Figma design tools
- Database connections
- Custom server implementations

## Contributing

Please see the main repository README for contribution guidelines.

## License

See LICENSE file in the root directory.