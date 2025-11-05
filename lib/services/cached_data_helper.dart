import 'package:lube_logger_companion_app/services/cache_service.dart';
import 'package:lube_logger_companion_app/services/connectivity_service.dart';

/// Helper class for implementing cached data fetching
class CachedDataHelper {
  /// Fetch data with caching support
  /// 
  /// [fetchFn] - Function to fetch data from API when online
  /// [cacheKey] - Unique key for caching this data
  /// [fromJson] - Function to deserialize JSON to object type T
  /// [toJson] - Function to serialize object type T to JSON
  /// 
  /// Returns cached data if offline, or fresh data from API if online
  static Future<List<T>> fetchWithCache<T>({
    required Future<List<T>> Function() fetchFn,
    required String cacheKey,
    required T Function(Map<String, dynamic>) fromJson,
    required Map<String, dynamic> Function(T) toJson,
  }) async {
    // Check connectivity
    final isConnected = await ConnectivityService.isConnected();
    
    // If offline, try to load from cache
    if (!isConnected) {
      final cached = CacheService.getList<T>(cacheKey, fromJson);
      if (cached != null && cached.isNotEmpty) {
        return cached;
      }
      throw Exception('No internet connection and no cached data available');
    }
    
    // If online, fetch from API and cache the result
    try {
      final data = await fetchFn();
      
      // Cache the result
      await CacheService.save(cacheKey, data.map(toJson).toList());
      
      return data;
    } catch (e) {
      // If API call fails, try cache as fallback
      final cached = CacheService.getList<T>(cacheKey, fromJson);
      if (cached != null && cached.isNotEmpty) {
        return cached;
      }
      rethrow;
    }
  }
  
  /// Fetch single item with caching support
  static Future<T> fetchSingleWithCache<T>({
    required Future<T> Function() fetchFn,
    required String cacheKey,
    required T Function(Map<String, dynamic>) fromJson,
    required Map<String, dynamic> Function(T) toJson,
  }) async {
    // Check connectivity
    final isConnected = await ConnectivityService.isConnected();
    
    // If offline, try to load from cache
    if (!isConnected) {
      final cached = CacheService.get<T>(cacheKey, fromJson);
      if (cached != null) {
        return cached;
      }
      throw Exception('No internet connection and no cached data available');
    }
    
    // If online, fetch from API and cache the result
    try {
      final data = await fetchFn();
      
      // Cache the result
      await CacheService.save(cacheKey, toJson(data));
      
      return data;
    } catch (e) {
      // If API call fails, try cache as fallback
      final cached = CacheService.get<T>(cacheKey, fromJson);
      if (cached != null) {
        return cached;
      }
      rethrow;
    }
  }
  
  /// Generate cache key for vehicle-specific data
  static String vehicleCacheKey(String baseKey, int vehicleId, String serverUrl, String username) {
    return '${baseKey}_${vehicleId}_${serverUrl}_$username';
  }
  
  /// Generate cache key for general data
  static String generalCacheKey(String baseKey, String serverUrl, String username) {
    return '${baseKey}_${serverUrl}_$username';
  }
}

