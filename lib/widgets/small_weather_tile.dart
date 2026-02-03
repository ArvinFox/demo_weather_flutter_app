import 'package:flutter/material.dart';
import '../models/weather_model.dart';

class SmallWeatherTile extends StatelessWidget {
  final WeatherModel weather;
  final bool isCelsius; // Added for unit toggle

  const SmallWeatherTile({
    super.key,
    required this.weather,
    this.isCelsius = true, // Default to Celsius
  });

  @override
  Widget build(BuildContext context) {
    // 1. Calculate Temperature based on unit
    final double tempVal = isCelsius
        ? weather.temperature
        : (weather.temperature * 9 / 5) + 32;

    final String unit = isCelsius
        ? "°C"
        : "°F"; // Simple degree symbol for C, F for Fahrenheit

    return Container(
      width: 140,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
      decoration: BoxDecoration(
        // GLASSMORPHISM STYLE
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 2. City Name
          Text(
            weather.cityName,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.white,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 10),

          // 3. Icon
          Icon(weather.iconData, color: Colors.white, size: 32),

          const SizedBox(height: 5),

          // 4. Temperature (Updated to use tempVal and unit)
          Text(
            "${tempVal.toStringAsFixed(1)}$unit",
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),

          const SizedBox(height: 5),

          // 5. Description
          Text(
            weather.description,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(0.7),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
