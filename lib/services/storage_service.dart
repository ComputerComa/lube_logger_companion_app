import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lube_logger_companion_app/core/constants/app_constants.dart';

class StorageService {
  static SharedPreferences? _prefs;
  
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }
  
  static Future<bool> saveServerUrl(String url) async {
    return await _prefs?.setString(AppConstants.keyServerUrl, url) ?? false;
  }
  
  static String? getServerUrl() {
    return _prefs?.getString(AppConstants.keyServerUrl);
  }
  
  static Future<bool> saveUsername(String username) async {
    return await _prefs?.setString(AppConstants.keyUsername, username) ?? false;
  }
  
  static String? getUsername() {
    return _prefs?.getString(AppConstants.keyUsername);
  }
  
  static Future<bool> savePassword(String password) async {
    return await _prefs?.setString(AppConstants.keyPassword, password) ?? false;
  }
  
  static String? getPassword() {
    return _prefs?.getString(AppConstants.keyPassword);
  }
  
  static Future<bool> setSetupComplete(bool complete) async {
    return await _prefs?.setBool(AppConstants.keySetupComplete, complete) ?? false;
  }
  
  static bool isSetupComplete() {
    return _prefs?.getBool(AppConstants.keySetupComplete) ?? false;
  }
  
  static Future<bool> setWelcomeShown(bool shown) async {
    return await _prefs?.setBool(AppConstants.keyWelcomeShown, shown) ?? false;
  }
  
  static bool isWelcomeShown() {
    return _prefs?.getBool(AppConstants.keyWelcomeShown) ?? false;
  }
  
  static Future<bool> clearAll() async {
    return await _prefs?.clear() ?? false;
  }
  
  // Polling configuration
  static const String _keyPollingEnabled = 'polling_enabled';
  static const String _keyPollingInterval = 'polling_interval';
  static const String _keyThemeMode = 'theme_mode';
  
  static const int defaultPollingInterval = 60; // 60 seconds default
  
  static Future<bool> setPollingEnabled(bool enabled) async {
    return await _prefs?.setBool(_keyPollingEnabled, enabled) ?? false;
  }
  
  static Future<bool> isPollingEnabled() async {
    return _prefs?.getBool(_keyPollingEnabled) ?? true; // Default to enabled
  }
  
  static Future<bool> setPollingInterval(int intervalSeconds) async {
    // Ensure minimum interval of 10 seconds
    final safeInterval = intervalSeconds < 10 ? 10 : intervalSeconds;
    return await _prefs?.setInt(_keyPollingInterval, safeInterval) ?? false;
  }
  
  static Future<int> getPollingInterval() async {
    return _prefs?.getInt(_keyPollingInterval) ?? defaultPollingInterval;
  }

  static Future<bool> setThemeMode(ThemeMode mode) async {
    return await _prefs?.setString(_keyThemeMode, mode.name) ?? false;
  }

  static ThemeMode getThemeMode() {
    final stored = _prefs?.getString(_keyThemeMode);
    switch (stored) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }
}
