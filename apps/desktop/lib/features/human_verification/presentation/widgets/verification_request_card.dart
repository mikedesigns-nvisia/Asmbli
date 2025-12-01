import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/design_system/design_system.dart';
import '../../models/verification_request.dart';

class VerificationRequestCard extends StatelessWidget {
  final VerificationRequest request;
  final Function(String, String?) onApprove;
  final Function(String, String?) onReject;

  const VerificationRequestCard({
    super.key,
    required this.request,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors(context);
    final isPending = request.status == VerificationStatus.pending;
    final dateFormat = DateFormat('MMM d, h:mm a');

    return AsmblCard(
      padding: const EdgeInsets.all(SpacingTokens.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildStatusBadge(context, request.status),
              const SizedBox(width: SpacingTokens.sm),
              Text(
                request.source,
                style: TextStyles.caption.copyWith(color: colors.onSurfaceVariant),
              ),
              const Spacer(),
              Text(
                dateFormat.format(request.createdAt),
                style: TextStyles.caption.copyWith(color: colors.onSurfaceVariant),
              ),
            ],
          ),
          const SizedBox(height: SpacingTokens.sm),
          Text(
            request.title,
            style: TextStyles.cardTitle,
          ),
          const SizedBox(height: SpacingTokens.xs),
          Text(
            request.description,
            style: TextStyles.bodyMedium.copyWith(color: colors.onSurfaceVariant),
          ),
          
          if (request.data.isNotEmpty) ...[
            const SizedBox(height: SpacingTokens.md),
            Container(
              padding: const EdgeInsets.all(SpacingTokens.sm),
              decoration: BoxDecoration(
                color: colors.surfaceVariant.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Context Data',
                    style: TextStyles.caption.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: SpacingTokens.xs),
                  ...request.data.entries.map((e) => Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${e.key}: ', style: TextStyles.caption.copyWith(fontSize: 12, color: colors.primary, fontFamily: 'monospace')),
                        Expanded(child: Text('${e.value}', style: TextStyles.caption.copyWith(fontSize: 12, fontFamily: 'monospace'))),
                      ],
                    ),
                  )),
                ],
              ),
            ),
          ],

          if (isPending) ...[
            const SizedBox(height: SpacingTokens.lg),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: () => _showRejectDialog(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colors.error,
                    side: BorderSide(color: colors.error),
                  ),
                  child: const Text('Reject'),
                ),
                const SizedBox(width: SpacingTokens.md),
                FilledButton(
                  onPressed: () => onApprove(request.id, null),
                  style: FilledButton.styleFrom(
                    backgroundColor: colors.success,
                  ),
                  child: const Text('Approve'),
                ),
              ],
            ),
          ] else if (request.resolutionNote != null) ...[
             const SizedBox(height: SpacingTokens.md),
             Text(
               'Note: ${request.resolutionNote}',
               style: TextStyles.caption.copyWith(fontStyle: FontStyle.italic),
             ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context, VerificationStatus status) {
    final colors = ThemeColors(context);
    Color color;
    String label;
    IconData icon;

    switch (status) {
      case VerificationStatus.pending:
        color = colors.warning;
        label = 'Pending';
        icon = Icons.hourglass_empty;
        break;
      case VerificationStatus.approved:
        color = colors.success;
        label = 'Approved';
        icon = Icons.check_circle;
        break;
      case VerificationStatus.rejected:
        color = colors.error;
        label = 'Rejected';
        icon = Icons.cancel;
        break;
      case VerificationStatus.timedOut:
        color = colors.onSurfaceVariant;
        label = 'Timed Out';
        icon = Icons.timer_off;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyles.caption.copyWith(color: color, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  void _showRejectDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Request'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Reason (optional)',
            hintText: 'Why are you rejecting this?',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onReject(request.id, controller.text);
            },
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }
}
