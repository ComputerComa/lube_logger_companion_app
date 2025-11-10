import 'package:flutter/material.dart';
import 'package:lube_logger_companion_app/data/models/service_record.dart';
import 'package:lube_logger_companion_app/core/utils/date_formatters.dart';

class ServiceRecordCard extends StatelessWidget {
  final ServiceRecord record;
  final VoidCallback? onLongPress;

  const ServiceRecordCard({
    super.key,
    required this.record,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const Icon(Icons.build, size: 32, color: Colors.blue),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.description,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  '\$${record.cost.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${DateFormatters.formatForDisplay(record.date)} • ${record.odometer} miles',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey,
                      ),
                ),
                if (record.notes != null && record.notes!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    record.notes!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey,
                          fontStyle: FontStyle.italic,
                        ),
                  ),
                ],
                if (record.extraFields.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: record.extraFields.map((field) {
                      return Chip(
                        label: Text('${field.name}: ${field.value}'),
                        labelStyle: const TextStyle(fontSize: 12),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
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

