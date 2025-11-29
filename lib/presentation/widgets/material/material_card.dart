import 'package:flutter/material.dart';
import '../../../domain/entities/material.dart' as app_entities;

class MaterialCard extends StatelessWidget {
  final app_entities.Material material;
  final VoidCallback? onDelete;
  final VoidCallback? onRetry;

  const MaterialCard({
    super.key,
    required this.material,
    this.onDelete,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: _buildLeadingIcon(context),
        title: Text(material.title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                if (material.subject != null) ...[
                  Chip(
                    label: Text(material.subject!),
                    visualDensity: VisualDensity.compact,
                  ),
                  const SizedBox(width: 8),
                ],
                if (material.gradeLevel != null)
                  Text('Grade ${material.gradeLevel}'),
              ],
            ),
            const SizedBox(height: 4),
            _buildStatusRow(context),
          ],
        ),
        trailing: _buildTrailing(context),
        isThreeLine: true,
      ),
    );
  }

  Widget _buildLeadingIcon(BuildContext context) {
    IconData icon;
    Color? color;

    switch (material.sourceType) {
      case 'pdf':
        icon = Icons.picture_as_pdf;
        color = Colors.red;
        break;
      case 'image':
        icon = Icons.image;
        color = Colors.blue;
        break;
      case 'camera':
        icon = Icons.camera_alt;
        color = Colors.green;
        break;
      default:
        icon = Icons.description;
    }

    return CircleAvatar(
      backgroundColor: color?.withOpacity(0.2),
      child: Icon(icon, color: color),
    );
  }

  Widget _buildStatusRow(BuildContext context) {
    IconData icon;
    String text;
    Color? color;

    switch (material.status) {
      case 'completed':
        icon = Icons.check_circle;
        text = 'Ready to help • ${_formatDate(material.processedAt)}';
        color = Colors.green;
        break;
      case 'processing':
        icon = Icons.hourglass_empty;
        text = 'Processing...';
        color = Colors.orange;
        break;
      case 'failed':
        icon = Icons.error;
        text = 'Failed • ${material.errorMessage ?? "Unknown error"}';
        color = Colors.red;
        break;
      default:
        icon = Icons.pending;
        text = 'Pending';
        color = Colors.grey;
    }

    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            text,
            style: TextStyle(color: color, fontSize: 12),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${date.month}/${date.day}';
  }

  Widget? _buildTrailing(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: (value) {
        if (value == 'retry' && onRetry != null) {
          onRetry!();
        } else if (value == 'delete' && onDelete != null) {
          onDelete!();
        }
      },
      itemBuilder: (context) => [
        if (material.status == 'failed' && onRetry != null)
          const PopupMenuItem(
            value: 'retry',
            child: Row(
              children: [
                Icon(Icons.refresh, size: 18),
                SizedBox(width: 8),
                Text('Retry'),
              ],
            ),
          ),
        const PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete, size: 18),
              SizedBox(width: 8),
              Text('Delete'),
            ],
          ),
        ),
      ],
    );
  }
}
