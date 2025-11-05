import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lube_logger_companion_app/core/utils/validators.dart';
import 'package:lube_logger_companion_app/data/models/reminder.dart';
import 'package:lube_logger_companion_app/providers/vehicle_provider.dart';
import 'package:lube_logger_companion_app/services/notification_service.dart';
import 'package:intl/intl.dart';

class AddReminderScreen extends ConsumerStatefulWidget {
  final int? vehicleId;

  const AddReminderScreen({super.key, this.vehicleId});

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
    _selectedVehicleId = widget.vehicleId;
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

    // Note: The API doesn't have an add reminder endpoint in the Postman collection
    // This is a placeholder implementation
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Reminder functionality requires API endpoint implementation'),
      ),
    );

    // TODO: Implement when API endpoint is available
    // For now, we'll just schedule the notification
    if (_selectedVehicleId != null) {
      final reminder = Reminder(
        id: DateTime.now().millisecondsSinceEpoch,
        vehicleId: _selectedVehicleId!,
        description: _titleController.text,
        date: _selectedDate,
        urgency: _selectedUrgency,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      );

      await NotificationService.scheduleReminderNotification(reminder);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reminder notification scheduled')),
        );
        context.pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final vehiclesAsync = ref.watch(vehiclesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Reminder'),
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
                child: const Text('Add Reminder'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
