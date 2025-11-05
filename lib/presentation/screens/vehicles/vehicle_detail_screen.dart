import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lube_logger_companion_app/presentation/routing/app_router.dart';
import 'package:lube_logger_companion_app/providers/vehicle_provider.dart';
import 'package:lube_logger_companion_app/providers/statistics_provider.dart';
import 'package:lube_logger_companion_app/providers/latest_data_provider.dart';
import 'package:lube_logger_companion_app/providers/odometer_provider.dart';
import 'package:lube_logger_companion_app/providers/fuel_provider.dart';
import 'package:lube_logger_companion_app/providers/reminder_provider.dart';
import 'package:lube_logger_companion_app/providers/service_provider.dart';
import 'package:lube_logger_companion_app/data/models/reminder.dart';
import 'package:lube_logger_companion_app/data/models/service_record.dart';
import 'package:lube_logger_companion_app/core/utils/date_formatters.dart';

class VehicleDetailScreen extends ConsumerWidget {
  final int vehicleId;

  const VehicleDetailScreen({super.key, required this.vehicleId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehicleAsync = ref.watch(vehicleProvider(vehicleId));
    final statisticsAsync = ref.watch(statisticsProvider(vehicleId));
    final latestOdometerAsync = ref.watch(latestOdometerValueProvider(vehicleId));
    final latestFuelAsync = ref.watch(latestFuelRecordProvider(vehicleId));
    final upcomingRemindersAsync = ref.watch(upcomingRemindersProvider(vehicleId));
    final serviceRecordsAsync = ref.watch(serviceRecordsProvider(vehicleId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vehicle Details'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // Invalidate all providers to refresh all data
          ref.invalidate(vehicleProvider(vehicleId));
          ref.invalidate(odometerRecordsProvider(vehicleId));
          ref.invalidate(fuelRecordsProvider(vehicleId));
          ref.invalidate(remindersProvider(vehicleId));
          ref.invalidate(serviceRecordsProvider(vehicleId));
          ref.invalidate(latestOdometerProvider(vehicleId));
          ref.invalidate(statisticsProvider(vehicleId));
          ref.invalidate(latestOdometerValueProvider(vehicleId));
          ref.invalidate(latestFuelRecordProvider(vehicleId));
          ref.invalidate(upcomingRemindersProvider(vehicleId));
          
          // Wait for the main vehicle provider to refresh
          await ref.read(vehicleProvider(vehicleId).future);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: vehicleAsync.when(
            data: (vehicle) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Vehicle Info Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.directions_car, size: 32, color: Colors.blue),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  vehicle.displayName,
                                  style: Theme.of(context).textTheme.headlineSmall,
                                ),
                              ),
                            ],
                          ),
                          if (vehicle.licensePlate != null) ...[
                            const SizedBox(height: 8),
                            Text('License: ${vehicle.licensePlate}'),
                          ],
                          if (vehicle.vin != null) ...[
                            const SizedBox(height: 4),
                            Text('VIN: ${vehicle.vin}'),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Latest Odometer Card
                  latestOdometerAsync.when(
                    data: (odometerValue) => _buildLatestOdometerCard(context, odometerValue),
                    loading: () => const Card(child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: CircularProgressIndicator()),
                    )),
                    error: (_, _) => const SizedBox(),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Latest Fuel Entry Card
                  latestFuelAsync.when(
                    data: (record) => _buildLatestFuelCard(context, record),
                    loading: () => const Card(child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: CircularProgressIndicator()),
                    )),
                    error: (_, _) => const SizedBox(),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Recent Service Records Card
                  serviceRecordsAsync.when(
                    data: (records) => _buildServiceRecordsCard(context, records, vehicleId),
                    loading: () => const Card(child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: CircularProgressIndicator()),
                    )),
                    error: (_, _) => const SizedBox(),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Upcoming Reminders Card
                  upcomingRemindersAsync.when(
                    data: (reminders) => _buildRemindersCard(context, reminders, vehicleId),
                    loading: () => const Card(child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: CircularProgressIndicator()),
                    )),
                    error: (_, _) => const SizedBox(),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Statistics Summary Card
                  statisticsAsync.when(
                    data: (stats) => _buildStatisticsSummaryCard(context, stats),
                    loading: () => const Card(child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: CircularProgressIndicator()),
                    )),
                    error: (_, _) => const SizedBox(),
                  ),
                ],
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.all(32.0),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, stack) => Padding(
              padding: const EdgeInsets.all(32.0),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Error: $error'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        ref.invalidate(vehicleProvider(vehicleId));
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _showQuickActionsMenu(context, vehicleId);
        },
        icon: const Icon(Icons.add),
        label: const Text('Quick Add'),
      ),
    );
  }

  Widget _buildLatestOdometerCard(BuildContext context, int? odometerValue) {
    if (odometerValue == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.speed, size: 32, color: Colors.green),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Latest Odometer',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'No odometer entries yet',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey,
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

    return Card(
      child: InkWell(
        onTap: () {
          context.push('${AppRoutes.odometer}?vehicleId=$vehicleId');
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.speed, size: 32, color: Colors.green),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Latest Odometer',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$odometerValue miles',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLatestFuelCard(BuildContext context, record) {
    if (record == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.local_gas_station, size: 32, color: Colors.orange),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Last Fuel Entry',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'No fuel entries yet',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey,
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

    return Card(
      child: InkWell(
        onTap: () {
          context.push('${AppRoutes.fuel}?vehicleId=$vehicleId');
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.local_gas_station, size: 32, color: Colors.orange),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Last Fuel Entry',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${record.gallons.toStringAsFixed(2)} gallons',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    Text(
                      '\$${record.cost.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    Text(
                      DateFormatters.formatForDisplay(record.date),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey,
                          ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildServiceRecordsCard(BuildContext context, List<ServiceRecord> records, int vehicleId) {
    // Sort by date descending (most recent first)
    final sortedRecords = List<ServiceRecord>.from(records)
      ..sort((a, b) => b.date.compareTo(a.date));
    
    return Card(
      child: InkWell(
        onTap: () {
          context.push('${AppRoutes.service}?vehicleId=$vehicleId');
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.build, size: 32, color: Colors.blue),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Recent Service Records',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
              const SizedBox(height: 12),
              if (sortedRecords.isEmpty)
                Text(
                  'No service records yet',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey,
                      ),
                )
              else
                ...sortedRecords.take(3).map((record) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                record.description,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w500,
                                    ),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Text(
                                    DateFormatters.formatForDisplay(record.date),
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: Colors.grey,
                                        ),
                                  ),
                                  if (record.odometer > 0) ...[
                                    const Text(' • ', style: TextStyle(color: Colors.grey)),
                                    Text(
                                      '${record.odometer} miles',
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                            color: Colors.grey,
                                          ),
                                    ),
                                  ],
                                  if (record.cost > 0) ...[
                                    const Text(' • ', style: TextStyle(color: Colors.grey)),
                                    Text(
                                      '\$${record.cost.toStringAsFixed(2)}',
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                            color: Colors.grey,
                                          ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              if (sortedRecords.length > 3)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    '${sortedRecords.length - 3} more service record${sortedRecords.length - 3 > 1 ? 's' : ''}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.blue,
                          fontStyle: FontStyle.italic,
                        ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRemindersCard(BuildContext context, List<Reminder> reminders, int vehicleId) {
    return Card(
      child: InkWell(
        onTap: () {
          context.push('${AppRoutes.reminders}?vehicleId=$vehicleId');
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.notifications, size: 32, color: Colors.red),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Upcoming Reminders',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
              const SizedBox(height: 12),
              if (reminders.isEmpty)
                Text(
                  'No upcoming reminders',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey,
                      ),
                )
              else
                ...reminders.take(3).map((reminder) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: reminder.urgency.color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                reminder.title,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              Text(
                                DateFormatters.formatForDisplay(reminder.date),
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.grey,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              if (reminders.length > 3)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    '${reminders.length - 3} more reminder${reminders.length - 3 > 1 ? 's' : ''}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.blue,
                          fontStyle: FontStyle.italic,
                        ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatisticsSummaryCard(BuildContext context, stats) {
    return Card(
      child: InkWell(
        onTap: () {
          context.push('${AppRoutes.statistics}?vehicleId=$vehicleId');
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.analytics, size: 32, color: Colors.purple),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Statistics',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
              const SizedBox(height: 12),
              if (stats.latestOdometer != null)
                _buildStatRow('Latest Odometer', '${stats.latestOdometer} miles'),
              if (stats.averageMpg > 0)
                _buildStatRow('Average MPG', '${stats.averageMpg.toStringAsFixed(1)} MPG'),
              if (stats.totalFuelCost > 0)
                _buildStatRow('Total Fuel Cost', '\$${stats.totalFuelCost.toStringAsFixed(2)}'),
              _buildStatRow('Total Entries', '${stats.totalFuelEntries + stats.totalOdometerEntries}'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }


  void _showQuickActionsMenu(BuildContext context, int vehicleId) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.speed),
              title: const Text('Add Odometer Entry'),
              onTap: () {
                Navigator.pop(context);
                context.push('${AppRoutes.addOdometer}?vehicleId=$vehicleId');
              },
            ),
            ListTile(
              leading: const Icon(Icons.local_gas_station),
              title: const Text('Add Fuel Entry'),
              onTap: () {
                Navigator.pop(context);
                context.push('${AppRoutes.addFuel}?vehicleId=$vehicleId');
              },
            ),
            ListTile(
              leading: const Icon(Icons.build),
              title: const Text('Add Service Record'),
              onTap: () {
                Navigator.pop(context);
                context.push('${AppRoutes.addService}?vehicleId=$vehicleId');
              },
            ),
            ListTile(
              leading: const Icon(Icons.notifications),
              title: const Text('View Reminders'),
              onTap: () {
                Navigator.pop(context);
                context.push('${AppRoutes.reminders}?vehicleId=$vehicleId');
              },
            ),
          ],
        ),
      ),
    );
  }
}