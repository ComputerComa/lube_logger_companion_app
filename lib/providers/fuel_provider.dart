import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lube_logger_companion_app/data/models/fuel_record.dart';
import 'package:lube_logger_companion_app/providers/auth_provider.dart';
import 'package:lube_logger_companion_app/providers/auth_helpers.dart';
import 'package:lube_logger_companion_app/providers/vehicle_provider.dart';
import 'package:lube_logger_companion_app/services/cached_data_helper.dart';

final fuelRecordsProvider = FutureProvider.family<List<FuelRecord>, int>((ref, vehicleId) async {
  final authState = ref.watch(authStateProvider);
  final repository = ref.watch(repositoryProvider);
  
  // Get credentials from storage
  final credentials = getCredentials(authState);
  
  final cacheKey = CachedDataHelper.vehicleCacheKey(
    'fuel_records',
    vehicleId,
    credentials.serverUrl,
    credentials.username,
  );
  
  return await CachedDataHelper.fetchWithCache<FuelRecord>(
    fetchFn: () => repository.getFuelRecords(
      serverUrl: credentials.serverUrl,
      username: credentials.username,
      password: credentials.password,
      vehicleId: vehicleId,
    ),
    cacheKey: cacheKey,
    fromJson: (json) => FuelRecord.fromJson(json),
    toJson: (record) => record.toJson(),
  );
});

final addFuelProvider = FutureProvider.family<void, ({
  int vehicleId,
  DateTime date,
  int odometer,
  double gallons,
  double cost,
  bool isFillToFull,
  bool missedFuelUp,
  List<String> tags,
  String? notes,
})>((ref, params) async {
  final authState = ref.watch(authStateProvider);
  final repository = ref.watch(repositoryProvider);
  
  // Get credentials from storage
  final credentials = getCredentials(authState);
  
  await repository.addFuelRecord(
    serverUrl: credentials.serverUrl,
    username: credentials.username,
    password: credentials.password,
    vehicleId: params.vehicleId,
    date: params.date,
    odometer: params.odometer,
    gallons: params.gallons,
    cost: params.cost,
    isFillToFull: params.isFillToFull,
    missedFuelUp: params.missedFuelUp,
    tags: params.tags,
    notes: params.notes,
  );
  
  // Invalidate related providers to refresh data
  ref.invalidate(fuelRecordsProvider(params.vehicleId));
});

final updateFuelProvider = FutureProvider.family<void, ({
  int id,
  DateTime date,
  int odometer,
  double gallons,
  double? cost,
  String? notes,
})>((ref, params) async {
  final authState = ref.watch(authStateProvider);
  final repository = ref.watch(repositoryProvider);
  
  // Get credentials from storage
  final credentials = getCredentials(authState);
  
  await repository.updateFuelRecord(
    serverUrl: credentials.serverUrl,
    username: credentials.username,
    password: credentials.password,
    id: params.id,
    date: params.date,
    odometer: params.odometer,
    gallons: params.gallons,
    cost: params.cost,
    notes: params.notes,
  );
  
  // Invalidate all fuel providers - in production, track vehicleId per record
  ref.invalidate(fuelRecordsProvider);
});

final deleteFuelProvider = FutureProvider.family<void, ({
  int id,
  int vehicleId,
})>((ref, params) async {
  final authState = ref.watch(authStateProvider);
  final repository = ref.watch(repositoryProvider);
  
  // Get credentials from storage
  final credentials = getCredentials(authState);
  
  await repository.deleteFuelRecord(
    serverUrl: credentials.serverUrl,
    username: credentials.username,
    password: credentials.password,
    id: params.id,
  );
  
  // Invalidate related providers to refresh data
  ref.invalidate(fuelRecordsProvider(params.vehicleId));
});
