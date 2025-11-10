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
import 'package:lube_logger_companion_app/presentation/screens/plan/plan_list_screen.dart';
import 'package:lube_logger_companion_app/presentation/screens/plan/add_plan_screen.dart';
import 'package:lube_logger_companion_app/presentation/screens/info/info_screen.dart';
import 'package:lube_logger_companion_app/presentation/screens/settings/settings_screen.dart';
import 'package:lube_logger_companion_app/services/storage_service.dart';
import 'package:lube_logger_companion_app/data/models/fuel_record.dart';
import 'package:lube_logger_companion_app/data/models/odometer_record.dart';
import 'package:lube_logger_companion_app/data/models/service_record.dart';
import 'package:lube_logger_companion_app/data/models/repair_record.dart';
import 'package:lube_logger_companion_app/data/models/upgrade_record.dart';
import 'package:lube_logger_companion_app/data/models/tax_record.dart';
import 'package:lube_logger_companion_app/data/models/plan_record.dart';
import 'package:lube_logger_companion_app/data/models/reminder.dart';

/// Helper function to check if setup credentials exist in storage
bool _hasSetupCredentials() {
  final serverUrl = StorageService.getServerUrl();
  final username = StorageService.getUsername();
  final password = StorageService.getPassword();
  return serverUrl != null && serverUrl.isNotEmpty &&
         username != null && username.isNotEmpty &&
         password != null && password.isNotEmpty;
}

class AppRoutes {
  static const String welcome = '/welcome';
  static const String setup = '/setup';
  static const String permissions = '/permissions';
  static const String home = '/';
  static const String vehicles = '/vehicles';
  static const String vehicleDetail = '/vehicles/:id';
  static const String odometer = '/odometer';
  static const String addOdometer = '/odometer/add';
  static const String editOdometer = '/odometer/edit';
  static const String fuel = '/fuel';
  static const String addFuel = '/fuel/add';
  static const String editFuel = '/fuel/edit';
  static const String reminders = '/reminders';
  static const String addReminder = '/reminders/add';
  static const String editReminder = '/reminders/edit';
  static const String statistics = '/statistics';
  static const String service = '/service';
  static const String addService = '/service/add';
  static const String editService = '/service/edit';
  static const String repair = '/repair';
  static const String addRepair = '/repair/add';
  static const String editRepair = '/repair/edit';
  static const String upgrade = '/upgrade';
  static const String addUpgrade = '/upgrade/add';
  static const String editUpgrade = '/upgrade/edit';
  static const String tax = '/tax';
  static const String addTax = '/tax/add';
  static const String editTax = '/tax/edit';
  static const String plan = '/plan';
  static const String addPlan = '/plan/add';
  static const String editPlan = '/plan/edit';
  static const String info = '/info';
  static const String settings = '/settings';
}

final routerProvider = Provider<GoRouter>((ref) {
  // Check if setup credentials exist in storage (synchronous and reliable)
  final hasCredentials = _hasSetupCredentials();
  final isWelcomeShown = StorageService.isWelcomeShown();
  
  // Determine initial location based on setup status
  // Show welcome screen first if it hasn't been shown yet
  String initialLocation;
  if (!isWelcomeShown) {
    // Show welcome screen for new users (first time)
    initialLocation = AppRoutes.welcome;
  } else if (hasCredentials) {
    // If credentials exist, setup is complete - go to home
    initialLocation = AppRoutes.home;
  } else {
    // Welcome shown but no credentials - go to setup
    initialLocation = AppRoutes.setup;
  }
  
  return GoRouter(
    initialLocation: initialLocation,
    redirect: (context, state) {
      // Check credentials synchronously from storage
      final hasCredentials = _hasSetupCredentials();
      final isWelcomeShown = StorageService.isWelcomeShown();
      
      // If we're on welcome and it's already been shown, redirect to appropriate screen
      if (state.uri.path == AppRoutes.welcome && isWelcomeShown) {
        return hasCredentials ? AppRoutes.home : AppRoutes.setup;
      }
      
      // If trying to access home/setup without welcome shown, show welcome first
      if (state.uri.path != AppRoutes.welcome && 
          state.uri.path != AppRoutes.permissions && 
          !isWelcomeShown) {
        return AppRoutes.welcome;
      }
      
      // If trying to access setup but credentials exist, redirect to home
      if (state.uri.path == AppRoutes.setup && hasCredentials) {
        return AppRoutes.home;
      }
      
      // If trying to access home but no credentials, redirect to setup
      if (state.uri.path == AppRoutes.home && !hasCredentials) {
        return AppRoutes.setup;
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
        path: AppRoutes.editOdometer,
        builder: (context, state) {
          final vehicleId = state.uri.queryParameters['vehicleId'];
          final record = state.extra as OdometerRecord?;
          return AddOdometerScreen(
            vehicleId: vehicleId != null
                ? int.parse(vehicleId)
                : record?.vehicleId,
            record: record,
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
        path: AppRoutes.editFuel,
        builder: (context, state) {
          final vehicleId = state.uri.queryParameters['vehicleId'];
          final record = state.extra as FuelRecord?;
          return AddFuelScreen(
            vehicleId: vehicleId != null
                ? int.parse(vehicleId)
                : record?.vehicleId,
            record: record,
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
        path: AppRoutes.editReminder,
        builder: (context, state) {
          final vehicleId = state.uri.queryParameters['vehicleId'];
          final record = state.extra as Reminder?;
          return AddReminderScreen(
            vehicleId: vehicleId != null
                ? int.parse(vehicleId)
                : record?.vehicleId,
            record: record,
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
        path: AppRoutes.editService,
        builder: (context, state) {
          final vehicleId = state.uri.queryParameters['vehicleId'];
          final record = state.extra as ServiceRecord?;
          return AddServiceScreen(
            vehicleId: vehicleId != null
                ? int.parse(vehicleId)
                : record?.vehicleId,
            record: record,
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
        path: AppRoutes.editRepair,
        builder: (context, state) {
          final vehicleId = state.uri.queryParameters['vehicleId'];
          final record = state.extra as RepairRecord?;
          return AddRepairScreen(
            vehicleId: vehicleId != null
                ? int.parse(vehicleId)
                : record?.vehicleId,
            record: record,
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
        path: AppRoutes.editUpgrade,
        builder: (context, state) {
          final vehicleId = state.uri.queryParameters['vehicleId'];
          final record = state.extra as UpgradeRecord?;
          return AddUpgradeScreen(
            vehicleId: vehicleId != null
                ? int.parse(vehicleId)
                : record?.vehicleId,
            record: record,
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
        path: AppRoutes.editTax,
        builder: (context, state) {
          final vehicleId = state.uri.queryParameters['vehicleId'];
          final record = state.extra as TaxRecord?;
          return AddTaxScreen(
            vehicleId: vehicleId != null
                ? int.parse(vehicleId)
                : record?.vehicleId,
            record: record,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.plan,
        builder: (context, state) {
          final vehicleId = state.uri.queryParameters['vehicleId'];
          return PlanListScreen(
            initialVehicleId: vehicleId != null ? int.parse(vehicleId) : null,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.addPlan,
        builder: (context, state) {
          final vehicleId = state.uri.queryParameters['vehicleId'];
          return AddPlanScreen(
            vehicleId: vehicleId != null ? int.parse(vehicleId) : null,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.editPlan,
        builder: (context, state) {
          final vehicleId = state.uri.queryParameters['vehicleId'];
          final record = state.extra as PlanRecord?;
          return AddPlanScreen(
            vehicleId: vehicleId != null
                ? int.parse(vehicleId)
                : record?.vehicleId,
            record: record,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.info,
        builder: (context, state) => const InfoScreen(),
      ),
      GoRoute(
        path: AppRoutes.settings,
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
  );
});
