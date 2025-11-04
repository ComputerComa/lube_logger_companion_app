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
}
