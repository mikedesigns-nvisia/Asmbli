import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Simple detection service for the initial build
class SimpleDetectionService {
  
  Future<SimpleDetectionResult> detectBasicTools() async {
    final results = <String, bool>{};
    
    try {
      // Test VS Code
      final vscodeLocations = [
        '${Platform.environment['LOCALAPPDATA']}\\Programs\\Microsoft VS Code\\Code.exe',
        'C:\\Program Files\\Microsoft VS Code\\Code.exe',
      ];
      
      for (final location in vscodeLocations) {
        if (location.isNotEmpty && await File(location).exists()) {
          results['VS Code'] = true;
          break;
        }
      }
      results['VS Code'] ??= false;
      
      // Test Git
      try {
        final gitResult = await Process.run('git', ['--version']);
        results['Git'] = gitResult.exitCode == 0;
      } catch (e) {
        results['Git'] = false;
      }
      
      // Test GitHub CLI
      try {
        final ghResult = await Process.run('gh', ['--version']);
        results['GitHub CLI'] = ghResult.exitCode == 0;
      } catch (e) {
        results['GitHub CLI'] = false;
      }
      
    } catch (e) {
      // Error handling
    }
    
    final totalFound = results.values.where((found) => found).length;
    final confidence = results.isNotEmpty ? ((totalFound / results.length) * 100).round() : 0;
    
    return SimpleDetectionResult(
      detections: results,
      totalFound: totalFound,
      confidence: confidence,
    );
  }
}

class SimpleDetectionResult {
  final Map<String, bool> detections;
  final int totalFound;
  final int confidence;
  
  const SimpleDetectionResult({
    required this.detections,
    required this.totalFound,
    required this.confidence,
  });
}

final simpleDetectionServiceProvider = Provider<SimpleDetectionService>((ref) {
  return SimpleDetectionService();
});