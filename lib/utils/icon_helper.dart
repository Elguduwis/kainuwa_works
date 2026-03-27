import 'package:flutter/material.dart';

class IconHelper {
  static IconData getIcon(String? iconName) {
    switch (iconName?.toLowerCase()) {
      case 'droplet': return Icons.water_drop_rounded;
      case 'zap': return Icons.electrical_services_rounded;
      case 'sparkles': return Icons.cleaning_services_rounded;
      case 'power': return Icons.power_rounded;
      case 'paint-roller': return Icons.format_paint_rounded;
      case 'hammer': return Icons.handyman_rounded;
      case 'snowflake': return Icons.ac_unit_rounded;
      case 'bug': return Icons.bug_report_rounded;
      case 'package': return Icons.inventory_2_rounded;
      case 'home': return Icons.roofing_rounded;
      case 'tree-deciduous': return Icons.nature_rounded;
      case 'brick-wall': return Icons.foundation_rounded;
      case 'flame': return Icons.local_fire_department_rounded;
      case 'car': return Icons.directions_car_rounded;
      case 'monitor': return Icons.computer_rounded;
      case 'smartphone': return Icons.smartphone_rounded;
      case 'camera': return Icons.camera_alt_rounded;
      case 'utensils': return Icons.restaurant_rounded;
      case 'calendar-days': return Icons.event_rounded;
      case 'scissors': return Icons.content_cut_rounded;
      case 'shirt': return Icons.local_laundry_service_rounded;
      case 'book-open': return Icons.menu_book_rounded;
      case 'dumbbell': return Icons.fitness_center_rounded;
      default: return Icons.work_outline_rounded;
    }
  }
}
