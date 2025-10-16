import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/design_system/design_system.dart';
import '../../../../core/services/mcp_settings_service.dart';

/// Context status indicator - connects to real service for global context documents
class ContextStatusIndicator extends ConsumerWidget {
  const ContextStatusIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch real MCP service for global context documents - no hardcoding
    final mcpService = ref.watch(mcpSettingsServiceProvider);
    final contextDocs = mcpService.globalContextDocuments;
    
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: SpacingTokens.md,
        vertical: SpacingTokens.sm,
      ),
      decoration: BoxDecoration(
        color: contextDocs.isNotEmpty 
            ? ThemeColors(context).accent.withValues(alpha: 0.1)
            : ThemeColors(context).surface,
        borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
        border: Border.all(
          color: contextDocs.isNotEmpty 
              ? ThemeColors(context).accent.withValues(alpha: 0.3)
              : ThemeColors(context).border,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.description,
            size: 16,
            color: contextDocs.isNotEmpty 
                ? ThemeColors(context).accent
                : ThemeColors(context).onSurfaceVariant,
          ),
          
          const SizedBox(width: SpacingTokens.xs),
          
          Text(
            'Context: ${contextDocs.length}',
            style: TextStyles.bodySmall.copyWith(
              color: contextDocs.isNotEmpty 
                  ? ThemeColors(context).accent
                  : ThemeColors(context).onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          
          if (contextDocs.isNotEmpty) ...[
            const SizedBox(width: SpacingTokens.xs),
            
            PopupMenuButton<String>(
              icon: Icon(
                Icons.keyboard_arrow_down,
                size: 14,
                color: ThemeColors(context).accent,
              ),
              offset: const Offset(0, 30),
              itemBuilder: (context) {
                return [
                  PopupMenuItem<String>(
                    enabled: false,
                    child: Text(
                      'Context Documents (${contextDocs.length})',
                      style: TextStyles.bodySmall.copyWith(
                        color: ThemeColors(context).onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const PopupMenuDivider(),
                  ...contextDocs.map((docPath) {
                    // Extract filename from path
                    final fileName = docPath.split('/').last.split('\\').last;
                    
                    return PopupMenuItem<String>(
                      value: docPath,
                      child: Row(
                        children: [
                          Icon(
                            _getFileIcon(fileName),
                            size: 16,
                            color: ThemeColors(context).accent,
                          ),
                          
                          const SizedBox(width: SpacingTokens.sm),
                          
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  fileName,
                                  style: TextStyles.bodyMedium,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  docPath,
                                  style: TextStyles.bodySmall.copyWith(
                                    color: ThemeColors(context).onSurfaceVariant,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          
                          const Icon(
                            Icons.check_circle,
                            size: 16,
                            color: Colors.green,
                          ),
                        ],
                      ),
                    );
                  }),
                ];
              },
              onSelected: (docPath) {
                // Could add document-specific actions here
                // For now, just show the document is available
              },
            ),
          ],
        ],
      ),
    );
  }

  IconData _getFileIcon(String fileName) {
    final extension = fileName.toLowerCase().split('.').last;
    switch (extension) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'txt':
        return Icons.text_snippet;
      case 'md':
        return Icons.code;
      case 'json':
        return Icons.data_object;
      case 'yml':
      case 'yaml':
        return Icons.settings;
      default:
        return Icons.insert_drive_file;
    }
  }
}