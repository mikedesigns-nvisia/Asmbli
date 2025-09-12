#!/usr/bin/env dart
/// 🚀 Production Build Script for Asmbli
/// 
/// This script handles production builds with magical user experience:
/// - Validates dependencies and environment
/// - Builds for multiple platforms with optimizations  
/// - Creates deployment-ready packages
/// - Provides friendly progress updates

import 'dart:io';
import 'dart:convert';

void main(List<String> arguments) async {
  print('🚀 Starting Asmbli production build...\n');
  
  final builder = ProductionBuilder();
  await builder.build(arguments);
}

class ProductionBuilder {
  static const String version = '1.0.0';
  
  Future<void> build(List<String> arguments) async {
    try {
      // Parse arguments
      final config = _parseArguments(arguments);
      
      // Pre-build validation
      await _validateEnvironment();
      
      // Build for specified platforms
      for (final platform in config['platforms']) {
        await _buildForPlatform(platform, config);
      }
      
      print('\n✅ Production build completed successfully!');
      print('🎉 Your Asmbli app is ready for deployment');
      
    } catch (e, stackTrace) {
      print('\n❌ Build failed: $e');
      if (arguments.contains('--verbose')) {
        print('Stack trace: $stackTrace');
      }
      exit(1);
    }
  }
  
  Map<String, dynamic> _parseArguments(List<String> arguments) {
    final config = <String, dynamic>{
      'platforms': <String>['windows'],
      'release': true,
      'verbose': false,
      'split-debug-info': true,
      'obfuscate': false, // Keep false for better error reporting
    };
    
    for (int i = 0; i < arguments.length; i++) {
      final arg = arguments[i];
      
      switch (arg) {
        case '--platforms':
          if (i + 1 < arguments.length) {
            config['platforms'] = arguments[i + 1].split(',');
            i++;
          }
          break;
        case '--debug':
          config['release'] = false;
          break;
        case '--verbose':
          config['verbose'] = true;
          break;
        case '--obfuscate':
          config['obfuscate'] = true;
          break;
        case '--help':
          _printUsage();
          exit(0);
      }
    }
    
    return config;
  }
  
  void _printUsage() {
    print('''
🚀 Asmbli Production Build Tool

Usage: dart build_production.dart [options]

Options:
  --platforms <list>    Comma-separated platforms (windows,macos,linux)
  --debug              Build in debug mode instead of release
  --verbose            Show detailed build output  
  --obfuscate          Enable code obfuscation (use with caution)
  --help               Show this help message

Examples:
  dart build_production.dart                           # Build for Windows (release)
  dart build_production.dart --platforms windows,macos # Build for Windows and macOS
  dart build_production.dart --debug --verbose         # Debug build with verbose output

The build output will be in the build/ directory.
''');
  }
  
  Future<void> _validateEnvironment() async {
    print('🔍 Validating build environment...');
    
    // Check Flutter installation
    final flutterCheck = await Process.run('flutter', ['--version']);
    if (flutterCheck.exitCode != 0) {
      throw Exception('Flutter not found. Please install Flutter and add it to your PATH.');
    }
    
    // Check Dart version
    final dartCheck = await Process.run('dart', ['--version']);
    if (dartCheck.exitCode != 0) {
      throw Exception('Dart not found. Please install Dart SDK.');
    }
    
    // Validate pubspec.yaml dependencies
    final pubspec = File('pubspec.yaml');
    if (!pubspec.existsSync()) {
      throw Exception('pubspec.yaml not found. Run this script from the app root directory.');
    }
    
    // Check critical dependencies
    final pubspecContent = await pubspec.readAsString();
    final criticalDeps = ['flutter_riverpod', 'go_router', 'hive_flutter', 'sqflite_common_ffi', 'encrypt'];
    
    for (final dep in criticalDeps) {
      if (!pubspecContent.contains(dep)) {
        print('⚠️  Warning: Missing critical dependency: $dep');
      }
    }
    
    print('✅ Environment validation passed');
  }
  
  Future<void> _buildForPlatform(String platform, Map<String, dynamic> config) async {
    print('\n🏗️  Building for $platform...');
    
    final buildArgs = [
      'build',
      platform,
      if (config['release']) '--release' else '--debug',
      '--tree-shake-icons',
      '--target=lib/main_production.dart', // Use production entry point
    ];
    
    if (config['split-debug-info']) {
      buildArgs.addAll(['--split-debug-info=build/debug-info/$platform']);
    }
    
    if (config['obfuscate']) {
      buildArgs.add('--obfuscate');
    }
    
    // Platform-specific optimizations
    switch (platform) {
      case 'windows':
        buildArgs.addAll([
          '--target-platform=windows-x64',
        ]);
        break;
      case 'macos':
        buildArgs.addAll([
          '--target-platform=darwin-x64',
        ]);
        break;
      case 'linux':
        buildArgs.addAll([
          '--target-platform=linux-x64',
        ]);
        break;
    }
    
    print('   Command: flutter ${buildArgs.join(' ')}');
    
    final process = await Process.start('flutter', buildArgs);
    
    // Stream output for user feedback
    process.stdout.transform(utf8.decoder).listen((data) {
      if (config['verbose']) {
        stdout.write(data);
      } else {
        // Show only important messages
        final lines = data.split('\n');
        for (final line in lines) {
          if (line.contains('Building') || 
              line.contains('Built') ||
              line.contains('Error') ||
              line.contains('Warning') ||
              line.startsWith('✓') ||
              line.startsWith('Running')) {
            print('   $line');
          }
        }
      }
    });
    
    process.stderr.transform(utf8.decoder).listen((data) {
      stderr.write(data);
    });
    
    final exitCode = await process.exitCode;
    
    if (exitCode == 0) {
      print('✅ $platform build completed successfully');
      await _postBuildOptimization(platform, config);
    } else {
      throw Exception('$platform build failed with exit code $exitCode');
    }
  }
  
  Future<void> _postBuildOptimization(String platform, Map<String, dynamic> config) async {
    print('   🔧 Post-build optimization...');
    
    try {
      // Create deployment directory
      final deployDir = Directory('deploy/$platform');
      if (!deployDir.existsSync()) {
        deployDir.createSync(recursive: true);
      }
      
      // Copy build output to deployment directory
      final buildOutputPath = _getBuildOutputPath(platform);
      final buildOutput = Directory(buildOutputPath);
      
      if (buildOutput.existsSync()) {
        await _copyDirectory(buildOutput, deployDir);
        print('   📦 Build output copied to deploy/$platform/');
        
        // Create version file
        final versionFile = File('deploy/$platform/VERSION');
        await versionFile.writeAsString('''
Asmbli Desktop v$version
Built: ${DateTime.now().toIso8601String()}
Platform: $platform
Mode: ${config['release'] ? 'release' : 'debug'}
''');
        
        // Create deployment README
        await _createDeploymentReadme(platform);
        
      } else {
        print('   ⚠️  Build output directory not found: $buildOutputPath');
      }
      
    } catch (e) {
      print('   ⚠️  Post-build optimization failed: $e');
      // Don't fail the entire build for post-processing issues
    }
  }
  
  String _getBuildOutputPath(String platform) {
    switch (platform) {
      case 'windows':
        return 'build/windows/runner/Release';
      case 'macos':
        return 'build/macos/Build/Products/Release';
      case 'linux':
        return 'build/linux/x64/release/bundle';
      default:
        return 'build/$platform';
    }
  }
  
  Future<void> _copyDirectory(Directory source, Directory destination) async {
    await for (final entity in source.list(recursive: false)) {
      if (entity is Directory) {
        final newDirectory = Directory('${destination.path}/${entity.uri.pathSegments.last}');
        await newDirectory.create();
        await _copyDirectory(entity, newDirectory);
      } else if (entity is File) {
        final newFile = File('${destination.path}/${entity.uri.pathSegments.last}');
        await entity.copy(newFile.path);
      }
    }
  }
  
  Future<void> _createDeploymentReadme(String platform) async {
    final readme = File('deploy/$platform/README.md');
    final content = '''
# Asmbli Desktop v$version - $platform

## 🚀 Quick Start

1. **Run the Application**
   ${_getRunInstructions(platform)}

2. **System Requirements**
   ${_getSystemRequirements(platform)}

3. **First Time Setup**
   - Launch the application
   - Follow the onboarding wizard
   - Add your AI API keys in Settings
   - Start building amazing AI agents!

## 📋 What's Included

- Main application executable
- Required runtime libraries
- Configuration files
- Version information

## 💡 Features

✨ **One-Click Agent Creation** - Build AI agents without coding
🔒 **Secure & Private** - Your data stays on your device  
🎨 **Beautiful Interface** - Designed for productivity and joy
🔄 **Smart Retry Logic** - Handles errors gracefully
📊 **Knowledge Management** - Organize your context and documents
🤖 **MCP Integration** - Connect to powerful AI tools and services

## 🆘 Support

If you encounter any issues:
1. Check the logs in the app's Settings > Advanced
2. Try restarting the application
3. Visit our documentation at [docs.asmbli.com](https://docs.asmbli.com)
4. Contact support: support@asmbli.com

---
Built with ❤️ by the Asmbli team
''';
    
    await readme.writeAsString(content);
  }
  
  String _getRunInstructions(String platform) {
    switch (platform) {
      case 'windows':
        return '''
   - Double-click `agentengine_desktop.exe`
   - Or run from command line: `./agentengine_desktop.exe`''';
      case 'macos':
        return '''
   - Double-click the Asmbli app bundle
   - Or run from Terminal: `open Asmbli.app`''';
      case 'linux':
        return '''
   - Run from terminal: `./agentengine_desktop`
   - Make sure it's executable: `chmod +x agentengine_desktop`''';
      default:
        return 'Follow platform-specific instructions';
    }
  }
  
  String _getSystemRequirements(String platform) {
    switch (platform) {
      case 'windows':
        return '''
   - Windows 10 (64-bit) or later
   - 4GB RAM minimum, 8GB recommended
   - 500MB free disk space''';
      case 'macos':
        return '''
   - macOS 10.15 (Catalina) or later
   - 4GB RAM minimum, 8GB recommended  
   - 500MB free disk space''';
      case 'linux':
        return '''
   - Ubuntu 18.04+ or equivalent Linux distribution
   - 4GB RAM minimum, 8GB recommended
   - 500MB free disk space
   - gtk3-dev libraries''';
      default:
        return 'Check platform documentation';
    }
  }
}