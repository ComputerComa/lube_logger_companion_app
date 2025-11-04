import 'package:flutter/material.dart';
import 'package:lube_logger_companion_app/data/models/tax_record.dart';
import 'package:lube_logger_companion_app/core/utils/date_formatters.dart';

class TaxRecordCard extends StatelessWidget {
  final TaxRecord record;

  const TaxRecordCard({super.key, required this.record});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.receipt, size: 32, color: Colors.red),
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
                    DateFormatters.formatForDisplay(record.date),
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

