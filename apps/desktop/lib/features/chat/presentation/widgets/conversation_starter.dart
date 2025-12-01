import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/design_system/design_system.dart';
import '../../../../core/models/model_config.dart';

/// Conversation type for the starter
enum ConversationType {
  quickChat,
  deepReasoning,
  codeAssistant,
  visionAnalysis,
  agent,
}

extension ConversationTypeExtension on ConversationType {
  String get title {
    switch (this) {
      case ConversationType.quickChat:
        return 'Quick Chat';
      case ConversationType.deepReasoning:
        return 'Deep Reasoning';
      case ConversationType.codeAssistant:
        return 'Code Assistant';
      case ConversationType.visionAnalysis:
        return 'Vision Analysis';
      case ConversationType.agent:
        return 'Agent with Tools';
    }
  }

  String get description {
    switch (this) {
      case ConversationType.quickChat:
        return 'Fast responses for simple questions';
      case ConversationType.deepReasoning:
        return 'Complex analysis and problem solving';
      case ConversationType.codeAssistant:
        return 'Help with coding and debugging';
      case ConversationType.visionAnalysis:
        return 'Analyze images and visual content';
      case ConversationType.agent:
        return 'AI with access to tools and APIs';
    }
  }

  IconData get icon {
    switch (this) {
      case ConversationType.quickChat:
        return Icons.bolt;
      case ConversationType.deepReasoning:
        return Icons.psychology;
      case ConversationType.codeAssistant:
        return Icons.code;
      case ConversationType.visionAnalysis:
        return Icons.visibility;
      case ConversationType.agent:
        return Icons.smart_toy;
    }
  }

  List<String> get recommendedCapabilities {
    switch (this) {
      case ConversationType.quickChat:
        return ['chat', 'fast'];
      case ConversationType.deepReasoning:
        return ['reasoning', 'analysis'];
      case ConversationType.codeAssistant:
        return ['code', 'programming'];
      case ConversationType.visionAnalysis:
        return ['vision', 'multimodal'];
      case ConversationType.agent:
        return ['tools', 'function_calling'];
    }
  }
}

/// A beautiful conversation starter widget that helps users choose how to start
class ConversationStarter extends ConsumerStatefulWidget {
  final List<ModelConfig> availableModels;
  final ModelConfig? selectedModel;
  final Function(ModelConfig model, ConversationType type) onStart;
  final VoidCallback? onAgentSelect;

  const ConversationStarter({
    super.key,
    required this.availableModels,
    this.selectedModel,
    required this.onStart,
    this.onAgentSelect,
  });

  @override
  ConsumerState<ConversationStarter> createState() => _ConversationStarterState();
}

class _ConversationStarterState extends ConsumerState<ConversationStarter> {
  ConversationType? _selectedType;
  ModelConfig? _selectedModel;

  @override
  void initState() {
    super.initState();
    _selectedModel = widget.selectedModel;
  }

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors(context);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(SpacingTokens.xxl),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Welcome header
              _buildHeader(colors),

              const SizedBox(height: SpacingTokens.xxl * 2),

              // Conversation type cards
              _buildTypeSelector(colors),

              const SizedBox(height: SpacingTokens.xxl),

              // Model selector (shown after type is selected)
              if (_selectedType != null && _selectedType != ConversationType.agent)
                _buildModelSelector(colors),

              // Start button
              if (_selectedType != null && _selectedModel != null)
                _buildStartButton(colors),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeColors colors) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colors.primary.withValues(alpha: 0.2),
                colors.accent.withValues(alpha: 0.2),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(
            Icons.chat_bubble_outline,
            size: 40,
            color: colors.primary,
          ),
        ),
        const SizedBox(height: SpacingTokens.lg),
        Text(
          'Start a Conversation',
          style: GoogleFonts.fustat(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: colors.onSurface,
          ),
        ),
        const SizedBox(height: SpacingTokens.sm),
        Text(
          'Choose how you want to chat',
          style: GoogleFonts.fustat(
            fontSize: 16,
            color: colors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildTypeSelector(ThemeColors colors) {
    return Wrap(
      spacing: SpacingTokens.md,
      runSpacing: SpacingTokens.md,
      alignment: WrapAlignment.center,
      children: ConversationType.values.map((type) {
        final isSelected = _selectedType == type;
        final hasModels = _getModelsForType(type).isNotEmpty || type == ConversationType.agent;

        return _ConversationTypeCard(
          type: type,
          isSelected: isSelected,
          isEnabled: hasModels,
          onTap: hasModels
              ? () {
                  setState(() {
                    _selectedType = type;
                    if (type == ConversationType.agent) {
                      widget.onAgentSelect?.call();
                    } else {
                      // Auto-select best model for this type
                      final models = _getModelsForType(type);
                      if (models.isNotEmpty) {
                        _selectedModel = models.first;
                      }
                    }
                  });
                }
              : null,
          colors: colors,
        );
      }).toList(),
    );
  }

  Widget _buildModelSelector(ThemeColors colors) {
    final models = _getModelsForType(_selectedType!);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: SpacingTokens.lg),
        Text(
          'Choose a Model',
          style: GoogleFonts.fustat(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: colors.onSurface,
          ),
        ),
        const SizedBox(height: SpacingTokens.md),
        Wrap(
          spacing: SpacingTokens.sm,
          runSpacing: SpacingTokens.sm,
          children: models.map((model) {
            final isSelected = _selectedModel?.id == model.id;
            return _ModelChip(
              model: model,
              isSelected: isSelected,
              onTap: () => setState(() => _selectedModel = model),
              colors: colors,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildStartButton(ThemeColors colors) {
    return Padding(
      padding: const EdgeInsets.only(top: SpacingTokens.xxl),
      child: SizedBox(
        width: 200,
        child: AsmblButton.primary(
          text: 'Start Chat',
          icon: Icons.arrow_forward,
          onPressed: () {
            if (_selectedModel != null && _selectedType != null) {
              widget.onStart(_selectedModel!, _selectedType!);
            }
          },
        ),
      ),
    );
  }

  List<ModelConfig> _getModelsForType(ConversationType type) {
    // For now, return all ready models
    // In future, filter by capabilities
    return widget.availableModels
        .where((m) => m.status == ModelStatus.ready)
        .toList();
  }
}

/// Individual conversation type card
class _ConversationTypeCard extends StatefulWidget {
  final ConversationType type;
  final bool isSelected;
  final bool isEnabled;
  final VoidCallback? onTap;
  final ThemeColors colors;

  const _ConversationTypeCard({
    required this.type,
    required this.isSelected,
    required this.isEnabled,
    required this.onTap,
    required this.colors,
  });

  @override
  State<_ConversationTypeCard> createState() => _ConversationTypeCardState();
}

class _ConversationTypeCardState extends State<_ConversationTypeCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final opacity = widget.isEnabled ? 1.0 : 0.5;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 150,
          padding: const EdgeInsets.all(SpacingTokens.lg),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? widget.colors.primary.withValues(alpha: 0.1)
                : (_isHovered && widget.isEnabled
                    ? widget.colors.surface.withValues(alpha: 0.8)
                    : widget.colors.surface.withValues(alpha: 0.5)),
            borderRadius: BorderRadius.circular(BorderRadiusTokens.lg),
            border: Border.all(
              color: widget.isSelected
                  ? widget.colors.primary
                  : widget.colors.border.withValues(alpha: 0.3),
              width: widget.isSelected ? 2 : 1,
            ),
          ),
          child: Opacity(
            opacity: opacity,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: widget.isSelected
                        ? widget.colors.primary.withValues(alpha: 0.2)
                        : widget.colors.onSurfaceVariant.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    widget.type.icon,
                    size: 24,
                    color: widget.isSelected
                        ? widget.colors.primary
                        : widget.colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: SpacingTokens.md),
                Text(
                  widget.type.title,
                  style: GoogleFonts.fustat(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: widget.isSelected
                        ? widget.colors.primary
                        : widget.colors.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: SpacingTokens.xs),
                Text(
                  widget.type.description,
                  style: GoogleFonts.fustat(
                    fontSize: 11,
                    color: widget.colors.onSurfaceVariant,
                    height: 1.3,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Model selection chip
class _ModelChip extends StatefulWidget {
  final ModelConfig model;
  final bool isSelected;
  final VoidCallback onTap;
  final ThemeColors colors;

  const _ModelChip({
    required this.model,
    required this.isSelected,
    required this.onTap,
    required this.colors,
  });

  @override
  State<_ModelChip> createState() => _ModelChipState();
}

class _ModelChipState extends State<_ModelChip> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(
            horizontal: SpacingTokens.md,
            vertical: SpacingTokens.sm,
          ),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? widget.colors.primary.withValues(alpha: 0.15)
                : (_isHovered
                    ? widget.colors.surface
                    : widget.colors.surface.withValues(alpha: 0.5)),
            borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
            border: Border.all(
              color: widget.isSelected
                  ? widget.colors.primary
                  : widget.colors.border.withValues(alpha: 0.3),
              width: widget.isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Model type indicator
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: widget.model.isLocal
                      ? widget.colors.success
                      : widget.colors.accent,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: SpacingTokens.sm),
              // Model name
              Text(
                widget.model.name,
                style: GoogleFonts.fustat(
                  fontSize: 13,
                  fontWeight: widget.isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: widget.isSelected
                      ? widget.colors.primary
                      : widget.colors.onSurface,
                ),
              ),
              // Local indicator
              if (widget.model.isLocal) ...[
                const SizedBox(width: SpacingTokens.xs),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: widget.colors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Local',
                    style: GoogleFonts.fustat(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: widget.colors.success,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
