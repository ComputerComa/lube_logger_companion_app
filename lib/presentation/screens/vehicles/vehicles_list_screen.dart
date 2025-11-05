import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:lube_logger_companion_app/presentation/routing/app_router.dart';
import 'package:lube_logger_companion_app/providers/vehicle_provider.dart';
import 'package:lube_logger_companion_app/providers/auth_provider.dart';
import 'package:lube_logger_companion_app/data/models/vehicle.dart';
import 'package:lube_logger_companion_app/presentation/widgets/offline_indicator.dart';

// Custom cache manager that accepts self-signed certificates
class CustomCacheManager extends CacheManager {
  static const key = 'lubelogger_custom_cache';
  
  CustomCacheManager() : super(Config(
    key,
    repo: JsonCacheInfoRepository(databaseName: key),
    fileService: HttpFileService(
      httpClient: _createHttpClient(),
    ),
  ));
  
  static http.Client _createHttpClient() {
    final httpClient = HttpClient()
      ..badCertificateCallback = (X509Certificate cert, String host, int port) {
        // Allow self-signed certificates for self-hosted instances
        return true;
      };
    return IOClient(httpClient);
  }
}

class VehiclesListScreen extends ConsumerStatefulWidget {
  const VehiclesListScreen({super.key});

  @override
  ConsumerState<VehiclesListScreen> createState() => _VehiclesListScreenState();
}

class _VehiclesListScreenState extends ConsumerState<VehiclesListScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  String? _buildImageUrl(Vehicle vehicle, String? serverUrl) {
    if (vehicle.imageLocation == null || serverUrl == null) {
      debugPrint('Image URL build failed: imageLocation=${vehicle.imageLocation}, serverUrl=$serverUrl');
      return null;
    }
    
    // Check if this is the default "no image" placeholder
    if (vehicle.imageLocation == '/defaults/noimage.png' || 
        vehicle.imageLocation!.endsWith('/defaults/noimage.png')) {
      debugPrint('Skipping default no image placeholder');
      return null;
    }
    
    // Normalize server URL
    final normalizedUrl = serverUrl.trim().replaceAll(RegExp(r'/$'), '');
    
    // Handle both relative and absolute image paths
    if (vehicle.imageLocation!.startsWith('http://') || 
        vehicle.imageLocation!.startsWith('https://')) {
      debugPrint('Using absolute image URL: ${vehicle.imageLocation}');
      return vehicle.imageLocation;
    }
    
    // Construct full URL
    final imagePath = vehicle.imageLocation!.startsWith('/') 
        ? vehicle.imageLocation 
        : '/${vehicle.imageLocation}';
    
    final fullUrl = '$normalizedUrl$imagePath';
    debugPrint('Built image URL: $fullUrl (from serverUrl=$normalizedUrl, imageLocation=${vehicle.imageLocation})');
    return fullUrl;
  }

  @override
  Widget build(BuildContext context) {
    final vehiclesAsync = ref.watch(vehiclesProvider);
    final authState = ref.watch(authStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('LubeLogger Companion'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              context.push(AppRoutes.settings);
            },
            tooltip: 'Settings',
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              context.push(AppRoutes.info);
            },
            tooltip: 'About',
          ),
        ],
      ),
      body: OfflineIndicator(
        child: vehiclesAsync.when(
          data: (vehicles) {
          if (vehicles.isEmpty) {
            return const Center(
              child: Text('No vehicles found'),
            );
          }
          
          // Reset page controller if vehicles list changed
          if (_currentIndex >= vehicles.length) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _pageController.jumpToPage(0);
              _currentIndex = 0;
            });
          }
          
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(vehiclesProvider);
            },
            child: PageView.builder(
              controller: _pageController,
              itemCount: vehicles.length,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              itemBuilder: (context, index) {
                final vehicle = vehicles[index];
                return _VehicleSwipeCard(
                  vehicle: vehicle,
                  imageUrl: _buildImageUrl(vehicle, authState.serverUrl),
                  serverUrl: authState.serverUrl,
                  username: authState.username,
                  password: authState.password,
                  onTap: () {
                    context.push('${AppRoutes.vehicles}/${vehicle.id}');
                  },
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
      ),
      bottomNavigationBar: vehiclesAsync.maybeWhen(
        data: (vehicles) {
          if (vehicles.isEmpty) {
            return const SizedBox.shrink();
          }
          if (vehicles.length == 1) {
            return const SizedBox.shrink(); // Don't show indicator for single vehicle
          }
          
          return SafeArea(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Swipe hint text
                  Text(
                    'Swipe to view more vehicles',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                  const SizedBox(height: 8),
                  // Page indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      vehicles.length,
                      (index) => Container(
                        width: _currentIndex == index ? 24 : 8,
                        height: 8,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          color: _currentIndex == index
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                        ),
                      ),
                    ),
                  ),
                  // Page counter
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      '${_currentIndex + 1} of ${vehicles.length}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        orElse: () => const SizedBox.shrink(),
      ),
    );
  }
}

class _VehicleSwipeCard extends StatelessWidget {
  final Vehicle vehicle;
  final String? imageUrl;
  final String? serverUrl;
  final String? username;
  final String? password;
  final VoidCallback onTap;

  const _VehicleSwipeCard({
    required this.vehicle,
    this.imageUrl,
    this.serverUrl,
    this.username,
    this.password,
    required this.onTap,
  });

  Widget _buildVehicleImage(BuildContext context) {
    if (imageUrl == null || serverUrl == null) {
      return Container(
        height: 200,
        color: Theme.of(context).cardColor,
        child: const Icon(
          Icons.directions_car,
          size: 80,
          color: Colors.blue,
        ),
      );
    }

    // Create custom cache manager for self-signed certificates
    final cacheManager = CustomCacheManager();
    
    // If we have credentials, use cached network image with authentication
    if (username != null && password != null) {
      final credentials = base64Encode(utf8.encode('$username:$password'));
      return CachedNetworkImage(
        imageUrl: imageUrl!,
        cacheManager: cacheManager,
        httpHeaders: {
          'Authorization': 'Basic $credentials',
        },
        height: 200,
        fit: BoxFit.contain,
        placeholder: (context, url) => Container(
          height: 200,
          color: Theme.of(context).cardColor,
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        ),
        errorWidget: (context, url, error) {
          // Log error for debugging
          debugPrint('Image load error for $url: $error');
          return Container(
            height: 200,
            color: Theme.of(context).cardColor,
            child: const Icon(
              Icons.directions_car,
              size: 80,
              color: Colors.blue,
            ),
          );
        },
      );
    }

    // Fallback to regular cached network image
    return CachedNetworkImage(
      imageUrl: imageUrl!,
      cacheManager: cacheManager,
      height: 200,
      fit: BoxFit.contain,
      placeholder: (context, url) => Container(
        height: 200,
        color: Theme.of(context).cardColor,
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      ),
      errorWidget: (context, url, error) {
        // Log error for debugging
        debugPrint('Image load error for $url: $error');
        return Container(
          height: 200,
          color: Theme.of(context).cardColor,
          child: const Icon(
            Icons.directions_car,
            size: 80,
            color: Colors.blue,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        clipBehavior: Clip.antiAlias,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Vehicle Image
              _buildVehicleImage(context),
              
              // Vehicle Info
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Vehicle Name
                    Text(
                      vehicle.displayName,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Vehicle Details
                    if (vehicle.licensePlate != null) ...[
                      _InfoRow(
                        icon: Icons.confirmation_number,
                        label: 'License Plate',
                        value: vehicle.licensePlate!,
                      ),
                      const SizedBox(height: 6),
                    ],
                    
                    if (vehicle.vin != null) ...[
                      _InfoRow(
                        icon: Icons.badge,
                        label: 'VIN',
                        value: vehicle.vin!,
                      ),
                      const SizedBox(height: 6),
                    ],
                    
                    if (vehicle.year != null) ...[
                      _InfoRow(
                        icon: Icons.calendar_today,
                        label: 'Year',
                        value: vehicle.year.toString(),
                      ),
                      const SizedBox(height: 6),
                    ],
                    
                    // Fuel Type Indicators
                    if (vehicle.isElectric || vehicle.isDiesel) ...[
                      Wrap(
                        spacing: 8,
                        children: [
                          if (vehicle.isElectric)
                            Chip(
                              label: const Text('Electric'),
                              avatar: const Icon(Icons.electric_car, size: 18),
                              backgroundColor: Colors.green[100],
                            ),
                          if (vehicle.isDiesel)
                            Chip(
                              label: const Text('Diesel'),
                              avatar: const Icon(Icons.local_gas_station, size: 18),
                              backgroundColor: Colors.orange[100],
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
}

