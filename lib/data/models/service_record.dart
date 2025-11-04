import 'package:lube_logger_companion_app/data/models/extra_field.dart';

class ServiceRecord {
  final int id;
  final int vehicleId;
  final DateTime date;
  final int odometer;
  final String description;
  final double cost;
  final String? notes;
  final List<ExtraField> extraFields;
  
  ServiceRecord({
    required this.id,
    required this.vehicleId,
    required this.date,
    required this.odometer,
    required this.description,
    required this.cost,
    this.notes,
    this.extraFields = const [],
  });
  
  factory ServiceRecord.fromJson(Map<String, dynamic> json) {
    // Helper to parse int values
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
    
    double parseDouble(dynamic value) {
      if (value == null) throw Exception('Required double value is null');
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) {
        final parsed = double.tryParse(value);
        if (parsed == null) throw Exception('Cannot parse double from: $value');
        return parsed;
      }
      if (value is num) return value.toDouble();
      throw Exception('Cannot convert to double: $value');
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
    
    // Handle vehicleId - might not be in response
    final vehicleIdValue = json['vehicleId'] ?? json['vehicle_id'] ?? json['VehicleId'];
    if (vehicleIdValue == null) {
      throw Exception('vehicleId is required but was null in service record');
    }
    
    // Handle id - might be missing from API response
    int generateId(String date, String description) {
      return '${date}_${description}'.hashCode;
    }
    
    final idValue = json['id'] ?? json['Id'];
    final id = idValue != null 
        ? parseInt(idValue)
        : generateId(
            json['date']?.toString() ?? '', 
            json['description']?.toString() ?? ''
          );
    
    return ServiceRecord(
      id: id,
      vehicleId: parseInt(vehicleIdValue),
      date: parseDate(json['date'] ?? json['Date']),
      odometer: parseInt(json['odometer'] ?? json['Odometer']),
      description: json['description'] as String? ?? '',
      cost: parseDouble(json['cost'] ?? json['Cost']),
      notes: json['notes'] as String?,
      extraFields: extraFields,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'vehicleId': vehicleId,
      'date': date.toIso8601String(),
      'odometer': odometer,
      'description': description,
      'cost': cost,
      'notes': notes,
      'extrafields': extraFields.map((e) => e.toJson()).toList(),
    };
  }
}

