import 'dart:io';
import '../adapters/mcp_adapter_registry.dart';
import '../../models/mcp_server_config.dart';

/// Basic MCP adapter test focusing on core functionality
void main() async {
  print('🧪 Running Basic MCP Adapter Test\n');
  
  bool allTestsPassed = true;
  int testCount = 0;
  int passedCount = 0;
  
  try {
    // Test 1: Registry initialization
    testCount++;
    print('🔍 Test 1: Registry Initialization');
    
    try {
      final registry = MCPAdapterRegistry.instance;
      final protocols = registry.getAvailableProtocols();
      
      if (protocols.isNotEmpty) {
        print('  ✅ Registry initialized with ${protocols.length} protocols');
        print('  📋 Available: ${protocols.join(', ')}');
        passedCount++;
      } else {
        print('  ❌ Registry has no protocols');
        allTestsPassed = false;
      }
    } catch (e) {
      print('  ❌ Registry initialization failed: $e');
      allTestsPassed = false;
    }
    
    // Test 2: Basic adapter creation
    testCount++;
    print('\n🔍 Test 2: Basic Adapter Creation');
    
    try {
      final registry = MCPAdapterRegistry.instance;
      final adapter = registry.getAdapter('http');
      
      if (adapter != null) {
        print('  ✅ HTTP adapter created successfully');
        print('  📋 Protocol: ${adapter.protocol}');
        print('  📋 Features: ${adapter.getSupportedFeatures().join(', ')}');
        
        // Test capabilities
        final capabilities = adapter.getCapabilities();
        if (capabilities.isNotEmpty) {
          print('  ✅ Capabilities available');
        }
        
        // Dispose adapter
        await adapter.dispose();
        print('  ✅ Adapter disposed successfully');
        passedCount++;
      } else {
        print('  ❌ HTTP adapter creation failed');
        allTestsPassed = false;
      }
    } catch (e) {
      print('  ❌ Adapter creation test failed: $e');
      allTestsPassed = false;
    }
    
    // Test 3: Configuration creation and validation
    testCount++;
    print('\n🔍 Test 3: Configuration Management');
    
    try {
      final config = MCPServerConfig(
        id: 'test-1',
        name: 'Test Server',
        url: 'https://example.com',
        protocol: 'http',
        enabled: true,
      );
      
      print('  ✅ Configuration created');
      print('  📋 ID: ${config.id}');
      print('  📋 Protocol: ${config.protocol}');
      print('  📋 URL: ${config.url}');
      
      // Test serialization
      final json = config.toJson();
      final restored = MCPServerConfig.fromJson(json);
      
      if (restored.id == config.id && 
          restored.protocol == config.protocol && 
          restored.url == config.url) {
        print('  ✅ Serialization works correctly');
        passedCount++;
      } else {
        print('  ❌ Serialization failed');
        allTestsPassed = false;
      }
    } catch (e) {
      print('  ❌ Configuration test failed: $e');
      allTestsPassed = false;
    }
    
    // Test 4: Registry statistics
    testCount++;
    print('\n🔍 Test 4: Registry Statistics');
    
    try {
      final registry = MCPAdapterRegistry.instance;
      final stats = registry.getRegistryStats();
      
      if (stats.isNotEmpty) {
        print('  ✅ Registry statistics available');
        print('  📊 Total Adapters: ${stats['totalAdapters']}');
        print('  📊 Protocols: ${stats['protocols']}');
        passedCount++;
      } else {
        print('  ❌ Registry statistics not available');
        allTestsPassed = false;
      }
    } catch (e) {
      print('  ❌ Registry statistics test failed: $e');
      allTestsPassed = false;
    }
    
    // Final summary
    print('\n${'='*60}');
    print('🏁 BASIC MCP ADAPTER TEST RESULTS');
    print('='*60);
    print('Tests Run: $testCount');
    print('Passed: $passedCount');
    print('Failed: ${testCount - passedCount}');
    print('Success Rate: ${((passedCount / testCount) * 100).toStringAsFixed(1)}%');
    
    if (allTestsPassed && passedCount == testCount) {
      print('\n🎉 ALL TESTS PASSED!');
      print('✅ MCP Adapter Framework basic functionality is working');
      print('✅ Registry management is operational');
      print('✅ Configuration system is functional');
      print('✅ Basic adapter lifecycle works');
      
      exit(0);
    } else {
      print('\n❌ SOME TESTS FAILED');
      print('⚠️ Basic MCP adapter functionality needs attention');
      exit(1);
    }
    
  } catch (e, stackTrace) {
    print('💥 Test execution failed: $e');
    print('Stack trace: $stackTrace');
    exit(1);
  }
}