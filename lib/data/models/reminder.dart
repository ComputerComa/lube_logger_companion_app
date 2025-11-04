import 'package:flutter/material.dart';

enum ReminderUrgency {
  notUrgent,
  urgent,
  veryUrgent,
  pastDue,
}

extension ReminderUrgencyExtension on ReminderUrgency {
  String get name {
    switch (this) {
      case ReminderUrgency.notUrgent:
        return 'NotUrgent';
      case ReminderUrgency.urgent:
        return 'Urgent';
      case ReminderUrgency.veryUrgent:
        return 'VeryUrgent';
      case ReminderUrgency.pastDue:
        return 'PastDue';
    }
  }
  
  String get displayName {
    switch (this) {
      case ReminderUrgency.notUrgent:
        return 'Not Urgent';
      case ReminderUrgency.urgent:
        return 'Urgent';
      case ReminderUrgency.veryUrgent:
        return 'Very Urgent';
      case ReminderUrgency.pastDue:
        return 'Past Due';
    }
  }
  
  Color get color {
    switch (this) {
      case ReminderUrgency.notUrgent:
        return Colors.green;
      case ReminderUrgency.urgent:
        return Colors.yellow;
      case ReminderUrgency.veryUrgent:
        return Colors.red;
      case ReminderUrgency.pastDue:
        return const Color(0xFF8B0000); // Dark red / maroon
    }
  }
  
  static ReminderUrgency fromString(String value) {
    switch (value) {
      case 'NotUrgent':
        return ReminderUrgency.notUrgent;
      case 'Urgent':
        return ReminderUrgency.urgent;
      case 'VeryUrgent':
        return ReminderUrgency.veryUrgent;
      case 'PastDue':
        return ReminderUrgency.pastDue;
      default:
        return ReminderUrgency.notUrgent;
    }
  }
}

class Reminder {
  final int id;
  final int vehicleId;
  final String description;
  final DateTime date;
  final ReminderUrgency urgency;
  final String? notes;
  final String? metric;
  final int? dueOdometer;
  
  Reminder({
    required this.id,
    required this.vehicleId,
    required this.description,
    required this.date,
    required this.urgency,
    this.notes,
    this.metric,
    this.dueOdometer,
  });
  
  // Getter for backward compatibility with title
  String get title => description;
  
  factory Reminder.fromJson(Map<String, dynamic> json) {
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
      throw Exception('vehicleId is required but was null in reminder');
    }
    
    // Handle id - might be missing from API response
    int generateId(String description, String dueDate) {
      return '${description}_${dueDate}'.hashCode;
    }
    
    final idValue = json['id'] ?? json['Id'];
    final id = idValue != null 
        ? parseInt(idValue)
        : generateId(
            json['description']?.toString() ?? json['title']?.toString() ?? '', 
            json['dueDate']?.toString() ?? json['date']?.toString() ?? ''
          );
    
    // Use description or title (API uses description)
    final descriptionValue = json['description'] as String? ?? 
                             json['Description'] as String? ?? 
                             json['title'] as String? ?? 
                             json['Title'] as String? ?? 
                             '';
    
    // Use dueDate or date (API uses dueDate)
    final dateValue = json['dueDate'] ?? json['DueDate'] ?? json['date'] ?? json['Date'];
    
    // Parse dueOdometer if present
    int? parseOdometer(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is String) return int.tryParse(value);
      if (value is num) return value.toInt();
      return null;
    }
    
    return Reminder(
      id: id,
      vehicleId: parseInt(vehicleIdValue),
      description: descriptionValue,
      date: parseDate(dateValue),
      urgency: ReminderUrgencyExtension.fromString(
        json['urgency'] as String? ?? json['Urgency'] as String? ?? 'NotUrgent',
      ),
      notes: json['notes'] as String? ?? json['Notes'] as String?,
      metric: json['metric'] as String? ?? json['Metric'] as String?,
      dueOdometer: parseOdometer(json['dueOdometer'] ?? json['due_odometer'] ?? json['DueOdometer']),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'vehicleId': vehicleId,
      'description': description,
      'dueDate': date.toIso8601String(),
      'urgency': urgency.name,
      'notes': notes,
      'metric': metric,
      'dueOdometer': dueOdometer,
    };
  }
  
  bool get isUpcoming {
    final now = DateTime.now();
    final difference = date.difference(now);
    return difference.inDays >= 0 && difference.inDays <= 30;
  }
  
  bool get isPastDue {
    return date.isBefore(DateTime.now());
  }
}
