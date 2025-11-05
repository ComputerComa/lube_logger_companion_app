import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lube_logger_companion_app/data/models/service_record.dart';
import 'package:lube_logger_companion_app/data/models/extra_field.dart';
import 'package:lube_logger_companion_app/providers/auth_provider.dart';
import 'package:lube_logger_companion_app/providers/auth_helpers.dart';
import 'package:lube_logger_companion_app/providers/vehicle_provider.dart';
import 'package:lube_logger_companion_app/services/cached_data_helper.dart';

final serviceRecordsProvider = FutureProvider.family<List<ServiceRecord>, int>((ref, vehicleId) async {
  final authState = ref.watch(authStateProvider);
  final repository = ref.watch(repositoryProvider);
  
  // Get credentials from storage
  final credentials = getCredentials(authState);
  
  final cacheKey = CachedDataHelper.vehicleCacheKey(
    'service_records',
    vehicleId,
      credentials.serverUrl,
      credentials.username,
  );
  
  return await CachedDataHelper.fetchWithCache<ServiceRecord>(
    fetchFn: () => repository.getServiceRecords(
      serverUrl: credentials.serverUrl,
      username: credentials.username,
      password: credentials.password,
      vehicleId: vehicleId,
    ),
    cacheKey: cacheKey,
    fromJson: (json) => ServiceRecord.fromJson(json),
    toJson: (record) => record.toJson(),
  );
});

final addServiceProvider = FutureProvider.family<void, ({
  int vehicleId,
  DateTime date,
  int odometer,
  String description,
  double cost,
  String? notes,
  List<ExtraField>? extraFields,
})>((ref, params) async {
  final authState = ref.watch(authStateProvider);
  final repository = ref.watch(repositoryProvider);
  
  // Get credentials from storage
  final credentials = getCredentials(authState);
  
  await repository.addServiceRecord(
    serverUrl: credentials.serverUrl,
    username: credentials.username,
    password: credentials.password,
    vehicleId: params.vehicleId,
    date: params.date,
    odometer: params.odometer,
    description: params.description,
    cost: params.cost,
    notes: params.notes,
    extraFields: params.extraFields,
  );
  
  // Invalidate related providers to refresh data
  ref.invalidate(serviceRecordsProvider(params.vehicleId));
});

final updateServiceProvider = FutureProvider.family<void, ({
  int id,
  DateTime date,
  int odometer,
  String description,
  double cost,
  String? notes,
  List<ExtraField>? extraFields,
  int vehicleId,
})>((ref, params) async {
  final authState = ref.watch(authStateProvider);
  final repository = ref.watch(repositoryProvider);
  
  // Get credentials from storage
  final credentials = getCredentials(authState);
  
  await repository.updateServiceRecord(
    serverUrl: credentials.serverUrl,
    username: credentials.username,
    password: credentials.password,
    id: params.id,
    date: params.date,
    odometer: params.odometer,
    description: params.description,
    cost: params.cost,
    notes: params.notes,
    extraFields: params.extraFields,
  );
  
  // Invalidate related providers to refresh data
  ref.invalidate(serviceRecordsProvider(params.vehicleId));
});

final deleteServiceProvider = FutureProvider.family<void, ({
  int id,
  int vehicleId,
})>((ref, params) async {
  final authState = ref.watch(authStateProvider);
  final repository = ref.watch(repositoryProvider);
  
  // Get credentials from storage
  final credentials = getCredentials(authState);
  
  await repository.deleteServiceRecord(
    serverUrl: credentials.serverUrl,
    username: credentials.username,
    password: credentials.password,
    id: params.id,
  );
  
  // Invalidate related providers to refresh data
  ref.invalidate(serviceRecordsProvider(params.vehicleId));
});

