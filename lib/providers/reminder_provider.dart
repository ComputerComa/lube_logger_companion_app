import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lube_logger_companion_app/data/models/reminder.dart';
import 'package:lube_logger_companion_app/providers/auth_provider.dart';
import 'package:lube_logger_companion_app/providers/auth_helpers.dart';
import 'package:lube_logger_companion_app/providers/vehicle_provider.dart';
import 'package:lube_logger_companion_app/services/cached_data_helper.dart';

final remindersProvider = FutureProvider.family<List<Reminder>, int?>((ref, vehicleId) async {
  final authState = ref.watch(authStateProvider);
  final repository = ref.watch(repositoryProvider);
  
  // Get credentials from storage
  final credentials = getCredentials(authState);
  
  final cacheKey = vehicleId != null
      ? CachedDataHelper.vehicleCacheKey(
          'reminders',
          vehicleId,
          credentials.serverUrl,
          credentials.username,
        )
      : CachedDataHelper.generalCacheKey(
          'reminders_all',
          credentials.serverUrl,
          credentials.username,
        );
  
  return await CachedDataHelper.fetchWithCache<Reminder>(
    fetchFn: () => repository.getReminders(
      serverUrl: credentials.serverUrl,
      username: credentials.username,
      password: credentials.password,
      vehicleId: vehicleId,
    ),
    cacheKey: cacheKey,
    fromJson: (json) => Reminder.fromJson(json),
    toJson: (reminder) => reminder.toJson(),
  );
});

final addReminderProvider = FutureProvider.family<void, ({
  int vehicleId,
  DateTime date,
  String description,
  ReminderUrgency urgency,
  String? notes,
  String? metric,
  int? dueOdometer,
})>((ref, params) async {
  final authState = ref.watch(authStateProvider);
  final repository = ref.watch(repositoryProvider);
  
  // Get credentials from storage
  final credentials = getCredentials(authState);
  
  await repository.addReminder(
    serverUrl: credentials.serverUrl,
    username: credentials.username,
    password: credentials.password,
    vehicleId: params.vehicleId,
    date: params.date,
    description: params.description,
    urgency: params.urgency,
    notes: params.notes,
    metric: params.metric,
    dueOdometer: params.dueOdometer,
  );
  
  // Invalidate related providers to refresh data
  ref.invalidate(remindersProvider(params.vehicleId));
});

final updateReminderProvider = FutureProvider.family<void, ({
  int id,
  DateTime date,
  String description,
  ReminderUrgency urgency,
  String? notes,
  String? metric,
  int? dueOdometer,
  int? vehicleId,
})>((ref, params) async {
  final authState = ref.watch(authStateProvider);
  final repository = ref.watch(repositoryProvider);
  
  // Get credentials from storage
  final credentials = getCredentials(authState);
  
  await repository.updateReminder(
    serverUrl: credentials.serverUrl,
    username: credentials.username,
    password: credentials.password,
    id: params.id,
    date: params.date,
    description: params.description,
    urgency: params.urgency,
    notes: params.notes,
    metric: params.metric,
    dueOdometer: params.dueOdometer,
  );
  
  // Invalidate related providers to refresh data
  if (params.vehicleId != null) {
    ref.invalidate(remindersProvider(params.vehicleId));
  } else {
    ref.invalidate(remindersProvider);
  }
});

final deleteReminderProvider = FutureProvider.family<void, ({
  int id,
  int? vehicleId,
})>((ref, params) async {
  final authState = ref.watch(authStateProvider);
  final repository = ref.watch(repositoryProvider);
  
  // Get credentials from storage
  final credentials = getCredentials(authState);
  
  await repository.deleteReminder(
    serverUrl: credentials.serverUrl,
    username: credentials.username,
    password: credentials.password,
    id: params.id,
  );
  
  // Invalidate related providers to refresh data
  if (params.vehicleId != null) {
    ref.invalidate(remindersProvider(params.vehicleId));
  } else {
    ref.invalidate(remindersProvider);
  }
});