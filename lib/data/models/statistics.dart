class VehicleStatistics {
  final int vehicleId;
  final int? latestOdometer;
  final int totalMiles;
  final double totalFuelCost;
  final double totalGallons;
  final double averageMpg;
  final double averagePricePerGallon;
  final int totalFuelEntries;
  final int totalOdometerEntries;
  
  VehicleStatistics({
    required this.vehicleId,
    this.latestOdometer,
    this.totalMiles = 0,
    this.totalFuelCost = 0.0,
    this.totalGallons = 0.0,
    this.averageMpg = 0.0,
    this.averagePricePerGallon = 0.0,
    this.totalFuelEntries = 0,
    this.totalOdometerEntries = 0,
  });
  
  factory VehicleStatistics.empty(int vehicleId) {
    return VehicleStatistics(vehicleId: vehicleId);
  }
}
