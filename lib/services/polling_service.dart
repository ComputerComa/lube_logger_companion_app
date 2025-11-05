import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lube_logger_companion_app/providers/auth_provider.dart';
import 'package:lube_logger_companion_app/providers/vehicle_provider.dart';
import 'package:lube_logger_companion_app/providers/fuel_provider.dart';
import 'package:lube_logger_companion_app/providers/odometer_provider.dart';
import 'package:lube_logger_companion_app/providers/reminder_provider.dart';
import 'package:lube_logger_companion_app/providers/service_provider.dart';
import 'package:lube_logger_companion_app/providers/repair_provider.dart';
import 'package:lube_logger_companion_app/providers/upgrade_provider.dart';
import 'package:lube_logger_companion_app/providers/tax_provider.dart';
import 'package:lube_logger_companion_app/providers/latest_data_provider.dart';
import 'package:lube_logger_companion_app/providers/statistics_provider.dart';
import 'package:lube_logger_companion_app/services/storage_service.dart';

class PollingService {
  Timer? _pollingTimer;
  final Ref _ref;
  bool _isPolling = false;
  
  PollingService(this._ref);
  
  /// Start polling with the specified interval in seconds
  void startPolling({int intervalSeconds = 60}) {
    if (_isPolling) {
      stopPolling();
    }
    
    _isPolling = true;
    _pollingTimer = Timer.periodic(
      Duration(seconds: intervalSeconds),
      (_) => _performPoll(),
    );
    
    // Perform initial poll
    _performPoll();
  }
  
  /// Stop polling
  void stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
    _isPolling = false;
  }
  
  /// Perform a single poll operation - refresh all relevant providers
  void _performPoll() {
    final authState = _ref.read(authStateProvider);
    
    // Only poll if authenticated
    if (!authState.isAuthenticated) {
      stopPolling();
      return;
    }
    
    // Invalidate vehicle list first - this will trigger a refresh
    _ref.invalidate(vehiclesProvider);
    
    // Get current vehicles from cache if available and refresh their data
    // We use read with a try-catch to avoid errors if not loaded yet
    try {
      final vehiclesAsync = _ref.read(vehiclesProvider);
      
      vehiclesAsync.whenData((vehicles) {
        // For each vehicle, invalidate all related providers
        for (final vehicle in vehicles) {
          _ref.invalidate(fuelRecordsProvider(vehicle.id));
          _ref.invalidate(odometerRecordsProvider(vehicle.id));
          _ref.invalidate(latestOdometerProvider(vehicle.id));
          _ref.invalidate(remindersProvider(vehicle.id));
          _ref.invalidate(serviceRecordsProvider(vehicle.id));
          _ref.invalidate(repairRecordsProvider(vehicle.id));
          _ref.invalidate(upgradeRecordsProvider(vehicle.id));
          _ref.invalidate(taxRecordsProvider(vehicle.id));
          _ref.invalidate(statisticsProvider(vehicle.id));
          _ref.invalidate(latestOdometerValueProvider(vehicle.id));
          _ref.invalidate(latestFuelRecordProvider(vehicle.id));
          _ref.invalidate(upcomingRemindersProvider(vehicle.id));
        }
      });
    } catch (e) {
      // If vehicles aren't loaded yet, that's okay - just invalidate the list
      // and let it load naturally
    }
  }
  
  bool get isPolling => _isPolling;
  
  void dispose() {
    stopPolling();
  }
}

/// Provider for polling service
final pollingServiceProvider = Provider<PollingService>((ref) {
  final service = PollingService(ref);
  
  // Auto-dispose when provider is disposed
  ref.onDispose(() => service.dispose());
  
  return service;
});

/// Provider for polling interval (in seconds)
final pollingIntervalProvider = FutureProvider<int>((ref) async {
  final interval = await StorageService.getPollingInterval();
  return interval;
});

/// Provider for polling enabled state
final pollingEnabledProvider = FutureProvider<bool>((ref) async {
  final enabled = await StorageService.isPollingEnabled();
  return enabled;
});

/// Provider that manages polling lifecycle
final pollingManagerProvider = Provider<void>((ref) {
  final pollingService = ref.watch(pollingServiceProvider);
  
  // Watch auth state
  final authState = ref.watch(authStateProvider);
  
  // Watch polling enabled state (async)
  ref.watch(pollingEnabledProvider);
  
  // Watch polling interval (async)
  ref.watch(pollingIntervalProvider);
  
  // Listen to auth state changes
  ref.listen(authStateProvider, (previous, next) async {
    if (!next.isAuthenticated) {
      pollingService.stopPolling();
      return;
    }
    
    final enabled = await ref.read(pollingEnabledProvider.future);
    final interval = await ref.read(pollingIntervalProvider.future);
    
    if (enabled) {
      pollingService.startPolling(intervalSeconds: interval);
    }
  });
  
  // Listen to polling enabled changes
  ref.listen(pollingEnabledProvider, (previous, next) async {
    next.whenData((enabled) async {
      if (!authState.isAuthenticated) {
        pollingService.stopPolling();
        return;
      }
      
      final interval = await ref.read(pollingIntervalProvider.future);
      
      if (enabled) {
        pollingService.startPolling(intervalSeconds: interval);
      } else {
        pollingService.stopPolling();
      }
    });
  });
  
  // Initialize polling based on current state
  if (authState.isAuthenticated) {
    // Use a microtask to handle async initialization
    Future.microtask(() async {
      final enabled = await ref.read(pollingEnabledProvider.future);
      if (enabled) {
        final interval = await ref.read(pollingIntervalProvider.future);
        pollingService.startPolling(intervalSeconds: interval);
      }
    });
  }
});

