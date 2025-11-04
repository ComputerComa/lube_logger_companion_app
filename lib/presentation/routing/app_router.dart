import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lube_logger_companion_app/presentation/screens/welcome/welcome_screen.dart';
import 'package:lube_logger_companion_app/presentation/screens/setup/setup_screen.dart';
import 'package:lube_logger_companion_app/presentation/screens/setup/permissions_setup_screen.dart';
import 'package:lube_logger_companion_app/presentation/screens/vehicles/vehicles_list_screen.dart';
import 'package:lube_logger_companion_app/presentation/screens/vehicles/vehicle_detail_screen.dart';
import 'package:lube_logger_companion_app/presentation/screens/odometer/odometer_list_screen.dart';
import 'package:lube_logger_companion_app/presentation/screens/odometer/add_odometer_screen.dart';
import 'package:lube_logger_companion_app/presentation/screens/fuel/fuel_list_screen.dart';
import 'package:lube_logger_companion_app/presentation/screens/fuel/add_fuel_screen.dart';
import 'package:lube_logger_companion_app/presentation/screens/reminders/reminders_list_screen.dart';
import 'package:lube_logger_companion_app/presentation/screens/reminders/add_reminder_screen.dart';
import 'package:lube_logger_companion_app/presentation/screens/statistics/statistics_screen.dart';
import 'package:lube_logger_companion_app/presentation/screens/service/service_list_screen.dart';
import 'package:lube_logger_companion_app/presentation/screens/service/add_service_screen.dart';
import 'package:lube_logger_companion_app/presentation/screens/repair/repair_list_screen.dart';
import 'package:lube_logger_companion_app/presentation/screens/repair/add_repair_screen.dart';
import 'package:lube_logger_companion_app/presentation/screens/upgrade/upgrade_list_screen.dart';
import 'package:lube_logger_companion_app/presentation/screens/upgrade/add_upgrade_screen.dart';
import 'package:lube_logger_companion_app/presentation/screens/tax/tax_list_screen.dart';
import 'package:lube_logger_companion_app/presentation/screens/tax/add_tax_screen.dart';
import 'package:lube_logger_companion_app/presentation/screens/info/info_screen.dart';
import 'package:lube_logger_companion_app/providers/auth_provider.dart';
import 'package:lube_logger_companion_app/services/storage_service.dart';

class AppRoutes {
  static const String welcome = '/welcome';
  static const String setup = '/setup';
  static const String permissions = '/permissions';
  static const String home = '/';
  static const String vehicles = '/vehicles';
  static const String vehicleDetail = '/vehicles/:id';
  static const String odometer = '/odometer';
  static const String addOdometer = '/odometer/add';
  static const String fuel = '/fuel';
  static const String addFuel = '/fuel/add';
  static const String reminders = '/reminders';
  static const String addReminder = '/reminders/add';
  static const String statistics = '/statistics';
  static const String service = '/service';
  static const String addService = '/service/add';
  static const String repair = '/repair';
  static const String addRepair = '/repair/add';
  static const String upgrade = '/upgrade';
  static const String addUpgrade = '/upgrade/add';
  static const String tax = '/tax';
  static const String addTax = '/tax/add';
  static const String info = '/info';
}

final routerProvider = Provider<GoRouter>((ref) {
  // Check setup status synchronously from storage
  final isSetupComplete = StorageService.isSetupComplete();
  final isWelcomeShown = StorageService.isWelcomeShown();
  
  // Determine initial location based on setup status
  // Show welcome screen first if it hasn't been shown yet
  String initialLocation;
  if (!isWelcomeShown) {
    // Show welcome screen for new users (first time)
    initialLocation = AppRoutes.welcome;
  } else if (isSetupComplete) {
    // If setup is complete, start at home (redirect will handle auth check)
    initialLocation = AppRoutes.home;
  } else {
    // Welcome shown but setup not complete - go to setup
    initialLocation = AppRoutes.setup;
  }
  
  return GoRouter(
    initialLocation: initialLocation,
    redirect: (context, state) {
      // Only check auth state after providers are initialized
      final isWelcomeShown = StorageService.isWelcomeShown();
      final isSetupComplete = StorageService.isSetupComplete();
      
      // If we're on welcome and it's already been shown, redirect to appropriate screen
      if (state.uri.path == AppRoutes.welcome && isWelcomeShown) {
        if (isSetupComplete) {
          // Try to get auth state, but don't fail if not ready
          try {
            final authState = ref.read(authStateProvider);
            return authState.isAuthenticated ? AppRoutes.home : AppRoutes.setup;
          } catch (e) {
            // Provider not ready yet, go to setup
            return AppRoutes.setup;
          }
        } else {
          return AppRoutes.setup;
        }
      }
      
      // If trying to access home/setup without welcome shown, show welcome first
      if (state.uri.path != AppRoutes.welcome && 
          state.uri.path != AppRoutes.permissions && 
          !isWelcomeShown) {
        return AppRoutes.welcome;
      }
      
      // If setup is complete and trying to access home, check auth
      if (state.uri.path == AppRoutes.home && isSetupComplete) {
        try {
          final authState = ref.read(authStateProvider);
          if (!authState.isAuthenticated) {
            return AppRoutes.setup;
          }
        } catch (e) {
          // Provider not ready, allow through (will show loading state)
        }
      }
      
      return null; // No redirect needed
    },
    routes: [
      GoRoute(
        path: AppRoutes.welcome,
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.setup,
        builder: (context, state) => const SetupScreen(),
      ),
      GoRoute(
        path: AppRoutes.permissions,
        builder: (context, state) => const PermissionsSetupScreen(),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const VehiclesListScreen(),
      ),
      GoRoute(
        path: AppRoutes.vehicles,
        builder: (context, state) => const VehiclesListScreen(),
      ),
      GoRoute(
        path: AppRoutes.vehicleDetail,
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return VehicleDetailScreen(vehicleId: id);
        },
      ),
      GoRoute(
        path: AppRoutes.odometer,
        builder: (context, state) {
          final vehicleId = state.uri.queryParameters['vehicleId'];
          return OdometerListScreen(
            initialVehicleId: vehicleId != null ? int.parse(vehicleId) : null,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.addOdometer,
        builder: (context, state) {
          final vehicleId = state.uri.queryParameters['vehicleId'];
          return AddOdometerScreen(
            vehicleId: vehicleId != null ? int.parse(vehicleId) : null,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.fuel,
        builder: (context, state) {
          final vehicleId = state.uri.queryParameters['vehicleId'];
          return FuelListScreen(
            initialVehicleId: vehicleId != null ? int.parse(vehicleId) : null,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.addFuel,
        builder: (context, state) {
          final vehicleId = state.uri.queryParameters['vehicleId'];
          return AddFuelScreen(
            vehicleId: vehicleId != null ? int.parse(vehicleId) : null,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.reminders,
        builder: (context, state) {
          final vehicleId = state.uri.queryParameters['vehicleId'];
          return RemindersListScreen(
            initialVehicleId: vehicleId != null ? int.parse(vehicleId) : null,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.addReminder,
        builder: (context, state) {
          final vehicleId = state.uri.queryParameters['vehicleId'];
          return AddReminderScreen(
            vehicleId: vehicleId != null ? int.parse(vehicleId) : null,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.statistics,
        builder: (context, state) {
          final vehicleId = state.uri.queryParameters['vehicleId'];
          return StatisticsScreen(
            initialVehicleId: vehicleId != null ? int.parse(vehicleId) : null,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.service,
        builder: (context, state) {
          final vehicleId = state.uri.queryParameters['vehicleId'];
          return ServiceListScreen(
            initialVehicleId: vehicleId != null ? int.parse(vehicleId) : null,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.addService,
        builder: (context, state) {
          final vehicleId = state.uri.queryParameters['vehicleId'];
          return AddServiceScreen(
            vehicleId: vehicleId != null ? int.parse(vehicleId) : null,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.repair,
        builder: (context, state) {
          final vehicleId = state.uri.queryParameters['vehicleId'];
          return RepairListScreen(
            initialVehicleId: vehicleId != null ? int.parse(vehicleId) : null,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.addRepair,
        builder: (context, state) {
          final vehicleId = state.uri.queryParameters['vehicleId'];
          return AddRepairScreen(
            vehicleId: vehicleId != null ? int.parse(vehicleId) : null,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.upgrade,
        builder: (context, state) {
          final vehicleId = state.uri.queryParameters['vehicleId'];
          return UpgradeListScreen(
            initialVehicleId: vehicleId != null ? int.parse(vehicleId) : null,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.addUpgrade,
        builder: (context, state) {
          final vehicleId = state.uri.queryParameters['vehicleId'];
          return AddUpgradeScreen(
            vehicleId: vehicleId != null ? int.parse(vehicleId) : null,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.tax,
        builder: (context, state) {
          final vehicleId = state.uri.queryParameters['vehicleId'];
          return TaxListScreen(
            initialVehicleId: vehicleId != null ? int.parse(vehicleId) : null,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.addTax,
        builder: (context, state) {
          final vehicleId = state.uri.queryParameters['vehicleId'];
          return AddTaxScreen(
            vehicleId: vehicleId != null ? int.parse(vehicleId) : null,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.info,
        builder: (context, state) => const InfoScreen(),
      ),
    ],
  );
});
