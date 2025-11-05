import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lube_logger_companion_app/data/models/vehicle.dart';
import 'package:lube_logger_companion_app/data/repositories/lubelogger_repository.dart';
import 'package:lube_logger_companion_app/providers/auth_provider.dart';
import 'package:lube_logger_companion_app/providers/auth_helpers.dart';
import 'package:lube_logger_companion_app/services/cache_service.dart';
import 'package:lube_logger_companion_app/services/connectivity_service.dart';

final repositoryProvider = Provider<LubeLoggerRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return LubeLoggerRepository(apiClient);
});

final vehiclesProvider = FutureProvider<List<Vehicle>>((ref) async {
  final authState = ref.watch(authStateProvider);
  final repository = ref.watch(repositoryProvider);
  
  // Get credentials from storage - no need for "authenticated" flag
  final credentials = getCredentials(authState);
  
  // Check connectivity
  final isConnected = await ConnectivityService.isConnected();
  final cacheKey = 'vehicles_${credentials.serverUrl}_${credentials.username}';
  
  // If offline, try to load from cache
  if (!isConnected) {
    final cached = CacheService.getList<Vehicle>(
      cacheKey,
      (json) => Vehicle.fromJson(json),
    );
    if (cached != null && cached.isNotEmpty) {
      return cached;
    }
    throw Exception('No internet connection and no cached data available');
  }
  
  // If online, fetch from API and cache the result
  try {
    final vehicles = await repository.getVehicles(
      serverUrl: credentials.serverUrl,
      username: credentials.username,
      password: credentials.password,
    );
    
    // Cache the result
    await CacheService.save(cacheKey, vehicles.map((v) => v.toJson()).toList());
    
    return vehicles;
  } catch (e) {
    // If API call fails, try cache as fallback
    final cached = CacheService.getList<Vehicle>(
      cacheKey,
      (json) => Vehicle.fromJson(json),
    );
    if (cached != null && cached.isNotEmpty) {
      return cached;
    }
    rethrow;
  }
});

final vehicleProvider = FutureProvider.family<Vehicle, int>((ref, vehicleId) async {
  final authState = ref.watch(authStateProvider);
  final repository = ref.watch(repositoryProvider);
  
  // Get credentials from storage
  final credentials = getCredentials(authState);
  
  // Check connectivity
  final isConnected = await ConnectivityService.isConnected();
  final cacheKey = 'vehicle_${vehicleId}_${credentials.serverUrl}_${credentials.username}';
  
  // If offline, try to load from cache
  if (!isConnected) {
    final cached = CacheService.get<Vehicle>(
      cacheKey,
      (json) => Vehicle.fromJson(json),
    );
    if (cached != null) {
      return cached;
    }
    throw Exception('No internet connection and no cached data available');
  }
  
  // If online, fetch from API and cache the result
  try {
    final vehicle = await repository.getVehicleInfo(
      serverUrl: credentials.serverUrl,
      username: credentials.username,
      password: credentials.password,
      vehicleId: vehicleId,
    );
    
    // Cache the result
    await CacheService.save(cacheKey, vehicle.toJson());
    
    return vehicle;
  } catch (e) {
    // If API call fails, try cache as fallback
    final cached = CacheService.get<Vehicle>(
      cacheKey,
      (json) => Vehicle.fromJson(json),
    );
    if (cached != null) {
      return cached;
    }
    rethrow;
  }
});
