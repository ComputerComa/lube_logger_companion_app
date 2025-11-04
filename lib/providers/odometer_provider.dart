import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lube_logger_companion_app/data/models/odometer_record.dart';
import 'package:lube_logger_companion_app/providers/auth_provider.dart';
import 'package:lube_logger_companion_app/providers/vehicle_provider.dart';

final odometerRecordsProvider = FutureProvider.family<List<OdometerRecord>, int>((ref, vehicleId) async {
  final authState = ref.watch(authStateProvider);
  final repository = ref.watch(repositoryProvider);
  
  if (!authState.isAuthenticated ||
      authState.serverUrl == null ||
      authState.username == null ||
      authState.password == null) {
    throw Exception('Not authenticated');
  }
  
  return await repository.getOdometerRecords(
    serverUrl: authState.serverUrl!,
    username: authState.username!,
    password: authState.password!,
    vehicleId: vehicleId,
  );
});

final latestOdometerProvider = FutureProvider.family<int, int>((ref, vehicleId) async {
  final authState = ref.watch(authStateProvider);
  final repository = ref.watch(repositoryProvider);
  
  if (!authState.isAuthenticated ||
      authState.serverUrl == null ||
      authState.username == null ||
      authState.password == null) {
    throw Exception('Not authenticated');
  }
  
  return await repository.getLatestOdometer(
    serverUrl: authState.serverUrl!,
    username: authState.username!,
    password: authState.password!,
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
  
  if (!authState.isAuthenticated ||
      authState.serverUrl == null ||
      authState.username == null ||
      authState.password == null) {
    throw Exception('Not authenticated');
  }
  
  await repository.addOdometerRecord(
    serverUrl: authState.serverUrl!,
    username: authState.username!,
    password: authState.password!,
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
  
  if (!authState.isAuthenticated ||
      authState.serverUrl == null ||
      authState.username == null ||
      authState.password == null) {
    throw Exception('Not authenticated');
  }
  
  // Get vehicle ID from the record (would need to fetch it or pass it)
  // For now, we'll invalidate all odometer providers
  await repository.updateOdometerRecord(
    serverUrl: authState.serverUrl!,
    username: authState.username!,
    password: authState.password!,
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
  
  if (!authState.isAuthenticated ||
      authState.serverUrl == null ||
      authState.username == null ||
      authState.password == null) {
    throw Exception('Not authenticated');
  }
  
  await repository.deleteOdometerRecord(
    serverUrl: authState.serverUrl!,
    username: authState.username!,
    password: authState.password!,
    id: params.id,
  );
  
  // Invalidate related providers to refresh data
  ref.invalidate(odometerRecordsProvider(params.vehicleId));
  ref.invalidate(latestOdometerProvider(params.vehicleId));
});
