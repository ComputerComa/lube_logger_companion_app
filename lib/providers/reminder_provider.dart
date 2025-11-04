import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lube_logger_companion_app/data/models/reminder.dart';
import 'package:lube_logger_companion_app/providers/auth_provider.dart';
import 'package:lube_logger_companion_app/providers/vehicle_provider.dart';

final remindersProvider = FutureProvider.family<List<Reminder>, int?>((ref, vehicleId) async {
  final authState = ref.watch(authStateProvider);
  final repository = ref.watch(repositoryProvider);
  
  if (!authState.isAuthenticated ||
      authState.serverUrl == null ||
      authState.username == null ||
      authState.password == null) {
    throw Exception('Not authenticated');
  }
  
  return await repository.getReminders(
    serverUrl: authState.serverUrl!,
    username: authState.username!,
    password: authState.password!,
    vehicleId: vehicleId,
  );
});
