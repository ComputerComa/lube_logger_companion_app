class FuelRecord {
  final int id;
  final int vehicleId;
  final DateTime date;
  final int odometer;
  final double gallons;
  final double? cost;
  final double? pricePerGallon;
  final String? notes;
  
  FuelRecord({
    required this.id,
    required this.vehicleId,
    required this.date,
    required this.odometer,
    required this.gallons,
    this.cost,
    this.pricePerGallon,
    this.notes,
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
      return '${date}_${odometer}'.hashCode;
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
    
    // Calculate pricePerGallon from cost and fuelConsumed if not provided
    final costValue = parseDoubleNullable(json['cost']);
    final fuelConsumedValue = parseDouble(fuelConsumed);
    final pricePerGallonValue = costValue != null && fuelConsumedValue > 0
        ? costValue / fuelConsumedValue
        : parseDoubleNullable(json['pricePerGallon'] ?? json['price_per_gallon']);
    
    return FuelRecord(
      id: id,
      vehicleId: parseInt(vehicleIdValue),
      date: parseDate(json['date'] ?? json['Date']),
      odometer: parseInt(json['odometer'] ?? json['Odometer']),
      gallons: fuelConsumedValue, // Store fuelConsumed as gallons
      cost: costValue,
      pricePerGallon: pricePerGallonValue,
      notes: json['notes'] as String?,
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
    };
  }
  
  double get calculatedPricePerGallon {
    if (cost != null && gallons > 0) {
      return cost! / gallons;
    }
    return pricePerGallon ?? 0.0;
  }
}
