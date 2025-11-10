import 'package:flutter/material.dart';
import 'package:lube_logger_companion_app/data/models/extra_field.dart';
import 'package:lube_logger_companion_app/data/models/extra_field_definition.dart';

class ExtraFieldsFormSection extends StatefulWidget {
  final List<ExtraFieldDefinition> definitions;
  final String title;
  final Map<String, String>? initialValues;

  const ExtraFieldsFormSection({
    super.key,
    required this.definitions,
    this.title = 'Additional Fields',
    this.initialValues,
  });

  @override
  State<ExtraFieldsFormSection> createState() => ExtraFieldsFormSectionState();
}

class ExtraFieldsFormSectionState extends State<ExtraFieldsFormSection> {
  final Map<String, TextEditingController> _controllers = {};
  Map<String, String> _lastInitialValues = {};

  @override
  void initState() {
    super.initState();
    _syncControllers();
  }

  @override
  void didUpdateWidget(covariant ExtraFieldsFormSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.definitions != widget.definitions) {
      _syncControllers();
    }
  }

  void _syncControllers() {
    final fieldNames =
        widget.definitions.map((definition) => definition.name).toSet();

    // Add controllers for new fields
    for (final definition in widget.definitions) {
      final didExist = _controllers.containsKey(definition.name);
      final controller = _controllers.putIfAbsent(
        definition.name,
        () => TextEditingController(),
      );
      final initialValue =
          widget.initialValues?[definition.name] ?? '';
      final lastValue = _lastInitialValues[definition.name];
      if (!didExist || lastValue != initialValue) {
        controller.text = initialValue;
      }
    }

    // Remove controllers for fields that no longer exist
    final keysToRemove = _controllers.keys
        .where((fieldName) => !fieldNames.contains(fieldName))
        .toList();

    for (final key in keysToRemove) {
      _controllers[key]?.dispose();
      _controllers.remove(key);
      _lastInitialValues.remove(key);
    }

    // Track current initial values
    _lastInitialValues = {
      for (final definition in widget.definitions)
        definition.name: widget.initialValues?[definition.name] ?? '',
    };
  }

  List<ExtraField> collectExtraFields() {
    final result = <ExtraField>[];
    for (final definition in widget.definitions) {
      final controller = _controllers[definition.name];
      if (controller == null) continue;
      final value = controller.text.trim();
      if (value.isNotEmpty || definition.isRequired) {
        result.add(ExtraField(name: definition.name, value: value));
      }
    }
    return result;
  }

  TextInputType _keyboardTypeForField(ExtraFieldDefinition definition) {
    switch (definition.fieldType.toLowerCase()) {
      case 'number':
      case 'integer':
        return TextInputType.number;
      case 'decimal':
      case 'double':
        return const TextInputType.numberWithOptions(decimal: true);
      case 'phone':
        return TextInputType.phone;
      case 'email':
        return TextInputType.emailAddress;
      default:
        return TextInputType.text;
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    _controllers.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.definitions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        ...widget.definitions.map((definition) {
          final controller = _controllers[definition.name]!;
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: TextFormField(
              controller: controller,
              decoration: InputDecoration(
                labelText: definition.isRequired
                    ? '${definition.name} *'
                    : definition.name,
                border: const OutlineInputBorder(),
              ),
              keyboardType: _keyboardTypeForField(definition),
              validator: (value) {
                if (definition.isRequired &&
                    (value == null || value.trim().isEmpty)) {
                  return '${definition.name} is required';
                }
                return null;
              },
            ),
          );
        }),
      ],
    );
  }
}

