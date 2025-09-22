import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/design_system/design_system.dart';
import '../../../../core/services/detection_configuration_service.dart';
import '../../../../core/services/simple_detection_service.dart';

class DetectionResultsScreen extends ConsumerStatefulWidget {
  const DetectionResultsScreen({super.key});

  @override
  ConsumerState<DetectionResultsScreen> createState() => _DetectionResultsScreenState();
}

class _DetectionResultsScreenState extends ConsumerState<DetectionResultsScreen> {
  SimpleDetectionResult? _detectionResult;
  ConfigurationResult? _configurationResult;
  bool _isDetecting = false;
  bool _isConfiguring = false;
  String _selectedCategory = 'all';

  final Map<String, String> _categories = {
    'all': 'All Tools',
    'development': 'Development',
    'browsers': 'Browsers',
    'productivity': 'Productivity',
  };

  @override
  void initState() {
    super.initState();
    _runDetection();
  }

  Future<void> _runDetection() async {
    setState(() {
      _isDetecting = true;
    });

    try {
      final detectionService = ref.read(simpleDetectionServiceProvider);
      final result = await detectionService.detectBasicTools();
      
      setState(() {
        _detectionResult = result;
        _isDetecting = false;
      });
    } catch (e) {
      setState(() {
        _isDetecting = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Detection failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _autoConfigureAll() async {
    if (_detectionResult == null) return;

    setState(() {
      _isConfiguring = true;
    });

    try {
      final configService = ref.read(detectionConfigurationServiceProvider);
      final result = await configService.autoConfigureFromDetection();
      
      setState(() {
        _configurationResult = result;
        _isConfiguring = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Configured ${result.totalConfigured} of ${result.totalDetected} tools successfully!'
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isConfiguring = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Configuration failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SemanticColors.background,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              SemanticColors.primary.withValues(alpha: 0.02),
              SemanticColors.background,
            ],
          ),
        ),
        child: Column(
          children: [
            _buildHeader(),
            Expanded(child: _buildContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(SpacingTokens.headerPadding),
      decoration: BoxDecoration(
        color: SemanticColors.surface.withValues(alpha: 0.8),
        border: const Border(
          bottom: BorderSide(color: SemanticColors.border),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: SemanticColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.auto_fix_high,
              color: SemanticColors.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Detection Results',
                  style: TextStyles.pageTitle,
                ),
                const SizedBox(height: 4),
                Text(
                  _isDetecting 
                    ? 'Scanning your system for tools...'
                    : _detectionResult != null 
                      ? 'Found ${_detectionResult!.totalFound} tools ready to integrate'
                      : 'Ready to scan your system',
                  style: TextStyles.bodyMedium.copyWith(
                    color: SemanticColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (_detectionResult != null && !_isConfiguring) ...[
            AsmblButton.secondary(
              text: 'Detect Again',
              onPressed: _runDetection,
            ),
            const SizedBox(width: 12),
            AsmblButton.primary(
              text: _configurationResult != null ? 'Reconfigure All' : 'Configure All',
              onPressed: _autoConfigureAll,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isDetecting) {
      return _buildDetectingState();
    }
    
    if (_detectionResult == null) {
      return _buildEmptyState();
    }

    return Column(
      children: [
        _buildSummaryCards(),
        const SizedBox(height: 24),
        _buildCategoryFilter(),
        const SizedBox(height: 16),
        Expanded(child: _buildResultsList()),
      ],
    );
  }

  Widget _buildDetectingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 80,
            height: 80,
            child: CircularProgressIndicator(
              strokeWidth: 6,
              valueColor: AlwaysStoppedAnimation<Color>(SemanticColors.primary),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Scanning Your System',
            style: TextStyles.pageTitle,
          ),
          const SizedBox(height: 12),
          Text(
            'Looking for installed development tools, browsers, and applications...',
            style: TextStyles.bodyMedium.copyWith(
              color: SemanticColors.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: SemanticColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.search,
              size: 48,
              color: SemanticColors.primary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Ready to Detect Tools',
            style: TextStyles.pageTitle,
          ),
          const SizedBox(height: 12),
          Text(
            'Click "Start Detection" to scan your system for installed tools and applications.',
            style: TextStyles.bodyMedium.copyWith(
              color: SemanticColors.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          AsmblButton.primary(
            text: 'Start Detection',
            onPressed: _runDetection,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryCard(
              'Tools Found',
              _detectionResult!.totalFound.toString(),
              Icons.check_circle,
              Colors.green,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildSummaryCard(
              'Ready to Configure',
              _detectionResult!.totalFound.toString(),
              Icons.settings,
              SemanticColors.primary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildSummaryCard(
              'Already Configured',
              _configurationResult?.totalConfigured.toString() ?? '0',
              Icons.done_all,
              Colors.blue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String label, String value, IconData icon, Color color) {
    return AsmblCard(
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: TextStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  Text(
                    label,
                    style: TextStyles.bodySmall.copyWith(
                      color: SemanticColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Text(
            'Filter:',
            style: TextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: SemanticColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 16),
          ...(_categories.entries.map((entry) {
            final isSelected = _selectedCategory == entry.key;
            return Container(
              margin: const EdgeInsets.only(right: 8),
              child: AsmblButton.secondary(
                text: entry.value,
                onPressed: () {
                  setState(() {
                    _selectedCategory = entry.key;
                  });
                },
              ),
            );
          }).toList()),
        ],
      ),
    );
  }

  Widget _buildResultsList() {
    final filteredResults = _getFilteredResults();
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 3.5,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: filteredResults.length,
        itemBuilder: (context, index) {
          final entry = filteredResults[index];
          return _buildToolCard(entry.key, entry.value);
        },
      ),
    );
  }

  Widget _buildToolCard(String toolName, bool isDetected) {
    final isConfigured = _configurationResult?.successfulConfigurations.contains(toolName) ?? false;
    
    return AsmblCard(
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Status icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isDetected
                  ? (isConfigured ? Colors.blue.withValues(alpha: 0.15) : Colors.green.withValues(alpha: 0.15))
                  : Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                isConfigured
                  ? Icons.done_all
                  : isDetected 
                    ? Icons.check_circle
                    : Icons.cancel,
                color: isConfigured
                  ? Colors.blue
                  : isDetected 
                    ? Colors.green
                    : Colors.grey,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            
            // Tool info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    toolName,
                    style: TextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: SemanticColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isConfigured
                      ? '✓ Configured and ready'
                      : isDetected 
                        ? 'Detected - ready to configure'
                        : 'Not found on this system',
                    style: TextStyles.bodySmall.copyWith(
                      color: isConfigured
                        ? Colors.blue
                        : isDetected 
                          ? Colors.green
                          : SemanticColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            
            // Action button
            if (isDetected && !isConfigured && !_isConfiguring)
              AsmblButton.secondary(
                text: 'Configure',
                onPressed: () => _configureSingleTool(toolName),
              )
            else if (_isConfiguring)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
          ],
        ),
      ),
    );
  }

  List<MapEntry<String, bool>> _getFilteredResults() {
    if (_detectionResult == null) return [];
    
    var results = _detectionResult!.detections.entries.toList();
    
    if (_selectedCategory != 'all') {
      results = results.where((entry) {
        return _getCategoryForTool(entry.key) == _selectedCategory;
      }).toList();
    }
    
    // Sort: detected first, then alphabetical
    results.sort((a, b) {
      if (a.value != b.value) {
        return b.value ? 1 : -1;
      }
      return a.key.compareTo(b.key);
    });
    
    return results;
  }

  String _getCategoryForTool(String toolName) {
    final tool = toolName.toLowerCase();
    if (tool.contains('vs code') || tool.contains('git') || tool.contains('node') || 
        tool.contains('python') || tool.contains('docker')) {
      return 'development';
    }
    if (tool.contains('browser') || tool.contains('chrome') || tool.contains('brave') ||
        tool.contains('firefox') || tool.contains('edge')) {
      return 'browsers';
    }
    return 'productivity';
  }

  Future<void> _configureSingleTool(String toolName) async {
    setState(() {
      _isConfiguring = true;
    });

    try {
      // TODO: Implement single tool configuration
      await Future.delayed(const Duration(seconds: 2)); // Simulate
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$toolName configured successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to configure $toolName: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isConfiguring = false;
      });
    }
  }
}