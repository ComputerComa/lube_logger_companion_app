class ExtraFieldDefinition {
  final String name;
  final bool isRequired;
  final String fieldType;

  ExtraFieldDefinition({
    required this.name,
    required this.isRequired,
    required this.fieldType,
  });

  factory ExtraFieldDefinition.fromJson(Map<String, dynamic> json) {
    final rawRequired = json['isRequired'];
    final bool isRequired;
    if (rawRequired is bool) {
      isRequired = rawRequired;
    } else if (rawRequired is String) {
      isRequired = rawRequired.toLowerCase() == 'true';
    } else if (rawRequired is num) {
      isRequired = rawRequired != 0;
    } else {
      isRequired = false;
    }

    return ExtraFieldDefinition(
      name: json['name'] as String? ?? '',
      isRequired: isRequired,
      fieldType: json['fieldType'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'isRequired': isRequired,
      'fieldType': fieldType,
    };
  }
}

class RecordExtraFields {
  final String recordType;
  final List<ExtraFieldDefinition> extraFields;

  RecordExtraFields({
    required this.recordType,
    required this.extraFields,
  });

  factory RecordExtraFields.fromJson(Map<String, dynamic> json) {
    final rawList = json['extraFields'] as List<dynamic>? ?? [];
    return RecordExtraFields(
      recordType: json['recordType'] as String? ?? '',
      extraFields: rawList
          .map((item) =>
              ExtraFieldDefinition.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'recordType': recordType,
      'extraFields': extraFields.map((e) => e.toJson()).toList(),
    };
  }
}

