import 'package:flutter/material.dart';
import '../../../../core/design_system/design_system.dart';
import '../../../../core/models/mcp_catalog_entry.dart';
import '../../../../core/models/mcp_server_category.dart';

class MCPCatalogEntryCard extends StatefulWidget {
  final MCPCatalogEntry entry;
  final VoidCallback? onTap;

  const MCPCatalogEntryCard({
    super.key,
    required this.entry,
    this.onTap,
  });

  @override
  State<MCPCatalogEntryCard> createState() => _MCPCatalogEntryCardState();
}

class _MCPCatalogEntryCardState extends State<MCPCatalogEntryCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors(context);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: EdgeInsets.all(SpacingTokens.lg),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
            border: Border.all(
              color: _isHovered
                ? colors.border.withValues(alpha: 0.6)
                : colors.border.withValues(alpha: 0.3),
              width: 1,
            ),
            boxShadow: _isHovered ? [
              BoxShadow(
                color: colors.onSurface.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ] : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildGitHubStyleHeader(colors),
              SizedBox(height: SpacingTokens.sm),
              _buildGitHubStyleDescription(colors),
              SizedBox(height: SpacingTokens.md),
              _buildGitHubStyleFooter(colors),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGitHubStyleHeader(ThemeColors colors) {
    return Row(
      children: [
        // Repository avatar (circular icon)
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: colors.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            _getServerIcon(),
            size: 12,
            color: colors.primary,
          ),
        ),
        SizedBox(width: SpacingTokens.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _getGitHubStyleName(),
                      style: TextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colors.primary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (widget.entry.isOfficial)
                    Container(
                      margin: EdgeInsets.only(left: SpacingTokens.xs),
                      padding: EdgeInsets.symmetric(
                        horizontal: SpacingTokens.xs,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: colors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(BorderRadiusTokens.xs),
                        border: Border.all(color: colors.primary.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        'Official',
                        style: TextStyles.caption.copyWith(
                          color: colors.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(height: SpacingTokens.xxs),
              Text(
                'by ${_getOwnerName()}',
                style: TextStyles.bodySmall.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        AsmblButton.outline(
          text: 'Install',
          onPressed: widget.onTap,
          size: AsmblButtonSize.small,
        ),
      ],
    );
  }

  Widget _buildGitHubStyleDescription(ThemeColors colors) {
    return Text(
      widget.entry.description,
      style: TextStyles.bodySmall.copyWith(
        color: colors.onSurfaceVariant,
        height: 1.3,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildGitHubStyleFooter(ThemeColors colors) {
    return Row(
      children: [
        // Language indicator (for primary capability)
        if (widget.entry.capabilities.isNotEmpty) ...[
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: _getLanguageColor(),
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: SpacingTokens.xs),
          Text(
            _getPrimaryLanguage(),
            style: TextStyles.bodySmall.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
          SizedBox(width: SpacingTokens.md),
        ],
        // Star count (mock)
        Icon(
          Icons.star_border,
          size: 16,
          color: colors.onSurfaceVariant,
        ),
        SizedBox(width: SpacingTokens.xs),
        Text(
          _getStarCount(),
          style: TextStyles.bodySmall.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
        SizedBox(width: SpacingTokens.md),
        // Updated time
        if (widget.entry.lastUpdated != null)
          Text(
            'Updated ${_getTimeAgo(widget.entry.lastUpdated!)}',
            style: TextStyles.bodySmall.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
      ],
    );
  }

  String _getGitHubStyleName() {
    // The name from GitHub registry is already the proper repository name
    // Example: "io.github.modelcontextprotocol/filesystem" -> "filesystem"
    String name = widget.entry.name;

    // Handle io.github.* format (common in GitHub MCP registry)
    if (name.startsWith('io.github.')) {
      // Extract just the server name from "io.github.owner/server-name"
      final parts = name.split('/');
      if (parts.length > 1) {
        return parts.last;
      }
    }

    // Handle npm-style names like "@modelcontextprotocol/server-name"
    if (name.startsWith('@')) {
      final parts = name.split('/');
      if (parts.length > 1) {
        return parts.last.replaceFirst(RegExp(r'^mcp-'), '');
      }
    }

    // Handle direct names like "mcp-server-name"
    name = name.replaceFirst(RegExp(r'^mcp-'), '');

    // Convert to display format
    return name.isEmpty ? widget.entry.name : name;
  }

  String _getOwnerName() {
    // Extract owner from name pattern
    String name = widget.entry.name;

    // Handle io.github.* format (common in GitHub MCP registry)
    if (name.startsWith('io.github.')) {
      // Extract owner from "io.github.owner/server-name"
      final parts = name.split('/');
      if (parts.length > 1) {
        return parts[1]; // Return the "owner" part
      }
    }

    // Handle npm-style names like "@owner/server-name"
    if (name.startsWith('@')) {
      final parts = name.split('/');
      if (parts.length > 1) {
        return parts.first.substring(1); // Remove @ and return owner
      }
    }

    // Handle regular names with slashes
    if (name.contains('/')) {
      return name.split('/').first;
    }

    // Fallback based on whether it's official
    return widget.entry.isOfficial ? 'modelcontextprotocol' : 'community';
  }

  String _getPrimaryLanguage() {
    if (widget.entry.capabilities.isEmpty) return 'MCP';

    final capability = widget.entry.capabilities.first;

    // Map capabilities to language-like names
    if (capability.contains('database') || capability.contains('sql')) return 'SQL';
    if (capability.contains('web') || capability.contains('http')) return 'TypeScript';
    if (capability.contains('file') || capability.contains('fs')) return 'Python';
    if (capability.contains('ai') || capability.contains('llm')) return 'Python';

    return capability.replaceAll('-', ' ').split(' ').first.capitalize();
  }

  Color _getLanguageColor() {
    final language = _getPrimaryLanguage().toLowerCase();

    // GitHub-style language colors
    switch (language) {
      case 'typescript': return const Color(0xFF3178C6);
      case 'python': return const Color(0xFF3776AB);
      case 'sql': return const Color(0xFF336791);
      case 'mcp': return const Color(0xFF007ACC);
      default: return const Color(0xFF586069);
    }
  }

  String _getStarCount() {
    // Mock star count based on entry properties
    int stars = 0;

    if (widget.entry.isOfficial) stars += 50;
    if (widget.entry.isFeatured) stars += 25;
    stars += widget.entry.capabilities.length * 3;

    if (stars > 100) return '${(stars / 100).round() * 100}';
    if (stars > 50) return '${(stars / 10).round() * 10}';

    return stars.toString();
  }

  IconData _getServerIcon() {
    final category = widget.entry.category;
    if (category == null) return Icons.extension;

    if (category == MCPServerCategory.development) return Icons.code;
    if (category == MCPServerCategory.productivity) return Icons.trending_up;
    if (category == MCPServerCategory.communication) return Icons.chat;
    if (category == MCPServerCategory.dataAnalysis) return Icons.analytics;
    if (category == MCPServerCategory.automation) return Icons.auto_awesome;
    if (category == MCPServerCategory.fileManagement) return Icons.folder;
    if (category == MCPServerCategory.webServices) return Icons.language;
    if (category == MCPServerCategory.cloud) return Icons.cloud;
    if (category == MCPServerCategory.database) return Icons.storage;
    if (category == MCPServerCategory.security) return Icons.security;
    if (category == MCPServerCategory.monitoring) return Icons.monitor;
    if (category == MCPServerCategory.ai) return Icons.psychology;
    if (category == MCPServerCategory.utility) return Icons.build;
    if (category == MCPServerCategory.experimental) return Icons.science;
    if (category == MCPServerCategory.custom) return Icons.extension;

    return Icons.extension; // fallback
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return '${months}mo ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'now';
    }
  }
}

extension StringCapitalize on String {
  String capitalize() {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1);
  }
}