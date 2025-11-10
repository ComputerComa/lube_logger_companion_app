import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lube_logger_companion_app/core/utils/validators.dart';
import 'package:lube_logger_companion_app/data/models/reminder.dart';
import 'package:lube_logger_companion_app/providers/vehicle_provider.dart';
import 'package:lube_logger_companion_app/providers/reminder_provider.dart';
import 'package:lube_logger_companion_app/services/notification_service.dart';
import 'package:intl/intl.dart';

class AddReminderScreen extends ConsumerStatefulWidget {
  final int? vehicleId;
  final Reminder? record;

  const AddReminderScreen({
    super.key,
    this.vehicleId,
    this.record,
  });

  bool get isEditing => record != null;

  @override
  ConsumerState<AddReminderScreen> createState() => _AddReminderScreenState();
}

class _AddReminderScreenState extends ConsumerState<AddReminderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  ReminderUrgency _selectedUrgency = ReminderUrgency.notUrgent;
  int? _selectedVehicleId;

  @override
  void initState() {
    super.initState();
    final record = widget.record;
    if (record != null) {
      _selectedVehicleId = record.vehicleId;
      _titleController.text = record.description;
      _notesController.text = record.notes ?? '';
      _selectedDate = record.date;
      _selectedUrgency = record.urgency;
    } else {
      _selectedVehicleId = widget.vehicleId;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
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
      if (widget.isEditing) {
        await ref.read(updateReminderProvider((
          id: widget.record!.id,
          date: _selectedDate,
          description: _titleController.text,
          urgency: _selectedUrgency,
          notes: _notesController.text.isNotEmpty ? _notesController.text : null,
          metric: null,
          dueOdometer: null,
          vehicleId: _selectedVehicleId,
        )).future);
      } else {
        await ref.read(addReminderProvider((
          vehicleId: _selectedVehicleId!,
          date: _selectedDate,
          description: _titleController.text,
          urgency: _selectedUrgency,
          notes: _notesController.text.isNotEmpty ? _notesController.text : null,
          metric: null,
          dueOdometer: null,
        )).future);
      }

      // Schedule notification for the reminder
      final reminder = Reminder(
        id: widget.record?.id ?? DateTime.now().millisecondsSinceEpoch,
        vehicleId: _selectedVehicleId!,
        description: _titleController.text,
        date: _selectedDate,
        urgency: _selectedUrgency,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      );
      await NotificationService.scheduleReminderNotification(reminder);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.isEditing
                ? 'Reminder updated successfully'
                : 'Reminder added successfully'),
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

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit Reminder' : 'Add Reminder'),
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
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  hintText: 'Enter reminder title',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.title),
                ),
                validator: (value) => Validators.validateRequired(value, 'Title'),
              ),
              const SizedBox(height: 16),
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
              const SizedBox(height: 16),
              DropdownButtonFormField<ReminderUrgency>(
                key: ValueKey(_selectedUrgency),
                initialValue: _selectedUrgency,
                decoration: const InputDecoration(
                  labelText: 'Urgency',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.priority_high),
                ),
                items: ReminderUrgency.values.map((urgency) {
                  return DropdownMenuItem<ReminderUrgency>(
                    value: urgency,
                    child: Text(urgency.displayName),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedUrgency = value;
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
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _handleSubmit,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(widget.isEditing ? 'Save Changes' : 'Add Reminder'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
