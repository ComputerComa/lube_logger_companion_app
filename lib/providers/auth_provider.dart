import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lube_logger_companion_app/services/storage_service.dart';
import 'package:lube_logger_companion_app/services/auth_service.dart';
import 'package:lube_logger_companion_app/data/api/lubelogger_api_client.dart';

class AuthState {
  final bool isAuthenticated;
  final String? serverUrl;
  final String? username;
  final String? password;
  final bool isLoading;
  final String? error;
  
  AuthState({
    this.isAuthenticated = false,
    this.serverUrl,
    this.username,
    this.password,
    this.isLoading = false,
    this.error,
  });
  
  AuthState copyWith({
    bool? isAuthenticated,
    String? serverUrl,
    String? username,
    String? password,
    bool? isLoading,
    String? error,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      serverUrl: serverUrl ?? this.serverUrl,
      username: username ?? this.username,
      password: password ?? this.password,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class AuthNotifier extends Notifier<AuthState> {
  AuthService get _authService => ref.read(authServiceProvider);
  
  @override
  AuthState build() {
    _loadSavedCredentials();
    return AuthState();
  }
  
  Future<void> _loadSavedCredentials() async {
    final serverUrl = StorageService.getServerUrl();
    final username = StorageService.getUsername();
    final password = StorageService.getPassword();
    
    if (serverUrl != null && username != null && password != null) {
      state = state.copyWith(
        serverUrl: serverUrl,
        username: username,
        password: password,
        isAuthenticated: StorageService.isSetupComplete(),
      );
    }
  }
  
  Future<bool> login({
    required String serverUrl,
    required String username,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final isValid = await _authService.validateCredentials(
        serverUrl: serverUrl,
        username: username,
        password: password,
      );
      
      if (isValid) {
        await StorageService.saveServerUrl(serverUrl);
        await StorageService.saveUsername(username);
        await StorageService.savePassword(password);
        await StorageService.setSetupComplete(true);
        
        state = state.copyWith(
          isAuthenticated: true,
          serverUrl: serverUrl,
          username: username,
          password: password,
          isLoading: false,
        );
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Invalid credentials. Please check your username and password.',
        );
        return false;
      }
    } catch (e) {
      print('Login error: $e');
      String errorMessage = 'Failed to connect to server';
      
      // Provide more specific error messages
      if (e.toString().contains('SocketException') || 
          e.toString().contains('Failed host lookup')) {
        errorMessage = 'Cannot connect to server. Please check the server URL.';
      } else if (e.toString().contains('401') || 
                 e.toString().contains('Unauthorized')) {
        errorMessage = 'Invalid credentials. Please check your username and password.';
      } else if (e.toString().contains('FormatException')) {
        errorMessage = 'Invalid server URL format. Please check the URL.';
      } else {
        errorMessage = 'Error: ${e.toString()}';
      }
      
      state = state.copyWith(
        isLoading: false,
        error: errorMessage,
      );
      return false;
    }
  }
  
  Future<void> logout() async {
    await StorageService.clearAll();
    state = AuthState();
  }
}

final apiClientProvider = Provider<LubeLoggerApiClient>((ref) {
  return LubeLoggerApiClient();
});

final authServiceProvider = Provider<AuthService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AuthService(apiClient);
});

final authNotifierProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);

final authStateProvider = Provider<AuthState>((ref) {
  return ref.watch(authNotifierProvider);
});
