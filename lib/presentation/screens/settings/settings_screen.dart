import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lube_logger_companion_app/presentation/routing/app_router.dart';
import 'package:lube_logger_companion_app/providers/auth_provider.dart';
import 'package:lube_logger_companion_app/services/polling_service.dart';
import 'package:lube_logger_companion_app/services/storage_service.dart';
import 'package:lube_logger_companion_app/providers/vehicle_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final pollingEnabledAsync = ref.watch(pollingEnabledProvider);
    final pollingIntervalAsync = ref.watch(pollingIntervalProvider);
    final authState = ref.watch(authStateProvider);
    final pollingService = ref.watch(pollingServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Connection Settings Section
          _buildSectionHeader('Connection'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.dns),
                  title: const Text('Server URL'),
                  subtitle: Text(
                    authState.serverUrl ?? 'Not set',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.person),
                  title: const Text('Username'),
                  subtitle: Text(
                    authState.username ?? 'Not set',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                if (!authState.isAuthenticated)
                  ListTile(
                    leading: const Icon(Icons.warning, color: Colors.orange),
                    title: const Text('Not Connected'),
                    subtitle: const Text('Please configure your connection in Setup'),
                    trailing: ElevatedButton(
                      onPressed: () {
                        context.push(AppRoutes.setup);
                      },
                      child: const Text('Setup'),
                    ),
                  ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Data Refresh Section
          _buildSectionHeader('Data Refresh'),
          Card(
            child: Column(
              children: [
                pollingEnabledAsync.when(
                  data: (enabled) => SwitchListTile(
                    secondary: const Icon(Icons.refresh),
                    title: const Text('Auto Refresh'),
                    subtitle: const Text('Automatically refresh data from server'),
                    value: enabled,
                    onChanged: (value) async {
                      await StorageService.setPollingEnabled(value);
                      ref.invalidate(pollingEnabledProvider);
                      
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            value 
                              ? 'Auto refresh enabled' 
                              : 'Auto refresh disabled',
                          ),
                        ),
                      );
                    },
                  ),
                  loading: () => const ListTile(
                    leading: CircularProgressIndicator(),
                    title: Text('Loading...'),
                  ),
                  error: (error, stack) => ListTile(
                    leading: const Icon(Icons.error, color: Colors.red),
                    title: const Text('Error loading setting'),
                    subtitle: Text('$error'),
                  ),
                ),
                pollingIntervalAsync.when(
                  data: (interval) => _PollingIntervalTile(
                    interval: interval,
                    onChanged: (newInterval) async {
                      await StorageService.setPollingInterval(newInterval);
                      ref.invalidate(pollingIntervalProvider);
                      
                      // Restart polling with new interval if enabled
                      final enabled = await StorageService.isPollingEnabled();
                      if (enabled && authState.isAuthenticated) {
                        pollingService.startPolling(intervalSeconds: newInterval);
                      }
                      
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Refresh interval set to ${_formatInterval(newInterval)}',
                          ),
                        ),
                      );
                    },
                  ),
                  loading: () => const ListTile(
                    leading: CircularProgressIndicator(),
                    title: Text('Loading...'),
                  ),
                  error: (error, stack) => ListTile(
                    leading: const Icon(Icons.error, color: Colors.red),
                    title: const Text('Error loading setting'),
                    subtitle: Text('$error'),
                  ),
                ),
                if (pollingService.isPolling)
                  ListTile(
                    leading: const Icon(Icons.check_circle, color: Colors.green),
                    title: const Text('Status'),
                    subtitle: const Text('Auto refresh is currently active'),
                  ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // App Settings Section
          _buildSectionHeader('App'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('About'),
                  subtitle: const Text('App version and information'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    context.push(AppRoutes.info);
                  },
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Actions Section
          _buildSectionHeader('Actions'),
          Card(
            child: Column(
              children: [
                if (authState.isAuthenticated)
                  ListTile(
                    leading: const Icon(Icons.logout, color: Colors.red),
                    title: const Text('Logout'),
                    subtitle: const Text('Clear stored credentials and logout'),
                    onTap: () => _showLogoutDialog(context, ref),
                  ),
                ListTile(
                  leading: const Icon(Icons.refresh),
                  title: const Text('Refresh Now'),
                  subtitle: const Text('Manually refresh all data'),
                  onTap: () => _refreshAllData(context, ref),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  String _formatInterval(int seconds) {
    if (seconds < 60) {
      return '$seconds seconds';
    } else if (seconds < 3600) {
      final minutes = seconds ~/ 60;
      return '$minutes minute${minutes > 1 ? 's' : ''}';
    } else {
      final hours = seconds ~/ 3600;
      return '$hours hour${hours > 1 ? 's' : ''}';
    }
  }

  Future<void> _showLogoutDialog(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text(
          'Are you sure you want to logout? This will clear your stored credentials.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await StorageService.clearAll();
      ref.invalidate(authStateProvider);
      
      if (context.mounted) {
        context.go(AppRoutes.setup);
      }
    }
  }

  void _refreshAllData(BuildContext context, WidgetRef ref) {
    final authState = ref.read(authStateProvider);
    
    if (!authState.isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please connect to a server first'),
        ),
      );
      return;
    }

    // Invalidate all providers to force refresh
    ref.invalidate(vehiclesProvider);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Refreshing data...'),
        duration: Duration(seconds: 1),
      ),
    );
  }
}

class _PollingIntervalTile extends StatefulWidget {
  final int interval;
  final ValueChanged<int> onChanged;

  const _PollingIntervalTile({
    required this.interval,
    required this.onChanged,
  });

  @override
  State<_PollingIntervalTile> createState() => _PollingIntervalTileState();
}

class _PollingIntervalTileState extends State<_PollingIntervalTile> {
  late int _currentInterval;

  @override
  void initState() {
    super.initState();
    _currentInterval = widget.interval;
  }

  @override
  void didUpdateWidget(_PollingIntervalTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.interval != widget.interval) {
      _currentInterval = widget.interval;
    }
  }

  String _formatInterval(int seconds) {
    if (seconds < 60) {
      return '$seconds seconds';
    } else if (seconds < 3600) {
      final minutes = seconds ~/ 60;
      return '$minutes minute${minutes > 1 ? 's' : ''}';
    } else {
      final hours = seconds ~/ 3600;
      return '$hours hour${hours > 1 ? 's' : ''}';
    }
  }

  Future<void> _showIntervalDialog() async {
    final interval = await showDialog<int>(
      context: context,
      builder: (context) => _IntervalDialog(initialInterval: _currentInterval),
    );

    if (interval != null && interval != _currentInterval) {
      setState(() {
        _currentInterval = interval;
      });
      widget.onChanged(interval);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.timer),
      title: const Text('Refresh Interval'),
      subtitle: Text(_formatInterval(_currentInterval)),
      trailing: const Icon(Icons.chevron_right),
      onTap: _showIntervalDialog,
    );
  }
}

class _IntervalDialog extends StatefulWidget {
  final int initialInterval;

  const _IntervalDialog({required this.initialInterval});

  @override
  State<_IntervalDialog> createState() => _IntervalDialogState();
}

class _IntervalDialogState extends State<_IntervalDialog> {
  late int _selectedInterval;
  final TextEditingController _customController = TextEditingController();
  bool _useCustom = false;

  // Predefined intervals in seconds
  final List<int> _presetIntervals = [
    10,
    30,
    60,
    120,
    300,
    600,
    1800,
    3600,
  ];

  @override
  void initState() {
    super.initState();
    _selectedInterval = widget.initialInterval;
    _useCustom = !_presetIntervals.contains(widget.initialInterval);
    if (_useCustom) {
      _customController.text = widget.initialInterval.toString();
    }
  }

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  String _formatInterval(int seconds) {
    if (seconds < 60) {
      return '$seconds seconds';
    } else if (seconds < 3600) {
      final minutes = seconds ~/ 60;
      return '$minutes minute${minutes > 1 ? 's' : ''}';
    } else {
      final hours = seconds ~/ 3600;
      return '$hours hour${hours > 1 ? 's' : ''}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select Refresh Interval'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ..._presetIntervals.map((interval) => RadioListTile<int>(
              title: Text(_formatInterval(interval)),
              value: interval,
              groupValue: _useCustom ? null : _selectedInterval,
              onChanged: (value) {
                setState(() {
                  _selectedInterval = value!;
                  _useCustom = false;
                });
              },
            )),
            RadioListTile<bool>(
              title: const Text('Custom'),
              value: true,
              groupValue: _useCustom,
              onChanged: (value) {
                setState(() {
                  _useCustom = true;
                });
              },
            ),
            if (_useCustom)
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _customController,
                  decoration: const InputDecoration(
                    labelText: 'Interval (seconds)',
                    hintText: 'Enter interval in seconds',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    final parsed = int.tryParse(value);
                    if (parsed != null && parsed >= 10) {
                      setState(() {
                        _selectedInterval = parsed;
                      });
                    }
                  },
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            final interval = _useCustom
                ? int.tryParse(_customController.text)
                : _selectedInterval;
            
            if (interval != null && interval >= 10) {
              Navigator.pop(context, interval);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Please enter a valid interval (minimum 10 seconds)'),
                ),
              );
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

