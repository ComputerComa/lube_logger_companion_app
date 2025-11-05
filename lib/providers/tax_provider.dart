import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lube_logger_companion_app/data/models/tax_record.dart';
import 'package:lube_logger_companion_app/data/models/extra_field.dart';
import 'package:lube_logger_companion_app/providers/auth_provider.dart';
import 'package:lube_logger_companion_app/providers/auth_helpers.dart';
import 'package:lube_logger_companion_app/providers/vehicle_provider.dart';
import 'package:lube_logger_companion_app/services/cached_data_helper.dart';

final taxRecordsProvider = FutureProvider.family<List<TaxRecord>, int>((ref, vehicleId) async {
  final authState = ref.watch(authStateProvider);
  final repository = ref.watch(repositoryProvider);
  
  // Get credentials from storage
  final credentials = getCredentials(authState);
  
  final cacheKey = CachedDataHelper.vehicleCacheKey(
    'tax_records',
    vehicleId,
      credentials.serverUrl,
      credentials.username,
  );
  
  return await CachedDataHelper.fetchWithCache<TaxRecord>(
    fetchFn: () => repository.getTaxRecords(
      serverUrl: credentials.serverUrl,
      username: credentials.username,
      password: credentials.password,
      vehicleId: vehicleId,
    ),
    cacheKey: cacheKey,
    fromJson: (json) => TaxRecord.fromJson(json),
    toJson: (record) => record.toJson(),
  );
});

final addTaxProvider = FutureProvider.family<void, ({
  int vehicleId,
  DateTime date,
  String description,
  double cost,
  String? notes,
  List<ExtraField>? extraFields,
})>((ref, params) async {
  final authState = ref.watch(authStateProvider);
  final repository = ref.watch(repositoryProvider);
  
  // Get credentials from storage
  final credentials = getCredentials(authState);
  
  await repository.addTaxRecord(
    serverUrl: credentials.serverUrl,
    username: credentials.username,
    password: credentials.password,
    vehicleId: params.vehicleId,
    date: params.date,
    description: params.description,
    cost: params.cost,
    notes: params.notes,
    extraFields: params.extraFields,
  );
  
  // Invalidate related providers to refresh data
  ref.invalidate(taxRecordsProvider(params.vehicleId));
});

final updateTaxProvider = FutureProvider.family<void, ({
  int id,
  DateTime date,
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
  
  await repository.updateTaxRecord(
    serverUrl: credentials.serverUrl,
    username: credentials.username,
    password: credentials.password,
    id: params.id,
    date: params.date,
    description: params.description,
    cost: params.cost,
    notes: params.notes,
    extraFields: params.extraFields,
  );
  
  // Invalidate related providers to refresh data
  ref.invalidate(taxRecordsProvider(params.vehicleId));
});

final deleteTaxProvider = FutureProvider.family<void, ({
  int id,
  int vehicleId,
})>((ref, params) async {
  final authState = ref.watch(authStateProvider);
  final repository = ref.watch(repositoryProvider);
  
  // Get credentials from storage
  final credentials = getCredentials(authState);
  
  await repository.deleteTaxRecord(
    serverUrl: credentials.serverUrl,
    username: credentials.username,
    password: credentials.password,
    id: params.id,
  );
  
  // Invalidate related providers to refresh data
  ref.invalidate(taxRecordsProvider(params.vehicleId));
});

