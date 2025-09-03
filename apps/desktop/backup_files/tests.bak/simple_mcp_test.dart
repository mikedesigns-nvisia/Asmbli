import 'dart:io';
import '../adapters/mcp_adapter_registry.dart';
import '../protocol/mcp_protocol_negotiator.dart';
import '../../models/mcp_server_config.dart';

/// Simple MCP adapter test without external dependencies
void main() async {
  print('🧪 Running Simple MCP Adapter Test\n');
  
  bool allTestsPassed = true;
  
  try {
    // Test 1: Registry initialization
    print('🔍 Test 1: Registry Initialization');
    final registry = MCPAdapterRegistry.instance;
    final protocols = registry.getAvailableProtocols();
    
    if (protocols.isNotEmpty) {
      print('  ✅ Registry initialized with ${protocols.length} protocols: ${protocols.join(', ')}');
    } else {
      print('  ❌ Registry failed to initialize');
      allTestsPassed = false;
    }
    
    // Test 2: Adapter creation
    print('\n🔍 Test 2: Adapter Creation');
    final adapters = ['websocket', 'http', 'sse'];
    int adapterCount = 0;
    
    for (final protocol in adapters) {
      final adapter = registry.getAdapter(protocol);
      if (adapter != null) {
        print('  ✅ $protocol adapter created');
        adapterCount++;
        
        // Test adapter properties
        if (adapter.protocol == protocol) {
          print('    └─ Protocol matches: ${adapter.protocol}');
        } else {
          print('    └─ ❌ Protocol mismatch: expected $protocol, got ${adapter.protocol}');
          allTestsPassed = false;
        }
        
        // Test supported features
        final features = adapter.getSupportedFeatures();
        if (features.isNotEmpty) {
          print('    └─ Features: ${features.join(', ')}');
        } else {
          print('    └─ ⚠️ No features reported');
        }
        
        // Dispose adapter
        await adapter.dispose();
      } else {
        print('  ❌ $protocol adapter creation failed');
        allTestsPassed = false;
      }
    }
    
    // Test 3: Configuration validation
    print('\n🔍 Test 3: Configuration Validation');
    final configs = [
      MCPServerConfig(
        id: 'test-ws',
        name: 'Test WebSocket',
        url: 'wss://echo.websocket.org',
        protocol: 'websocket',
        enabled: true,
      ),
      MCPServerConfig(
        id: 'test-http',
        name: 'Test HTTP',
        url: 'https://httpbin.org',
        protocol: 'http',
        enabled: true,
      ),
      MCPServerConfig(
        id: 'test-sse',
        name: 'Test SSE',
        url: 'https://httpbin.org/stream',
        protocol: 'sse',
        enabled: true,
      ),
    ];
    
    int validConfigs = 0;
    for (final config in configs) {
      final adapter = registry.getAdapter(config.protocol);
      if (adapter != null && adapter.validateConfig(config)) {
        print('  ✅ ${config.protocol} config validation passed');
        validConfigs++;
      } else {
        print('  ❌ ${config.protocol} config validation failed');
        allTestsPassed = false;
      }
    }
    
    // Test 4: Protocol negotiation setup
    print('\n🔍 Test 4: Protocol Negotiation');
    final negotiator = MCPProtocolNegotiator();
    
    // Test strategy creation
    final testConfig = configs.first;
    final strategy = negotiator.createStrategy(testConfig);
    
    if (strategy.preferredProtocol == testConfig.protocol) {
      print('  ✅ Negotiation strategy created');
      print('    └─ Preferred: ${strategy.preferredProtocol}');
      print('    └─ Fallbacks: ${strategy.fallbackProtocols.join(', ')}');
      print('    └─ Timeout: ${strategy.connectionTimeout.inSeconds}s');
    } else {
      print('  ❌ Negotiation strategy creation failed');
      allTestsPassed = false;
    }
    
    // Test 5: Registry statistics
    print('\n🔍 Test 5: Registry Statistics');
    final stats = registry.getRegistryStats();
    
    if (stats.isNotEmpty) {
      print('  ✅ Registry stats available');
      print('    └─ Total adapters: ${stats['totalAdapters']}');
      print('    └─ Protocols: ${stats['protocols']}');
    } else {
      print('  ❌ Registry stats unavailable');
      allTestsPassed = false;
    }
    
    // Test 6: Configuration serialization
    print('\n🔍 Test 6: Configuration Serialization');
    final config = configs.first;
    
    try {
      final json = config.toJson();
      final restored = MCPServerConfig.fromJson(json);
      
      if (restored.id == config.id && 
          restored.protocol == config.protocol && 
          restored.url == config.url) {
        print('  ✅ Configuration serialization works');
      } else {
        print('  ❌ Configuration serialization failed');
        allTestsPassed = false;
      }
    } catch (e) {
      print('  ❌ Configuration serialization error: $e');
      allTestsPassed = false;
    }
    
    // Final summary
    print('\n${'='*60}');
    print('🏁 SIMPLE MCP TEST RESULTS');
    print('='*60);
    
    if (allTestsPassed) {
      print('🎉 ALL TESTS PASSED!');
      print('✅ MCP Adapter Framework is functional');
      print('✅ Registry properly manages adapters');
      print('✅ Protocol negotiation is working');
      print('✅ Configuration validation works');
      print('✅ Serialization mechanisms work');
      
      print('\n📋 Test Checklist:');
      print('✅ Registry initialization');
      print('✅ Adapter creation (WebSocket, HTTP, SSE)');
      print('✅ Configuration validation');
      print('✅ Protocol negotiation setup');
      print('✅ Registry statistics');
      print('✅ Configuration serialization');
      
      exit(0);
    } else {
      print('❌ SOME TESTS FAILED');
      print('⚠️ MCP adapter framework needs attention');
      exit(1);
    }
    
  } catch (e, stackTrace) {
    print('💥 Test execution failed: $e');
    print('Stack trace: $stackTrace');
    exit(1);
  }
}