import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lube_logger_companion_app/presentation/routing/app_router.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('LubeLogger Companion'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              context.push(AppRoutes.settings);
            },
          ),
        ],
      ),
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(16),
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        children: [
          _buildMenuCard(
            context,
            title: 'Vehicles',
            icon: Icons.directions_car,
            color: Colors.blue,
            onTap: () => context.push(AppRoutes.vehicles),
          ),
          _buildMenuCard(
            context,
            title: 'Odometer',
            icon: Icons.speed,
            color: Colors.green,
            onTap: () => context.push(AppRoutes.odometer),
          ),
          _buildMenuCard(
            context,
            title: 'Fuel Entries',
            icon: Icons.local_gas_station,
            color: Colors.orange,
            onTap: () => context.push(AppRoutes.fuel),
          ),
          _buildMenuCard(
            context,
            title: 'Reminders',
            icon: Icons.notifications,
            color: Colors.red,
            onTap: () => context.push(AppRoutes.reminders),
          ),
          _buildMenuCard(
            context,
            title: 'Statistics',
            icon: Icons.analytics,
            color: Colors.purple,
            onTap: () => context.push(AppRoutes.statistics),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Quick action menu
          showModalBottomSheet(
            context: context,
            builder: (context) => _QuickActionsSheet(),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Quick Add'),
      ),
    );
  }

  Widget _buildMenuCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: color),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionsSheet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.speed),
            title: const Text('Add Odometer Entry'),
            onTap: () {
              Navigator.pop(context);
              context.push(AppRoutes.addOdometer);
            },
          ),
          ListTile(
            leading: const Icon(Icons.local_gas_station),
            title: const Text('Add Fuel Entry'),
            onTap: () {
              Navigator.pop(context);
              context.push(AppRoutes.addFuel);
            },
          ),
          ListTile(
            leading: const Icon(Icons.notifications),
            title: const Text('Add Reminder'),
            onTap: () {
              Navigator.pop(context);
              context.push(AppRoutes.addReminder);
            },
          ),
        ],
      ),
    );
  }
}
