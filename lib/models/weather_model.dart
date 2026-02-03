import 'package:flutter/material.dart';
import '../utils/weather_utils.dart';

class WeatherModel {
  final String cityName; // Main Title (e.g. "Current Location")
  final double temperature;
  final double windSpeed;
  final String description;
  final double? lat;
  final double? lon;
  final IconData iconData;
  final int weatherCode;

  WeatherModel({
    required this.cityName,
    required this.temperature,
    required this.windSpeed,
    required this.description,
    this.lat,
    this.lon,
    required this.iconData,
    required this.weatherCode,
  });

  factory WeatherModel.fromOpenMeteo(
    Map<String, dynamic> json,
    String name, {
    String? subTitle,
    double? lat,
    double? lon,
  }) {
    final currentData = json['current'];
    final int code = currentData['weather_code'] ?? 0;

    return WeatherModel(
      cityName: name,
      temperature: (currentData['temperature_2m'] as num).toDouble(),
      windSpeed: (currentData['wind_speed_10m'] as num).toDouble(),
      description: WeatherUtils.getWeatherDescription(code),
      lat: lat ?? json['latitude'],
      lon: lon ?? json['longitude'],
      iconData: WeatherUtils.getWeatherIcon(code),
      weatherCode: code,
    );
  }
}
