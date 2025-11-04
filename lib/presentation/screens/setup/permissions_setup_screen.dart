import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lube_logger_companion_app/presentation/routing/app_router.dart';
import 'package:lube_logger_companion_app/services/notification_service.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionsSetupScreen extends StatefulWidget {
  const PermissionsSetupScreen({super.key});

  @override
  State<PermissionsSetupScreen> createState() => _PermissionsSetupScreenState();
}

class _PermissionsSetupScreenState extends State<PermissionsSetupScreen> {
  bool _isRequesting = false;
  bool _notificationGranted = false;
  bool _locationGranted = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final notificationStatus = await Permission.notification.status;
    final locationStatus = await Permission.location.status;
    
    setState(() {
      _notificationGranted = notificationStatus.isGranted;
      _locationGranted = locationStatus.isGranted;
    });
  }

  Future<void> _requestNotificationPermission() async {
    setState(() => _isRequesting = true);
    
    try {
      // First request through notification service
      final notificationGranted = await NotificationService.requestPermissions();
      
      // Also request through permission_handler for consistency
      final status = await Permission.notification.request();
      
      setState(() {
        _notificationGranted = notificationGranted || status.isGranted;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to request notification permission: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isRequesting = false);
    }
  }

  Future<void> _requestLocationPermission() async {
    setState(() => _isRequesting = true);
    
    try {
      final status = await Permission.location.request();
      
      setState(() {
        _locationGranted = status.isGranted;
      });
      
      if (!status.isGranted && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location permission is recommended for accurate reminder scheduling'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to request location permission: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isRequesting = false);
    }
  }

  Future<void> _requestAllPermissions() async {
    await _requestNotificationPermission();
    await _requestLocationPermission();
  }

  void _handleContinue() {
    // Navigate to home screen even if permissions weren't granted
    // The app can still function without them
    context.go(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Permissions'),
        automaticallyImplyLeading: false, // Prevent back navigation
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.security,
                size: 80,
                color: Colors.blue,
              ),
              const SizedBox(height: 24),
              const Text(
                'Enable Permissions',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'To provide the best experience, we need a few permissions',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              
              // Notification Permission Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.notifications,
                            color: _notificationGranted ? Colors.green : Colors.grey,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Notifications',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _notificationGranted
                                      ? 'Permission granted'
                                      : 'Required for reminder notifications',
                                  style: TextStyle(
                                    color: _notificationGranted ? Colors.green : Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (_notificationGranted)
                            const Icon(Icons.check_circle, color: Colors.green)
                          else
                            IconButton(
                              icon: const Icon(Icons.arrow_forward),
                              onPressed: _isRequesting ? null : _requestNotificationPermission,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Location Permission Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            color: _locationGranted ? Colors.green : Colors.grey,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Location',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _locationGranted
                                      ? 'Permission granted'
                                      : 'Recommended for accurate timezone detection',
                                  style: TextStyle(
                                    color: _locationGranted ? Colors.green : Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (_locationGranted)
                            const Icon(Icons.check_circle, color: Colors.green)
                          else
                            IconButton(
                              icon: const Icon(Icons.arrow_forward),
                              onPressed: _isRequesting ? null : _requestLocationPermission,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Request All Button
              if (!_notificationGranted || !_locationGranted)
                OutlinedButton(
                  onPressed: _isRequesting ? null : _requestAllPermissions,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isRequesting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Request All Permissions'),
                ),
              
              const SizedBox(height: 16),
              
              // Continue Button
              ElevatedButton(
                onPressed: _isRequesting ? null : _handleContinue,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Continue'),
              ),
              
              const SizedBox(height: 16),
              
              Text(
                'You can enable these permissions later in your device settings',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

