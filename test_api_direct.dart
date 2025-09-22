import 'dart:io';
import 'dart:convert';

/// Simple test to verify GitHub MCP Registry API access
Future<void> main() async {
  print('🧪 Testing GitHub MCP Registry API Direct Access...\n');

  try {
    // Test direct HTTP call to the registry
    final client = HttpClient();

    // Allow insecure connections (for development testing)
    client.badCertificateCallback = (cert, host, port) => true;

    print('📡 Making request to GitHub MCP Registry...');
    final request = await client.getUrl(
      Uri.parse('https://registry.modelcontextprotocol.io/v0/servers?status=active&limit=5')
    );

    request.headers.set('Accept', 'application/json');
    request.headers.set('User-Agent', 'AgentEngine/1.0.0');

    final response = await request.close();

    print('📊 Response status: ${response.statusCode}');

    if (response.statusCode == 200) {
      final responseBody = await response.transform(utf8.decoder).join();
      print('📄 Raw response: ${responseBody.substring(0, responseBody.length > 500 ? 500 : responseBody.length)}...');

      final responseData = json.decode(responseBody);

      // Check if response is a list or an object with servers
      List<dynamic> servers;
      if (responseData is List) {
        servers = responseData;
      } else if (responseData is Map<String, dynamic> && responseData.containsKey('servers')) {
        servers = responseData['servers'] as List<dynamic>;
      } else {
        print('❌ Unexpected response format: ${responseData.runtimeType}');
        print('Response keys: ${responseData is Map ? (responseData as Map).keys.toList() : 'Not a map'}');
        return;
      }

      print('✅ Successfully fetched ${servers.length} servers');
      print('📦 Sample servers:');

      for (int i = 0; i < servers.length && i < 3; i++) {
        final server = servers[i] as Map<String, dynamic>;
        print('   ${i + 1}. ${server['name'] ?? 'Unknown'} - ${server['description'] ?? 'No description'}');

        final packages = server['packages'] as List<dynamic>? ?? [];
        if (packages.isNotEmpty) {
          final firstPackage = packages.first as Map<String, dynamic>;
          print('      Package: ${firstPackage['registry_type'] ?? 'unknown'}:${firstPackage['identifier'] ?? 'unknown'}');
        }
      }

      print('\n✅ GitHub MCP Registry API is accessible and working!');
      print('🎉 Integration should work correctly in the Flutter app');

    } else {
      print('❌ HTTP Error: ${response.statusCode}');
      final responseBody = await response.transform(utf8.decoder).join();
      print('Error details: $responseBody');
    }

    client.close();

  } catch (e) {
    print('❌ Test failed with error: $e');
    exit(1);
  }
}