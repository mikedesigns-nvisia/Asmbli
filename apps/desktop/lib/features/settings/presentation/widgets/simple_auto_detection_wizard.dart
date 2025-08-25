import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/design_system/design_system.dart';
import '../../../../core/services/simple_detection_service.dart';

class SimpleAutoDetectionWizard extends ConsumerStatefulWidget {
  final VoidCallback? onComplete;

  const SimpleAutoDetectionWizard({
    super.key,
    this.onComplete,
  });

  @override
  ConsumerState<SimpleAutoDetectionWizard> createState() => _SimpleAutoDetectionWizardState();
}

class _SimpleAutoDetectionWizardState extends ConsumerState<SimpleAutoDetectionWizard> {
  bool _isDetecting = false;
  SimpleDetectionResult? _detectionResult;
  String _currentStep = 'ready';

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 500,
        height: 400,
        decoration: BoxDecoration(
          color: SemanticColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: SemanticColors.border),
        ),
        child: Column(
          children: [
            _buildHeader(),
            Expanded(child: _buildContent()),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: SemanticColors.border)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.auto_fix_high,
            color: SemanticColors.primary,
            size: 24,
          ),
          SizedBox(width: 16),
          Text(
            'Auto-Detect Integrations',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: SemanticColors.onSurface,
            ),
          ),
          Spacer(),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(Icons.close, color: SemanticColors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_currentStep == 'ready') {
      return _buildReadyStep();
    } else if (_currentStep == 'detecting') {
      return _buildDetectingStep();
    } else {
      return _buildResultsStep();
    }
  }

  Widget _buildReadyStep() {
    return Padding(
      padding: EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: SemanticColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.search,
              size: 48,
              color: SemanticColors.primary,
            ),
          ),
          SizedBox(height: 24),
          Text(
            'Automatic Integration Detection',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: SemanticColors.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 12),
          Text(
            'We\'ll scan your system for installed development tools and automatically configure the ones we find.',
            style: TextStyle(
              fontSize: 14,
              color: SemanticColors.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDetectingStep() {
    return Padding(
      padding: EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 60,
            height: 60,
            child: CircularProgressIndicator(
              strokeWidth: 4,
              valueColor: AlwaysStoppedAnimation<Color>(SemanticColors.primary),
            ),
          ),
          SizedBox(height: 24),
          Text(
            'Scanning System...',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: SemanticColors.onSurface,
            ),
          ),
          SizedBox(height: 12),
          Text(
            'Detecting installed tools and services',
            style: TextStyle(
              fontSize: 14,
              color: SemanticColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsStep() {
    if (_detectionResult == null) return SizedBox();

    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          // Summary
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: SemanticColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    Text(
                      '${_detectionResult!.totalFound}',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: SemanticColors.primary,
                      ),
                    ),
                    Text(
                      'Found',
                      style: TextStyle(
                        fontSize: 12,
                        color: SemanticColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                Column(
                  children: [
                    Text(
                      '${_detectionResult!.confidence}%',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: SemanticColors.primary,
                      ),
                    ),
                    Text(
                      'Confidence',
                      style: TextStyle(
                        fontSize: 12,
                        color: SemanticColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          SizedBox(height: 16),
          
          // Results list
          Expanded(
            child: ListView(
              children: _detectionResult!.detections.entries.map((entry) {
                return Container(
                  margin: EdgeInsets.only(bottom: 8),
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: SemanticColors.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: SemanticColors.border),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: entry.value ? Colors.green : Colors.grey,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          entry.key,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: SemanticColors.onSurface,
                          ),
                        ),
                      ),
                      Text(
                        entry.value ? 'Ready' : 'Not Found',
                        style: TextStyle(
                          fontSize: 12,
                          color: entry.value ? Colors.green : SemanticColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: SemanticColors.border)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (_currentStep == 'ready') ...[
            AsmblButton.secondary(
              text: 'Cancel',
              onPressed: () => Navigator.of(context).pop(),
            ),
            SizedBox(width: 16),
            AsmblButton.primary(
              text: 'Start Detection',
              onPressed: _startDetection,
            ),
          ] else if (_currentStep == 'results') ...[
            AsmblButton.secondary(
              text: 'Detect Again',
              onPressed: () => setState(() {
                _currentStep = 'ready';
                _detectionResult = null;
              }),
            ),
            SizedBox(width: 16),
            AsmblButton.primary(
              text: 'Complete',
              onPressed: () {
                widget.onComplete?.call();
                Navigator.of(context).pop();
              },
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _startDetection() async {
    setState(() {
      _isDetecting = true;
      _currentStep = 'detecting';
    });

    try {
      final detectionService = ref.read(simpleDetectionServiceProvider);
      _detectionResult = await detectionService.detectBasicTools();
      
      setState(() {
        _currentStep = 'results';
      });
    } catch (e) {
      setState(() {
        _currentStep = 'ready';
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Detection failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isDetecting = false;
      });
    }
  }
}