import 'package:flutter/foundation.dart';

class Vehicle {
  final int id;
  final String? make;
  final String? model;
  final int? year;
  final String? licensePlate;
  final String? vin;
  final String? imageLocation;
  final String? purchaseDate;
  final String? soldDate;
  final double? purchasePrice;
  final double? soldPrice;
  final bool isElectric;
  final bool isDiesel;
  final bool useHours;
  final bool odometerOptional;
  
  Vehicle({
    required this.id,
    this.make,
    this.model,
    this.year,
    this.licensePlate,
    this.vin,
    this.imageLocation,
    this.purchaseDate,
    this.soldDate,
    this.purchasePrice,
    this.soldPrice,
    this.isElectric = false,
    this.isDiesel = false,
    this.useHours = false,
    this.odometerOptional = false,
  });
  
  factory Vehicle.fromJson(Map<String, dynamic> json) {
    // Handle id - could be int, String, or null
    int? parseId(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is String) return int.tryParse(value);
      return null;
    }
    
    // Handle year - could be int, String, or null
    int? parseYear(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is String) return int.tryParse(value);
      return null;
    }
    
    // Handle double - could be double, int, String, or null
    double? parseDouble(dynamic value) {
      if (value == null) return null;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value);
      if (value is num) return value.toDouble();
      return null;
    }
    
    // Extract VIN from extraFields array
    String? extractVin(List<dynamic>? extraFields) {
      if (extraFields == null) return null;
      for (final field in extraFields) {
        if (field is Map<String, dynamic>) {
          final name = field['name'] as String?;
          if (name != null && name.toUpperCase() == 'VIN') {
            return field['value'] as String?;
          }
        }
      }
      return null;
    }
    
    final id = parseId(json['id']);
    if (id == null) {
      // Log the actual JSON data for debugging
      debugPrint('Warning: Vehicle ID is null or invalid in JSON: ${json['id']}');
      debugPrint('Full JSON keys: ${json.keys.toList()}');
      throw Exception('Vehicle ID is required but was null or invalid. JSON keys: ${json.keys.toList()}');
    }
    
    final extraFields = json['extraFields'] as List<dynamic>? ?? json['extrafields'] as List<dynamic>?;
    
    return Vehicle(
      id: id,
      make: json['make'] as String?,
      model: json['model'] as String?,
      year: parseYear(json['year']),
      licensePlate: json['licensePlate'] as String?,
      vin: extractVin(extraFields) ?? json['vin'] as String? ?? json['VIN'] as String?,
      imageLocation: json['imageLocation'] as String?,
      purchaseDate: json['purchaseDate'] as String?,
      soldDate: json['soldDate'] as String?,
      purchasePrice: parseDouble(json['purchasePrice']),
      soldPrice: parseDouble(json['soldPrice']),
      isElectric: json['isElectric'] as bool? ?? false,
      isDiesel: json['isDiesel'] as bool? ?? false,
      useHours: json['useHours'] as bool? ?? false,
      odometerOptional: json['odometerOptional'] as bool? ?? false,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'make': make,
      'model': model,
      'year': year,
      'licensePlate': licensePlate,
      'vin': vin,
      'imageLocation': imageLocation,
      'purchaseDate': purchaseDate,
      'soldDate': soldDate,
      'purchasePrice': purchasePrice,
      'soldPrice': soldPrice,
      'isElectric': isElectric,
      'isDiesel': isDiesel,
      'useHours': useHours,
      'odometerOptional': odometerOptional,
    };
  }
  
  String get displayName {
    if (make != null && model != null && year != null) {
      return '$year $make $model';
    }
    if (make != null && model != null) {
      return '$make $model';
    }
    if (make != null) {
      return make!;
    }
    if (model != null) {
      return model!;
    }
    return 'Vehicle $id';
  }
}
