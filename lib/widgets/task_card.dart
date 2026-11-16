import 'package:flutter/material.dart';

class TaskCard extends StatelessWidget {
  final Map<String, dynamic> task;
  final bool isCompleted;
  final ValueChanged<bool>? onCompletionChanged;
  final VoidCallback? onTap;

  const TaskCard({
    super.key,
    required this.task,
    this.isCompleted = false,
    this.onCompletionChanged,
    this.onTap,
  });

  static const Color primary = Color(0xFF4220E5);
  static const Color primaryContainer = Color(0xFF5C45FD);
  static const Color background = Color(0xFFF8F9FF);
  static const Color textColor = Color(0xFF0B1C30);
  static const Color muted = Color(0xFF474556);

  String _formatDeadline(dynamic value) {
    if (value == null) return 'No due date';

    final date = DateTime.tryParse(value.toString());
    if (date == null) return value.toString();

    final localDate = date.toLocal();

    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    final day = localDate.day;
    final month = months[localDate.month - 1];
    final year = localDate.year;

    final hour = localDate.hour;
    final minute = localDate.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour % 12 == 0 ? 12 : hour % 12;

    return '$month $day, $year • $displayHour:$minute $period';
  }

  Widget _buildTag(String label, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = (task['title'] ?? 'Untitled task').toString();
    final description = (task['description'] ?? '').toString();
    final category = (task['subject_name'] ?? '').toString();
    final priority = int.tryParse(
      (task['priority_level'] ?? '').toString(),
    );
    final status = (task['status'] ?? 'pending').toString();

    String? priorityLabel;
    Color priorityBg = Colors.transparent;
    Color priorityFg = muted;

    switch (priority) {
      case 1:
        priorityLabel = 'High';
        priorityBg = const Color(0xFFFDE8E8);
        priorityFg = const Color(0xFFE34B4B);
        break;
      case 2:
        priorityLabel = 'Medium';
        priorityBg = const Color(0xFFFFF2DB);
        priorityFg = const Color(0xFFE69A28);
        break;
      case 3:
        priorityLabel = 'Low';
        priorityBg = const Color(0xFFE3F5ED);
        priorityFg = const Color(0xFF269B70);
        break;
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(17),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: isCompleted ? background : Colors.white,
          borderRadius: BorderRadius.circular(17),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.035),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: onCompletionChanged == null
                  ? null
                  : () => onCompletionChanged!(!isCompleted),
              child: Container(
                width: 23,
                height: 23,
                margin: const EdgeInsets.only(top: 2),
                decoration: BoxDecoration(
                  color: isCompleted ? primaryContainer : background,
                  border: Border.all(
                    color: isCompleted
                        ? primaryContainer
                        : const Color(0xFFBDB8D5),
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: isCompleted
                    ? const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 17,
                      )
                    : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      if (priorityLabel != null)
                        _buildTag(
                          priorityLabel,
                          priorityBg,
                          priorityFg,
                        ),
                      if (category.isNotEmpty)
                        _buildTag(
                          category,
                          const Color(0xFFEFF4FF),
                          muted,
                        ),
                    ],
                  ),
                  const SizedBox(height: 9),
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      decoration: isCompleted
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                    ),
                  ),
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 5),
                    Text(
                      description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: muted,
                        fontSize: 11,
                        height: 1.5,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  const Divider(
                    height: 1,
                    color: Color(0xFFEFF4FF),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(
                        Icons.schedule,
                        color: Color(0xFF787588),
                        size: 15,
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          _formatDeadline(task['deadline']),
                          style: const TextStyle(
                            color: muted,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      Text(
                        status,
                        style: const TextStyle(
                          color: Color(0xFF006C49),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
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
