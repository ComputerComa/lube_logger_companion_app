import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lube_logger_companion_app/data/models/tax_record.dart';
import 'package:lube_logger_companion_app/data/models/odometer_record.dart';
import 'package:lube_logger_companion_app/providers/auth_provider.dart';
import 'package:lube_logger_companion_app/providers/vehicle_provider.dart';

final taxRecordsProvider = FutureProvider.family<List<TaxRecord>, int>((ref, vehicleId) async {
  final authState = ref.watch(authStateProvider);
  final repository = ref.watch(repositoryProvider);
  
  if (!authState.isAuthenticated ||
      authState.serverUrl == null ||
      authState.username == null ||
      authState.password == null) {
    throw Exception('Not authenticated');
  }
  
  return await repository.getTaxRecords(
    serverUrl: authState.serverUrl!,
    username: authState.username!,
    password: authState.password!,
    vehicleId: vehicleId,
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
  
  if (!authState.isAuthenticated ||
      authState.serverUrl == null ||
      authState.username == null ||
      authState.password == null) {
    throw Exception('Not authenticated');
  }
  
  await repository.addTaxRecord(
    serverUrl: authState.serverUrl!,
    username: authState.username!,
    password: authState.password!,
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

