import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

class LubeLoggerApiClient {
  // Create an HTTP client that allows self-signed certificates
  // This is necessary for self-hosted LubeLogger instances
  static http.Client _createHttpClient() {
    final httpClient = HttpClient();
    httpClient.badCertificateCallback = (X509Certificate cert, String host, int port) {
      // Allow certificates for self-hosted servers
      // In production, you might want to validate certificates properly
      // but for self-hosted instances, this is often necessary
      return true;
    };
    return IOClient(httpClient);
  }
  
  final http.Client _client = _createHttpClient();
  
  Future<http.Response> get(
    String endpoint, {
    required String serverUrl,
    required String username,
    required String password,
    Map<String, String>? queryParameters,
  }) async {
    // Normalize server URL - remove trailing slash
    final normalizedUrl = serverUrl.trim().replaceAll(RegExp(r'/$'), '');
    
    // Build URI - endpoint should start with /
    final endpointPath = endpoint.startsWith('/') ? endpoint : '/$endpoint';
    final uri = Uri.parse('$normalizedUrl$endpointPath');
    
    final finalUri = queryParameters != null && queryParameters.isNotEmpty
        ? uri.replace(queryParameters: queryParameters)
        : uri;
    
    final credentials = base64Encode(utf8.encode('$username:$password'));
    final headers = {
      'Authorization': 'Basic $credentials',
      'Content-Type': 'application/json',
    };
    
    return await _client.get(finalUri, headers: headers);
  }
  
  Future<http.Response> post(
    String endpoint, {
    required String serverUrl,
    required String username,
    required String password,
    Map<String, String>? queryParameters,
    Map<String, dynamic>? body,
    bool isFormData = false,
  }) async {
    // Normalize server URL - remove trailing slash
    final normalizedUrl = serverUrl.trim().replaceAll(RegExp(r'/$'), '');
    
    // Build URI - endpoint should start with /
    final endpointPath = endpoint.startsWith('/') ? endpoint : '/$endpoint';
    final uri = Uri.parse('$normalizedUrl$endpointPath');
    
    final finalUri = queryParameters != null && queryParameters.isNotEmpty
        ? uri.replace(queryParameters: queryParameters)
        : uri;
    
    final credentials = base64Encode(utf8.encode('$username:$password'));
    final headers = {
      'Authorization': 'Basic $credentials',
    };
    
    if (isFormData) {
      return await _client.post(
        finalUri,
        headers: headers,
        body: body,
      );
    } else {
      headers['Content-Type'] = 'application/json';
      return await _client.post(
        finalUri,
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      );
    }
  }
  
  Future<http.Response> put(
    String endpoint, {
    required String serverUrl,
    required String username,
    required String password,
    Map<String, String>? queryParameters,
    Map<String, dynamic>? body,
    bool isFormData = false,
  }) async {
    // Normalize server URL - remove trailing slash
    final normalizedUrl = serverUrl.trim().replaceAll(RegExp(r'/$'), '');
    
    // Build URI - endpoint should start with /
    final endpointPath = endpoint.startsWith('/') ? endpoint : '/$endpoint';
    final uri = Uri.parse('$normalizedUrl$endpointPath');
    
    final finalUri = queryParameters != null && queryParameters.isNotEmpty
        ? uri.replace(queryParameters: queryParameters)
        : uri;
    
    final credentials = base64Encode(utf8.encode('$username:$password'));
    final headers = {
      'Authorization': 'Basic $credentials',
    };
    
    if (isFormData) {
      return await _client.put(
        finalUri,
        headers: headers,
        body: body,
      );
    } else {
      headers['Content-Type'] = 'application/json';
      return await _client.put(
        finalUri,
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      );
    }
  }
  
  Future<http.Response> delete(
    String endpoint, {
    required String serverUrl,
    required String username,
    required String password,
    Map<String, String>? queryParameters,
  }) async {
    // Normalize server URL - remove trailing slash
    final normalizedUrl = serverUrl.trim().replaceAll(RegExp(r'/$'), '');
    
    // Build URI - endpoint should start with /
    final endpointPath = endpoint.startsWith('/') ? endpoint : '/$endpoint';
    final uri = Uri.parse('$normalizedUrl$endpointPath');
    
    final finalUri = queryParameters != null && queryParameters.isNotEmpty
        ? uri.replace(queryParameters: queryParameters)
        : uri;
    
    final credentials = base64Encode(utf8.encode('$username:$password'));
    final headers = {
      'Authorization': 'Basic $credentials',
      'Content-Type': 'application/json',
    };
    
    return await _client.delete(finalUri, headers: headers);
  }
  
  Map<String, String> buildFormData(Map<String, dynamic> data) {
    final formData = <String, String>{};
    
    data.forEach((key, value) {
      if (value == null) return;
      
      if (value is List) {
        // Handle extra fields array format: extrafields[0][name], extrafields[0][value]
        for (var i = 0; i < value.length; i++) {
          final item = value[i];
          if (item is Map<String, dynamic>) {
            item.forEach((subKey, subValue) {
              formData['$key[$i][$subKey]'] = subValue.toString();
            });
          }
        }
      } else {
        formData[key] = value.toString();
      }
    });
    
    return formData;
  }
}
