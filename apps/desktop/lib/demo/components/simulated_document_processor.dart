import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import '../../core/design_system/design_system.dart';

/// Realistic document upload and processing simulation
class SimulatedDocumentProcessor extends StatefulWidget {
  final Function(ProcessingResult)? onProcessingComplete;
  final Function(ProcessingStep)? onStepUpdate;

  const SimulatedDocumentProcessor({
    super.key,
    this.onProcessingComplete,
    this.onStepUpdate,
  });

  @override
  State<SimulatedDocumentProcessor> createState() => _SimulatedDocumentProcessorState();
}

class _SimulatedDocumentProcessorState extends State<SimulatedDocumentProcessor>
    with TickerProviderStateMixin {
  
  late AnimationController _uploadController;
  late AnimationController _processingController;
  late AnimationController _pulseController;

  ProcessingPhase _currentPhase = ProcessingPhase.waiting;
  List<ProcessingStep> _completedSteps = [];
  ProcessingStep? _currentStep;
  String? _uploadedFileName;
  double _uploadProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _uploadController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _processingController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors(context);

    return Container(
      padding: const EdgeInsets.all(SpacingTokens.lg),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(BorderRadiusTokens.lg),
        border: Border.all(
          color: _currentPhase == ProcessingPhase.waiting 
              ? colors.primary.withOpacity(0.3)
              : colors.border,
          width: 2,
          style: _currentPhase == ProcessingPhase.waiting 
              ? BorderStyle.solid 
              : BorderStyle.solid,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(colors),
          const SizedBox(height: SpacingTokens.lg),
          _buildContent(colors),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeColors colors) {
    return Row(
      children: [
        AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            return Icon(
              _getPhaseIcon(),
              color: _getPhaseColor(colors).withOpacity(
                _currentPhase == ProcessingPhase.waiting 
                    ? 0.6 + 0.4 * _pulseController.value
                    : 1.0,
              ),
              size: 28,
            );
          },
        ),
        const SizedBox(width: SpacingTokens.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _getPhaseTitle(),
                style: TextStyles.cardTitle.copyWith(color: colors.onSurface),
              ),
              if (_uploadedFileName != null) ...[
                const SizedBox(height: SpacingTokens.xs),
                Text(
                  _uploadedFileName!,
                  style: TextStyles.bodySmall.copyWith(
                    color: colors.onSurfaceVariant,
                    fontFamily: 'Courier',
                  ),
                ),
              ],
            ],
          ),
        ),
        if (_currentPhase == ProcessingPhase.processing ||
            _currentPhase == ProcessingPhase.analyzing) ...[
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: colors.primary,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildContent(ThemeColors colors) {
    switch (_currentPhase) {
      case ProcessingPhase.waiting:
        return _buildUploadArea(colors);
      case ProcessingPhase.uploading:
        return _buildUploadProgress(colors);
      case ProcessingPhase.processing:
        return _buildProcessingSteps(colors);
      case ProcessingPhase.analyzing:
        return _buildAnalysisSteps(colors);
      case ProcessingPhase.complete:
        return _buildResults(colors);
    }
  }

  Widget _buildUploadArea(ThemeColors colors) {
    return GestureDetector(
      onTap: _simulateDocumentUpload,
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: colors.primary.withOpacity(0.05),
          borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
          border: Border.all(
            color: colors.primary.withOpacity(0.3),
            width: 2,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.upload_file,
                size: 32,
                color: colors.primary,
              ),
              const SizedBox(height: SpacingTokens.sm),
              Text(
                'Drop document here or click to upload',
                style: TextStyles.bodyMedium.copyWith(color: colors.primary),
              ),
              const SizedBox(height: SpacingTokens.xs),
              Text(
                'Supports: PDF, DOC, TXT (Max 50MB)',
                style: TextStyles.bodySmall.copyWith(color: colors.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUploadProgress(ThemeColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.description, color: colors.primary, size: 20),
            const SizedBox(width: SpacingTokens.sm),
            Expanded(
              child: Text(
                'Uploading $_uploadedFileName...',
                style: TextStyles.bodyMedium.copyWith(color: colors.onSurface),
              ),
            ),
            Text(
              '${(_uploadProgress * 100).toInt()}%',
              style: TextStyles.bodyMedium.copyWith(
                color: colors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: SpacingTokens.md),
        AnimatedBuilder(
          animation: _uploadController,
          builder: (context, child) {
            return LinearProgressIndicator(
              value: _uploadProgress,
              backgroundColor: colors.border,
              valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
            );
          },
        ),
      ],
    );
  }

  Widget _buildProcessingSteps(ThemeColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Processing Document',
          style: TextStyles.bodyLarge.copyWith(
            color: colors.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: SpacingTokens.lg),
        ..._completedSteps.map((step) => _buildStepItem(step, colors, true)),
        if (_currentStep != null)
          _buildStepItem(_currentStep!, colors, false),
      ],
    );
  }

  Widget _buildAnalysisSteps(ThemeColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'AI Analysis in Progress',
          style: TextStyles.bodyLarge.copyWith(
            color: colors.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: SpacingTokens.lg),
        ..._completedSteps.map((step) => _buildStepItem(step, colors, true)),
        if (_currentStep != null)
          _buildStepItem(_currentStep!, colors, false),
      ],
    );
  }

  Widget _buildStepItem(ProcessingStep step, ThemeColors colors, bool isComplete) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: SpacingTokens.sm),
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: isComplete ? Colors.green : colors.primary,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isComplete ? Icons.check : Icons.more_horiz,
              color: Colors.white,
              size: 12,
            ),
          ),
          const SizedBox(width: SpacingTokens.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.description,
                  style: TextStyles.bodyMedium.copyWith(
                    color: colors.onSurface,
                    fontWeight: isComplete ? FontWeight.normal : FontWeight.w500,
                  ),
                ),
                if (step.details != null) ...[
                  const SizedBox(height: SpacingTokens.xs),
                  Text(
                    step.details!,
                    style: TextStyles.bodySmall.copyWith(
                      color: colors.onSurfaceVariant,
                      fontFamily: 'Courier',
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (step.duration != null) ...[
            Text(
              '${step.duration!.toStringAsFixed(1)}s',
              style: TextStyles.bodySmall.copyWith(color: colors.onSurfaceVariant),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildResults(ThemeColors colors) {
    return Container(
      padding: const EdgeInsets.all(SpacingTokens.lg),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
        border: Border.all(color: Colors.green.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 24),
              const SizedBox(width: SpacingTokens.md),
              Text(
                'Document Analysis Complete',
                style: TextStyles.bodyLarge.copyWith(
                  color: Colors.green.shade700,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: SpacingTokens.md),
          _buildResultStat('Pages Analyzed', '47 pages'),
          _buildResultStat('Words Extracted', '12,450 words'),
          _buildResultStat('Sections Identified', '8 sections'),
          _buildResultStat('Processing Time', '8.3 seconds'),
          _buildResultStat('Confidence Range', '23% - 94%'),
          const SizedBox(height: SpacingTokens.lg),
          AsmblButton.primary(
            text: 'Start Reasoning Workflow',
            onPressed: () {
              widget.onProcessingComplete?.call(ProcessingResult(
                fileName: _uploadedFileName!,
                pageCount: 47,
                wordCount: 12450,
                sectionCount: 8,
                processingTime: 8.3,
                confidenceRange: ConfidenceRange(min: 0.23, max: 0.94),
              ));
            },
          ),
        ],
      ),
    );
  }

  Widget _buildResultStat(String label, String value) {
    final colors = ThemeColors(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: SpacingTokens.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyles.bodyMedium.copyWith(color: colors.onSurfaceVariant),
          ),
          Text(
            value,
            style: TextStyles.bodyMedium.copyWith(
              color: colors.onSurface,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _simulateDocumentUpload() async {
    // Simulate file selection
    setState(() {
      _uploadedFileName = 'TechnoVate_Pitch_Deck.pdf';
      _currentPhase = ProcessingPhase.uploading;
      _uploadProgress = 0.0;
    });

    // Simulate upload progress
    _uploadController.forward();
    for (int i = 0; i <= 100; i += 5) {
      await Future.delayed(const Duration(milliseconds: 100)); // Slower for demo control
      setState(() {
        _uploadProgress = i / 100.0;
      });
    }

    // Start processing
    setState(() {
      _currentPhase = ProcessingPhase.processing;
    });

    await _simulateProcessingSteps();
  }

  Future<void> _simulateProcessingSteps() async {
    final processingSteps = [
      ProcessingStep('Uploading file to secure storage', details: '2.4 MB uploaded'),
      ProcessingStep('Extracting text content', details: 'PDF OCR processing'),
      ProcessingStep('Identifying document structure', details: '8 sections detected'),
      ProcessingStep('Parsing financial data', details: '15 metrics extracted'),
      ProcessingStep('Analyzing market information', details: 'Competitive landscape mapped'),
    ];

    for (final step in processingSteps) {
      setState(() {
        _currentStep = step;
      });
      widget.onStepUpdate?.call(step);

      // Simulate realistic processing time
      final duration = 0.8 + Random().nextDouble() * 1.5;
      await Future.delayed(Duration(milliseconds: (duration * 1000).toInt()));

      setState(() {
        _completedSteps.add(step.copyWith(duration: duration));
        _currentStep = null;
      });
    }

    // Start AI analysis phase
    setState(() {
      _currentPhase = ProcessingPhase.analyzing;
      _completedSteps.clear();
    });

    await _simulateAnalysisSteps();
  }

  Future<void> _simulateAnalysisSteps() async {
    final analysisSteps = [
      ProcessingStep('Initializing Claude-3.5-Sonnet', details: 'Model warming up'),
      ProcessingStep('Analyzing business model', details: '94% confidence'),
      ProcessingStep('Evaluating market opportunity', details: '67% confidence'),
      ProcessingStep('Assessing financial projections', details: '42% confidence ⚠️'),
      ProcessingStep('Reviewing competitive analysis', details: '89% confidence'),
      ProcessingStep('Generating investment thesis', details: 'Synthesis complete'),
    ];

    for (final step in analysisSteps) {
      setState(() {
        _currentStep = step;
      });
      widget.onStepUpdate?.call(step);

      // Simulate AI processing time
      final duration = 1.2 + Random().nextDouble() * 2.0;
      await Future.delayed(Duration(milliseconds: (duration * 1000).toInt()));

      setState(() {
        _completedSteps.add(step.copyWith(duration: duration));
        _currentStep = null;
      });
    }

    // Complete processing
    setState(() {
      _currentPhase = ProcessingPhase.complete;
    });
  }

  String _getPhaseTitle() {
    switch (_currentPhase) {
      case ProcessingPhase.waiting:
        return 'Document Upload';
      case ProcessingPhase.uploading:
        return 'Uploading Document';
      case ProcessingPhase.processing:
        return 'Processing Document';
      case ProcessingPhase.analyzing:
        return 'AI Analysis';
      case ProcessingPhase.complete:
        return 'Analysis Complete';
    }
  }

  IconData _getPhaseIcon() {
    switch (_currentPhase) {
      case ProcessingPhase.waiting:
        return Icons.upload_file;
      case ProcessingPhase.uploading:
        return Icons.cloud_upload;
      case ProcessingPhase.processing:
        return Icons.settings;
      case ProcessingPhase.analyzing:
        return Icons.psychology;
      case ProcessingPhase.complete:
        return Icons.check_circle;
    }
  }

  Color _getPhaseColor(ThemeColors colors) {
    switch (_currentPhase) {
      case ProcessingPhase.waiting:
        return colors.primary;
      case ProcessingPhase.uploading:
        return colors.primary;
      case ProcessingPhase.processing:
        return Colors.orange;
      case ProcessingPhase.analyzing:
        return Colors.purple;
      case ProcessingPhase.complete:
        return Colors.green;
    }
  }

  @override
  void dispose() {
    _uploadController.dispose();
    _processingController.dispose();
    _pulseController.dispose();
    super.dispose();
  }
}

enum ProcessingPhase {
  waiting,
  uploading,
  processing,
  analyzing,
  complete,
}

class ProcessingStep {
  final String description;
  final String? details;
  final double? duration;

  ProcessingStep(this.description, {this.details, this.duration});

  ProcessingStep copyWith({
    String? description,
    String? details,
    double? duration,
  }) {
    return ProcessingStep(
      description ?? this.description,
      details: details ?? this.details,
      duration: duration ?? this.duration,
    );
  }
}

class ProcessingResult {
  final String fileName;
  final int pageCount;
  final int wordCount;
  final int sectionCount;
  final double processingTime;
  final ConfidenceRange confidenceRange;

  ProcessingResult({
    required this.fileName,
    required this.pageCount,
    required this.wordCount,
    required this.sectionCount,
    required this.processingTime,
    required this.confidenceRange,
  });
}

class ConfidenceRange {
  final double min;
  final double max;

  ConfidenceRange({required this.min, required this.max});
}