import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lube_logger_companion_app/data/models/vehicle.dart';
import 'package:lube_logger_companion_app/data/repositories/lubelogger_repository.dart';
import 'package:lube_logger_companion_app/providers/auth_provider.dart';

final repositoryProvider = Provider<LubeLoggerRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return LubeLoggerRepository(apiClient);
});

final vehiclesProvider = FutureProvider<List<Vehicle>>((ref) async {
  final authState = ref.watch(authStateProvider);
  final repository = ref.watch(repositoryProvider);
  
  if (!authState.isAuthenticated ||
      authState.serverUrl == null ||
      authState.username == null ||
      authState.password == null) {
    throw Exception('Not authenticated');
  }
  
  return await repository.getVehicles(
    serverUrl: authState.serverUrl!,
    username: authState.username!,
    password: authState.password!,
  );
});

final vehicleProvider = FutureProvider.family<Vehicle, int>((ref, vehicleId) async {
  final authState = ref.watch(authStateProvider);
  final repository = ref.watch(repositoryProvider);
  
  if (!authState.isAuthenticated ||
      authState.serverUrl == null ||
      authState.username == null ||
      authState.password == null) {
    throw Exception('Not authenticated');
  }
  
  return await repository.getVehicleInfo(
    serverUrl: authState.serverUrl!,
    username: authState.username!,
    password: authState.password!,
    vehicleId: vehicleId,
  );
});
