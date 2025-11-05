import 'dart:convert';
import 'package:lube_logger_companion_app/data/api/lubelogger_api_client.dart';
import 'package:lube_logger_companion_app/data/models/vehicle.dart';
import 'package:lube_logger_companion_app/data/models/odometer_record.dart';
import 'package:lube_logger_companion_app/data/models/fuel_record.dart';
import 'package:lube_logger_companion_app/data/models/reminder.dart';
import 'package:lube_logger_companion_app/data/models/service_record.dart';
import 'package:lube_logger_companion_app/data/models/repair_record.dart';
import 'package:lube_logger_companion_app/data/models/upgrade_record.dart';
import 'package:lube_logger_companion_app/data/models/tax_record.dart';
import 'package:lube_logger_companion_app/data/models/extra_field.dart';
import 'package:lube_logger_companion_app/core/utils/date_formatters.dart';

class LubeLoggerRepository {
  final LubeLoggerApiClient apiClient;
  
  LubeLoggerRepository(this.apiClient);
  
  Future<List<Vehicle>> getVehicles({
    required String serverUrl,
    required String username,
    required String password,
  }) async {
    final response = await apiClient.get(
      '/api/vehicles',
      serverUrl: serverUrl,
      username: username,
      password: password,
    );
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List;
      return data.map((json) => Vehicle.fromJson(json as Map<String, dynamic>)).toList();
    }
    
    throw Exception('Failed to load vehicles: ${response.statusCode}');
  }
  
  Future<Vehicle> getVehicleInfo({
    required String serverUrl,
    required String username,
    required String password,
    required int vehicleId,
  }) async {
    final response = await apiClient.get(
      '/api/vehicle/info',
      serverUrl: serverUrl,
      username: username,
      password: password,
      queryParameters: {'vehicleId': vehicleId.toString()},
    );
    
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      
      // Handle the nested structure: response is a List with vehicleData property
      if (decoded is List) {
        if (decoded.isEmpty) {
          throw Exception('Vehicle not found');
        }
        // Get the first item which contains vehicleData
        final firstItem = decoded.first as Map<String, dynamic>;
        
        // Extract vehicleData from the response
        Map<String, dynamic>? vehicleDataMap;
        if (firstItem.containsKey('vehicleData')) {
          vehicleDataMap = firstItem['vehicleData'] as Map<String, dynamic>?;
        } else {
          // Fallback: if no vehicleData, try to use the item itself
          vehicleDataMap = firstItem;
        }
        
        if (vehicleDataMap == null) {
          throw Exception('Vehicle data not found in response');
        }
        
        // Ensure ID is present, use vehicleId as fallback
        if (vehicleDataMap['id'] == null) {
          vehicleDataMap['id'] = vehicleId;
        }
        
        return Vehicle.fromJson(vehicleDataMap);
      } else if (decoded is Map<String, dynamic>) {
        // Handle direct Map response (might have vehicleData or be direct vehicle data)
        Map<String, dynamic> vehicleDataMap;
        if (decoded.containsKey('vehicleData')) {
          vehicleDataMap = decoded['vehicleData'] as Map<String, dynamic>;
        } else {
          vehicleDataMap = Map<String, dynamic>.from(decoded);
        }
        
        // Ensure ID is present, use vehicleId as fallback
        if (vehicleDataMap['id'] == null) {
          vehicleDataMap['id'] = vehicleId;
        }
        
        return Vehicle.fromJson(vehicleDataMap);
      } else {
        throw Exception('Unexpected response format from vehicle info endpoint');
      }
    }
    
    throw Exception('Failed to load vehicle info: ${response.statusCode}');
  }
  
  Future<List<OdometerRecord>> getOdometerRecords({
    required String serverUrl,
    required String username,
    required String password,
    required int vehicleId,
  }) async {
    final response = await apiClient.get(
      '/api/vehicle/odometerrecords',
      serverUrl: serverUrl,
      username: username,
      password: password,
      queryParameters: {'vehicleId': vehicleId.toString()},
    );
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List;
      return data.map((json) {
        final recordJson = json as Map<String, dynamic>;
        // Inject vehicleId if it's missing from the response
        if (!recordJson.containsKey('vehicleId') && 
            !recordJson.containsKey('vehicle_id') && 
            !recordJson.containsKey('VehicleId')) {
          recordJson['vehicleId'] = vehicleId;
        }
        return OdometerRecord.fromJson(recordJson);
      }).toList();
    }
    
    throw Exception('Failed to load odometer records: ${response.statusCode}');
  }
  
  Future<int> getLatestOdometer({
    required String serverUrl,
    required String username,
    required String password,
    required int vehicleId,
  }) async {
    final response = await apiClient.get(
      '/api/vehicle/odometerrecords/latest',
      serverUrl: serverUrl,
      username: username,
      password: password,
      queryParameters: {'vehicleId': vehicleId.toString()},
    );
    
    if (response.statusCode == 200) {
      final body = response.body.trim();
      // Handle both JSON object and plain number responses
      try {
        final decoded = jsonDecode(body);
        if (decoded is Map<String, dynamic>) {
          // If it's a map, try to get odometer field
          return decoded['odometer'] as int? ?? 
                 int.tryParse(decoded['odometer'].toString()) ?? 0;
        } else if (decoded is int) {
          // If it's already an int
          return decoded;
        } else if (decoded is String) {
          // If it's a string, try to parse
          return int.tryParse(decoded) ?? 0;
        }
      } catch (e) {
        // If JSON decode fails, try parsing as plain number
        return int.tryParse(body) ?? 0;
      }
      // Fallback: try parsing body directly as number
      return int.tryParse(body) ?? 0;
    }
    
    throw Exception('Failed to load latest odometer: ${response.statusCode}');
  }
  
  Future<void> addOdometerRecord({
    required String serverUrl,
    required String username,
    required String password,
    required int vehicleId,
    required DateTime date,
    required int odometer,
    List<ExtraField>? extraFields,
  }) async {
    final formData = <String, dynamic>{
      'date': DateFormatters.formatForApi(date),
      'odometer': odometer.toString(),
    };
    
    if (extraFields != null && extraFields.isNotEmpty) {
      formData['extrafields'] = extraFields.map((e) => e.toJson()).toList();
    }
    
    final formDataMap = apiClient.buildFormData(formData);
    
    final response = await apiClient.post(
      '/api/vehicle/odometerrecords/add',
      serverUrl: serverUrl,
      username: username,
      password: password,
      queryParameters: {'vehicleId': vehicleId.toString()},
      body: formDataMap,
      isFormData: true,
    );
    
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to add odometer record: ${response.statusCode}');
    }
  }
  
  Future<void> updateOdometerRecord({
    required String serverUrl,
    required String username,
    required String password,
    required int id,
    required DateTime date,
    required int odometer,
    int? initialOdometer,
    List<ExtraField>? extraFields,
  }) async {
    final formData = <String, dynamic>{
      'id': id.toString(),
      'date': DateFormatters.formatForApi(date),
      'odometer': odometer.toString(),
    };
    
    if (initialOdometer != null) {
      formData['initialOdometer'] = initialOdometer.toString();
    }
    
    if (extraFields != null && extraFields.isNotEmpty) {
      formData['extrafields'] = extraFields.map((e) => e.toJson()).toList();
    }
    
    final formDataMap = apiClient.buildFormData(formData);
    
    final response = await apiClient.put(
      '/api/vehicle/odometerrecords/update',
      serverUrl: serverUrl,
      username: username,
      password: password,
      body: formDataMap,
      isFormData: true,
    );
    
    if (response.statusCode != 200) {
      throw Exception('Failed to update odometer record: ${response.statusCode}');
    }
  }
  
  Future<void> deleteOdometerRecord({
    required String serverUrl,
    required String username,
    required String password,
    required int id,
  }) async {
    final response = await apiClient.delete(
      '/api/vehicle/odometerrecords/delete',
      serverUrl: serverUrl,
      username: username,
      password: password,
      queryParameters: {'id': id.toString()},
    );
    
    if (response.statusCode != 200) {
      throw Exception('Failed to delete odometer record: ${response.statusCode}');
    }
  }
  
  Future<List<FuelRecord>> getFuelRecords({
    required String serverUrl,
    required String username,
    required String password,
    required int vehicleId,
  }) async {
    final response = await apiClient.get(
      '/api/vehicle/gasrecords',
      serverUrl: serverUrl,
      username: username,
      password: password,
      queryParameters: {'vehicleId': vehicleId.toString()},
    );
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List;
      return data.map((json) {
        final recordJson = json as Map<String, dynamic>;
        // Inject vehicleId if it's missing from the response
        if (!recordJson.containsKey('vehicleId') && 
            !recordJson.containsKey('vehicle_id') && 
            !recordJson.containsKey('VehicleId')) {
          recordJson['vehicleId'] = vehicleId;
        }
        return FuelRecord.fromJson(recordJson);
      }).toList();
    }
    
    throw Exception('Failed to load fuel records: ${response.statusCode}');
  }
  
  Future<void> addFuelRecord({
    required String serverUrl,
    required String username,
    required String password,
    required int vehicleId,
    required DateTime date,
    required int odometer,
    required double gallons,
    required double cost,
    bool isFillToFull = false,
    bool missedFuelUp = false,
    List<String> tags = const [],
    String? notes,
  }) async {
    final formData = <String, dynamic>{
      'date': DateFormatters.formatForApi(date),
      'odometer': odometer.toString(),
      'fuelConsumed': gallons.toString(),
      'cost': cost.toString(),
      'isFillToFull': isFillToFull ? 'True' : 'False',
      'missedFuelUp': missedFuelUp ? 'True' : 'False',
    };
    
    if (tags.isNotEmpty) {
      formData['tags'] = tags.join(' ');
    }
    
    if (notes != null && notes.isNotEmpty) {
      formData['notes'] = notes;
    }
    
    final formDataMap = apiClient.buildFormData(formData);
    
    final response = await apiClient.post(
      '/api/vehicle/gasrecords/add',
      serverUrl: serverUrl,
      username: username,
      password: password,
      queryParameters: {'vehicleId': vehicleId.toString()},
      body: formDataMap,
      isFormData: true,
    );
    
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to add fuel record: ${response.statusCode}');
    }
  }
  
  Future<void> updateFuelRecord({
    required String serverUrl,
    required String username,
    required String password,
    required int id,
    required DateTime date,
    required int odometer,
    required double gallons,
    double? cost,
    String? notes,
  }) async {
    final formData = <String, dynamic>{
      'id': id.toString(),
      'date': DateFormatters.formatForApi(date),
      'odometer': odometer.toString(),
      'gallons': gallons.toString(),
    };
    
    if (cost != null) {
      formData['cost'] = cost.toString();
    }
    
    if (notes != null && notes.isNotEmpty) {
      formData['notes'] = notes;
    }
    
    final formDataMap = apiClient.buildFormData(formData);
    
    final response = await apiClient.put(
      '/api/vehicle/gasrecords/update',
      serverUrl: serverUrl,
      username: username,
      password: password,
      body: formDataMap,
      isFormData: true,
    );
    
    if (response.statusCode != 200) {
      throw Exception('Failed to update fuel record: ${response.statusCode}');
    }
  }
  
  Future<void> deleteFuelRecord({
    required String serverUrl,
    required String username,
    required String password,
    required int id,
  }) async {
    final response = await apiClient.delete(
      '/api/vehicle/gasrecords/delete',
      serverUrl: serverUrl,
      username: username,
      password: password,
      queryParameters: {'id': id.toString()},
    );
    
    if (response.statusCode != 200) {
      throw Exception('Failed to delete fuel record: ${response.statusCode}');
    }
  }
  
  Future<List<Reminder>> getReminders({
    required String serverUrl,
    required String username,
    required String password,
    int? vehicleId,
  }) async {
    final queryParams = vehicleId != null
        ? {'vehicleId': vehicleId.toString()}
        : <String, String>{};
    
    final response = await apiClient.get(
      '/api/vehicle/reminders',
      serverUrl: serverUrl,
      username: username,
      password: password,
      queryParameters: queryParams,
    );
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List;
      return data.map((json) {
        final recordJson = json as Map<String, dynamic>;
        // Inject vehicleId if it's missing from the response
        if (!recordJson.containsKey('vehicleId') && 
            !recordJson.containsKey('vehicle_id') && 
            !recordJson.containsKey('VehicleId')) {
          if (vehicleId != null) {
            recordJson['vehicleId'] = vehicleId;
          } else {
            throw Exception('vehicleId is required but was not provided and not in response');
          }
        }
        return Reminder.fromJson(recordJson);
      }).toList();
    }
    
    throw Exception('Failed to load reminders: ${response.statusCode}');
  }

  Future<void> addReminder({
    required String serverUrl,
    required String username,
    required String password,
    required int vehicleId,
    required DateTime date,
    required String description,
    required ReminderUrgency urgency,
    String? notes,
    String? metric,
    int? dueOdometer,
  }) async {
    final formData = <String, dynamic>{
      'date': DateFormatters.formatForApi(date),
      'description': description,
      'urgency': urgency.name,
    };
    
    if (notes != null && notes.isNotEmpty) {
      formData['notes'] = notes;
    }
    
    if (metric != null && metric.isNotEmpty) {
      formData['metric'] = metric;
    }
    
    if (dueOdometer != null) {
      formData['dueOdometer'] = dueOdometer.toString();
    }
    
    final formDataMap = apiClient.buildFormData(formData);
    
    final response = await apiClient.post(
      '/api/vehicle/reminders/add',
      serverUrl: serverUrl,
      username: username,
      password: password,
      queryParameters: {'vehicleId': vehicleId.toString()},
      body: formDataMap,
      isFormData: true,
    );
    
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to add reminder: ${response.statusCode}');
    }
  }

  Future<void> updateReminder({
    required String serverUrl,
    required String username,
    required String password,
    required int id,
    required DateTime date,
    required String description,
    required ReminderUrgency urgency,
    String? notes,
    String? metric,
    int? dueOdometer,
  }) async {
    final formData = <String, dynamic>{
      'id': id.toString(),
      'date': DateFormatters.formatForApi(date),
      'description': description,
      'urgency': urgency.name,
    };
    
    if (notes != null && notes.isNotEmpty) {
      formData['notes'] = notes;
    }
    
    if (metric != null && metric.isNotEmpty) {
      formData['metric'] = metric;
    }
    
    if (dueOdometer != null) {
      formData['dueOdometer'] = dueOdometer.toString();
    }
    
    final formDataMap = apiClient.buildFormData(formData);
    
    final response = await apiClient.put(
      '/api/vehicle/reminders/update',
      serverUrl: serverUrl,
      username: username,
      password: password,
      body: formDataMap,
      isFormData: true,
    );
    
    if (response.statusCode != 200) {
      throw Exception('Failed to update reminder: ${response.statusCode}');
    }
  }

  Future<void> deleteReminder({
    required String serverUrl,
    required String username,
    required String password,
    required int id,
  }) async {
    final response = await apiClient.delete(
      '/api/vehicle/reminders/delete',
      serverUrl: serverUrl,
      username: username,
      password: password,
      queryParameters: {'id': id.toString()},
    );
    
    if (response.statusCode != 200) {
      throw Exception('Failed to delete reminder: ${response.statusCode}');
    }
  }

  // Service Records
  Future<List<ServiceRecord>> getServiceRecords({
    required String serverUrl,
    required String username,
    required String password,
    required int vehicleId,
  }) async {
    final response = await apiClient.get(
      '/api/vehicle/servicerecords',
      serverUrl: serverUrl,
      username: username,
      password: password,
      queryParameters: {'vehicleId': vehicleId.toString()},
    );
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List;
      return data.map((json) {
        final recordJson = json as Map<String, dynamic>;
        if (!recordJson.containsKey('vehicleId') && 
            !recordJson.containsKey('vehicle_id') && 
            !recordJson.containsKey('VehicleId')) {
          recordJson['vehicleId'] = vehicleId;
        }
        return ServiceRecord.fromJson(recordJson);
      }).toList();
    }
    
    throw Exception('Failed to load service records: ${response.statusCode}');
  }

  Future<void> addServiceRecord({
    required String serverUrl,
    required String username,
    required String password,
    required int vehicleId,
    required DateTime date,
    required int odometer,
    required String description,
    required double cost,
    String? notes,
    List<ExtraField>? extraFields,
  }) async {
    final formData = <String, dynamic>{
      'date': DateFormatters.formatForApi(date),
      'odometer': odometer.toString(),
      'description': description,
      'cost': cost.toString(),
    };
    
    if (notes != null && notes.isNotEmpty) {
      formData['notes'] = notes;
    }
    
    if (extraFields != null && extraFields.isNotEmpty) {
      formData['extrafields'] = extraFields.map((e) => e.toJson()).toList();
    }
    
    final formDataMap = apiClient.buildFormData(formData);
    
    final response = await apiClient.post(
      '/api/vehicle/servicerecords/add',
      serverUrl: serverUrl,
      username: username,
      password: password,
      queryParameters: {'vehicleId': vehicleId.toString()},
      body: formDataMap,
      isFormData: true,
    );
    
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to add service record: ${response.statusCode}');
    }
  }

  Future<void> updateServiceRecord({
    required String serverUrl,
    required String username,
    required String password,
    required int id,
    required DateTime date,
    required int odometer,
    required String description,
    required double cost,
    String? notes,
    List<ExtraField>? extraFields,
  }) async {
    final formData = <String, dynamic>{
      'id': id.toString(),
      'date': DateFormatters.formatForApi(date),
      'odometer': odometer.toString(),
      'description': description,
      'cost': cost.toString(),
    };
    
    if (notes != null && notes.isNotEmpty) {
      formData['notes'] = notes;
    }
    
    if (extraFields != null && extraFields.isNotEmpty) {
      formData['extrafields'] = extraFields.map((e) => e.toJson()).toList();
    }
    
    final formDataMap = apiClient.buildFormData(formData);
    
    final response = await apiClient.put(
      '/api/vehicle/servicerecords/update',
      serverUrl: serverUrl,
      username: username,
      password: password,
      body: formDataMap,
      isFormData: true,
    );
    
    if (response.statusCode != 200) {
      throw Exception('Failed to update service record: ${response.statusCode}');
    }
  }

  Future<void> deleteServiceRecord({
    required String serverUrl,
    required String username,
    required String password,
    required int id,
  }) async {
    final response = await apiClient.delete(
      '/api/vehicle/servicerecords/delete',
      serverUrl: serverUrl,
      username: username,
      password: password,
      queryParameters: {'id': id.toString()},
    );
    
    if (response.statusCode != 200) {
      throw Exception('Failed to delete service record: ${response.statusCode}');
    }
  }

  // Repair Records
  Future<List<RepairRecord>> getRepairRecords({
    required String serverUrl,
    required String username,
    required String password,
    required int vehicleId,
  }) async {
    final response = await apiClient.get(
      '/api/vehicle/repairrecords',
      serverUrl: serverUrl,
      username: username,
      password: password,
      queryParameters: {'vehicleId': vehicleId.toString()},
    );
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List;
      return data.map((json) {
        final recordJson = json as Map<String, dynamic>;
        if (!recordJson.containsKey('vehicleId') && 
            !recordJson.containsKey('vehicle_id') && 
            !recordJson.containsKey('VehicleId')) {
          recordJson['vehicleId'] = vehicleId;
        }
        return RepairRecord.fromJson(recordJson);
      }).toList();
    }
    
    throw Exception('Failed to load repair records: ${response.statusCode}');
  }

  Future<void> addRepairRecord({
    required String serverUrl,
    required String username,
    required String password,
    required int vehicleId,
    required DateTime date,
    required int odometer,
    required String description,
    required double cost,
    String? notes,
    List<ExtraField>? extraFields,
  }) async {
    final formData = <String, dynamic>{
      'date': DateFormatters.formatForApi(date),
      'odometer': odometer.toString(),
      'description': description,
      'cost': cost.toString(),
    };
    
    if (notes != null && notes.isNotEmpty) {
      formData['notes'] = notes;
    }
    
    if (extraFields != null && extraFields.isNotEmpty) {
      formData['extrafields'] = extraFields.map((e) => e.toJson()).toList();
    }
    
    final formDataMap = apiClient.buildFormData(formData);
    
    final response = await apiClient.post(
      '/api/vehicle/repairrecords/add',
      serverUrl: serverUrl,
      username: username,
      password: password,
      queryParameters: {'vehicleId': vehicleId.toString()},
      body: formDataMap,
      isFormData: true,
    );
    
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to add repair record: ${response.statusCode}');
    }
  }

  Future<void> updateRepairRecord({
    required String serverUrl,
    required String username,
    required String password,
    required int id,
    required DateTime date,
    required int odometer,
    required String description,
    required double cost,
    String? notes,
    List<ExtraField>? extraFields,
  }) async {
    final formData = <String, dynamic>{
      'id': id.toString(),
      'date': DateFormatters.formatForApi(date),
      'odometer': odometer.toString(),
      'description': description,
      'cost': cost.toString(),
    };
    
    if (notes != null && notes.isNotEmpty) {
      formData['notes'] = notes;
    }
    
    if (extraFields != null && extraFields.isNotEmpty) {
      formData['extrafields'] = extraFields.map((e) => e.toJson()).toList();
    }
    
    final formDataMap = apiClient.buildFormData(formData);
    
    final response = await apiClient.put(
      '/api/vehicle/repairrecords/update',
      serverUrl: serverUrl,
      username: username,
      password: password,
      body: formDataMap,
      isFormData: true,
    );
    
    if (response.statusCode != 200) {
      throw Exception('Failed to update repair record: ${response.statusCode}');
    }
  }

  Future<void> deleteRepairRecord({
    required String serverUrl,
    required String username,
    required String password,
    required int id,
  }) async {
    final response = await apiClient.delete(
      '/api/vehicle/repairrecords/delete',
      serverUrl: serverUrl,
      username: username,
      password: password,
      queryParameters: {'id': id.toString()},
    );
    
    if (response.statusCode != 200) {
      throw Exception('Failed to delete repair record: ${response.statusCode}');
    }
  }

  // Upgrade Records
  Future<List<UpgradeRecord>> getUpgradeRecords({
    required String serverUrl,
    required String username,
    required String password,
    required int vehicleId,
  }) async {
    final response = await apiClient.get(
      '/api/vehicle/upgraderecords',
      serverUrl: serverUrl,
      username: username,
      password: password,
      queryParameters: {'vehicleId': vehicleId.toString()},
    );
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List;
      return data.map((json) {
        final recordJson = json as Map<String, dynamic>;
        if (!recordJson.containsKey('vehicleId') && 
            !recordJson.containsKey('vehicle_id') && 
            !recordJson.containsKey('VehicleId')) {
          recordJson['vehicleId'] = vehicleId;
        }
        return UpgradeRecord.fromJson(recordJson);
      }).toList();
    }
    
    throw Exception('Failed to load upgrade records: ${response.statusCode}');
  }

  Future<void> addUpgradeRecord({
    required String serverUrl,
    required String username,
    required String password,
    required int vehicleId,
    required DateTime date,
    required int odometer,
    required String description,
    required double cost,
    String? notes,
    List<ExtraField>? extraFields,
  }) async {
    final formData = <String, dynamic>{
      'date': DateFormatters.formatForApi(date),
      'odometer': odometer.toString(),
      'description': description,
      'cost': cost.toString(),
    };
    
    if (notes != null && notes.isNotEmpty) {
      formData['notes'] = notes;
    }
    
    if (extraFields != null && extraFields.isNotEmpty) {
      formData['extrafields'] = extraFields.map((e) => e.toJson()).toList();
    }
    
    final formDataMap = apiClient.buildFormData(formData);
    
    final response = await apiClient.post(
      '/api/vehicle/upgraderecords/add',
      serverUrl: serverUrl,
      username: username,
      password: password,
      queryParameters: {'vehicleId': vehicleId.toString()},
      body: formDataMap,
      isFormData: true,
    );
    
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to add upgrade record: ${response.statusCode}');
    }
  }

  Future<void> updateUpgradeRecord({
    required String serverUrl,
    required String username,
    required String password,
    required int id,
    required DateTime date,
    required int odometer,
    required String description,
    required double cost,
    String? notes,
    List<ExtraField>? extraFields,
  }) async {
    final formData = <String, dynamic>{
      'id': id.toString(),
      'date': DateFormatters.formatForApi(date),
      'odometer': odometer.toString(),
      'description': description,
      'cost': cost.toString(),
    };
    
    if (notes != null && notes.isNotEmpty) {
      formData['notes'] = notes;
    }
    
    if (extraFields != null && extraFields.isNotEmpty) {
      formData['extrafields'] = extraFields.map((e) => e.toJson()).toList();
    }
    
    final formDataMap = apiClient.buildFormData(formData);
    
    final response = await apiClient.put(
      '/api/vehicle/upgraderecords/update',
      serverUrl: serverUrl,
      username: username,
      password: password,
      body: formDataMap,
      isFormData: true,
    );
    
    if (response.statusCode != 200) {
      throw Exception('Failed to update upgrade record: ${response.statusCode}');
    }
  }

  Future<void> deleteUpgradeRecord({
    required String serverUrl,
    required String username,
    required String password,
    required int id,
  }) async {
    final response = await apiClient.delete(
      '/api/vehicle/upgraderecords/delete',
      serverUrl: serverUrl,
      username: username,
      password: password,
      queryParameters: {'id': id.toString()},
    );
    
    if (response.statusCode != 200) {
      throw Exception('Failed to delete upgrade record: ${response.statusCode}');
    }
  }

  // Tax Records
  Future<List<TaxRecord>> getTaxRecords({
    required String serverUrl,
    required String username,
    required String password,
    required int vehicleId,
  }) async {
    final response = await apiClient.get(
      '/api/vehicle/taxrecords',
      serverUrl: serverUrl,
      username: username,
      password: password,
      queryParameters: {'vehicleId': vehicleId.toString()},
    );
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List;
      return data.map((json) {
        final recordJson = json as Map<String, dynamic>;
        if (!recordJson.containsKey('vehicleId') && 
            !recordJson.containsKey('vehicle_id') && 
            !recordJson.containsKey('VehicleId')) {
          recordJson['vehicleId'] = vehicleId;
        }
        return TaxRecord.fromJson(recordJson);
      }).toList();
    }
    
    throw Exception('Failed to load tax records: ${response.statusCode}');
  }

  Future<void> addTaxRecord({
    required String serverUrl,
    required String username,
    required String password,
    required int vehicleId,
    required DateTime date,
    required String description,
    required double cost,
    String? notes,
    List<ExtraField>? extraFields,
  }) async {
    final formData = <String, dynamic>{
      'date': DateFormatters.formatForApi(date),
      'description': description,
      'cost': cost.toString(),
    };
    
    if (notes != null && notes.isNotEmpty) {
      formData['notes'] = notes;
    }
    
    if (extraFields != null && extraFields.isNotEmpty) {
      formData['extrafields'] = extraFields.map((e) => e.toJson()).toList();
    }
    
    final formDataMap = apiClient.buildFormData(formData);
    
    final response = await apiClient.post(
      '/api/vehicle/taxrecords/add',
      serverUrl: serverUrl,
      username: username,
      password: password,
      queryParameters: {'vehicleId': vehicleId.toString()},
      body: formDataMap,
      isFormData: true,
    );
    
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to add tax record: ${response.statusCode}');
    }
  }

  Future<void> updateTaxRecord({
    required String serverUrl,
    required String username,
    required String password,
    required int id,
    required DateTime date,
    required String description,
    required double cost,
    String? notes,
    List<ExtraField>? extraFields,
  }) async {
    final formData = <String, dynamic>{
      'id': id.toString(),
      'date': DateFormatters.formatForApi(date),
      'description': description,
      'cost': cost.toString(),
    };
    
    if (notes != null && notes.isNotEmpty) {
      formData['notes'] = notes;
    }
    
    if (extraFields != null && extraFields.isNotEmpty) {
      formData['extrafields'] = extraFields.map((e) => e.toJson()).toList();
    }
    
    final formDataMap = apiClient.buildFormData(formData);
    
    final response = await apiClient.put(
      '/api/vehicle/taxrecords/update',
      serverUrl: serverUrl,
      username: username,
      password: password,
      body: formDataMap,
      isFormData: true,
    );
    
    if (response.statusCode != 200) {
      throw Exception('Failed to update tax record: ${response.statusCode}');
    }
  }

  Future<void> deleteTaxRecord({
    required String serverUrl,
    required String username,
    required String password,
    required int id,
  }) async {
    final response = await apiClient.delete(
      '/api/vehicle/taxrecords/delete',
      serverUrl: serverUrl,
      username: username,
      password: password,
      queryParameters: {'id': id.toString()},
    );
    
    if (response.statusCode != 200) {
      throw Exception('Failed to delete tax record: ${response.statusCode}');
    }
  }
}
