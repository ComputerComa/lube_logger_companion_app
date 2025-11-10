import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lube_logger_companion_app/core/utils/validators.dart';
import 'package:lube_logger_companion_app/providers/vehicle_provider.dart';
import 'package:lube_logger_companion_app/providers/odometer_provider.dart';
import 'package:lube_logger_companion_app/providers/extra_fields_provider.dart';
import 'package:lube_logger_companion_app/data/models/extra_field.dart';
import 'package:lube_logger_companion_app/data/models/extra_field_definition.dart';
import 'package:lube_logger_companion_app/data/models/odometer_record.dart';
import 'package:lube_logger_companion_app/presentation/widgets/extra_fields_form_section.dart';
import 'package:intl/intl.dart';

class AddOdometerScreen extends ConsumerStatefulWidget {
  final int? vehicleId;
  final OdometerRecord? record;

  const AddOdometerScreen({
    super.key,
    this.vehicleId,
    this.record,
  });

  bool get isEditing => record != null;

  @override
  ConsumerState<AddOdometerScreen> createState() => _AddOdometerScreenState();
}

class _AddOdometerScreenState extends ConsumerState<AddOdometerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _odometerController = TextEditingController();
  final _initialOdometerController = TextEditingController();
  final _extraFieldsKey = GlobalKey<ExtraFieldsFormSectionState>();
  DateTime _selectedDate = DateTime.now();
  int? _selectedVehicleId;
  Map<String, String> _initialExtraFieldValues = {};

  @override
  void initState() {
    super.initState();
    final record = widget.record;
    if (record != null) {
      _selectedVehicleId = record.vehicleId;
      _selectedDate = record.date;
      _odometerController.text = record.odometer.toString();
      if (record.initialOdometer != null) {
        _initialOdometerController.text = record.initialOdometer.toString();
      }
      _initialExtraFieldValues = {
        for (final field in record.extraFields) field.name: field.value,
      };
    } else {
      _selectedVehicleId = widget.vehicleId;
    }
  }

  @override
  void dispose() {
    _odometerController.dispose();
    _initialOdometerController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedVehicleId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a vehicle')),
      );
      return;
    }

    try {
      final extraFields =
          _extraFieldsKey.currentState?.collectExtraFields() ?? <ExtraField>[];

      if (widget.isEditing) {
        await ref.read(updateOdometerProvider((
          id: widget.record!.id,
          date: _selectedDate,
          odometer: int.parse(_odometerController.text),
          initialOdometer: _initialOdometerController.text.isNotEmpty
              ? int.tryParse(_initialOdometerController.text)
              : null,
          extraFields: extraFields.isNotEmpty ? extraFields : null,
        )).future);
      } else {
        await ref.read(addOdometerProvider((
          vehicleId: _selectedVehicleId!,
          date: _selectedDate,
          odometer: int.parse(_odometerController.text),
          extraFields: extraFields.isNotEmpty ? extraFields : null,
        )).future);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.isEditing
                ? 'Odometer entry updated successfully'
                : 'Odometer entry added successfully'),
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final vehiclesAsync = ref.watch(vehiclesProvider);
    final extraFieldsAsync = ref.watch(extraFieldDefinitionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit Odometer Entry' : 'Add Odometer Entry'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              vehiclesAsync.when(
                data: (vehicles) {
                  if (vehicles.isEmpty) {
                    return const Text('No vehicles found');
                  }
                  return DropdownButtonFormField<int>(
                    key: ValueKey(_selectedVehicleId),
                    initialValue: _selectedVehicleId,
                    decoration: const InputDecoration(
                      labelText: 'Vehicle',
                      border: OutlineInputBorder(),
                    ),
                    items: vehicles.map((vehicle) {
                      return DropdownMenuItem<int>(
                        value: vehicle.id,
                        child: Text(vehicle.displayName),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedVehicleId = value;
                      });
                    },
                    validator: (value) {
                      if (value == null) {
                        return 'Please select a vehicle';
                      }
                      return null;
                    },
                  );
                },
                loading: () => const CircularProgressIndicator(),
                error: (_, _) => const Text('Error loading vehicles'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _odometerController,
                decoration: const InputDecoration(
                  labelText: 'Odometer Reading',
                  hintText: 'Enter odometer reading',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.speed),
                ),
                keyboardType: TextInputType.number,
                validator: (value) => Validators.validatePositiveNumber(
                  value,
                  'Odometer reading',
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _initialOdometerController,
                decoration: const InputDecoration(
                  labelText: 'Initial Odometer (optional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.history),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              extraFieldsAsync.when(
                data: (records) {
                  final recordDefinition = records.firstWhere(
                    (record) => record.recordType == 'OdometerRecord',
                    orElse: () => RecordExtraFields(
                      recordType: 'OdometerRecord',
                      extraFields: const [],
                    ),
                  );

                  if (recordDefinition.extraFields.isEmpty) {
                    return const SizedBox.shrink();
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ExtraFieldsFormSection(
                        key: _extraFieldsKey,
                        definitions: recordDefinition.extraFields,
                        title: 'Additional Odometer Fields',
                        initialValues: _initialExtraFieldValues,
                      ),
                      const SizedBox(height: 16),
                    ],
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (error, stack) => const SizedBox.shrink(),
              ),
              InkWell(
                onTap: _selectDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Date',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(DateFormat('MM/dd/yyyy').format(_selectedDate)),
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _handleSubmit,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(widget.isEditing ? 'Save Changes' : 'Add Entry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
