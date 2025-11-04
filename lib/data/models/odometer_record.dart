import 'package:lube_logger_companion_app/data/models/extra_field.dart';

class OdometerRecord {
  final int id;
  final int vehicleId;
  final DateTime date;
  final int odometer;
  final int? initialOdometer;
  final List<ExtraField> extraFields;
  
  OdometerRecord({
    required this.id,
    required this.vehicleId,
    required this.date,
    required this.odometer,
    this.initialOdometer,
    this.extraFields = const [],
  });
  
  factory OdometerRecord.fromJson(Map<String, dynamic> json) {
    // Helper to parse int values that might be null or different types
    int parseInt(dynamic value) {
      if (value == null) throw Exception('Required int value is null');
      if (value is int) return value;
      if (value is String) {
        final parsed = int.tryParse(value);
        if (parsed == null) throw Exception('Cannot parse int from: $value');
        return parsed;
      }
      if (value is num) return value.toInt();
      throw Exception('Cannot convert to int: $value');
    }
    
    int? parseIntNullable(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is String) return int.tryParse(value);
      if (value is num) return value.toInt();
      return null;
    }
    
    final extraFieldsJson = json['extrafields'] as List<dynamic>? ?? json['extraFields'] as List<dynamic>? ?? [];
    final extraFields = extraFieldsJson
        .map((e) => ExtraField.fromJson(e as Map<String, dynamic>))
        .toList();
    
    // Parse date - handle different formats
    DateTime parseDate(dynamic value) {
      if (value == null) throw Exception('Date is required');
      if (value is DateTime) return value;
      if (value is String) {
        try {
          return DateTime.parse(value);
        } catch (e) {
          // Try MM/dd/yyyy format
          final parts = value.split('/');
          if (parts.length == 3) {
            final month = int.parse(parts[0]);
            final day = int.parse(parts[1]);
            final year = int.parse(parts[2]);
            return DateTime(year, month, day);
          }
          rethrow;
        }
      }
      throw Exception('Cannot parse date: $value');
    }
    
    // Handle vehicleId - might not be in response, but we can't parse without it
    final vehicleIdValue = json['vehicleId'] ?? json['vehicle_id'] ?? json['VehicleId'];
    if (vehicleIdValue == null) {
      throw Exception('vehicleId is required but was null in odometer record');
    }
    
    // Handle id - might be missing from API response, generate a hash from date + odometer if needed
    int generateId(String date, String odometer) {
      return '${date}_${odometer}'.hashCode;
    }
    
    final idValue = json['id'] ?? json['Id'];
    final id = idValue != null 
        ? parseInt(idValue)
        : generateId(
            json['date']?.toString() ?? '', 
            json['odometer']?.toString() ?? ''
          );
    
    return OdometerRecord(
      id: id,
      vehicleId: parseInt(vehicleIdValue),
      date: parseDate(json['date'] ?? json['Date']),
      odometer: parseInt(json['odometer'] ?? json['Odometer']),
      initialOdometer: parseIntNullable(json['initialOdometer'] ?? json['initial_odometer'] ?? json['InitialOdometer']),
      extraFields: extraFields,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'vehicleId': vehicleId,
      'date': date.toIso8601String(),
      'odometer': odometer,
      'initialOdometer': initialOdometer,
      'extrafields': extraFields.map((e) => e.toJson()).toList(),
    };
  }
}
