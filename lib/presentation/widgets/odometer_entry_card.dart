import 'package:flutter/material.dart';
import 'package:lube_logger_companion_app/data/models/odometer_record.dart';
import 'package:lube_logger_companion_app/core/utils/date_formatters.dart';

class OdometerEntryCard extends StatelessWidget {
  final OdometerRecord record;

  const OdometerEntryCard({super.key, required this.record});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.speed, size: 32, color: Colors.green),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${record.odometer} miles',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormatters.formatForDisplay(record.date),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey,
                        ),
                  ),
                  if (record.extraFields.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      children: record.extraFields.map((field) {
                        return Chip(
                          label: Text('${field.name}: ${field.value}'),
                          labelStyle: const TextStyle(fontSize: 12),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
