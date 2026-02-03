import 'package:flutter/material.dart';
import '../views/weather_home_page.dart';

class AppRoutes {
  static const String home = '/';

  static Map<String, WidgetBuilder> get routes => {
    home: (context) => const WeatherHomePage(),
  };
}
