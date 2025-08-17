import 'package:flutter/material.dart';
import '../models/extension.dart';

class ExtensionCard extends StatelessWidget {
  final Extension extension;
  final bool isSelected;
  final VoidCallback onToggle;
  final VoidCallback? onConfigure;
  final bool showDetails;

  const ExtensionCard({
    super.key,
    required this.extension,
    required this.isSelected,
    required this.onToggle,
    this.onConfigure,
    this.showDetails = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      elevation: isSelected ? 8 : 2,
      shadowColor: isSelected ? theme.primaryColor.withValues(alpha: 0.3) : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? theme.primaryColor : Colors.transparent,
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: onToggle,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  // Icon
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _getComplexityColor().withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getIconData(),
                      color: _getComplexityColor(),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  
                  // Name and provider
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          extension.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          extension.provider,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Selection indicator
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected ? theme.primaryColor : Colors.transparent,
                      border: Border.all(
                        color: isSelected ? theme.primaryColor : theme.dividerColor,
                        width: 2,
                      ),
                    ),
                    child: isSelected
                        ? Icon(
                            Icons.check,
                            size: 16,
                            color: theme.colorScheme.onPrimary,
                          )
                        : null,
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Description
              Text(
                extension.description,
                style: theme.textTheme.bodyMedium,
                maxLines: showDetails ? null : 2,
                overflow: showDetails ? null : TextOverflow.ellipsis,
              ),
              
              const SizedBox(height: 12),
              
              // Tags
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  _buildTag(extension.complexity.name.toUpperCase(), _getComplexityColor()),
                  _buildTag(extension.connectionType.name.toUpperCase(), theme.primaryColor),
                  _buildTag(extension.pricing.name.toUpperCase(), _getPricingColor()),
                ],
              ),
              
              if (showDetails) ...[
                const SizedBox(height: 16),
                
                // Features
                if (extension.features.isNotEmpty) ...[
                  Text(
                    'Features',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...extension.features.take(3).map((feature) => Padding(
                    padding: const EdgeInsets.only(left: 8, bottom: 4),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          size: 16,
                          color: theme.primaryColor,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            feature,
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  )),
                  if (extension.features.length > 3)
                    Padding(
                      padding: const EdgeInsets.only(left: 32),
                      child: Text(
                        '... and ${extension.features.length - 3} more',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                ],
                
                const SizedBox(height: 12),
                
                // Requirements
                if (extension.requirements.isNotEmpty) ...[
                  Text(
                    'Requirements',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...extension.requirements.map((requirement) => Padding(
                    padding: const EdgeInsets.only(left: 8, bottom: 4),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 16,
                          color: Colors.orange,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            requirement,
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  )),
                ],
              ],
              
              // Actions
              if (isSelected && onConfigure != null) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onConfigure,
                        icon: const Icon(Icons.settings, size: 16),
                        label: const Text('Configure'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: theme.primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }

  IconData _getIconData() {
    // Map icon names to Material Icons
    switch (extension.icon?.toLowerCase()) {
      case 'harddrive':
        return Icons.storage;
      case 'github':
        return Icons.code;
      case 'globe':
        return Icons.public;
      case 'database':
        return Icons.storage;
      case 'brain':
        return Icons.psychology;
      case 'briefcase':
        return Icons.business_center;
      case 'messagesquare':
        return Icons.chat;
      case 'checksquare':
        return Icons.check_box;
      case 'palette':
        return Icons.palette;
      case 'shield':
        return Icons.security;
      case 'barchart':
        return Icons.bar_chart;
      default:
        return Icons.extension;
    }
  }

  Color _getComplexityColor() {
    switch (extension.complexity) {
      case ExtensionComplexity.low:
        return Colors.green;
      case ExtensionComplexity.medium:
        return Colors.orange;
      case ExtensionComplexity.high:
        return Colors.red;
    }
  }

  Color _getPricingColor() {
    switch (extension.pricing) {
      case PricingTier.free:
        return Colors.green;
      case PricingTier.freemium:
        return Colors.blue;
      case PricingTier.paid:
        return Colors.purple;
    }
  }
}