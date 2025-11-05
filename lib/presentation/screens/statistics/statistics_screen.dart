import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lube_logger_companion_app/providers/vehicle_provider.dart';
import 'package:lube_logger_companion_app/providers/statistics_provider.dart';

class StatisticsScreen extends ConsumerStatefulWidget {
  final int? initialVehicleId;
  
  const StatisticsScreen({super.key, this.initialVehicleId});

  @override
  ConsumerState<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends ConsumerState<StatisticsScreen> {
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
        title: const Text('Statistics'),
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
                  child: _buildStatistics(_selectedVehicleId!),
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

  Widget _buildStatistics(int vehicleId) {
    final statisticsAsync = ref.watch(statisticsProvider(vehicleId));

    return statisticsAsync.when(
      data: (stats) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Vehicle Statistics',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      _buildStatCard(
                        'Latest Odometer',
                        stats.latestOdometer != null
                            ? '${stats.latestOdometer} miles'
                            : 'N/A',
                        Icons.speed,
                        Colors.green,
                      ),
                      const SizedBox(height: 16),
                      _buildStatCard(
                        'Total Miles',
                        '${stats.totalMiles} miles',
                        Icons.straighten,
                        Colors.blue,
                      ),
                      const SizedBox(height: 16),
                      _buildStatCard(
                        'Total Fuel Cost',
                        '\$${stats.totalFuelCost.toStringAsFixed(2)}',
                        Icons.attach_money,
                        Colors.orange,
                      ),
                      const SizedBox(height: 16),
                      _buildStatCard(
                        'Total Gallons',
                        '${stats.totalGallons.toStringAsFixed(2)} gallons',
                        Icons.local_gas_station,
                        Colors.red,
                      ),
                      if (stats.averageMpg > 0) ...[
                        const SizedBox(height: 16),
                        _buildStatCard(
                          'Average MPG',
                          '${stats.averageMpg.toStringAsFixed(1)} MPG',
                          Icons.speed,
                          Colors.purple,
                        ),
                      ],
                      if (stats.averagePricePerGallon > 0) ...[
                        const SizedBox(height: 16),
                        _buildStatCard(
                          'Avg Price/Gallon',
                          '\$${stats.averagePricePerGallon.toStringAsFixed(2)}',
                          Icons.local_gas_station,
                          Colors.teal,
                        ),
                      ],
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatCard(
                            'Fuel Entries',
                            '${stats.totalFuelEntries}',
                            Icons.list,
                            Colors.grey,
                            flex: 1,
                          ),
                          const SizedBox(width: 16),
                          _buildStatCard(
                            'Odometer Entries',
                            '${stats.totalOdometerEntries}',
                            Icons.list,
                            Colors.grey,
                            flex: 1,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
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
              onPressed: () => ref.invalidate(statisticsProvider(vehicleId)),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color, {
    int flex = 0,
  }) {
    final widget = Card(
      color: color.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    if (flex > 0) {
      return Expanded(child: widget);
    }
    return widget;
  }
}
