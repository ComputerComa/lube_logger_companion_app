import 'dart:convert';
import 'package:lube_logger_companion_app/data/api/lubelogger_api_client.dart';

class AuthService {
  final LubeLoggerApiClient apiClient;
  
  AuthService(this.apiClient);
  
  Future<bool> validateCredentials({
    required String serverUrl,
    required String username,
    required String password,
  }) async {
    try {
      // Use /api/vehicles endpoint to test authentication
      // This endpoint requires authentication and will return vehicles if auth succeeds
      final response = await apiClient.get(
        '/api/vehicles',
        serverUrl: serverUrl,
        username: username,
        password: password,
      );
      
      // Log response for debugging
      print('Auth response status: ${response.statusCode}');
      print('Auth response body: ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}');
      
      // Check for 200 or 201 (some APIs return 201 for success)
      if (response.statusCode == 200 || response.statusCode == 201) {
        // Try to parse as JSON to verify it's a valid response
        try {
          jsonDecode(response.body);
          // If it's valid JSON (even if empty array), auth succeeded
          return true;
        } catch (e) {
          // If response is not valid JSON, still consider it success if status is 200
          print('Warning: Response is not valid JSON, but status is ${response.statusCode}');
          return response.statusCode == 200;
        }
      }
      
      // If we get 401, it's definitely invalid credentials
      if (response.statusCode == 401) {
        print('Authentication failed: 401 Unauthorized');
        return false;
      }
      
      // For other status codes, log for debugging
      print('Unexpected status code: ${response.statusCode}');
      return false;
    } catch (e) {
      print('Auth error: $e');
      rethrow; // Re-throw so we can see the actual error
    }
  }
}
