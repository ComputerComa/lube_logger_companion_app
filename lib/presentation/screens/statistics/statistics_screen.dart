import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:lube_logger_companion_app/providers/vehicle_provider.dart';
import 'package:lube_logger_companion_app/providers/statistics_provider.dart';
import 'package:lube_logger_companion_app/providers/fuel_provider.dart';
import 'package:lube_logger_companion_app/data/models/fuel_record.dart';

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
    final fuelRecordsAsync = ref.watch(fuelRecordsProvider(vehicleId));

    return statisticsAsync.when(
      data: (stats) {
        return fuelRecordsAsync.when(
          data: (fuelRecords) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Summary Statistics Cards
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
                  
                  const SizedBox(height: 24),
                  
                  // Charts Section
                  if (fuelRecords.isNotEmpty) ...[
                    // Fuel Cost Over Time Chart
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Fuel Cost Over Time',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              height: 200,
                              child: _buildFuelCostChart(fuelRecords),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // MPG Over Time Chart
                    if (fuelRecords.length > 1) ...[
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'MPG Over Time',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                height: 200,
                                child: _buildMpgChart(fuelRecords),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                    ],
                    
                    // Fuel Consumption Chart
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Fuel Consumption',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              height: 200,
                              child: _buildFuelConsumptionChart(fuelRecords),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Price Per Gallon Chart
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Price Per Gallon Over Time',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              height: 200,
                              child: _buildPricePerGallonChart(fuelRecords),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => const SizedBox.shrink(),
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

  Widget _buildFuelCostChart(List<FuelRecord> fuelRecords) {
    final sortedRecords = List.from(fuelRecords)
      ..sort((a, b) => a.date.compareTo(b.date));
    
    if (sortedRecords.isEmpty) {
      return const Center(child: Text('No data available'));
    }

    final maxCost = sortedRecords.map((r) => r.cost).reduce((a, b) => a > b ? a : b);
    final minCost = sortedRecords.map((r) => r.cost).reduce((a, b) => a < b ? a : b);
    final costRange = maxCost - minCost;

    final spots = sortedRecords.asMap().entries.map((entry) {
      final index = entry.key.toDouble();
      final record = entry.value;
      return FlSpot(index, record.cost);
    }).toList();

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: costRange > 0 ? costRange / 4 : 1,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey.withValues(alpha: 0.2),
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: (sortedRecords.length / 4).ceil().toDouble(),
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < sortedRecords.length) {
                  final record = sortedRecords[index];
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      DateFormat('MM/dd').format(record.date),
                      style: const TextStyle(fontSize: 10),
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 50,
              getTitlesWidget: (value, meta) {
                return Text(
                  '\$${value.toStringAsFixed(0)}',
                  style: const TextStyle(fontSize: 10),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: Colors.orange,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: sortedRecords.length <= 20,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: Colors.orange,
                  strokeWidth: 2,
                  strokeColor: Colors.white,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.orange.withValues(alpha: 0.1),
            ),
          ),
        ],
        minY: minCost > 0 ? (minCost * 0.9) : 0,
        maxY: maxCost * 1.1,
      ),
    );
  }

  Widget _buildMpgChart(List<FuelRecord> fuelRecords) {
    final sortedRecords = List.from(fuelRecords)
      ..sort((a, b) => a.date.compareTo(b.date));
    
    if (sortedRecords.length < 2) {
      return const Center(child: Text('Need at least 2 fuel entries to calculate MPG'));
    }

    // Calculate MPG for each pair of consecutive records
    final mpgData = <FlSpot>[];
    for (var i = 1; i < sortedRecords.length; i++) {
      final current = sortedRecords[i];
      final previous = sortedRecords[i - 1];
      final miles = current.odometer - previous.odometer;
      if (miles > 0 && current.gallons > 0) {
        final mpg = miles / current.gallons;
        mpgData.add(FlSpot((i - 1).toDouble(), mpg));
      }
    }

    if (mpgData.isEmpty) {
      return const Center(child: Text('No valid MPG data'));
    }

    final maxMpg = mpgData.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    final minMpg = mpgData.map((s) => s.y).reduce((a, b) => a < b ? a : b);
    final mpgRange = maxMpg - minMpg;

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: mpgRange > 0 ? mpgRange / 4 : 1,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey.withValues(alpha: 0.2),
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: (mpgData.length / 4).ceil().toDouble(),
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < mpgData.length && index + 1 < sortedRecords.length) {
                  final record = sortedRecords[index + 1];
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      DateFormat('MM/dd').format(record.date),
                      style: const TextStyle(fontSize: 10),
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toStringAsFixed(0),
                  style: const TextStyle(fontSize: 10),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: mpgData,
            isCurved: true,
            color: Colors.purple,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: mpgData.length <= 20,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: Colors.purple,
                  strokeWidth: 2,
                  strokeColor: Colors.white,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.purple.withValues(alpha: 0.1),
            ),
          ),
        ],
        minY: minMpg > 0 ? (minMpg * 0.9) : 0,
        maxY: maxMpg * 1.1,
      ),
    );
  }

  Widget _buildFuelConsumptionChart(List<FuelRecord> fuelRecords) {
    final sortedRecords = List.from(fuelRecords)
      ..sort((a, b) => a.date.compareTo(b.date));
    
    if (sortedRecords.isEmpty) {
      return const Center(child: Text('No data available'));
    }

    final maxGallons = sortedRecords.map((r) => r.gallons).reduce((a, b) => a > b ? a : b);
    final minGallons = sortedRecords.map((r) => r.gallons).reduce((a, b) => a < b ? a : b);
    final gallonsRange = maxGallons - minGallons;

    final barGroups = sortedRecords.asMap().entries.map((entry) {
      final index = entry.key;
      final record = entry.value;
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: record.gallons,
            color: Colors.red,
            width: 16,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
        ],
      );
    }).toList();

    return BarChart(
      BarChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: gallonsRange > 0 ? gallonsRange / 4 : 1,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey.withValues(alpha: 0.2),
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: (sortedRecords.length / 4).ceil().toDouble(),
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < sortedRecords.length) {
                  final record = sortedRecords[index];
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      DateFormat('MM/dd').format(record.date),
                      style: const TextStyle(fontSize: 10),
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toStringAsFixed(1),
                  style: const TextStyle(fontSize: 10),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
        ),
        barGroups: barGroups,
        minY: minGallons > 0 ? (minGallons * 0.9) : 0,
        maxY: maxGallons * 1.1,
      ),
    );
  }

  Widget _buildPricePerGallonChart(List<FuelRecord> fuelRecords) {
    final sortedRecords = List.from(fuelRecords)
      ..sort((a, b) => a.date.compareTo(b.date));
    
    if (sortedRecords.isEmpty) {
      return const Center(child: Text('No data available'));
    }

    final priceData = sortedRecords.map((r) => r.calculatedPricePerGallon).toList();
    final maxPrice = priceData.reduce((a, b) => a > b ? a : b);
    final minPrice = priceData.reduce((a, b) => a < b ? a : b);
    final priceRange = maxPrice - minPrice;

    final spots = sortedRecords.asMap().entries.map((entry) {
      final index = entry.key.toDouble();
      final record = entry.value;
      return FlSpot(index, record.calculatedPricePerGallon);
    }).toList();

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: priceRange > 0 ? priceRange / 4 : 0.1,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey.withValues(alpha: 0.2),
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: (sortedRecords.length / 4).ceil().toDouble(),
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < sortedRecords.length) {
                  final record = sortedRecords[index];
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      DateFormat('MM/dd').format(record.date),
                      style: const TextStyle(fontSize: 10),
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 50,
              getTitlesWidget: (value, meta) {
                return Text(
                  '\$${value.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 10),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: Colors.teal,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: sortedRecords.length <= 20,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: Colors.teal,
                  strokeWidth: 2,
                  strokeColor: Colors.white,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.teal.withValues(alpha: 0.1),
            ),
          ),
        ],
        minY: minPrice > 0 ? (minPrice * 0.95) : 0,
        maxY: maxPrice * 1.05,
      ),
    );
  }
}
