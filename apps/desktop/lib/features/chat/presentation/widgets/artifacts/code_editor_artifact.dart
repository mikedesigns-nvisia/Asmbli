import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/atom-one-dark.dart';
import 'package:flutter_highlight/themes/atom-one-light.dart';
import '../../../../../core/design_system/design_system.dart';
import '../../../../../core/models/artifact.dart';
import '../../../../../providers/artifact_provider.dart';

/// Code editor artifact widget with syntax highlighting
class CodeEditorArtifact extends ConsumerStatefulWidget {
  final Artifact artifact;

  const CodeEditorArtifact({
    super.key,
    required this.artifact,
  });

  @override
  ConsumerState<CodeEditorArtifact> createState() => _CodeEditorArtifactState();
}

class _CodeEditorArtifactState extends ConsumerState<CodeEditorArtifact> {
  bool _isEditing = false;
  late TextEditingController _controller;
  bool _copied = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.artifact.content);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleEdit() {
    setState(() {
      _isEditing = !_isEditing;
      if (!_isEditing && _controller.text != widget.artifact.content) {
        // Save changes
        ref.read(artifactProvider.notifier).updateArtifactContent(
              widget.artifact.id,
              _controller.text,
            );
      }
    });
  }

  Future<void> _copyToClipboard() async {
    await Clipboard.setData(ClipboardData(text: widget.artifact.content));
    setState(() => _copied = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _copied = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(BorderRadiusTokens.lg),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header with language badge and actions
          _buildHeader(colors),

          // Code content
          Expanded(
            child: _isEditing ? _buildEditor(colors) : _buildHighlightedCode(isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeColors colors) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: SpacingTokens.md,
        vertical: SpacingTokens.sm,
      ),
      decoration: BoxDecoration(
        color: colors.background.withOpacity(0.3),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(BorderRadiusTokens.lg),
          topRight: Radius.circular(BorderRadiusTokens.lg),
        ),
        border: Border(bottom: BorderSide(color: colors.border)),
      ),
      child: Row(
        children: [
          // Language badge
          if (widget.artifact.language != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: SpacingTokens.sm,
                vertical: SpacingTokens.xs,
              ),
              decoration: BoxDecoration(
                color: colors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
                border: Border.all(color: colors.primary.withOpacity(0.3)),
              ),
              child: Text(
                widget.artifact.language!.toUpperCase(),
                style: TextStyles.bodySmall.copyWith(
                  color: colors.primary,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(width: SpacingTokens.sm),
          ],

          // Line count
          Text(
            '${widget.artifact.content.split('\n').length} lines',
            style: TextStyles.bodySmall.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),

          const Spacer(),

          // Action buttons
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Copy button
              IconButton(
                onPressed: _copyToClipboard,
                icon: Icon(
                  _copied ? Icons.check : Icons.copy,
                  size: 16,
                ),
                color: _copied ? colors.success : colors.onSurfaceVariant,
                tooltip: _copied ? 'Copied!' : 'Copy code',
                constraints: const BoxConstraints(
                  minWidth: 32,
                  minHeight: 32,
                ),
                padding: const EdgeInsets.all(SpacingTokens.xs),
              ),

              const SizedBox(width: SpacingTokens.xs),

              // Edit button
              IconButton(
                onPressed: _toggleEdit,
                icon: Icon(
                  _isEditing ? Icons.check : Icons.edit,
                  size: 16,
                ),
                color: _isEditing ? colors.primary : colors.onSurfaceVariant,
                tooltip: _isEditing ? 'Save' : 'Edit',
                constraints: const BoxConstraints(
                  minWidth: 32,
                  minHeight: 32,
                ),
                padding: const EdgeInsets.all(SpacingTokens.xs),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHighlightedCode(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(SpacingTokens.md),
      child: SingleChildScrollView(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: HighlightView(
            widget.artifact.content,
            language: widget.artifact.language ?? 'plaintext',
            theme: isDark ? atomOneDarkTheme : atomOneLightTheme,
            padding: EdgeInsets.zero,
            textStyle: TextStyle(
              fontFamily: 'monospace',
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEditor(ThemeColors colors) {
    return Container(
      padding: const EdgeInsets.all(SpacingTokens.md),
      child: TextField(
        controller: _controller,
        maxLines: null,
        expands: true,
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: 13,
          height: 1.5,
          color: colors.onSurface,
        ),
        decoration: InputDecoration(
          border: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.zero,
        ),
      ),
    );
  }
}
