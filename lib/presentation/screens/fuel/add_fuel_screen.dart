import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lube_logger_companion_app/core/utils/validators.dart';
import 'package:lube_logger_companion_app/providers/vehicle_provider.dart';
import 'package:lube_logger_companion_app/providers/fuel_provider.dart';
import 'package:intl/intl.dart';

class AddFuelScreen extends ConsumerStatefulWidget {
  final int? vehicleId;

  const AddFuelScreen({super.key, this.vehicleId});

  @override
  ConsumerState<AddFuelScreen> createState() => _AddFuelScreenState();
}

class _AddFuelScreenState extends ConsumerState<AddFuelScreen> {
  final _formKey = GlobalKey<FormState>();
  final _odometerController = TextEditingController();
  final _gallonsController = TextEditingController();
  final _costController = TextEditingController();
  final _notesController = TextEditingController();
  final _tagController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  int? _selectedVehicleId;
  bool _isFillToFull = false;
  bool _missedFuelUp = false;
  final Set<String> _selectedTags = {};

  @override
  void initState() {
    super.initState();
    _selectedVehicleId = widget.vehicleId;
  }

  @override
  void dispose() {
    _odometerController.dispose();
    _gallonsController.dispose();
    _costController.dispose();
    _notesController.dispose();
    _tagController.dispose();
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

  void _addTag(String tag) {
    final trimmedTag = tag.trim();
    if (trimmedTag.isNotEmpty) {
      setState(() {
        _selectedTags.add(trimmedTag);
      });
      _tagController.clear();
    }
  }

  void _removeTag(String tag) {
    setState(() {
      _selectedTags.remove(tag);
    });
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
      await ref.read(addFuelProvider(
        (
          vehicleId: _selectedVehicleId!,
          date: _selectedDate,
          odometer: int.parse(_odometerController.text),
          gallons: double.parse(_gallonsController.text),
          cost: double.parse(_costController.text),
          isFillToFull: _isFillToFull,
          missedFuelUp: _missedFuelUp,
          tags: _selectedTags.toList(),
          notes: _notesController.text.isNotEmpty ? _notesController.text : null,
        ),
      ).future);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fuel entry added successfully')),
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
        title: const Text('Add Fuel Entry'),
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
                error: (error, stackTrace) => const Text('Error loading vehicles'),
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
                controller: _gallonsController,
                decoration: const InputDecoration(
                  labelText: 'Gallons',
                  hintText: 'Enter gallons',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.local_gas_station),
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                validator: (value) => Validators.validatePositiveNumber(
                  value,
                  'Gallons',
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _costController,
                decoration: const InputDecoration(
                  labelText: 'Cost',
                  hintText: 'Enter total cost',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.attach_money),
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                validator: (value) => Validators.validatePositiveNumber(
                  value,
                  'Cost',
                ),
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
              SwitchListTile(
                title: const Text('Filled To Full'),
                value: _isFillToFull,
                onChanged: (value) {
                  setState(() {
                    _isFillToFull = value;
                  });
                },
              ),
              SwitchListTile(
                title: const Text('Missed last Refill'),
                value: _missedFuelUp,
                onChanged: (value) {
                  setState(() {
                    _missedFuelUp = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              // Tags Section
              const Text(
                'Tags',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              // Selected Tags
              if (_selectedTags.isNotEmpty) ...[
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _selectedTags.map((tag) {
                    return Chip(
                      label: Text(tag),
                      onDeleted: () => _removeTag(tag),
                      deleteIcon: const Icon(Icons.close, size: 18),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 8),
              ],
              // Tag Input
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _tagController,
                      decoration: const InputDecoration(
                        labelText: 'Add Tag',
                        hintText: 'Enter tag name',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.tag),
                      ),
                      onSubmitted: _addTag,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () => _addTag(_tagController.text),
                    tooltip: 'Add Tag',
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Existing Tags
              if (_selectedVehicleId != null)
                Consumer(
                  builder: (context, ref, child) {
                    final fuelAsync = ref.watch(fuelRecordsProvider(_selectedVehicleId!));
                    return fuelAsync.when(
                      data: (records) {
                        // Collect all unique tags from this vehicle's fuel records
                        final allTags = <String>{};
                        for (final record in records) {
                          allTags.addAll(record.tags);
                        }
                        
                        // Filter out already selected tags
                        final availableTags = allTags.where((tag) => !_selectedTags.contains(tag) && tag.isNotEmpty).toList()..sort();
                        
                        if (availableTags.isEmpty) {
                          return const SizedBox.shrink();
                        }
                        
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Existing Tags',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: availableTags.map((tag) {
                                return ActionChip(
                                  label: Text(tag),
                                  onPressed: () => _addTag(tag),
                                  avatar: const Icon(Icons.add, size: 18),
                                );
                              }).toList(),
                            ),
                          ],
                        );
                      },
                      loading: () => const SizedBox.shrink(),
                      error: (error, stackTrace) => const SizedBox.shrink(),
                    );
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
                child: const Text('Add Entry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
