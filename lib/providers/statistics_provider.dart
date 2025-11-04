import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lube_logger_companion_app/data/models/statistics.dart';
import 'package:lube_logger_companion_app/data/models/fuel_record.dart';
import 'package:lube_logger_companion_app/data/models/odometer_record.dart';
import 'package:lube_logger_companion_app/providers/fuel_provider.dart';
import 'package:lube_logger_companion_app/providers/odometer_provider.dart';

final statisticsProvider = FutureProvider.family<VehicleStatistics, int>((ref, vehicleId) async {
  final fuelRecordsAsync = ref.watch(fuelRecordsProvider(vehicleId));
  final odometerRecordsAsync = ref.watch(odometerRecordsProvider(vehicleId));
  final latestOdometerAsync = ref.watch(latestOdometerProvider(vehicleId));
  
  return fuelRecordsAsync.when(
    data: (fuelRecords) => odometerRecordsAsync.when(
      data: (odometerRecords) => latestOdometerAsync.when(
        data: (latestOdometer) => _calculateStatistics(
          vehicleId: vehicleId,
          fuelRecords: fuelRecords,
          odometerRecords: odometerRecords,
          latestOdometer: latestOdometer,
        ),
        loading: () => VehicleStatistics.empty(vehicleId),
        error: (_, __) => VehicleStatistics.empty(vehicleId),
      ),
      loading: () => VehicleStatistics.empty(vehicleId),
      error: (_, __) => VehicleStatistics.empty(vehicleId),
    ),
    loading: () => VehicleStatistics.empty(vehicleId),
    error: (_, __) => VehicleStatistics.empty(vehicleId),
  );
});

VehicleStatistics _calculateStatistics({
  required int vehicleId,
  required List<FuelRecord> fuelRecords,
  required List<OdometerRecord> odometerRecords,
  required int latestOdometer,
}) {
  double totalFuelCost = 0.0;
  double totalGallons = 0.0;
  int totalMiles = 0;
  
  // Calculate fuel statistics
  for (final record in fuelRecords) {
    totalFuelCost += record.cost;
    totalGallons += record.gallons;
  }
  
  // Calculate miles from odometer records
  if (odometerRecords.length >= 2) {
    final sorted = List<OdometerRecord>.from(odometerRecords)
      ..sort((a, b) => a.odometer.compareTo(b.odometer));
    totalMiles = sorted.last.odometer - sorted.first.odometer;
  }
  
  // Calculate average MPG
  double averageMpg = 0.0;
  if (totalGallons > 0 && totalMiles > 0) {
    averageMpg = totalMiles / totalGallons;
  } else if (fuelRecords.isNotEmpty) {
    // Calculate MPG from individual fuel records
    double totalMpg = 0.0;
    int validRecords = 0;
    
    for (var i = 1; i < fuelRecords.length; i++) {
      final current = fuelRecords[i];
      final previous = fuelRecords[i - 1];
      final miles = current.odometer - previous.odometer;
      if (miles > 0 && current.gallons > 0) {
        totalMpg += miles / current.gallons;
        validRecords++;
      }
    }
    
    if (validRecords > 0) {
      averageMpg = totalMpg / validRecords;
    }
  }
  
  // Calculate average price per gallon
  double averagePricePerGallon = 0.0;
  if (totalGallons > 0 && totalFuelCost > 0) {
    averagePricePerGallon = totalFuelCost / totalGallons;
  }
  
  return VehicleStatistics(
    vehicleId: vehicleId,
    latestOdometer: latestOdometer > 0 ? latestOdometer : null,
    totalMiles: totalMiles,
    totalFuelCost: totalFuelCost,
    totalGallons: totalGallons,
    averageMpg: averageMpg,
    averagePricePerGallon: averagePricePerGallon,
    totalFuelEntries: fuelRecords.length,
    totalOdometerEntries: odometerRecords.length,
  );
}
