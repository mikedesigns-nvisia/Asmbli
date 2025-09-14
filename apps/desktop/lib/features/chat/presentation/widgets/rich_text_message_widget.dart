import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:markdown_widget/markdown_widget.dart';
import 'package:flutter_highlighter/flutter_highlighter.dart';
import 'package:flutter_highlighter/themes/github.dart';
import 'package:flutter_highlighter/themes/vs2015.dart';
import '../../../../core/design_system/design_system.dart';

/// A rich text widget that displays LLM responses with markdown formatting,
/// syntax highlighting, and interactive features
class RichTextMessageWidget extends StatefulWidget {
  final String content;
  final bool isStreaming;
  final bool isDarkTheme;
  final VoidCallback? onCopy;

  const RichTextMessageWidget({
    super.key,
    required this.content,
    this.isStreaming = false,
    this.isDarkTheme = false,
    this.onCopy,
  });

  @override
  State<RichTextMessageWidget> createState() => _RichTextMessageWidgetState();
}

class _RichTextMessageWidgetState extends State<RichTextMessageWidget> {
  bool _showCopyButton = false;

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors(context);
    
    return MouseRegion(
      onEnter: (_) => setState(() => _showCopyButton = true),
      onExit: (_) => setState(() => _showCopyButton = false),
      child: Stack(
        children: [
          // Main content
          _buildMarkdownContent(context, colors),
          
          // Copy button overlay
          if (_showCopyButton && !widget.isStreaming)
            _buildCopyButton(context, colors),
        ],
      ),
    );
  }

  Widget _buildMarkdownContent(BuildContext context, ThemeColors colors) {
    print('DEBUG: RichTextMessageWidget rendering markdown with content length: ${widget.content.length}');
    print('DEBUG: Content preview: ${widget.content.substring(0, widget.content.length > 100 ? 100 : widget.content.length)}');
    
    try {
      return MarkdownWidget(
        data: widget.content,
        config: MarkdownConfig(
          configs: [
            // Basic paragraph config
            PConfig(
              textStyle: TextStyles.bodyMedium.copyWith(
                color: colors.onSurface,
                height: 1.6,
              ),
            ),
            
            // Code block config
            PreConfig(
              decoration: BoxDecoration(
                color: colors.surfaceVariant.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
                border: Border.all(color: colors.border.withValues(alpha: 0.5)),
              ),
              padding: const EdgeInsets.all(SpacingTokens.md),
              wrapper: (child, code, language) => _buildCodeBlock(child, code, language),
            ),
            
            // Inline code config
            CodeConfig(
              style: TextStyle(
                fontFamily: 'Courier New',
                fontSize: 13,
                color: colors.primary,
                backgroundColor: colors.surfaceVariant.withValues(alpha: 0.2),
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      print('ERROR: MarkdownWidget failed to render: $e');
      // Fallback to plain text if markdown fails
      return SelectableText(
        widget.content,
        style: TextStyles.bodyMedium.copyWith(
          color: colors.onSurface,
        ),
      );
    }
  }

  Widget _buildCodeBlock(Widget child, String code, String? language) {
    final colors = ThemeColors(context);
    
    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Language label and copy button
            if (language != null || code.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: SpacingTokens.md,
                  vertical: SpacingTokens.xs,
                ),
                decoration: BoxDecoration(
                  color: colors.surfaceVariant.withValues(alpha: 0.5),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(BorderRadiusTokens.md),
                    topRight: Radius.circular(BorderRadiusTokens.md),
                  ),
                ),
                child: Row(
                  children: [
                    if (language != null)
                      Text(
                        language.toUpperCase(),
                        style: TextStyles.caption.copyWith(
                          color: colors.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    const Spacer(),
                    _buildCodeCopyButton(code, colors),
                  ],
                ),
              ),
            
            // Code content with syntax highlighting
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(SpacingTokens.md),
              decoration: BoxDecoration(
                color: colors.surfaceVariant.withValues(alpha: 0.3),
                borderRadius: language != null
                    ? const BorderRadius.only(
                        bottomLeft: Radius.circular(BorderRadiusTokens.md),
                        bottomRight: Radius.circular(BorderRadiusTokens.md),
                      )
                    : BorderRadius.circular(BorderRadiusTokens.md),
              ),
              child: language != null
                  ? HighlightView(
                      code,
                      language: language,
                      theme: widget.isDarkTheme ? vs2015Theme : githubTheme,
                      textStyle: TextStyle(
                        fontFamily: 'Courier New',
                        fontSize: 13,
                        color: colors.onSurface,
                      ),
                    )
                  : SelectableText(
                      code,
                      style: TextStyle(
                        fontFamily: 'Courier New',
                        fontSize: 13,
                        color: colors.onSurface,
                      ),
                    ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCodeCopyButton(String code, ThemeColors colors) {
    return InkWell(
      onTap: () => _copyToClipboard(code),
      borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
      child: Padding(
        padding: const EdgeInsets.all(SpacingTokens.xs),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.copy,
              size: 14,
              color: colors.onSurfaceVariant,
            ),
            const SizedBox(width: SpacingTokens.xs),
            Text(
              'Copy',
              style: TextStyles.caption.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCopyButton(BuildContext context, ThemeColors colors) {
    return Positioned(
      top: 0,
      right: 0,
      child: Container(
        margin: const EdgeInsets.all(SpacingTokens.xs),
        decoration: BoxDecoration(
          color: colors.surface.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
          border: Border.all(color: colors.border.withValues(alpha: 0.5)),
        ),
        child: InkWell(
          onTap: () => _copyToClipboard(widget.content),
          borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
          child: Padding(
            padding: const EdgeInsets.all(SpacingTokens.xs),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.copy,
                  size: 16,
                  color: colors.onSurfaceVariant,
                ),
                const SizedBox(width: SpacingTokens.xs),
                Text(
                  'Copy',
                  style: TextStyles.caption.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Copied to clipboard'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showLinkDialog(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Open Link'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Do you want to open this link?'),
            const SizedBox(height: SpacingTokens.md),
            Container(
              padding: const EdgeInsets.all(SpacingTokens.sm),
              decoration: BoxDecoration(
                color: ThemeColors(context).surfaceVariant.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
              ),
              child: SelectableText(
                url,
                style: TextStyles.caption.copyWith(
                  color: ThemeColors(context).onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _copyToClipboard(url);
            },
            child: Text('Copy URL'),
          ),
        ],
      ),
    );
  }
}