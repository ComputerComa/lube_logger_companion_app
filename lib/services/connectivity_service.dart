import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Service for checking network connectivity
class ConnectivityService {
  static final Connectivity _connectivity = Connectivity();
  static StreamSubscription<List<ConnectivityResult>>? _subscription;
  static bool _isConnected = true; // Default to true (assume connected)
  
  /// Initialize connectivity monitoring
  static Future<void> init() async {
    // Check initial connectivity
    final result = await _connectivity.checkConnectivity();
    _isConnected = result.any((result) => 
      result == ConnectivityResult.mobile || 
      result == ConnectivityResult.wifi ||
      result == ConnectivityResult.ethernet
    );
    
    // Listen to connectivity changes
    _subscription = _connectivity.onConnectivityChanged.listen((List<ConnectivityResult> results) {
      _isConnected = results.any((result) => 
        result == ConnectivityResult.mobile || 
        result == ConnectivityResult.wifi ||
        result == ConnectivityResult.ethernet
      );
    });
  }
  
  /// Check if device is currently connected to internet
  static Future<bool> isConnected() async {
    final result = await _connectivity.checkConnectivity();
    _isConnected = result.any((result) => 
      result == ConnectivityResult.mobile || 
      result == ConnectivityResult.wifi ||
      result == ConnectivityResult.ethernet
    );
    return _isConnected;
  }
  
  /// Get current connectivity status (cached)
  static bool get isConnectedCached => _isConnected;
  
  /// Dispose connectivity monitoring
  static void dispose() {
    _subscription?.cancel();
    _subscription = null;
  }
}

