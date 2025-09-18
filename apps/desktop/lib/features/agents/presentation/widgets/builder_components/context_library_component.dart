import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../../../../../core/design_system/design_system.dart';
import '../../../models/agent_builder_state.dart';
import '../../screens/agent_builder_screen.dart';

/// Context Library Component with upload functionality
class ContextLibraryComponent extends ConsumerStatefulWidget {
  const ContextLibraryComponent({super.key});

  @override
  ConsumerState<ContextLibraryComponent> createState() => _ContextLibraryComponentState();
}

class _ContextLibraryComponentState extends ConsumerState<ContextLibraryComponent> {
  bool _isUploading = false;

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors(context);
    final builderState = ref.watch(agentBuilderStateProvider);

    return Padding(
      padding: const EdgeInsets.all(SpacingTokens.lg),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(colors),
            const SizedBox(height: SpacingTokens.sectionSpacing),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left side - Upload area and controls
                Expanded(
                  flex: 2,
                  child: _buildUploadArea(builderState, colors),
                ),

                const SizedBox(width: SpacingTokens.lg),

                // Right side - File library and management
                Expanded(
                  flex: 1,
                  child: _buildFileLibrary(builderState, colors),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(ThemeColors colors) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(SpacingTokens.sm),
          decoration: BoxDecoration(
            color: colors.primary.withOpacity( 0.1),
            borderRadius: BorderRadius.circular(BorderRadiusTokens.lg),
          ),
          child: Icon(
            Icons.library_books,
            color: colors.primary,
            size: 24,
          ),
        ),
        const SizedBox(width: SpacingTokens.md),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Context & Knowledge Library',
              style: TextStyles.titleLarge.copyWith(color: colors.onSurface),
            ),
            Text(
              'Upload documents and files to enhance your agent\'s knowledge',
              style: TextStyles.bodyMedium.copyWith(color: colors.onSurfaceVariant),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildUploadArea(AgentBuilderState builderState, ThemeColors colors) {
    return AsmblCard(
      child: Padding(
        padding: const EdgeInsets.all(SpacingTokens.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.cloud_upload, color: colors.accent, size: 20),
                const SizedBox(width: SpacingTokens.sm),
                Text(
                  'Upload Files',
                  style: TextStyles.titleSmall.copyWith(color: colors.onSurface),
                ),
              ],
            ),
            const SizedBox(height: SpacingTokens.md),

            // Upload drop zone
            Container(
              height: 200,
              decoration: BoxDecoration(
                border: Border.all(
                  color: colors.border,
                  width: 2,
                  style: BorderStyle.solid,
                ),
                borderRadius: BorderRadius.circular(BorderRadiusTokens.lg),
                color: colors.surface.withOpacity( 0.5),
              ),
              child: InkWell(
                onTap: _isUploading ? null : _pickFiles,
                borderRadius: BorderRadius.circular(BorderRadiusTokens.lg),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_isUploading)
                        const CircularProgressIndicator()
                      else
                        Icon(
                          Icons.upload_file,
                          size: 48,
                          color: colors.primary,
                        ),
                      const SizedBox(height: SpacingTokens.md),
                      Text(
                        _isUploading ? 'Uploading...' : 'Click to select files or drag and drop',
                        style: TextStyles.bodyMedium.copyWith(
                          color: _isUploading ? colors.onSurfaceVariant : colors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: SpacingTokens.sm),
                      Text(
                        'Supported: PDF, TXT, MD, DOCX, JSON, CSV',
                        style: TextStyles.bodySmall.copyWith(color: colors.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: SpacingTokens.lg),

            // Upload buttons
            Row(
              children: [
                Expanded(
                  child: AsmblButton.primary(
                    text: 'Select Context Documents',
                    onPressed: _isUploading ? null : () => _pickFiles(isContext: true),
                    icon: Icons.description,
                  ),
                ),
                const SizedBox(width: SpacingTokens.md),
                Expanded(
                  child: AsmblButton.secondary(
                    text: 'Select Knowledge Files',
                    onPressed: _isUploading ? null : () => _pickFiles(isContext: false),
                    icon: Icons.auto_stories,
                  ),
                ),
              ],
            ),

            const SizedBox(height: SpacingTokens.lg),

            // File type information
            Container(
              padding: const EdgeInsets.all(SpacingTokens.md),
              decoration: BoxDecoration(
                color: colors.accent.withOpacity( 0.1),
                borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
                border: Border.all(color: colors.accent.withOpacity( 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: colors.accent, size: 16),
                      const SizedBox(width: SpacingTokens.xs),
                      Text(
                        'File Types',
                        style: TextStyles.bodySmall.copyWith(
                          color: colors.accent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: SpacingTokens.xs),
                  Text(
                    '• Context Documents: Instructions, guidelines, examples\n'
                    '• Knowledge Files: Reference materials, data, documentation\n'
                    '• Maximum file size: 10MB per file',
                    style: TextStyles.caption.copyWith(color: colors.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileLibrary(AgentBuilderState builderState, ThemeColors colors) {
    final totalFiles = builderState.contextDocuments.length + builderState.knowledgeFiles.length;

    return Column(
      children: [
        // File count summary
        AsmblCard(
          child: Padding(
            padding: const EdgeInsets.all(SpacingTokens.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.folder, color: colors.primary, size: 20),
                    const SizedBox(width: SpacingTokens.sm),
                    Text(
                      'File Library',
                      style: TextStyles.titleSmall.copyWith(color: colors.onSurface),
                    ),
                  ],
                ),
                const SizedBox(height: SpacingTokens.md),

                _buildFileCount('Context Documents', builderState.contextDocuments.length, Icons.description, colors),
                const SizedBox(height: SpacingTokens.sm),
                _buildFileCount('Knowledge Files', builderState.knowledgeFiles.length, Icons.auto_stories, colors),

                const SizedBox(height: SpacingTokens.md),

                Container(
                  padding: const EdgeInsets.all(SpacingTokens.sm),
                  decoration: BoxDecoration(
                    color: colors.primary.withOpacity( 0.1),
                    borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.analytics, color: colors.primary, size: 16),
                      const SizedBox(width: SpacingTokens.sm),
                      Text(
                        'Total: $totalFiles files',
                        style: TextStyles.bodySmall.copyWith(
                          color: colors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: SpacingTokens.lg),

        // File list
        if (totalFiles > 0)
          AsmblCard(
            child: Padding(
              padding: const EdgeInsets.all(SpacingTokens.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.list, color: colors.accent, size: 20),
                      const SizedBox(width: SpacingTokens.sm),
                      Text(
                        'Uploaded Files',
                        style: TextStyles.titleSmall.copyWith(color: colors.onSurface),
                      ),
                    ],
                  ),
                  const SizedBox(height: SpacingTokens.md),

                  SizedBox(
                    height: 200,
                    child: ListView(
                      children: [
                        ...builderState.contextDocuments.map((doc) => _buildFileItem(
                          doc,
                          'Context',
                          Icons.description,
                          colors,
                          () => builderState.removeContextDocument(doc),
                        )),
                        ...builderState.knowledgeFiles.map((file) => _buildFileItem(
                          file,
                          'Knowledge',
                          Icons.auto_stories,
                          colors,
                          () => builderState.removeKnowledgeFile(file),
                        )),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          AsmblCard(
            child: Padding(
              padding: const EdgeInsets.all(SpacingTokens.lg),
              child: Column(
                children: [
                  Icon(Icons.folder_open, size: 48, color: colors.onSurfaceVariant),
                  const SizedBox(height: SpacingTokens.md),
                  Text(
                    'No files uploaded yet',
                    style: TextStyles.bodyMedium.copyWith(
                      color: colors.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: SpacingTokens.sm),
                  Text(
                    'Upload files to enhance your agent\'s knowledge and context',
                    style: TextStyles.bodySmall.copyWith(color: colors.onSurfaceVariant),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildFileCount(String label, int count, IconData icon, ThemeColors colors) {
    return Row(
      children: [
        Icon(icon, color: colors.accent, size: 16),
        const SizedBox(width: SpacingTokens.sm),
        Text(
          '$label: $count',
          style: TextStyles.bodyMedium.copyWith(color: colors.onSurface),
        ),
      ],
    );
  }

  Widget _buildFileItem(String fileName, String type, IconData icon, ThemeColors colors, VoidCallback onRemove) {
    return Padding(
      padding: const EdgeInsets.only(bottom: SpacingTokens.sm),
      child: Container(
        padding: const EdgeInsets.all(SpacingTokens.sm),
        decoration: BoxDecoration(
          border: Border.all(color: colors.border),
          borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
        ),
        child: Row(
          children: [
            Icon(icon, color: colors.accent, size: 16),
            const SizedBox(width: SpacingTokens.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fileName,
                    style: TextStyles.bodySmall.copyWith(color: colors.onSurface),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    type,
                    style: TextStyles.caption.copyWith(color: colors.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.delete_outline, color: colors.error),
              iconSize: 16,
              onPressed: onRemove,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickFiles({bool isContext = true}) async {
    try {
      setState(() {
        _isUploading = true;
      });

      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'txt', 'md', 'docx', 'json', 'csv'],
        allowMultiple: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final builderState = ref.read(agentBuilderStateProvider);

        for (final file in result.files) {
          if (file.path != null) {
            final fileName = file.name;
            final fileSize = File(file.path!).lengthSync();

            // Check file size (10MB limit)
            if (fileSize > 10 * 1024 * 1024) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('File $fileName is too large (max 10MB)'),
                    backgroundColor: ThemeColors(context).error,
                  ),
                );
              }
              continue;
            }

            if (isContext) {
              builderState.addContextDocument(fileName);
            } else {
              builderState.addKnowledgeFile(fileName);
            }
          }
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Successfully uploaded ${result.files.length} file(s) as ${isContext ? 'context documents' : 'knowledge files'}',
              ),
              backgroundColor: ThemeColors(context).primary,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload files: $e'),
            backgroundColor: ThemeColors(context).error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }
}