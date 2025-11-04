import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lube_logger_companion_app/presentation/routing/app_router.dart';
import 'package:lube_logger_companion_app/providers/vehicle_provider.dart';
import 'package:lube_logger_companion_app/presentation/widgets/vehicle_card.dart';

class VehiclesListScreen extends ConsumerWidget {
  const VehiclesListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehiclesAsync = ref.watch(vehiclesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('LubeLogger Companion'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              context.push(AppRoutes.info);
            },
            tooltip: 'About',
          ),
        ],
      ),
      body: vehiclesAsync.when(
        data: (vehicles) {
          if (vehicles.isEmpty) {
            return const Center(
              child: Text('No vehicles found'),
            );
          }
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(vehiclesProvider);
            },
            child: ListView.builder(
              itemCount: vehicles.length,
              padding: const EdgeInsets.all(16),
              itemBuilder: (context, index) {
                final vehicle = vehicles[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: VehicleCard(
                    vehicle: vehicle,
                    onTap: () {
                      context.push('${AppRoutes.vehicles}/${vehicle.id}');
                    },
                  ),
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Error: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(vehiclesProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
