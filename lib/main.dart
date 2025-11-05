import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lube_logger_companion_app/core/theme/app_theme.dart';
import 'package:lube_logger_companion_app/presentation/routing/app_router.dart';
import 'package:lube_logger_companion_app/services/storage_service.dart';
import 'package:lube_logger_companion_app/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize services
  await StorageService.init();
  
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

    return MaterialApp.router(
      title: 'LubeLogger Companion',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}