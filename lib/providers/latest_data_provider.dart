import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lube_logger_companion_app/data/models/fuel_record.dart';
import 'package:lube_logger_companion_app/data/models/reminder.dart';
import 'package:lube_logger_companion_app/providers/odometer_provider.dart';
import 'package:lube_logger_companion_app/providers/fuel_provider.dart';
import 'package:lube_logger_companion_app/providers/reminder_provider.dart';

// Get latest odometer value (using the /latest endpoint directly)
final latestOdometerValueProvider = FutureProvider.family<int?, int>((ref, vehicleId) async {
  final odometerAsync = ref.watch(latestOdometerProvider(vehicleId));
  
  return odometerAsync.when(
    data: (value) => value > 0 ? value : null,
    loading: () => null,
    error: (_, _) => null,
  );
});

// Get latest fuel record
final latestFuelRecordProvider = FutureProvider.family<FuelRecord?, int>((ref, vehicleId) async {
  final recordsAsync = ref.watch(fuelRecordsProvider(vehicleId));
  
  return recordsAsync.when(
    data: (records) {
      if (records.isEmpty) return null;
      // Sort by date descending and get the most recent
      final sorted = List<FuelRecord>.from(records)
        ..sort((a, b) => b.date.compareTo(a.date));
      return sorted.first;
    },
    loading: () => null,
    error: (_, _) => null,
  );
});

// Get upcoming reminders (next 30 days)
final upcomingRemindersProvider = FutureProvider.family<List<Reminder>, int>((ref, vehicleId) async {
  final remindersAsync = ref.watch(remindersProvider(vehicleId));
  
  return remindersAsync.when(
    data: (reminders) {
      final now = DateTime.now();
      final thirtyDaysFromNow = now.add(const Duration(days: 30));
      
      // Filter reminders that are upcoming (not past due, within next 30 days)
      final upcoming = reminders.where((reminder) {
        return reminder.date.isAfter(now) && 
               reminder.date.isBefore(thirtyDaysFromNow);
      }).toList();
      
      // Sort by date ascending (soonest first)
      upcoming.sort((a, b) => a.date.compareTo(b.date));
      
      return upcoming;
    },
    loading: () => [],
    error: (_, _) => [],
  );
});
