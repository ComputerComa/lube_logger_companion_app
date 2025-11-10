import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lube_logger_companion_app/presentation/routing/app_router.dart';
import 'package:lube_logger_companion_app/providers/vehicle_provider.dart';
import 'package:lube_logger_companion_app/providers/upgrade_provider.dart';
import 'package:lube_logger_companion_app/presentation/widgets/upgrade_record_card.dart';
import 'package:lube_logger_companion_app/data/models/upgrade_record.dart';

class UpgradeListScreen extends ConsumerStatefulWidget {
  final int? initialVehicleId;
  
  const UpgradeListScreen({super.key, this.initialVehicleId});

  @override
  ConsumerState<UpgradeListScreen> createState() => _UpgradeListScreenState();
}

class _UpgradeListScreenState extends ConsumerState<UpgradeListScreen> {
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
        title: const Text('Upgrade Records'),
      ),
      body: vehiclesAsync.when(
        data: (vehicles) {
          if (vehicles.isEmpty) {
            return const Center(child: Text('No vehicles found'));
          }

          if (_selectedVehicleId == null && vehicles.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              setState(() {
                _selectedVehicleId = widget.initialVehicleId ?? vehicles.first.id;
              });
            });
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: DropdownButtonFormField<int>(
                  key: ValueKey(_selectedVehicleId),
                  initialValue: _selectedVehicleId,
                  decoration: const InputDecoration(
                    labelText: 'Select Vehicle',
                    border: OutlineInputBorder(),
                  ),
                  items: vehicles.map((vehicle) {
                    return DropdownMenuItem<int>(
                      value: vehicle.id,
                      child: Text(vehicle.displayName),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedVehicleId = value;
                    });
                  },
                ),
              ),
              if (_selectedVehicleId != null)
                Expanded(
                  child: _buildRecordsList(_selectedVehicleId!),
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
                ? '${AppRoutes.addUpgrade}?vehicleId=$_selectedVehicleId'
                : AppRoutes.addUpgrade,
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildRecordsList(int vehicleId) {
    final recordsAsync = ref.watch(upgradeRecordsProvider(vehicleId));

    return recordsAsync.when(
      data: (records) {
        if (records.isEmpty) {
          return const Center(child: Text('No upgrade records found'));
        }

        final sortedRecords = List.from(records)
          ..sort((a, b) => b.date.compareTo(a.date));

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(upgradeRecordsProvider(vehicleId));
          },
          child: ListView.builder(
            itemCount: sortedRecords.length,
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final record = sortedRecords[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: UpgradeRecordCard(
                  record: record,
                  onLongPress: () => _showUpgradeActions(context, record, vehicleId),
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
              onPressed: () => ref.invalidate(upgradeRecordsProvider(vehicleId)),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  void _showUpgradeActions(
    BuildContext context,
    UpgradeRecord record,
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
              title: const Text('Edit Record'),
              onTap: () {
                Navigator.pop(context);
                if (!mounted) return;
                rootContext.push(
                  '${AppRoutes.editUpgrade}?vehicleId=$vehicleId',
                  extra: record,
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete Record'),
              onTap: () async {
                Navigator.pop(context);
                final confirmed = await showDialog<bool>(
                  context: rootContext,
                  builder: (context) => AlertDialog(
                    title: const Text('Delete Upgrade Record'),
                    content: const Text('Are you sure you want to delete this upgrade record?'),
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
                    await ref.read(deleteUpgradeProvider((
                      id: record.id,
                      vehicleId: vehicleId,
                    )).future);
                    if (!mounted) return;
                    ScaffoldMessenger.of(this.context).showSnackBar(
                      const SnackBar(content: Text('Upgrade record deleted')),
                    );
                  } catch (e) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(this.context).showSnackBar(
                      SnackBar(content: Text('Error deleting record: $e')),
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

