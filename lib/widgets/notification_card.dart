import 'package:flutter/material.dart';

class NotificationCard extends StatelessWidget {
  final Map<String, dynamic> notification;
  final VoidCallback? onTap;

  const NotificationCard({
    super.key,
    required this.notification,
    this.onTap,
  });

  static const Color primary = Color(0xFF4220E5);
  static const Color textColor = Color(0xFF0B1C30);
  static const Color muted = Color(0xFF474556);

  IconData _iconForType(String type) {
    switch (type.toLowerCase()) {
      case 'ai':
      case 'ai_insight':
        return Icons.auto_awesome;

      case 'task':
      case 'tasks':
      case 'task_assigned':
        return Icons.assignment_ind_outlined;

      case 'team':
      case 'invitation':
      case 'team_invitation':
        return Icons.groups_outlined;

      case 'milestone':
      case 'achievement':
        return Icons.check_circle_outline;

      default:
        return Icons.notifications_none;
    }
  }

  Color _colorForType(String type) {
    switch (type.toLowerCase()) {
      case 'milestone':
      case 'achievement':
        return const Color(0xFF006C49);

      case 'team':
      case 'invitation':
      case 'team_invitation':
        return const Color(0xFF5E26C7);

      default:
        return primary;
    }
  }

  String _formatTime(dynamic value) {
    if (value == null) return '';

    final date = DateTime.tryParse(value.toString());
    if (date == null) return '';

    final localDate = date.toLocal();
    final difference = DateTime.now().difference(localDate);

    if (difference.inSeconds < 60) return 'Just now';
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    }
    if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    }
    if (difference.inDays == 1) return 'Yesterday';
    if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    }

    return '${localDate.day}/${localDate.month}/${localDate.year}';
  }

  @override
  Widget build(BuildContext context) {
    final title = (notification['title'] ?? '').toString();
    final message = (notification['message'] ?? '').toString();
    final type = (notification['type'] ?? '').toString();
    final isRead = notification['is_read'] == true;

    final color = _colorForType(type);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _iconForType(type),
                color: color,
                size: 21,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.6,
                            color: color,
                          ),
                        ),
                      ),
                      Text(
                        _formatTime(notification['created_at']),
                        style: const TextStyle(
                          fontSize: 11,
                          color: muted,
                        ),
                      ),
                      if (!isRead) ...[
                        const SizedBox(width: 7),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 7),
                  Text(
                    message,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: textColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
