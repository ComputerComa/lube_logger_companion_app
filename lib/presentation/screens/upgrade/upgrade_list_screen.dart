import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lube_logger_companion_app/presentation/routing/app_router.dart';
import 'package:lube_logger_companion_app/providers/vehicle_provider.dart';
import 'package:lube_logger_companion_app/providers/upgrade_provider.dart';
import 'package:lube_logger_companion_app/presentation/widgets/upgrade_record_card.dart';

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
                child: UpgradeRecordCard(record: record),
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
}

