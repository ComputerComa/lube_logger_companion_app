import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for caching data locally to enable offline viewing
class CacheService {
  static SharedPreferences? _prefs;
  
  static const String _cachePrefix = 'cache_';
  static const String _cacheTimestampPrefix = 'cache_timestamp_';
  
  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }
  
  /// Save data to cache with a key
  static Future<bool> save<T>(String key, T data, {Duration? maxAge}) async {
    await init();
    if (_prefs == null) return false;
    
    try {
      // Serialize data to JSON
      final jsonString = jsonEncode(data);
      
      // Save the data
      final dataSaved = await _prefs!.setString('$_cachePrefix$key', jsonString);
      
      // Save the timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final timestampSaved = await _prefs!.setInt('$_cacheTimestampPrefix$key', timestamp);
      
      return dataSaved && timestampSaved;
    } catch (e) {
      return false;
    }
  }
  
  /// Get cached data by key
  static T? get<T>(String key, T Function(Map<String, dynamic>) fromJson, {Duration? maxAge}) {
    if (_prefs == null) return null;
    
    try {
      // Check if data exists
      final jsonString = _prefs!.getString('$_cachePrefix$key');
      if (jsonString == null) return null;
      
      // Check timestamp if maxAge is provided
      if (maxAge != null) {
        final timestamp = _prefs!.getInt('$_cacheTimestampPrefix$key');
        if (timestamp == null) return null;
        
        final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
        final now = DateTime.now();
        if (now.difference(cacheTime) > maxAge) {
          // Cache expired, remove it
          _prefs!.remove('$_cachePrefix$key');
          _prefs!.remove('$_cacheTimestampPrefix$key');
          return null;
        }
      }
      
      // Parse JSON
      final json = jsonDecode(jsonString);
      
      // Handle different data types
      if (T == List) {
        // For lists, we need the item type
        return json as T?;
      } else if (json is Map<String, dynamic>) {
        return fromJson(json) as T?;
      } else if (json is List) {
        // For lists, we need to handle each item
        return json as T?;
      }
      
      return json as T?;
    } catch (e) {
      return null;
    }
  }
  
  /// Get cached list data by key
  static List<T>? getList<T>(String key, T Function(Map<String, dynamic>) fromJson, {Duration? maxAge}) {
    if (_prefs == null) return null;
    
    try {
      // Check if data exists
      final jsonString = _prefs!.getString('$_cachePrefix$key');
      if (jsonString == null) return null;
      
      // Check timestamp if maxAge is provided
      if (maxAge != null) {
        final timestamp = _prefs!.getInt('$_cacheTimestampPrefix$key');
        if (timestamp == null) return null;
        
        final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
        final now = DateTime.now();
        if (now.difference(cacheTime) > maxAge) {
          // Cache expired, remove it
          _prefs!.remove('$_cachePrefix$key');
          _prefs!.remove('$_cacheTimestampPrefix$key');
          return null;
        }
      }
      
      // Parse JSON
      final json = jsonDecode(jsonString);
      if (json is! List) return null;
      
      // Convert each item
      return json.map((item) {
        if (item is Map<String, dynamic>) {
          return fromJson(item);
        }
        return item as T;
      }).toList();
    } catch (e) {
      return null;
    }
  }
  
  /// Check if cached data exists and is valid
  static bool exists(String key, {Duration? maxAge}) {
    if (_prefs == null) return false;
    
    if (!_prefs!.containsKey('$_cachePrefix$key')) return false;
    
    if (maxAge != null) {
      final timestamp = _prefs!.getInt('$_cacheTimestampPrefix$key');
      if (timestamp == null) return false;
      
      final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      final now = DateTime.now();
      if (now.difference(cacheTime) > maxAge) {
        return false;
      }
    }
    
    return true;
  }
  
  /// Remove cached data by key
  static Future<bool> remove(String key) async {
    await init();
    if (_prefs == null) return false;
    
    final removed1 = await _prefs!.remove('$_cachePrefix$key');
    final removed2 = await _prefs!.remove('$_cacheTimestampPrefix$key');
    return removed1 || removed2;
  }
  
  /// Clear all cached data
  static Future<bool> clearAll() async {
    await init();
    if (_prefs == null) return false;
    
    final keys = _prefs!.getKeys();
    final cacheKeys = keys.where((key) => 
      key.startsWith(_cachePrefix) || key.startsWith(_cacheTimestampPrefix)
    ).toList();
    
    for (final key in cacheKeys) {
      await _prefs!.remove(key);
    }
    
    return true;
  }
  
  /// Get cache timestamp for a key
  static DateTime? getCacheTimestamp(String key) {
    if (_prefs == null) return null;
    
    final timestamp = _prefs!.getInt('$_cacheTimestampPrefix$key');
    if (timestamp == null) return null;
    
    return DateTime.fromMillisecondsSinceEpoch(timestamp);
  }
}

