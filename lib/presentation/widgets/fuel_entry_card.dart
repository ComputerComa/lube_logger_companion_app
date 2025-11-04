import 'package:flutter/material.dart';
import 'package:lube_logger_companion_app/data/models/fuel_record.dart';
import 'package:lube_logger_companion_app/core/utils/date_formatters.dart';

class FuelEntryCard extends StatelessWidget {
  final FuelRecord record;

  const FuelEntryCard({super.key, required this.record});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.local_gas_station, size: 32, color: Colors.orange),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${record.gallons.toStringAsFixed(2)} gallons',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormatters.formatForDisplay(record.date),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey,
                        ),
                  ),
                  if (record.cost != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Cost: \$${record.cost!.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                  if (record.calculatedPricePerGallon > 0) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Price/Gallon: \$${record.calculatedPricePerGallon.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.bodySmall,
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
