import 'package:lube_logger_companion_app/providers/auth_provider.dart';

/// Helper function to get credentials from auth state
/// Throws if credentials are missing
({String serverUrl, String username, String password}) getCredentials(AuthState authState) {
  if (authState.serverUrl == null ||
      authState.username == null ||
      authState.password == null) {
    throw Exception('No credentials found. Please complete setup.');
  }
  
  return (
    serverUrl: authState.serverUrl!,
    username: authState.username!,
    password: authState.password!,
  );
}

