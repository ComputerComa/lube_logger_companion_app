import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lube_logger_companion_app/data/models/odometer_record.dart';
import 'package:lube_logger_companion_app/data/models/extra_field.dart';
import 'package:lube_logger_companion_app/providers/auth_provider.dart';
import 'package:lube_logger_companion_app/providers/auth_helpers.dart';
import 'package:lube_logger_companion_app/providers/vehicle_provider.dart';
import 'package:lube_logger_companion_app/services/cached_data_helper.dart';

final odometerRecordsProvider = FutureProvider.family<List<OdometerRecord>, int>((ref, vehicleId) async {
  final authState = ref.watch(authStateProvider);
  final repository = ref.watch(repositoryProvider);
  
  // Get credentials from storage
  final credentials = getCredentials(authState);
  
  final cacheKey = CachedDataHelper.vehicleCacheKey(
    'odometer_records',
    vehicleId,
      credentials.serverUrl,
      credentials.username,
  );
  
  return await CachedDataHelper.fetchWithCache<OdometerRecord>(
    fetchFn: () => repository.getOdometerRecords(
      serverUrl: credentials.serverUrl,
      username: credentials.username,
      password: credentials.password,
      vehicleId: vehicleId,
    ),
    cacheKey: cacheKey,
    fromJson: (json) => OdometerRecord.fromJson(json),
    toJson: (record) => record.toJson(),
  );
});

final latestOdometerProvider = FutureProvider.family<int, int>((ref, vehicleId) async {
  final authState = ref.watch(authStateProvider);
  final repository = ref.watch(repositoryProvider);
  
  // Get credentials from storage
  final credentials = getCredentials(authState);
  
  return await repository.getLatestOdometer(
    serverUrl: credentials.serverUrl,
    username: credentials.username,
    password: credentials.password,
    vehicleId: vehicleId,
  );
});

final addOdometerProvider = FutureProvider.family<void, ({
  int vehicleId,
  DateTime date,
  int odometer,
  List<ExtraField>? extraFields,
})>((ref, params) async {
  final authState = ref.watch(authStateProvider);
  final repository = ref.watch(repositoryProvider);
  
  // Get credentials from storage
  final credentials = getCredentials(authState);
  
  await repository.addOdometerRecord(
    serverUrl: credentials.serverUrl,
    username: credentials.username,
    password: credentials.password,
    vehicleId: params.vehicleId,
    date: params.date,
    odometer: params.odometer,
    extraFields: params.extraFields,
  );
  
  // Invalidate related providers to refresh data
  ref.invalidate(odometerRecordsProvider(params.vehicleId));
  ref.invalidate(latestOdometerProvider(params.vehicleId));
});

final updateOdometerProvider = FutureProvider.family<void, ({
  int id,
  DateTime date,
  int odometer,
  int? initialOdometer,
  List<ExtraField>? extraFields,
})>((ref, params) async {
  final authState = ref.watch(authStateProvider);
  final repository = ref.watch(repositoryProvider);
  
  // Get credentials from storage
  final credentials = getCredentials(authState);
  
  // Get vehicle ID from the record (would need to fetch it or pass it)
  // For now, we'll invalidate all odometer providers
  await repository.updateOdometerRecord(
    serverUrl: credentials.serverUrl,
    username: credentials.username,
    password: credentials.password,
    id: params.id,
    date: params.date,
    odometer: params.odometer,
    initialOdometer: params.initialOdometer,
    extraFields: params.extraFields,
  );
  
  // Invalidate all odometer providers - in production, track vehicleId per record
  ref.invalidate(odometerRecordsProvider);
  ref.invalidate(latestOdometerProvider);
});

final deleteOdometerProvider = FutureProvider.family<void, ({
  int id,
  int vehicleId,
})>((ref, params) async {
  final authState = ref.watch(authStateProvider);
  final repository = ref.watch(repositoryProvider);
  
  // Get credentials from storage
  final credentials = getCredentials(authState);
  
  await repository.deleteOdometerRecord(
    serverUrl: credentials.serverUrl,
    username: credentials.username,
    password: credentials.password,
    id: params.id,
  );
  
  // Invalidate related providers to refresh data
  ref.invalidate(odometerRecordsProvider(params.vehicleId));
  ref.invalidate(latestOdometerProvider(params.vehicleId));
});
