import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:lube_logger_companion_app/core/theme/app_theme.dart';
import 'package:lube_logger_companion_app/presentation/routing/app_router.dart';
import 'package:lube_logger_companion_app/services/storage_service.dart';
import 'package:lube_logger_companion_app/services/notification_service.dart';
import 'package:lube_logger_companion_app/services/polling_service.dart';
import 'package:lube_logger_companion_app/services/cache_service.dart';
import 'package:lube_logger_companion_app/services/connectivity_service.dart';
import 'package:lube_logger_companion_app/providers/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Configure CachedNetworkImage to accept self-signed certificates
  // This is necessary for self-hosted LubeLogger instances
  CachedNetworkImage.logLevel = CacheManagerLogLevel.none;
  
  // Initialize services
  await StorageService.init();
  await CacheService.init();
  await ConnectivityService.init();
  
  // Initialize notifications asynchronously (don't block app startup)
  // Permissions will be requested during setup flow
  NotificationService.initialize().catchError((error) {
    debugPrint('Notification initialization error: $error');
    return;
  });
  
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);
    
    // Initialize polling manager - this will start/stop polling based on auth state
    ref.listen(pollingManagerProvider, (previous, next) {
      // Handle polling manager state changes if needed
    });

    return MaterialApp.router(
      title: 'LubeLogger Companion',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}