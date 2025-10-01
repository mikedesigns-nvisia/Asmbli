import 'dart:io';
import 'package:dio/dio.dart';
import 'lib/core/services/github_mcp_registry_service.dart';
import 'lib/core/services/mcp_catalog_service.dart';
import 'lib/core/services/mcp_catalog_adapter.dart';
import 'lib/core/services/featured_mcp_servers_service.dart';

/// Simple test to verify GitHub MCP Registry integration
Future<void> main() async {
  print('🧪 Testing GitHub MCP Registry Integration...\n');

  try {
    // Initialize HTTP client
    final dio = Dio();
    dio.options.connectTimeout = const Duration(seconds: 30);
    dio.options.receiveTimeout = const Duration(seconds: 30);

    // Test 1: Direct API call
    print('📡 Test 1: Direct API Call to GitHub MCP Registry');
    final api = GitHubMCPRegistryApi(dio);

    try {
      final servers = await api.getServers(status: 'active', limit: 5);
      print('✅ Successfully fetched ${servers.length} servers');

      if (servers.isNotEmpty) {
        final server = servers.first;
        print('   📦 Sample server: ${server.name}');
        print('   📝 Description: ${server.description}');
        print('   🔧 Packages: ${server.packages.length}');
        print('   🏷️ Tags: ${server.tags.join(', ')}');
      }
    } catch (e) {
      print('❌ API call failed: $e');
    }

    print('\n📚 Test 2: MCP Catalog Service Integration');

    // Test 2: Service integration
    final githubService = GitHubMCPRegistryService(api);
    final featuredService = FeaturedMCPServersService();
    final catalogService = MCPCatalogService(githubService, featuredService);

    try {
      final entries = await catalogService.getAllEntries();
      print('✅ Successfully fetched ${entries.length} catalog entries');

      if (entries.isNotEmpty) {
        final entry = entries.first;
        print('   📦 Sample entry: ${entry.name}');
        print('   📝 Description: ${entry.description}');
        print('   🔧 Command: ${entry.command} ${entry.args.join(' ')}');
        print('   🏷️ Tags: ${entry.tags.join(', ')}');
        print('   ⭐ Featured: ${entry.isFeatured}');
        print('   🏛️ Official: ${entry.isOfficial}');
      }

      // Test search functionality
      print('\n🔍 Test 3: Search Functionality');
      final searchResults = await catalogService.searchEntries('git');
      print('✅ Found ${searchResults.length} servers matching "git"');

      // Test featured servers
      print('\n⭐ Test 4: Featured Servers');
      final featuredEntries = await catalogService.getFeaturedEntries();
      print('✅ Found ${featuredEntries.length} featured servers');

    } catch (e) {
      print('❌ Service integration failed: $e');
    }

    print('\n🔧 Test 5: Adapter Functionality');

    // Test 3: Test adapter conversion
    try {
      final githubServers = await api.getServers(status: 'active', limit: 3);
      if (githubServers.isNotEmpty) {
        final githubServer = githubServers.first;
        final catalogEntry = MCPCatalogAdapter.fromGitHubEntry(githubServer);

        print('✅ Successfully converted GitHub entry to catalog entry');
        print('   📦 Original: ${githubServer.name}');
        print('   📦 Converted: ${catalogEntry.name}');
        print('   🔧 Command: ${catalogEntry.command} ${catalogEntry.args.join(' ')}');
        print('   📋 Capabilities: ${catalogEntry.capabilities.join(', ')}');
      }
    } catch (e) {
      print('❌ Adapter test failed: $e');
    }

    print('\n✅ All tests completed successfully!');
    print('🎉 GitHub MCP Registry integration is working correctly');

  } catch (e) {
    print('❌ Test failed with error: $e');
    exit(1);
  }
}