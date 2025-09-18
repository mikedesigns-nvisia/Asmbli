import 'dart:io';

/// Simple test to run the app without the new features to verify base functionality
void main() async {
  print('🧪 Testing Simple App Run...');
  
  try {
    print('\n📦 Checking if we can run the app without new features...');
    
    // Let's try to run flutter analyze first
    final analyzeResult = await Process.run(
      'flutter',
      ['analyze', '--no-fatal-infos'],
      workingDirectory: 'apps/desktop',
      runInShell: true,
    ).timeout(const Duration(minutes: 2));
    
    print('Flutter analyze result:');
    print('Exit code: ${analyzeResult.exitCode}');
    if (analyzeResult.stdout.toString().isNotEmpty) {
      print('STDOUT: ${analyzeResult.stdout}');
    }
    if (analyzeResult.stderr.toString().isNotEmpty) {
      print('STDERR: ${analyzeResult.stderr}');
    }
    
    if (analyzeResult.exitCode == 0) {
      print('✅ Flutter analyze passed - app should run');
    } else {
      print('❌ Flutter analyze failed - there are compilation issues');
    }
    
    print('\n🎯 Summary:');
    if (analyzeResult.exitCode == 0) {
      print('✅ The app should run successfully');
      print('💡 You can now run: flutter run -d windows');
    } else {
      print('❌ There are compilation issues that need to be fixed');
      print('💡 The new agent-terminal architecture has some conflicts with existing code');
      print('💡 We may need to disable some features temporarily to get the app running');
    }
    
  } catch (e, stackTrace) {
    print('❌ Test failed: $e');
    print('Stack trace: $stackTrace');
    exit(1);
  }
}