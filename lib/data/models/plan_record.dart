import 'package:lube_logger_companion_app/data/models/extra_field.dart';

enum PlanRecordType { service, repair, upgrade, unknown }

enum PlanRecordPriority { low, normal, critical, unknown }

enum PlanRecordProgress { backlog, inProgress, testing, done, unknown }

PlanRecordType planRecordTypeFromString(String? value) {
  switch (value) {
    case 'ServiceRecord':
      return PlanRecordType.service;
    case 'RepairRecord':
      return PlanRecordType.repair;
    case 'UpgradeRecord':
      return PlanRecordType.upgrade;
    default:
      return PlanRecordType.unknown;
  }
}

String planRecordTypeToApi(PlanRecordType type) {
  switch (type) {
    case PlanRecordType.service:
      return 'ServiceRecord';
    case PlanRecordType.repair:
      return 'RepairRecord';
    case PlanRecordType.upgrade:
      return 'UpgradeRecord';
    case PlanRecordType.unknown:
      return 'ServiceRecord';
  }
}

PlanRecordPriority planRecordPriorityFromString(String? value) {
  switch (value) {
    case 'Low':
      return PlanRecordPriority.low;
    case 'Normal':
      return PlanRecordPriority.normal;
    case 'Critical':
      return PlanRecordPriority.critical;
    default:
      return PlanRecordPriority.unknown;
  }
}

String planRecordPriorityToApi(PlanRecordPriority priority) {
  switch (priority) {
    case PlanRecordPriority.low:
      return 'Low';
    case PlanRecordPriority.normal:
      return 'Normal';
    case PlanRecordPriority.critical:
      return 'Critical';
    case PlanRecordPriority.unknown:
      return 'Normal';
  }
}

PlanRecordProgress planRecordProgressFromString(String? value) {
  switch (value) {
    case 'Backlog':
      return PlanRecordProgress.backlog;
    case 'InProgress':
      return PlanRecordProgress.inProgress;
    case 'Testing':
      return PlanRecordProgress.testing;
    case 'Done':
      return PlanRecordProgress.done;
    default:
      return PlanRecordProgress.unknown;
  }
}

String planRecordProgressToApi(PlanRecordProgress progress) {
  switch (progress) {
    case PlanRecordProgress.backlog:
      return 'Backlog';
    case PlanRecordProgress.inProgress:
      return 'InProgress';
    case PlanRecordProgress.testing:
      return 'Testing';
    case PlanRecordProgress.done:
      return 'Done';
    case PlanRecordProgress.unknown:
      return 'Backlog';
  }
}

class PlanRecord {
  final int id;
  final int vehicleId;
  final String description;
  final double cost;
  final PlanRecordType type;
  final PlanRecordPriority priority;
  final PlanRecordProgress progress;
  final String? notes;
  final List<ExtraField> extraFields;

  PlanRecord({
    required this.id,
    required this.vehicleId,
    required this.description,
    required this.cost,
    required this.type,
    required this.priority,
    required this.progress,
    this.notes,
    this.extraFields = const [],
  });

  factory PlanRecord.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) {
        final parsed = double.tryParse(value);
        if (parsed != null) return parsed;
      }
      return 0.0;
    }

    int parseInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is String) {
        return int.tryParse(value) ?? 0;
      }
      if (value is num) return value.toInt();
      return 0;
    }

    final extraFieldsJson =
        json['extrafields'] as List<dynamic>? ?? json['extraFields'] as List<dynamic>? ?? [];
    final extraFields = extraFieldsJson
        .map((e) => ExtraField.fromJson(e as Map<String, dynamic>))
        .toList();

    final idValue = json['id'] ?? json['Id'];
    final vehicleIdValue = json['vehicleId'] ?? json['vehicle_id'] ?? json['VehicleId'];

    return PlanRecord(
      id: parseInt(idValue),
      vehicleId: parseInt(vehicleIdValue),
      description: (json['description'] ?? '') as String,
      cost: parseDouble(json['cost']),
      type: planRecordTypeFromString(json['type'] as String? ?? json['Type'] as String?),
      priority: planRecordPriorityFromString(json['priority'] as String? ?? json['Priority'] as String?),
      progress: planRecordProgressFromString(json['progress'] as String? ?? json['Progress'] as String?),
      notes: json['notes'] as String?,
      extraFields: extraFields,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'vehicleId': vehicleId,
      'description': description,
      'cost': cost,
      'type': planRecordTypeToApi(type),
      'priority': planRecordPriorityToApi(priority),
      'progress': planRecordProgressToApi(progress),
      'notes': notes,
      'extrafields': extraFields.map((e) => e.toJson()).toList(),
    };
  }
}

