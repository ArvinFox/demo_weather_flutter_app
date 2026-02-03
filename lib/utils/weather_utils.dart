import 'package:flutter/material.dart';

class WeatherUtils {
  // 1. Get Text Description
  static String getWeatherDescription(int code) {
    switch (code) {
      case 0:
        return 'Clear Sky';
      case 1:
      case 2:
      case 3:
        return 'Cloudy';
      case 45:
      case 48:
        return 'Fog';
      case 51:
      case 53:
      case 55:
        return 'Drizzle';
      case 61:
      case 63:
      case 65:
        return 'Rain';
      case 71:
      case 73:
      case 75:
        return 'Snow';
      case 95:
      case 96:
      case 99:
        return 'Thunderstorm';
      default:
        return 'Unknown';
    }
  }

  // 2. Get Icon Data (NEW)
  static IconData getWeatherIcon(int code) {
    switch (code) {
      case 0:
        return Icons.wb_sunny_rounded;
      case 1:
      case 2:
        return Icons.wb_cloudy_rounded;
      case 3:
        return Icons.cloud_rounded;
      case 45:
      case 48:
        return Icons.foggy;
      case 51:
      case 53:
      case 55:
        return Icons.grain_rounded;
      case 61:
      case 63:
      case 65:
        return Icons.water_drop_rounded;
      case 71:
      case 73:
      case 75:
        return Icons.ac_unit_rounded;
      case 95:
      case 96:
      case 99:
        return Icons.thunderstorm_rounded;
      default:
        return Icons.question_mark_rounded;
    }
  }

  // 3. Get Color for Background (NEW)
  static List<Color> getBackgroundColors(int code) {
    if (code == 0)
      return [const Color(0xFF56CCF2), const Color(0xFF2F80ED)]; // Sunny Blue
    if (code >= 1 && code <= 3)
      return [const Color(0xFFBDC3C7), const Color(0xFF2C3E50)]; // Cloudy Grey
    if (code >= 95)
      return [const Color(0xFF141E30), const Color(0xFF243B55)]; // Storm Dark
    return [const Color(0xFF4CA1AF), const Color(0xFFC4E0E5)]; // Default Teal
  }
}
