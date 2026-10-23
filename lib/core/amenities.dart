import 'package:flutter/material.dart';

const kAmenities = ['Wi-Fi', 'Pool', 'Spa', 'Parking', 'Gym', 'Restaurant', 'Breakfast', 'Beach access'];

IconData amenityIcon(String name) {
  switch (name) {
    case 'Wi-Fi':
      return Icons.wifi_rounded;
    case 'Pool':
      return Icons.pool_rounded;
    case 'Spa':
      return Icons.spa_rounded;
    case 'Parking':
      return Icons.local_parking_rounded;
    case 'Gym':
      return Icons.fitness_center_rounded;
    case 'Restaurant':
      return Icons.restaurant_rounded;
    case 'Breakfast':
      return Icons.free_breakfast_rounded;
    case 'Beach access':
      return Icons.beach_access_rounded;
    default:
      return Icons.check_circle_outline_rounded;
  }
}
