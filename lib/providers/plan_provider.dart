import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lube_logger_companion_app/data/models/plan_record.dart';
import 'package:lube_logger_companion_app/data/models/extra_field.dart';
import 'package:lube_logger_companion_app/providers/auth_provider.dart';
import 'package:lube_logger_companion_app/providers/auth_helpers.dart';
import 'package:lube_logger_companion_app/providers/vehicle_provider.dart';
import 'package:lube_logger_companion_app/services/cached_data_helper.dart';

final planRecordsProvider = FutureProvider.family<List<PlanRecord>, int>((ref, vehicleId) async {
  final authState = ref.watch(authStateProvider);
  final repository = ref.watch(repositoryProvider);

  final credentials = getCredentials(authState);

  final cacheKey = CachedDataHelper.vehicleCacheKey(
    'plan_records',
    vehicleId,
    credentials.serverUrl,
    credentials.username,
  );

  return CachedDataHelper.fetchWithCache<PlanRecord>(
    fetchFn: () => repository.getPlanRecords(
      serverUrl: credentials.serverUrl,
      username: credentials.username,
      password: credentials.password,
      vehicleId: vehicleId,
    ),
    cacheKey: cacheKey,
    fromJson: (json) => PlanRecord.fromJson(json),
    toJson: (record) => record.toJson(),
  );
});

final addPlanRecordProvider = FutureProvider.family<void, ({
  int vehicleId,
  String description,
  double cost,
  PlanRecordType type,
  PlanRecordPriority priority,
  PlanRecordProgress progress,
  String? notes,
  List<ExtraField>? extraFields,
})>((ref, params) async {
  final authState = ref.watch(authStateProvider);
  final repository = ref.watch(repositoryProvider);

  final credentials = getCredentials(authState);

  await repository.addPlanRecord(
    serverUrl: credentials.serverUrl,
    username: credentials.username,
    password: credentials.password,
    vehicleId: params.vehicleId,
    description: params.description,
    cost: params.cost,
    type: params.type,
    priority: params.priority,
    progress: params.progress,
    notes: params.notes,
    extraFields: params.extraFields,
  );

  ref.invalidate(planRecordsProvider(params.vehicleId));
});

final updatePlanRecordProvider = FutureProvider.family<void, ({
  int id,
  int vehicleId,
  String description,
  double cost,
  PlanRecordType type,
  PlanRecordPriority priority,
  PlanRecordProgress progress,
  String? notes,
  List<ExtraField>? extraFields,
})>((ref, params) async {
  final authState = ref.watch(authStateProvider);
  final repository = ref.watch(repositoryProvider);

  final credentials = getCredentials(authState);

  await repository.updatePlanRecord(
    serverUrl: credentials.serverUrl,
    username: credentials.username,
    password: credentials.password,
    id: params.id,
    description: params.description,
    cost: params.cost,
    type: params.type,
    priority: params.priority,
    progress: params.progress,
    notes: params.notes,
    extraFields: params.extraFields,
  );

  ref.invalidate(planRecordsProvider(params.vehicleId));
});

final deletePlanRecordProvider = FutureProvider.family<void, ({
  int id,
  int vehicleId,
})>((ref, params) async {
  final authState = ref.watch(authStateProvider);
  final repository = ref.watch(repositoryProvider);

  final credentials = getCredentials(authState);

  await repository.deletePlanRecord(
    serverUrl: credentials.serverUrl,
    username: credentials.username,
    password: credentials.password,
    id: params.id,
  );

  ref.invalidate(planRecordsProvider(params.vehicleId));
});

