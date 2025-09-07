import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/mcp_catalog_entry.dart';
import 'mcp_catalog_service.dart';
import 'secure_credentials_service.dart';
import 'mcp_validation_service.dart';
import 'mcp_server_execution_service.dart';

/// Integration test service for MCP catalog functionality
/// This service provides methods to test the end-to-end MCP catalog workflow
class MCPCatalogIntegrationTest {
  final MCPCatalogService _catalogService;
  final SecureCredentialsService _credentialsService;
  final MCPValidationService _validationService;
  final MCPServerExecutionService _executionService;

  MCPCatalogIntegrationTest(
    this._catalogService,
    this._credentialsService,
    this._validationService,
    this._executionService,
  );

  /// Run comprehensive integration test
  Future<MCPIntegrationTestResult> runFullIntegrationTest() async {
    final result = MCPIntegrationTestResult();
    
    print('🧪 Starting MCP Catalog Integration Test...');
    
    try {
      // Test 1: Catalog loading
      await _testCatalogLoading(result);
      
      // Test 2: Agent configuration
      await _testAgentConfiguration(result);
      
      // Test 3: Credential storage
      await _testCredentialStorage(result);
      
      // Test 4: Validation service
      await _testValidationService(result);
      
      // Test 5: Server startup simulation
      await _testServerStartupValidation(result);
      
      result.success = result.errors.isEmpty;
      
    } catch (e) {
      result.errors.add('Integration test failed: $e');
      result.success = false;
    }
    
    _printTestResults(result);
    return result;
  }

  /// Test catalog loading and basic operations
  Future<void> _testCatalogLoading(MCPIntegrationTestResult result) async {
    print('  📚 Testing catalog loading...');
    
    try {
      final catalogEntries = _catalogService.getAllCatalogEntries();
      
      if (catalogEntries.isEmpty) {
        result.errors.add('No catalog entries loaded');
        return;
      }
      
      // Check for expected entries
      final expectedEntries = ['github', 'slack', 'filesystem', 'brave-search'];
      final actualIds = catalogEntries.map((e) => e.id).toList();
      
      for (final expectedId in expectedEntries) {
        if (!actualIds.contains(expectedId)) {
          result.errors.add('Expected catalog entry not found: $expectedId');
        }
      }
      
      // Test entry retrieval
      final githubEntry = _catalogService.getCatalogEntry('github');
      if (githubEntry == null) {
        result.errors.add('GitHub entry not retrievable');
      } else {
        result.successes.add('GitHub catalog entry loaded successfully');
      }
      
      // Test featured entries
      final featuredEntries = _catalogService.getFeaturedEntries();
      if (featuredEntries.isNotEmpty) {
        result.successes.add('Featured entries loaded: ${featuredEntries.length}');
      }
      
    } catch (e) {
      result.errors.add('Catalog loading failed: $e');
    }
  }

  /// Test agent configuration operations
  Future<void> _testAgentConfiguration(MCPIntegrationTestResult result) async {
    print('  🤖 Testing agent configuration...');
    
    const testAgentId = 'test-agent-123';
    
    try {
      // Test initial state
      final initialConfigs = _catalogService.getAgentMCPConfigs(testAgentId);
      if (initialConfigs.isNotEmpty) {
        result.warnings.add('Agent already has MCP configurations');
      }
      
      // Test enabling a server
      final testCredentials = {'GITHUB_PERSONAL_ACCESS_TOKEN': 'test-token-123'};
      await _catalogService.enableServerForAgent(testAgentId, 'github', testCredentials);
      
      // Verify configuration
      final isEnabled = _catalogService.isServerEnabledForAgent(testAgentId, 'github');
      if (isEnabled) {
        result.successes.add('Successfully enabled GitHub server for test agent');
      } else {
        result.errors.add('Failed to enable GitHub server for test agent');
      }
      
      // Test configuration retrieval
      final enabledServers = _catalogService.getEnabledServerIds(testAgentId);
      if (enabledServers.contains('github')) {
        result.successes.add('Enabled servers list is correct');
      } else {
        result.errors.add('Enabled servers list is incorrect');
      }
      
      // Clean up
      await _catalogService.removeServerFromAgent(testAgentId, 'github');
      
    } catch (e) {
      result.errors.add('Agent configuration test failed: $e');
    }
  }

  /// Test credential storage and retrieval
  Future<void> _testCredentialStorage(MCPIntegrationTestResult result) async {
    print('  🔐 Testing credential storage...');
    
    try {
      await _credentialsService.initialize();
      
      // Test storing and retrieving a credential
      const testKey = 'test-credential';
      const testValue = 'test-secret-value-123';
      
      await _credentialsService.storeCredential(testKey, testValue);
      
      final retrievedValue = await _credentialsService.getCredential(testKey);
      
      if (retrievedValue == testValue) {
        result.successes.add('Credential storage and retrieval working');
      } else {
        result.errors.add('Credential retrieval failed - got: $retrievedValue');
      }
      
      // Test credential validation
      final isValid = _credentialsService.validateCredential('GITHUB_PERSONAL_ACCESS_TOKEN', 'ghp_test123456789');
      if (isValid) {
        result.successes.add('Credential validation working');
      } else {
        result.warnings.add('Credential validation may be too strict');
      }
      
      // Clean up
      await _credentialsService.removeCredential(testKey);
      
    } catch (e) {
      result.errors.add('Credential storage test failed: $e');
    }
  }

  /// Test validation service
  Future<void> _testValidationService(MCPIntegrationTestResult result) async {
    print('  ✅ Testing validation service...');
    
    const testAgentId = 'test-validation-agent';
    
    try {
      // Set up test configuration
      await _catalogService.enableServerForAgent(
        testAgentId, 
        'filesystem', 
        {}, // No auth required for filesystem
      );
      
      // Test validation
      final validationResult = await _validationService.validateAgentMCPConfiguration(testAgentId);
      
      if (validationResult.serverValidations.containsKey('filesystem')) {
        result.successes.add('Validation service executed successfully');
        
        final fsValidation = validationResult.serverValidations['filesystem']!;
        if (fsValidation.isValid) {
          result.successes.add('Filesystem server validation passed');
        } else {
          result.warnings.add('Filesystem server validation failed: ${fsValidation.errors.map((e) => e.message).join(", ")}');
        }
      } else {
        result.errors.add('Validation service did not validate configured server');
      }
      
      // Test system requirements
      final requirements = _validationService.getSystemRequirements('github');
      if (requirements.isNotEmpty) {
        result.successes.add('System requirements check working');
      }
      
      // Clean up
      await _catalogService.removeServerFromAgent(testAgentId, 'filesystem');
      
    } catch (e) {
      result.errors.add('Validation service test failed: $e');
    }
  }

  /// Test server startup validation (without actual startup)
  Future<void> _testServerStartupValidation(MCPIntegrationTestResult result) async {
    print('  🚀 Testing server startup validation...');
    
    const testAgentId = 'test-startup-agent';
    
    try {
      // Configure a server that should validate successfully
      await _catalogService.enableServerForAgent(
        testAgentId,
        'filesystem',
        {},
      );
      
      // Test startup validation
      final validationResults = await _executionService.validateAgentMCPServers(testAgentId);
      
      if (validationResults.containsKey('filesystem')) {
        final fsResult = validationResults['filesystem']!;
        if (fsResult == 'OK') {
          result.successes.add('Server startup validation passed');
        } else {
          result.warnings.add('Server startup validation issue: $fsResult');
        }
      } else {
        result.errors.add('Server startup validation did not run');
      }
      
      // Clean up
      await _catalogService.removeServerFromAgent(testAgentId, 'filesystem');
      
    } catch (e) {
      result.errors.add('Server startup validation test failed: $e');
    }
  }

  /// Print test results summary
  void _printTestResults(MCPIntegrationTestResult result) {
    print('\n📊 MCP Catalog Integration Test Results:');
    print('  Overall Success: ${result.success ? "✅ PASS" : "❌ FAIL"}');
    
    if (result.successes.isNotEmpty) {
      print('  ✅ Successes (${result.successes.length}):');
      for (final success in result.successes) {
        print('    • $success');
      }
    }
    
    if (result.warnings.isNotEmpty) {
      print('  ⚠️ Warnings (${result.warnings.length}):');
      for (final warning in result.warnings) {
        print('    • $warning');
      }
    }
    
    if (result.errors.isNotEmpty) {
      print('  ❌ Errors (${result.errors.length}):');
      for (final error in result.errors) {
        print('    • $error');
      }
    }
    
    print('');
  }

  /// Quick smoke test for essential functionality
  Future<bool> runSmokeTest() async {
    print('🔥 Running MCP Catalog Smoke Test...');
    
    try {
      // Test 1: Can load catalog
      final entries = _catalogService.getAllCatalogEntries();
      if (entries.isEmpty) {
        print('❌ Smoke test failed: No catalog entries');
        return false;
      }
      
      // Test 2: Can initialize credentials service
      await _credentialsService.initialize();
      
      // Test 3: Can store and retrieve a test credential
      await _credentialsService.storeCredential('smoke-test', 'test-value');
      final retrieved = await _credentialsService.getCredential('smoke-test');
      if (retrieved != 'test-value') {
        print('❌ Smoke test failed: Credential storage');
        return false;
      }
      await _credentialsService.removeCredential('smoke-test');
      
      print('✅ Smoke test passed: Core functionality working');
      return true;
      
    } catch (e) {
      print('❌ Smoke test failed with exception: $e');
      return false;
    }
  }
}

/// Test result data structure
class MCPIntegrationTestResult {
  bool success = false;
  final List<String> successes = [];
  final List<String> warnings = [];
  final List<String> errors = [];

  int get totalTests => successes.length + warnings.length + errors.length;
  double get successRate => totalTests > 0 ? successes.length / totalTests : 0.0;
}

// ==================== Riverpod Provider ====================

final mcpIntegrationTestProvider = Provider<MCPCatalogIntegrationTest>((ref) {
  final catalogService = ref.read(mcpCatalogServiceProvider);
  final credentialsService = ref.read(secureCredentialsServiceProvider);
  final validationService = ref.read(mcpValidationServiceProvider);
  final executionService = ref.read(mcpServerExecutionServiceProvider);
  
  return MCPCatalogIntegrationTest(
    catalogService,
    credentialsService,
    validationService,
    executionService,
  );
});

/// Provider for running integration test
final mcpIntegrationTestResultProvider = FutureProvider<MCPIntegrationTestResult>((ref) async {
  final testService = ref.read(mcpIntegrationTestProvider);
  return await testService.runFullIntegrationTest();
});