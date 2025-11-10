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
import 'package:lube_logger_companion_app/providers/plan_provider.dart';
import 'package:lube_logger_companion_app/data/models/reminder.dart';
import 'package:lube_logger_companion_app/data/models/service_record.dart';
import 'package:lube_logger_companion_app/core/utils/date_formatters.dart';
import 'package:lube_logger_companion_app/data/models/odometer_record.dart';
import 'package:lube_logger_companion_app/data/models/fuel_record.dart';
import 'package:lube_logger_companion_app/presentation/widgets/odometer_entry_card.dart';
import 'package:lube_logger_companion_app/presentation/widgets/fuel_entry_card.dart';
import 'package:lube_logger_companion_app/presentation/widgets/reminder_card.dart';
import 'package:lube_logger_companion_app/presentation/widgets/service_record_card.dart';

class VehicleDetailScreen extends ConsumerStatefulWidget {
  final int vehicleId;

  const VehicleDetailScreen({super.key, required this.vehicleId});

  @override
  ConsumerState<VehicleDetailScreen> createState() => _VehicleDetailScreenState();
}

class _VehicleDetailScreenState extends ConsumerState<VehicleDetailScreen> {
  static const _sectionDefinitions = [
    (label: 'Overview', icon: Icons.dashboard_customize),
    (label: 'Odometer', icon: Icons.speed),
    (label: 'Fuel', icon: Icons.local_gas_station),
    (label: 'Service', icon: Icons.build),
    (label: 'Reminders', icon: Icons.alarm),
    (label: 'Statistics', icon: Icons.analytics_outlined),
  ];

  int _selectedIndex = 0;

  bool get _isTablet {
    final width = MediaQuery.of(context).size.width;
    return width >= 720;
  }

  void _onSectionSelected(int index, {bool closeDrawer = false}) {
    if (_selectedIndex == index) {
      if (closeDrawer) Navigator.of(context).maybePop();
      return;
    }
    setState(() => _selectedIndex = index);
    if (closeDrawer) Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final vehicleAsync = ref.watch(vehicleProvider(widget.vehicleId));
    final statisticsAsync = ref.watch(statisticsProvider(widget.vehicleId));
    final latestOdometerAsync = ref.watch(latestOdometerValueProvider(widget.vehicleId));
    final latestFuelAsync = ref.watch(latestFuelRecordProvider(widget.vehicleId));
    final upcomingRemindersAsync = ref.watch(upcomingRemindersProvider(widget.vehicleId));
    final serviceRecordsAsync = ref.watch(serviceRecordsProvider(widget.vehicleId));
    final odometerRecordsAsync = ref.watch(odometerRecordsProvider(widget.vehicleId));
    final fuelRecordsAsync = ref.watch(fuelRecordsProvider(widget.vehicleId));
    final allRemindersAsync = ref.watch(remindersProvider(widget.vehicleId));

    final drawer = _isTablet ? null : _buildDrawer();
    final bottomNav = _isTablet ? _buildBottomNavigation() : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vehicle Details'),
      ),
      drawer: drawer,
      body: RefreshIndicator(
        onRefresh: () async {
          final vehicleId = widget.vehicleId;
          ref.invalidate(vehicleProvider(vehicleId));
          ref.invalidate(odometerRecordsProvider(vehicleId));
          ref.invalidate(fuelRecordsProvider(vehicleId));
          ref.invalidate(remindersProvider(vehicleId));
          ref.invalidate(serviceRecordsProvider(vehicleId));
          ref.invalidate(planRecordsProvider(vehicleId));
          ref.invalidate(latestOdometerProvider(vehicleId));
          ref.invalidate(statisticsProvider(vehicleId));
          ref.invalidate(latestOdometerValueProvider(vehicleId));
          ref.invalidate(latestFuelRecordProvider(vehicleId));
          ref.invalidate(upcomingRemindersProvider(vehicleId));

          await ref.read(vehicleProvider(vehicleId).future);
        },
        child: _buildSectionContent(
          vehicleAsync: vehicleAsync,
          statisticsAsync: statisticsAsync,
          latestOdometerAsync: latestOdometerAsync,
          latestFuelAsync: latestFuelAsync,
          remindersAsync: upcomingRemindersAsync,
          serviceRecordsAsync: serviceRecordsAsync,
          odometerRecordsAsync: odometerRecordsAsync,
          fuelRecordsAsync: fuelRecordsAsync,
          allRemindersAsync: allRemindersAsync,
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showQuickActionsMenu(context, widget.vehicleId),
        icon: const Icon(Icons.add),
        label: const Text('Quick Add'),
      ),
      bottomNavigationBar: bottomNav,
    );
  }

  Widget _buildSectionContent({
    required AsyncValue vehicleAsync,
    required AsyncValue statisticsAsync,
    required AsyncValue<int?> latestOdometerAsync,
    required AsyncValue latestFuelAsync,
    required AsyncValue<List<Reminder>> remindersAsync,
    required AsyncValue<List<ServiceRecord>> serviceRecordsAsync,
    required AsyncValue<List<OdometerRecord>> odometerRecordsAsync,
    required AsyncValue<List<FuelRecord>> fuelRecordsAsync,
    required AsyncValue<List<Reminder>> allRemindersAsync,
  }) {
    return vehicleAsync.when(
      data: (vehicle) {
        final List<Widget> children = [];

        switch (_selectedIndex) {
          case 0: // Overview
            children.add(_buildVehicleHeaderCard(vehicle));
            children.add(const SizedBox(height: 16));
            children.add(
              latestOdometerAsync.when(
                data: (value) => _buildLatestOdometerCard(context, value),
                loading: () => _buildLoadingCard(),
                error: (error, stack) => const SizedBox(),
              ),
            );
            children.add(const SizedBox(height: 16));
            children.add(
              latestFuelAsync.when(
                data: (record) => _buildLatestFuelCard(context, record),
                loading: () => _buildLoadingCard(),
                error: (error, stack) => const SizedBox(),
              ),
            );
            children.add(const SizedBox(height: 16));
            children.add(
              statisticsAsync.when(
                data: (stats) => _buildStatisticsSummaryCard(context, stats, interactive: false),
                loading: () => _buildLoadingCard(),
                error: (error, stack) => const SizedBox(),
              ),
            );
            children.add(const SizedBox(height: 16));
            children.add(
              serviceRecordsAsync.when(
                data: (records) => _buildServiceRecordsCard(context, records, widget.vehicleId),
                loading: () => _buildLoadingCard(),
                error: (error, stack) => const SizedBox(),
              ),
            );
            children.add(const SizedBox(height: 16));
            children.add(
              remindersAsync.when(
                data: (reminders) => _buildRemindersCard(context, reminders, widget.vehicleId),
                loading: () => _buildLoadingCard(),
                error: (error, stack) => const SizedBox(),
              ),
            );
            break;
          case 1: // Odometer
            children.add(_buildVehicleHeaderCard(vehicle));
            children.add(const SizedBox(height: 16));
            children.add(
              odometerRecordsAsync.when(
                data: (records) => _buildOdometerRecordsList(context, records),
                loading: () => _buildLoadingCard(),
                error: (error, stack) => const SizedBox(),
              ),
            );
            break;
          case 2: // Fuel
            children.add(_buildVehicleHeaderCard(vehicle));
            children.add(const SizedBox(height: 16));
            children.add(
              fuelRecordsAsync.when(
                data: (records) => _buildFuelRecordsList(context, records),
                loading: () => _buildLoadingCard(),
                error: (error, stack) => const SizedBox(),
              ),
            );
            break;
          case 3: // Service
            children.add(_buildVehicleHeaderCard(vehicle));
            children.add(const SizedBox(height: 16));
            children.add(
              serviceRecordsAsync.when(
                data: (records) => _buildServiceRecordsList(context, records),
                loading: () => _buildLoadingCard(),
                error: (error, stack) => const SizedBox(),
              ),
            );
            break;
          case 4: // Reminders
            children.add(_buildVehicleHeaderCard(vehicle));
            children.add(const SizedBox(height: 16));
            children.add(
              allRemindersAsync.when(
                data: (reminders) => _buildRemindersList(context, reminders),
                loading: () => _buildLoadingCard(),
                error: (error, stack) => const SizedBox(),
              ),
            );
            break;
          case 5: // Statistics
            children.add(_buildVehicleHeaderCard(vehicle));
            children.add(const SizedBox(height: 16));
            children.add(
              _buildStatisticsDetailSection(
                context: context,
                statisticsAsync: statisticsAsync,
                fuelRecordsAsync: fuelRecordsAsync,
              ),
            );
            break;
        }

        return ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: children,
        );
      },
      loading: () => const Center(child: Padding(
        padding: EdgeInsets.all(32),
        child: CircularProgressIndicator(),
      )),
      error: (error, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Error: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(vehicleProvider(widget.vehicleId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Drawer _buildDrawer() {
    return Drawer(
      child: SafeArea(
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 16),
          itemBuilder: (context, index) {
            final entry = _sectionDefinitions[index];
            final selected = index == _selectedIndex;
            return ListTile(
              leading: Icon(entry.icon, color: selected ? Theme.of(context).colorScheme.primary : null),
              title: Text(entry.label),
              selected: selected,
              onTap: () => _onSectionSelected(index, closeDrawer: true),
            );
          },
          separatorBuilder: (context, _) => const SizedBox(height: 4),
          itemCount: _sectionDefinitions.length,
        ),
      ),
    );
  }

  Widget? _buildBottomNavigation() {
    return NavigationBar(
      height: 72,
      selectedIndex: _selectedIndex,
      onDestinationSelected: (index) => _onSectionSelected(index),
      destinations: [
        for (final entry in _sectionDefinitions)
          NavigationDestination(
            icon: Icon(entry.icon),
            label: entry.label,
          ),
      ],
    );
  }

  Widget _buildVehicleHeaderCard(dynamic vehicle) {
    return Card(
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
    );
  }

  Widget _buildLoadingCard() {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
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
          ],
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
          ],
        ),
      ),
    );
  }

  Widget _buildServiceRecordsCard(BuildContext context, List<ServiceRecord> records, int vehicleId) {
    // Sort by date descending (most recent first)
    final sortedRecords = List<ServiceRecord>.from(records)
      ..sort((a, b) => b.date.compareTo(a.date));
    
    return Card(
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
    );
  }

  Widget _buildRemindersCard(BuildContext context, List<Reminder> reminders, int vehicleId) {
    return Card(
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
    );
  }

  Widget _buildStatisticsSummaryCard(BuildContext context, stats, {bool interactive = true}) {
    final content = Padding(
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
              if (interactive) const Icon(Icons.chevron_right),
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
    );

    if (!interactive) {
      return Card(child: content);
    }

    return Card(
      child: InkWell(
        onTap: () => context.push('${AppRoutes.statistics}?vehicleId=${widget.vehicleId}'),
        child: content,
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

  Widget _buildOdometerRecordsList(BuildContext context, List<OdometerRecord> records) {
    if (records.isEmpty) {
      return _buildEmptyStateCard(
        context,
        icon: Icons.speed,
        title: 'No odometer entries yet',
        subtitle: 'Add your first odometer reading to start tracking mileage.',
        actionLabel: 'Add Odometer Entry',
        onAction: () => context.push('${AppRoutes.addOdometer}?vehicleId=${widget.vehicleId}'),
      );
    }

    final sortedRecords = List<OdometerRecord>.from(records)
      ..sort((a, b) => b.date.compareTo(a.date));

    return Column(
      children: [
        for (final record in sortedRecords) ...[
          OdometerEntryCard(record: record),
          const SizedBox(height: 12),
        ],
        const SizedBox(height: 4),
        OutlinedButton.icon(
          onPressed: () => context.push('${AppRoutes.addOdometer}?vehicleId=${widget.vehicleId}'),
          icon: const Icon(Icons.add),
          label: const Text('Add Odometer Entry'),
        ),
      ],
    );
  }

  Widget _buildFuelRecordsList(BuildContext context, List<FuelRecord> records) {
    if (records.isEmpty) {
      return _buildEmptyStateCard(
        context,
        icon: Icons.local_gas_station,
        title: 'No fuel entries yet',
        subtitle: 'Log your first fill-up to begin tracking consumption and cost.',
        actionLabel: 'Add Fuel Entry',
        onAction: () => context.push('${AppRoutes.addFuel}?vehicleId=${widget.vehicleId}'),
      );
    }

    final sortedRecords = List<FuelRecord>.from(records)
      ..sort((a, b) => b.date.compareTo(a.date));

    return Column(
      children: [
        for (final record in sortedRecords) ...[
          FuelEntryCard(record: record),
          const SizedBox(height: 12),
        ],
        const SizedBox(height: 4),
        OutlinedButton.icon(
          onPressed: () => context.push('${AppRoutes.addFuel}?vehicleId=${widget.vehicleId}'),
          icon: const Icon(Icons.add),
          label: const Text('Add Fuel Entry'),
        ),
      ],
    );
  }

  Widget _buildServiceRecordsList(BuildContext context, List<ServiceRecord> records) {
    if (records.isEmpty) {
      return _buildEmptyStateCard(
        context,
        icon: Icons.build,
        title: 'No service records yet',
        subtitle: 'Track maintenance history to stay ahead of repairs.',
        actionLabel: 'Add Service Record',
        onAction: () => context.push('${AppRoutes.addService}?vehicleId=${widget.vehicleId}'),
      );
    }

    final sortedRecords = List<ServiceRecord>.from(records)
      ..sort((a, b) => b.date.compareTo(a.date));

    return Column(
      children: [
        for (final record in sortedRecords) ...[
          ServiceRecordCard(record: record),
          const SizedBox(height: 12),
        ],
        const SizedBox(height: 4),
        OutlinedButton.icon(
          onPressed: () => context.push('${AppRoutes.addService}?vehicleId=${widget.vehicleId}'),
          icon: const Icon(Icons.add),
          label: const Text('Add Service Record'),
        ),
      ],
    );
  }

  Widget _buildRemindersList(BuildContext context, List<Reminder> reminders) {
    if (reminders.isEmpty) {
      return _buildEmptyStateCard(
        context,
        icon: Icons.alarm_add,
        title: 'No reminders scheduled',
        subtitle: 'Set reminders for oil changes, inspections, and more.',
        actionLabel: 'Create Reminder',
        onAction: () => context.push('${AppRoutes.addReminder}?vehicleId=${widget.vehicleId}'),
      );
    }

    final sortedReminders = List<Reminder>.from(reminders)
      ..sort((a, b) => b.date.compareTo(a.date));

    return Column(
      children: [
        for (final reminder in sortedReminders) ...[
          ReminderCard(reminder: reminder),
          const SizedBox(height: 12),
        ],
        const SizedBox(height: 4),
        OutlinedButton.icon(
          onPressed: () => context.push('${AppRoutes.addReminder}?vehicleId=${widget.vehicleId}'),
          icon: const Icon(Icons.add),
          label: const Text('Create Reminder'),
        ),
      ],
    );
  }

  Widget _buildStatisticsDetailSection({
    required BuildContext context,
    required AsyncValue statisticsAsync,
    required AsyncValue<List<FuelRecord>> fuelRecordsAsync,
  }) {
    return statisticsAsync.when(
      data: (stats) {
        return fuelRecordsAsync.when(
          data: (fuelRecords) {
            final highestCost = fuelRecords.fold<double>(
              0,
              (prev, record) => record.cost > prev ? record.cost : prev,
            );

            return Column(
              children: [
                _buildStatisticsSummaryCard(context, stats),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Fuel Insights',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        if (fuelRecords.isEmpty)
                          Text(
                            'No fuel history yet. Add entries to see trends here.',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.grey,
                                ),
                          )
                        else ...[
                          _buildStatRow(
                            'Highest Cost Fill-up',
                            '\$${highestCost.toStringAsFixed(2)}',
                          ),
                          _buildStatRow(
                            'Avg Price/Gallon',
                            stats.averagePricePerGallon > 0
                                ? '\$${stats.averagePricePerGallon.toStringAsFixed(2)}'
                                : 'N/A',
                          ),
                        ],
                        const SizedBox(height: 16),
                        OutlinedButton.icon(
                          onPressed: () => context.push('${AppRoutes.statistics}?vehicleId=${widget.vehicleId}'),
                          icon: const Icon(Icons.open_in_new),
                          label: const Text('Open full analytics'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
          loading: () => _buildLoadingCard(),
          error: (error, stack) => const SizedBox(),
        );
      },
      loading: () => _buildLoadingCard(),
      error: (error, stack) => const SizedBox(),
    );
  }

  Widget _buildEmptyStateCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required String actionLabel,
    required VoidCallback onAction,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 12),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: onAction,
              child: Text(actionLabel),
            ),
          ],
        ),
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
            ListTile(
              leading: const Icon(Icons.assignment),
              title: const Text('Manage Plan Records'),
              onTap: () {
                Navigator.pop(context);
                context.push('${AppRoutes.plan}?vehicleId=$vehicleId');
              },
            ),
          ],
        ),
      ),
    );
  }
}