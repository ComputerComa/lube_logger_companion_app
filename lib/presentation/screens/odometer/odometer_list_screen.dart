import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lube_logger_companion_app/presentation/routing/app_router.dart';
import 'package:lube_logger_companion_app/providers/vehicle_provider.dart';
import 'package:lube_logger_companion_app/providers/odometer_provider.dart';
import 'package:lube_logger_companion_app/presentation/widgets/odometer_entry_card.dart';

class OdometerListScreen extends ConsumerStatefulWidget {
  final int? initialVehicleId;
  
  const OdometerListScreen({super.key, this.initialVehicleId});

  @override
  ConsumerState<OdometerListScreen> createState() => _OdometerListScreenState();
}

class _OdometerListScreenState extends ConsumerState<OdometerListScreen> {
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
        title: const Text('Odometer Records'),
      ),
      body: vehiclesAsync.when(
        data: (vehicles) {
          if (vehicles.isEmpty) {
            return const Center(child: Text('No vehicles found'));
          }

          // Auto-select initial vehicle or first vehicle if none selected
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
                ? '${AppRoutes.addOdometer}?vehicleId=$_selectedVehicleId'
                : AppRoutes.addOdometer,
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildRecordsList(int vehicleId) {
    final recordsAsync = ref.watch(odometerRecordsProvider(vehicleId));

    return recordsAsync.when(
      data: (records) {
        if (records.isEmpty) {
          return const Center(child: Text('No odometer records found'));
        }

        // Sort by date descending
        final sortedRecords = List.from(records)
          ..sort((a, b) => b.date.compareTo(a.date));

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(odometerRecordsProvider(vehicleId));
          },
          child: ListView.builder(
            itemCount: sortedRecords.length,
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final record = sortedRecords[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: OdometerEntryCard(record: record),
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
              onPressed: () => ref.invalidate(odometerRecordsProvider(vehicleId)),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
