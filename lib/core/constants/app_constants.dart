class AppConstants {
  // Storage Keys
  static const String keyServerUrl = 'server_url';
  static const String keyUsername = 'username';
  static const String keyPassword = 'password';
  static const String keySetupComplete = 'setup_complete';
  static const String keyWelcomeShown = 'welcome_shown';
  
  // Date Format
  static const String dateFormat = 'MM/dd/yyyy';
  
  // Notification Channel
  static const String notificationChannelId = 'lubelogger_reminders';
  static const String notificationChannelName = 'LubeLogger Reminders';
  static const String notificationChannelDescription = 'Notifications for vehicle maintenance reminders';
  
  // API Endpoints
  static const String endpointWhoAmI = '/api/whoami';
  static const String endpointVehicles = '/api/vehicles';
  static const String endpointVehicleInfo = '/api/vehicle/info';
  static const String endpointOdometerRecords = '/api/vehicle/odometerrecords';
  static const String endpointLatestOdometer = '/api/vehicle/odometerrecords/latest';
  static const String endpointAdjustedOdometer = '/api/vehicle/adjustedodometer';
  static const String endpointGasRecords = '/api/vehicle/gasrecords';
  static const String endpointReminders = '/api/vehicle/reminders';
}
