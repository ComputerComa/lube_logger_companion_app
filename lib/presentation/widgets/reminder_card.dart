import 'package:flutter/material.dart';
import 'package:lube_logger_companion_app/data/models/reminder.dart';
import 'package:lube_logger_companion_app/core/utils/date_formatters.dart';

class ReminderCard extends StatelessWidget {
  final Reminder reminder;
  final VoidCallback? onLongPress;

  const ReminderCard({
    super.key,
    required this.reminder,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 60,
            decoration: BoxDecoration(
              color: reminder.urgency.color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reminder.title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormatters.formatForDisplay(reminder.date),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey,
                      ),
                ),
                if (reminder.notes != null && reminder.notes!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    reminder.notes!,
                    style: Theme.of(context).textTheme.bodySmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          Chip(
            label: Text(reminder.urgency.displayName),
            backgroundColor: reminder.urgency.color.withValues(alpha: 0.2),
          ),
        ],
      ),
    );

    return Card(
      clipBehavior: Clip.antiAlias,
      child: onLongPress == null
          ? content
          : InkWell(
              onLongPress: onLongPress,
              child: content,
            ),
    );
  }
}
