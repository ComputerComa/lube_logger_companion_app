import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lube_logger_companion_app/data/models/plan_record.dart';
import 'package:lube_logger_companion_app/presentation/routing/app_router.dart';
import 'package:lube_logger_companion_app/providers/plan_provider.dart';
import 'package:lube_logger_companion_app/providers/vehicle_provider.dart';

class PlanListScreen extends ConsumerStatefulWidget {
  final int? initialVehicleId;

  const PlanListScreen({super.key, this.initialVehicleId});

  @override
  ConsumerState<PlanListScreen> createState() => _PlanListScreenState();
}

class _PlanListScreenState extends ConsumerState<PlanListScreen> {
  int? _selectedVehicleId;

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
        title: const Text('Plan Records'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            vehiclesAsync.when(
              data: (vehicles) {
                if (vehicles.isEmpty) {
                  return const Text('No vehicles found');
                }
                _selectedVehicleId ??= vehicles.first.id;
                return DropdownButtonFormField<int>(
                  key: ValueKey(_selectedVehicleId),
                  initialValue: _selectedVehicleId,
                  decoration: const InputDecoration(
                    labelText: 'Vehicle',
                    border: OutlineInputBorder(),
                  ),
                  items: vehicles
                      .map(
                        (vehicle) => DropdownMenuItem<int>(
                          value: vehicle.id,
                          child: Text(vehicle.displayName),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedVehicleId = value;
                    });
                  },
                );
              },
              loading: () => const CircularProgressIndicator(),
              error: (error, stackTrace) => Text('Error: $error'),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _selectedVehicleId == null
                  ? const Center(child: Text('Select a vehicle to view plan records'))
                  : Consumer(
                      builder: (context, ref, _) {
                        final plansAsync = ref.watch(planRecordsProvider(_selectedVehicleId!));

                        return plansAsync.when(
                          data: (records) {
                            if (records.isEmpty) {
                              return const Center(child: Text('No plan records found'));
                            }
                            return RefreshIndicator(
                              onRefresh: () async {
                                ref.invalidate(planRecordsProvider(_selectedVehicleId!));
                              },
                              child: ListView.separated(
                                physics: const AlwaysScrollableScrollPhysics(),
                                itemBuilder: (context, index) {
                                  final record = records[index];
                                  return GestureDetector(
                                    onLongPress: () => _showPlanActions(
                                      context,
                                      record,
                                      _selectedVehicleId!,
                                    ),
                                    child: _PlanRecordCard(record: record),
                                  );
                                },
                                separatorBuilder: (context, index) => const SizedBox(height: 12),
                                itemCount: records.length,
                              ),
                            );
                          },
                          loading: () => const Center(child: CircularProgressIndicator()),
                          error: (error, stackTrace) => Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('Error: $error'),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: () => ref.invalidate(planRecordsProvider(_selectedVehicleId!)),
                                  child: const Text('Retry'),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: _selectedVehicleId == null
          ? null
          : FloatingActionButton(
              onPressed: () {
                context.push('${AppRoutes.addPlan}?vehicleId=$_selectedVehicleId');
              },
              tooltip: 'Add Plan Record',
              child: const Icon(Icons.add),
            ),
    );
  }

  void _showPlanActions(
    BuildContext context,
    PlanRecord record,
    int vehicleId,
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
              title: const Text('Edit Plan'),
              onTap: () {
                Navigator.pop(context);
                if (!mounted) return;
                rootContext.push(
                  '${AppRoutes.editPlan}?vehicleId=$vehicleId',
                  extra: record,
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete Plan'),
              onTap: () async {
                Navigator.pop(context);
                final confirmed = await showDialog<bool>(
                  context: rootContext,
                  builder: (context) => AlertDialog(
                    title: const Text('Delete Plan Record'),
                    content: const Text('Are you sure you want to delete this plan record?'),
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
                    await ref.read(deletePlanRecordProvider((
                      id: record.id,
                      vehicleId: vehicleId,
                    )).future);
                    if (!mounted) return;
                    ScaffoldMessenger.of(this.context).showSnackBar(
                      const SnackBar(content: Text('Plan record deleted')),
                    );
                  } catch (e) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(this.context).showSnackBar(
                      SnackBar(content: Text('Error deleting plan: $e')),
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

class _PlanRecordCard extends ConsumerWidget {
  final PlanRecord record;

  const _PlanRecordCard({required this.record});

  Color _priorityColor(BuildContext context) {
    switch (record.priority) {
      case PlanRecordPriority.low:
        return Colors.green;
      case PlanRecordPriority.normal:
        return Theme.of(context).colorScheme.primary;
      case PlanRecordPriority.critical:
        return Colors.red;
      case PlanRecordPriority.unknown:
        return Colors.grey;
    }
  }

  String _progressLabel() {
    switch (record.progress) {
      case PlanRecordProgress.backlog:
        return 'Backlog';
      case PlanRecordProgress.inProgress:
        return 'In Progress';
      case PlanRecordProgress.testing:
        return 'Testing';
      case PlanRecordProgress.done:
        return 'Done';
      case PlanRecordProgress.unknown:
        return 'Unknown';
    }
  }

  String _typeLabel() {
    switch (record.type) {
      case PlanRecordType.service:
        return 'Service';
      case PlanRecordType.repair:
        return 'Repair';
      case PlanRecordType.upgrade:
        return 'Upgrade';
      case PlanRecordType.unknown:
        return 'Other';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    record.description,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                Text(
                  '\$${record.cost.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                Chip(
                  label: Text(_typeLabel()),
                  avatar: const Icon(Icons.category, size: 18),
                ),
                Chip(
                  label: Text(
                    record.priority == PlanRecordPriority.unknown
                        ? 'Priority: Unknown'
                        : 'Priority: ${_priorityLabel()}',
                  ),
                  backgroundColor: _priorityColor(context).withValues(alpha: 0.1),
                  labelStyle: TextStyle(color: _priorityColor(context)),
                ),
                Chip(
                  label: Text('Progress: ${_progressLabel()}'),
                  avatar: const Icon(Icons.timeline, size: 18),
                ),
              ],
            ),
            if (record.notes != null && record.notes!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                record.notes!,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _priorityLabel() {
    switch (record.priority) {
      case PlanRecordPriority.low:
        return 'Low';
      case PlanRecordPriority.normal:
        return 'Normal';
      case PlanRecordPriority.critical:
        return 'Critical';
      case PlanRecordPriority.unknown:
        return 'Unknown';
    }
  }
}

