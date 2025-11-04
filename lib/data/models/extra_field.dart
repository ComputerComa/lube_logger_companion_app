class ExtraField {
  final String name;
  final String value;
  
  ExtraField({
    required this.name,
    required this.value,
  });
  
  factory ExtraField.fromJson(Map<String, dynamic> json) {
    return ExtraField(
      name: json['name'] as String? ?? '',
      value: json['value'] as String? ?? '',
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'value': value,
    };
  }
}

