import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lube_logger_companion_app/core/utils/validators.dart';
import 'package:lube_logger_companion_app/data/models/extra_field.dart';
import 'package:lube_logger_companion_app/data/models/extra_field_definition.dart';
import 'package:lube_logger_companion_app/data/models/plan_record.dart';
import 'package:lube_logger_companion_app/presentation/widgets/extra_fields_form_section.dart';
import 'package:lube_logger_companion_app/providers/extra_fields_provider.dart';
import 'package:lube_logger_companion_app/providers/plan_provider.dart';
import 'package:lube_logger_companion_app/providers/vehicle_provider.dart';

class AddPlanScreen extends ConsumerStatefulWidget {
  final int? vehicleId;
  final PlanRecord? record;

  const AddPlanScreen({
    super.key,
    this.vehicleId,
    this.record,
  });

  bool get isEditing => record != null;

  @override
  ConsumerState<AddPlanScreen> createState() => _AddPlanScreenState();
}

class _AddPlanScreenState extends ConsumerState<AddPlanScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _costController = TextEditingController();
  final _notesController = TextEditingController();
  final _extraFieldsKey = GlobalKey<ExtraFieldsFormSectionState>();

  int? _selectedVehicleId;
  PlanRecordType _selectedType = PlanRecordType.service;
  PlanRecordPriority _selectedPriority = PlanRecordPriority.normal;
  PlanRecordProgress _selectedProgress = PlanRecordProgress.backlog;
  Map<String, String> _initialExtraFieldValues = {};

  @override
  void initState() {
    super.initState();
    final record = widget.record;
    if (record != null) {
      _selectedVehicleId = record.vehicleId;
      _descriptionController.text = record.description;
      _costController.text = record.cost.toStringAsFixed(2);
      _notesController.text = record.notes ?? '';
      _selectedType = record.type == PlanRecordType.unknown
          ? PlanRecordType.service
          : record.type;
      _selectedPriority = record.priority == PlanRecordPriority.unknown
          ? PlanRecordPriority.normal
          : record.priority;
      _selectedProgress = record.progress == PlanRecordProgress.unknown
          ? PlanRecordProgress.backlog
          : record.progress;
      _initialExtraFieldValues = {
        for (final field in record.extraFields) field.name: field.value,
      };
    } else {
      _selectedVehicleId = widget.vehicleId;
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _costController.dispose();
    _notesController.dispose();
    super.dispose();
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

      final params = (
        vehicleId: _selectedVehicleId!,
        description: _descriptionController.text,
        cost: double.parse(_costController.text),
        type: _selectedType,
        priority: _selectedPriority,
        progress: _selectedProgress,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
        extraFields: extraFields.isNotEmpty ? extraFields : null,
      );

      if (widget.isEditing) {
        await ref.read(updatePlanRecordProvider((
          id: widget.record!.id,
          vehicleId: params.vehicleId,
          description: params.description,
          cost: params.cost,
          type: params.type,
          priority: params.priority,
          progress: params.progress,
          notes: params.notes,
          extraFields: params.extraFields,
        )).future);
      } else {
        await ref.read(addPlanRecordProvider(params).future);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.isEditing
                ? 'Plan record updated successfully'
                : 'Plan record added successfully'),
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
        title: Text(widget.isEditing ? 'Edit Plan Record' : 'Add Plan Record'),
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
                    items: vehicles
                        .map(
                          (vehicle) => DropdownMenuItem<int>(
                            value: vehicle.id,
                            child: Text(vehicle.displayName),
                          ),
                        )
                        .toList(),
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
                error: (error, stackTrace) => Text('Error: $error'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => Validators.validateRequired(value, 'Description'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _costController,
                decoration: const InputDecoration(
                  labelText: 'Cost',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.attach_money),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) => Validators.validatePositiveNumber(value, 'Cost'),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<PlanRecordType>(
                key: ValueKey(_selectedType),
                initialValue: _selectedType,
                decoration: const InputDecoration(
                  labelText: 'Record Type',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                    value: PlanRecordType.service,
                    child: Text('Service'),
                  ),
                  DropdownMenuItem(
                    value: PlanRecordType.repair,
                    child: Text('Repair'),
                  ),
                  DropdownMenuItem(
                    value: PlanRecordType.upgrade,
                    child: Text('Upgrade'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedType = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<PlanRecordPriority>(
                key: ValueKey(_selectedPriority),
                initialValue: _selectedPriority,
                decoration: const InputDecoration(
                  labelText: 'Priority',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                    value: PlanRecordPriority.low,
                    child: Text('Low'),
                  ),
                  DropdownMenuItem(
                    value: PlanRecordPriority.normal,
                    child: Text('Normal'),
                  ),
                  DropdownMenuItem(
                    value: PlanRecordPriority.critical,
                    child: Text('Critical'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedPriority = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<PlanRecordProgress>(
                key: ValueKey(_selectedProgress),
                initialValue: _selectedProgress,
                decoration: const InputDecoration(
                  labelText: 'Progress',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                    value: PlanRecordProgress.backlog,
                    child: Text('Backlog'),
                  ),
                  DropdownMenuItem(
                    value: PlanRecordProgress.inProgress,
                    child: Text('In Progress'),
                  ),
                  DropdownMenuItem(
                    value: PlanRecordProgress.testing,
                    child: Text('Testing'),
                  ),
                  DropdownMenuItem(
                    value: PlanRecordProgress.done,
                    child: Text('Done'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedProgress = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.note),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              extraFieldsAsync.when(
                data: (records) {
                  final recordDefinition = records.firstWhere(
                    (record) => record.recordType == 'PlanRecord',
                    orElse: () => RecordExtraFields(
                      recordType: 'PlanRecord',
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
                        title: 'Additional Plan Fields',
                        initialValues: _initialExtraFieldValues,
                      ),
                      const SizedBox(height: 16),
                    ],
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (error, stackTrace) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _handleSubmit,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(widget.isEditing ? 'Save Changes' : 'Add Plan Record'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

