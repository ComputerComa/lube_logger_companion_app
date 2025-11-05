import 'package:lube_logger_companion_app/data/models/extra_field.dart';

class FuelRecord {
  final int id;
  final int vehicleId;
  final DateTime date;
  final int odometer;
  final double gallons;
  final double cost;
  final double? pricePerGallon;
  final String? notes;
  final bool isFillToFull;
  final bool missedFuelUp;
  final List<String> tags;
  final List<ExtraField> extraFields;
  
  FuelRecord({
    required this.id,
    required this.vehicleId,
    required this.date,
    required this.odometer,
    required this.gallons,
    required this.cost,
    this.pricePerGallon,
    this.notes,
    this.isFillToFull = false,
    this.missedFuelUp = false,
    this.tags = const [],
    this.extraFields = const [],
  });
  
  factory FuelRecord.fromJson(Map<String, dynamic> json) {
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
    
    double? parseDoubleNullable(dynamic value) {
      if (value == null) return null;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value);
      if (value is num) return value.toDouble();
      return null;
    }
    
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
      throw Exception('vehicleId is required but was null in fuel record');
    }
    
    // Handle id - might be missing from API response, generate a hash from date + odometer if needed
    int generateId(String date, String odometer) {
      return '$date' '_$odometer'.hashCode;
    }
    
    final idValue = json['id'] ?? json['Id'];
    final id = idValue != null 
        ? parseInt(idValue)
        : generateId(
            json['date']?.toString() ?? '', 
            json['odometer']?.toString() ?? ''
          );
    
    // Use fuelConsumed instead of gallons (API uses fuelConsumed)
    final fuelConsumed = json['fuelConsumed'] ?? json['fuel_consumed'] ?? json['gallons'];
    if (fuelConsumed == null) {
      throw Exception('fuelConsumed is required but was null in fuel record');
    }
    
    // Parse cost - now required
    final costValue = parseDouble(json['cost']);
    final fuelConsumedValue = parseDouble(fuelConsumed);
    final pricePerGallonValue = costValue > 0 && fuelConsumedValue > 0
        ? costValue / fuelConsumedValue
        : parseDoubleNullable(json['pricePerGallon'] ?? json['price_per_gallon']);
    
    // Parse boolean fields
    bool parseBool(dynamic value) {
      if (value == null) return false;
      if (value is bool) return value;
      if (value is String) {
        return value.toLowerCase() == 'true';
      }
      return false;
    }
    
    final isFillToFull = parseBool(json['isFillToFull'] ?? json['is_fill_to_full'] ?? json['isFillToFull']);
    final missedFuelUp = parseBool(json['missedFuelUp'] ?? json['missed_fuel_up'] ?? json['missedFuelUp']);
    
    // Parse tags - can be space-separated string or list
    List<String> parseTags(dynamic value) {
      if (value == null) return [];
      if (value is List) {
        return value.map((e) => e.toString().trim()).where((e) => e.isNotEmpty).toList();
      }
      if (value is String && value.isNotEmpty) {
        return value.split(' ').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      }
      return [];
    }
    
    final tags = parseTags(json['tags'] ?? json['Tags']);
    
    // Parse extraFields
    final extraFieldsJson = json['extrafields'] as List<dynamic>? ?? json['extraFields'] as List<dynamic>? ?? [];
    final extraFields = extraFieldsJson
        .map((e) => ExtraField.fromJson(e as Map<String, dynamic>))
        .toList();
    
    return FuelRecord(
      id: id,
      vehicleId: parseInt(vehicleIdValue),
      date: parseDate(json['date'] ?? json['Date']),
      odometer: parseInt(json['odometer'] ?? json['Odometer']),
      gallons: fuelConsumedValue, // Store fuelConsumed as gallons
      cost: costValue,
      pricePerGallon: pricePerGallonValue,
      notes: json['notes'] as String?,
      isFillToFull: isFillToFull,
      missedFuelUp: missedFuelUp,
      tags: tags,
      extraFields: extraFields,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'vehicleId': vehicleId,
      'date': date.toIso8601String(),
      'odometer': odometer,
      'gallons': gallons,
      'cost': cost,
      'pricePerGallon': pricePerGallon,
      'notes': notes,
      'isFillToFull': isFillToFull,
      'missedFuelUp': missedFuelUp,
      'tags': tags.join(' '),
      'extrafields': extraFields.map((e) => e.toJson()).toList(),
    };
  }
  
  double get calculatedPricePerGallon {
    if (gallons > 0) {
      return cost / gallons;
    }
    return pricePerGallon ?? 0.0;
  }
}
