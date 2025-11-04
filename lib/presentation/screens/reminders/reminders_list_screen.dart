import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lube_logger_companion_app/presentation/routing/app_router.dart';
import 'package:lube_logger_companion_app/providers/vehicle_provider.dart';
import 'package:lube_logger_companion_app/providers/reminder_provider.dart';
import 'package:lube_logger_companion_app/presentation/widgets/reminder_card.dart';

class RemindersListScreen extends ConsumerStatefulWidget {
  final int? initialVehicleId;
  
  const RemindersListScreen({super.key, this.initialVehicleId});

  @override
  ConsumerState<RemindersListScreen> createState() => _RemindersListScreenState();
}

class _RemindersListScreenState extends ConsumerState<RemindersListScreen> {
  late int? _selectedVehicleId;
  
  @override
  void initState() {
    super.initState();
    _selectedVehicleId = widget.initialVehicleId;
  }

  @override
  Widget build(BuildContext context) {
    final vehiclesAsync = ref.watch(vehiclesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reminders'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              context.push(
                _selectedVehicleId != null
                    ? '${AppRoutes.addReminder}?vehicleId=$_selectedVehicleId'
                    : AppRoutes.addReminder,
              );
            },
          ),
        ],
      ),
      body: vehiclesAsync.when(
        data: (vehicles) {
          if (vehicles.isEmpty) {
            return const Center(child: Text('No vehicles found'));
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: DropdownButtonFormField<int>(
                  value: _selectedVehicleId,
                  decoration: const InputDecoration(
                    labelText: 'Select Vehicle (optional)',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem<int>(
                      value: null,
                      child: Text('All Vehicles'),
                    ),
                    ...vehicles.map((vehicle) {
                      return DropdownMenuItem<int>(
                        value: vehicle.id,
                        child: Text(vehicle.displayName),
                      );
                    }).toList(),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedVehicleId = value;
                    });
                  },
                ),
              ),
              Expanded(
                child: _buildRemindersList(_selectedVehicleId),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Error: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(vehiclesProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRemindersList(int? vehicleId) {
    final remindersAsync = ref.watch(remindersProvider(vehicleId));

    return remindersAsync.when(
      data: (reminders) {
        if (reminders.isEmpty) {
          return const Center(child: Text('No reminders found'));
        }

        final sortedReminders = List.from(reminders)
          ..sort((a, b) => a.date.compareTo(b.date));

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(remindersProvider(vehicleId));
          },
          child: ListView.builder(
            itemCount: sortedReminders.length,
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final reminder = sortedReminders[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: ReminderCard(reminder: reminder),
              );
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Error: $error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.invalidate(remindersProvider(vehicleId)),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
