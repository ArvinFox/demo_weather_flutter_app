import 'package:flutter/material.dart';
import '../models/weather_model.dart';

class CurrentWeatherCard extends StatelessWidget {
  final WeatherModel? weather;
  final bool isCelsius;
  final DateTime? lastUpdated;

  const CurrentWeatherCard({
    super.key,
    this.weather,
    this.isCelsius = true,
    this.lastUpdated,
  });

  @override
  Widget build(BuildContext context) {
    if (weather == null) {
      return const Center(child: Text("Waiting for location..."));
    }

    // Calculation Logic
    final double tempVal = isCelsius
        ? weather!.temperature
        : (weather!.temperature * 9 / 5) + 32;
    final String unit = isCelsius ? "°C" : "°F";

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 1. City Name
          Text(
            weather!.cityName,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 5),

          // 2. Coordinates Row
          if (weather!.lat != null && weather!.lon != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.6),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.location_on, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    "Lat: ${weather!.lat!.toStringAsFixed(2)}  Lon: ${weather!.lon!.toStringAsFixed(2)}",
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 15),

          // 3. Temperature with C/F Toggle
          Text(
            "${tempVal.toStringAsFixed(1)}$unit",
            style: const TextStyle(
              fontSize: 60,
              fontWeight: FontWeight.w300,
              color: Colors.blue,
            ),
          ),

          const SizedBox(height: 10),

          // 4. Description
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.blue.shade100,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              weather!.description,
              style: TextStyle(fontSize: 16, color: Colors.blue.shade900),
            ),
          ),

          const SizedBox(height: 15),

          // 5. PHYSICAL TIMER PROOF
          if (lastUpdated != null)
            Text(
              "Last refresh: ${lastUpdated!.hour}:${lastUpdated!.minute.toString().padLeft(2, '0')}:${lastUpdated!.second.toString().padLeft(2, '0')}",
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
        ],
      ),
    );
  }
}
