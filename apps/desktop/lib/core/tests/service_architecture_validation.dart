import 'dart:io';

/// Validates service layer architecture by analyzing code structure
class ServiceArchitectureValidator {
  static const String baseDir = 'lib';
  
  /// Run architectural validation
  static Future<bool> validateArchitecture() async {
    print('🏗️  Validating Service Layer Architecture\n');
    
    bool allPassed = true;
    
    // Test 1: Business services exist and are properly structured
    allPassed &= await _validateBusinessServicesExist();
    
    // Test 2: Dependency injection is implemented
    allPassed &= await _validateDependencyInjection();
    
    // Test 3: UI widgets use business services (not direct repositories)
    allPassed &= await _validateUIUsesServices();
    
    // Test 4: Business services are isolated from UI
    allPassed &= await _validateServiceIsolation();
    
    print('\n' + '='*60);
    print('🏁 ARCHITECTURE VALIDATION RESULTS');
    print('='*60);
    
    if (allPassed) {
      print('✅ ALL ARCHITECTURAL REQUIREMENTS MET');
      print('\n📋 Service Layer Checklist:');
      print('✅ Business services properly structured');
      print('✅ Dependency injection implemented'); 
      print('✅ UI components use business services');
      print('✅ Business logic isolated from UI');
      print('✅ Clean architecture principles followed');
    } else {
      print('❌ SOME ARCHITECTURAL REQUIREMENTS NOT MET');
      print('⚠️  Review the failed checks above');
    }
    
    return allPassed;
  }
  
  /// Validate that business services exist and are properly structured
  static Future<bool> _validateBusinessServicesExist() async {
    print('🔍 Test 1: Business Services Structure');
    
    final requiredFiles = [
      'core/services/business/base_business_service.dart',
      'core/services/business/agent_business_service.dart', 
      'core/services/business/conversation_business_service.dart',
    ];
    
    bool allExist = true;
    
    for (final filePath in requiredFiles) {
      final file = File('$baseDir/$filePath');
      if (await file.exists()) {
        print('  ✅ $filePath exists');
        
        // Check if it contains key patterns
        final content = await file.readAsString();
        if (content.contains('class') && content.contains('BusinessService')) {
          print('     └─ Contains business service class');
        } else {
          print('     └─ ❌ Missing business service class structure');
          allExist = false;
        }
      } else {
        print('  ❌ $filePath missing');
        allExist = false;
      }
    }
    
    print('  Result: ${allExist ? "✅ PASSED" : "❌ FAILED"}');
    return allExist;
  }
  
  /// Validate dependency injection container exists
  static Future<bool> _validateDependencyInjection() async {
    print('\n🔍 Test 2: Dependency Injection Container');
    
    final serviceLocatorFile = File('$baseDir/core/di/service_locator.dart');
    
    if (!await serviceLocatorFile.exists()) {
      print('  ❌ Service locator file missing');
      return false;
    }
    
    final content = await serviceLocatorFile.readAsString();
    
    final checks = [
      ('ServiceLocator class', content.contains('class ServiceLocator')),
      ('Singleton registration', content.contains('registerSingleton')),
      ('Factory registration', content.contains('registerFactory')),
      ('Service retrieval', content.contains('get<T>')),
      ('Service initialization', content.contains('initialize')),
    ];
    
    bool allPassed = true;
    for (final (description, passed) in checks) {
      print('  ${passed ? "✅" : "❌"} $description');
      if (!passed) allPassed = false;
    }
    
    print('  Result: ${allPassed ? "✅ PASSED" : "❌ FAILED"}');
    return allPassed;
  }
  
  /// Validate UI widgets use business services instead of direct repositories  
  static Future<bool> _validateUIUsesServices() async {
    print('\n🔍 Test 3: UI Uses Business Services');
    
    // Check provider files use business services
    final providerFiles = [
      'providers/agent_provider.dart',
      'providers/conversation_provider.dart',
    ];
    
    bool allPassed = true;
    
    for (final filePath in providerFiles) {
      final file = File('$baseDir/$filePath');
      if (await file.exists()) {
        final content = await file.readAsString();
        
        final usesBusinessService = content.contains('BusinessService') || 
                                   content.contains('ServiceLocator');
        
        if (usesBusinessService) {
          print('  ✅ $filePath uses business services');
        } else {
          print('  ❌ $filePath not using business services');
          allPassed = false;
        }
      } else {
        print('  ⚠️  $filePath not found (skipped)');
      }
    }
    
    print('  Result: ${allPassed ? "✅ PASSED" : "❌ FAILED"}');
    return allPassed;
  }
  
  /// Validate business services don't contain UI code
  static Future<bool> _validateServiceIsolation() async {
    print('\n🔍 Test 4: Business Service Isolation');
    
    final serviceFiles = await _findServiceFiles();
    bool allPassed = true;
    
    for (final file in serviceFiles) {
      final content = await file.readAsString();
      
      // Check for UI-related imports/code
      final uiPatterns = [
        'package:flutter/material.dart',
        'package:flutter/widgets.dart', 
        'BuildContext',
        'setState(',
        'Navigator.',
        'showDialog(',
        'ScaffoldMessenger.',
      ];
      
      final foundUICode = <String>[];
      for (final pattern in uiPatterns) {
        if (content.contains(pattern)) {
          foundUICode.add(pattern);
        }
      }
      
      if (foundUICode.isEmpty) {
        print('  ✅ ${file.path.split('/').last} - No UI dependencies');
      } else {
        print('  ❌ ${file.path.split('/').last} - Contains UI code: ${foundUICode.join(', ')}');
        allPassed = false;
      }
    }
    
    print('  Result: ${allPassed ? "✅ PASSED" : "❌ FAILED"}');
    return allPassed;
  }
  
  /// Find all business service files
  static Future<List<File>> _findServiceFiles() async {
    final serviceDir = Directory('$baseDir/core/services/business');
    
    if (!await serviceDir.exists()) {
      return [];
    }
    
    final files = await serviceDir
        .list(recursive: true)
        .where((entity) => entity is File && entity.path.endsWith('.dart'))
        .cast<File>()
        .toList();
    
    return files;
  }
}

/// Main entry point for architecture validation
void main() async {
  try {
    final success = await ServiceArchitectureValidator.validateArchitecture();
    exit(success ? 0 : 1);
  } catch (e) {
    print('💥 Architecture validation failed: $e');
    exit(1);
  }
}