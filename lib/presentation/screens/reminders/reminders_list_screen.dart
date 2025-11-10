import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lube_logger_companion_app/presentation/routing/app_router.dart';
import 'package:lube_logger_companion_app/providers/vehicle_provider.dart';
import 'package:lube_logger_companion_app/providers/reminder_provider.dart';
import 'package:lube_logger_companion_app/presentation/widgets/reminder_card.dart';
import 'package:lube_logger_companion_app/data/models/reminder.dart';

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
                  key: ValueKey(_selectedVehicleId),
                  initialValue: _selectedVehicleId,
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
                    }),
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.push(
            _selectedVehicleId != null
                ? '${AppRoutes.addReminder}?vehicleId=$_selectedVehicleId'
                : AppRoutes.addReminder,
          );
        },
        tooltip: 'Add Reminder',
        child: const Icon(Icons.add),
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
          ..sort((a, b) => b.date.compareTo(a.date));

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
                child: ReminderCard(
                  reminder: reminder,
                  onLongPress: () => _showReminderActions(context, reminder, vehicleId),
                ),
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

  void _showReminderActions(
    BuildContext context,
    Reminder reminder,
    int? vehicleId,
  ) {
    final rootContext = this.context;
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit Reminder'),
              onTap: () {
                Navigator.pop(context);
                if (!mounted) return;
                rootContext.push(
                  '${AppRoutes.editReminder}?vehicleId=${vehicleId ?? reminder.vehicleId}',
                  extra: reminder,
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete Reminder'),
              onTap: () async {
                Navigator.pop(context);
                final confirmed = await showDialog<bool>(
                  context: rootContext,
                  builder: (context) => AlertDialog(
                    title: const Text('Delete Reminder'),
                    content: const Text('Are you sure you want to delete this reminder?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: TextButton.styleFrom(foregroundColor: Colors.red),
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                );
                if (confirmed == true) {
                  try {
                    await ref.read(deleteReminderProvider((
                      id: reminder.id,
                      vehicleId: vehicleId ?? reminder.vehicleId,
                    )).future);
                    if (!mounted) return;
                    ScaffoldMessenger.of(this.context).showSnackBar(
                      const SnackBar(content: Text('Reminder deleted')),
                    );
                  } catch (e) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(this.context).showSnackBar(
                      SnackBar(content: Text('Error deleting reminder: $e')),
                    );
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
