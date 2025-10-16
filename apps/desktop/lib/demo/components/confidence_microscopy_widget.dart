import 'package:flutter/material.dart';
import '../../core/design_system/design_system.dart';

/// Interactive confidence visualization with drill-down capability
class ConfidenceMicroscopyWidget extends StatefulWidget {
  final ConfidenceTree confidenceTree;
  final Function(ConfidenceNode)? onNodeTap;
  final Function(UncertaintyIntervention)? onInterventionTrigger;

  const ConfidenceMicroscopyWidget({
    super.key,
    required this.confidenceTree,
    this.onNodeTap,
    this.onInterventionTrigger,
  });

  @override
  State<ConfidenceMicroscopyWidget> createState() => _ConfidenceMicroscopyWidgetState();
}

class _ConfidenceMicroscopyWidgetState extends State<ConfidenceMicroscopyWidget>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _expandController;
  ConfidenceNode? _selectedNode;
  bool _showDetails = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
    
    _expandController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    // Monitor for low confidence nodes
    _monitorUncertainty();
  }

  void _monitorUncertainty() {
    for (final node in widget.confidenceTree.getAllNodes()) {
      if (node.confidence < 0.5 && node.requiresIntervention) {
        // Auto-trigger intervention for very low confidence
        Future.delayed(Duration.zero, () {
          _triggerIntervention(node);
        });
      }
    }
  }

  void _triggerIntervention(ConfidenceNode node) {
    if (widget.onInterventionTrigger != null) {
      final intervention = UncertaintyIntervention(
        node: node,
        reason: node.uncertaintyReason,
        suggestedAction: _getSuggestedAction(node),
        timestamp: DateTime.now(),
      );
      widget.onInterventionTrigger!(intervention);
    }
  }

  String _getSuggestedAction(ConfidenceNode node) {
    if (node.confidence < 0.3) return "Escalate to human expert";
    if (node.confidence < 0.5) return "Request additional context";
    if (node.confidence < 0.7) return "Use premium model";
    return "Continue with monitoring";
  }

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors(context);

    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(SpacingTokens.md),
      child: Padding(
        padding: const EdgeInsets.all(SpacingTokens.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(colors),
            const SizedBox(height: SpacingTokens.lg),
            _buildConfidenceTree(colors),
            if (_showDetails) ...[
              const SizedBox(height: SpacingTokens.lg),
              _buildDetailPanel(colors),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeColors colors) {
    return Row(
      children: [
        Icon(
          Icons.psychology,
          color: colors.primary,
          size: 24,
        ),
        const SizedBox(width: SpacingTokens.sm),
        Text(
          'Confidence Microscopy',
          style: TextStyles.sectionTitle.copyWith(color: colors.onSurface),
        ),
        const Spacer(),
        Text(
          'Overall: ${(widget.confidenceTree.root.confidence * 100).toInt()}%',
          style: TextStyles.bodyMedium.copyWith(
            color: _getConfidenceColor(widget.confidenceTree.root.confidence, colors),
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildConfidenceTree(ThemeColors colors) {
    return _buildConfidenceNode(widget.confidenceTree.root, colors, level: 0);
  }

  Widget _buildConfidenceNode(ConfidenceNode node, ThemeColors colors, {required int level}) {
    final isSelected = _selectedNode == node;
    final isLowConfidence = node.confidence < 0.5;
    final nodeColor = _getConfidenceColor(node.confidence, colors);

    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Container(
          margin: EdgeInsets.only(
            left: level * 24.0,
            bottom: SpacingTokens.sm,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () => _selectNode(node),
                child: Container(
                  padding: const EdgeInsets.all(SpacingTokens.md),
                  decoration: BoxDecoration(
                    color: isSelected ? colors.primary.withOpacity(0.1) : null,
                    border: Border.all(
                      color: isLowConfidence 
                          ? Colors.red.withOpacity(0.3 + 0.3 * _pulseController.value)
                          : colors.border,
                      width: isLowConfidence ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
                  ),
                  child: Row(
                    children: [
                      // Task icon
                      Icon(
                        _getTaskIcon(node.taskType),
                        color: nodeColor,
                        size: 20,
                      ),
                      const SizedBox(width: SpacingTokens.sm),
                      
                      // Task name
                      Expanded(
                        flex: 2,
                        child: Text(
                          node.taskName,
                          style: TextStyles.bodyMedium.copyWith(
                            color: colors.onSurface,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                      
                      // Confidence bar
                      Expanded(
                        flex: 3,
                        child: _buildConfidenceBar(node.confidence, nodeColor),
                      ),
                      
                      // Confidence percentage
                      SizedBox(
                        width: 60,
                        child: Text(
                          '${(node.confidence * 100).toInt()}%',
                          style: TextStyles.bodyMedium.copyWith(
                            color: nodeColor,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.end,
                        ),
                      ),
                      
                      // Warning icon for low confidence
                      if (isLowConfidence) ...[
                        const SizedBox(width: SpacingTokens.sm),
                        Icon(
                          Icons.warning,
                          color: Colors.red,
                          size: 20,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              
              // Child nodes (sub-tasks)
              if (node.children.isNotEmpty) ...[
                const SizedBox(height: SpacingTokens.xs),
                ...node.children.map(
                  (child) => _buildConfidenceNode(child, colors, level: level + 1),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildConfidenceBar(double confidence, Color color) {
    return Container(
      height: 8,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        color: Colors.grey.shade300,
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: confidence,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: color,
          ),
        ),
      ),
    );
  }

  Widget _buildDetailPanel(ThemeColors colors) {
    if (_selectedNode == null) return const SizedBox.shrink();

    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 1),
        end: Offset.zero,
      ).animate(_expandController),
      child: Container(
        padding: const EdgeInsets.all(SpacingTokens.lg),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
          border: Border.all(color: colors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Uncertainty Analysis: ${_selectedNode!.taskName}',
              style: TextStyles.cardTitle.copyWith(color: colors.onSurface),
            ),
            const SizedBox(height: SpacingTokens.md),
            
            _buildAnalysisRow('Confidence Level', '${(_selectedNode!.confidence * 100).toInt()}%', colors),
            _buildAnalysisRow('Uncertainty Source', _selectedNode!.uncertaintyReason, colors),
            _buildAnalysisRow('Required Expertise', _selectedNode!.requiredExpertise ?? 'General', colors),
            _buildAnalysisRow('Recommended Action', _getSuggestedAction(_selectedNode!), colors),
            
            if (_selectedNode!.confidence < 0.5) ...[
              const SizedBox(height: SpacingTokens.md),
              AsmblButton.primary(
                text: 'Request Human Help',
                onPressed: () => _triggerIntervention(_selectedNode!),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAnalysisRow(String label, String value, ThemeColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: SpacingTokens.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              '$label:',
              style: TextStyles.bodyMedium.copyWith(
                color: colors.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyles.bodyMedium.copyWith(color: colors.onSurface),
            ),
          ),
        ],
      ),
    );
  }

  void _selectNode(ConfidenceNode node) {
    setState(() {
      _selectedNode = node;
      _showDetails = true;
    });
    _expandController.forward();
    widget.onNodeTap?.call(node);
  }

  Color _getConfidenceColor(double confidence, ThemeColors colors) {
    if (confidence >= 0.8) return Colors.green;
    if (confidence >= 0.6) return Colors.orange;
    return Colors.red;
  }

  IconData _getTaskIcon(String taskType) {
    switch (taskType.toLowerCase()) {
      case 'goal': return Icons.flag;
      case 'context': return Icons.info;
      case 'reasoning': return Icons.psychology;
      case 'gateway': return Icons.decision_tree;
      case 'fallback': return Icons.alt_route;
      case 'trace': return Icons.timeline;
      case 'exit': return Icons.check_circle;
      default: return Icons.task;
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _expandController.dispose();
    super.dispose();
  }
}

/// Data model for confidence tree structure
class ConfidenceTree {
  final ConfidenceNode root;

  ConfidenceTree({required this.root});

  List<ConfidenceNode> getAllNodes() {
    final nodes = <ConfidenceNode>[];
    _collectNodes(root, nodes);
    return nodes;
  }

  void _collectNodes(ConfidenceNode node, List<ConfidenceNode> nodes) {
    nodes.add(node);
    for (final child in node.children) {
      _collectNodes(child, nodes);
    }
  }
}

/// Individual node in the confidence tree
class ConfidenceNode {
  final String taskName;
  final String taskType;
  final double confidence;
  final String uncertaintyReason;
  final String? requiredExpertise;
  final bool requiresIntervention;
  final List<ConfidenceNode> children;

  ConfidenceNode({
    required this.taskName,
    required this.taskType,
    required this.confidence,
    required this.uncertaintyReason,
    this.requiredExpertise,
    this.requiresIntervention = false,
    this.children = const [],
  });
}

/// Intervention triggered by uncertainty
class UncertaintyIntervention {
  final ConfidenceNode node;
  final String reason;
  final String suggestedAction;
  final DateTime timestamp;

  UncertaintyIntervention({
    required this.node,
    required this.reason,
    required this.suggestedAction,
    required this.timestamp,
  });
}