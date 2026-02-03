import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/weather_model.dart';
import '../constants/app_constants.dart';

class WeatherController extends ChangeNotifier {
  // STATE
  WeatherModel? mainWeather;
  List<WeatherModel> savedLocations = [];
  String? errorMessage;

  // New: Timestamps for "Physical Timer" proof
  DateTime? lastMainUpdate;
  DateTime? lastListUpdate;

  // New: Unit Toggle
  bool isCelsius = true;

  // Granular Loading States
  bool isMainLoading = true;
  bool isListLoading = false;
  bool isAddingCity = false;

  // Settings
  bool useGPS = true;
  String? manualMainCity;

  Timer? _mainTimer;
  Timer? _savedTimer;

  // --- INIT ---
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    useGPS = prefs.getBool('use_gps') ?? true;
    manualMainCity = prefs.getString('manual_main_city');
    isCelsius = prefs.getBool('is_celsius') ?? true; // Load Unit Preference

    await _fetchMainWeather();
    await _loadSavedCities();

    _startTimers();
  }

  void _startTimers() {
    _mainTimer?.cancel();
    _savedTimer?.cancel();
    // 1 Minute Timer
    _mainTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => _fetchMainWeather(silent: true),
    );
    // 5 Minute Timer
    _savedTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => _refreshSavedList(silent: true),
    );
  }

  // --- TOGGLE UNITS ---
  void toggleUnit() async {
    isCelsius = !isCelsius;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_celsius', isCelsius);
    notifyListeners();
  }

  // SEARCH
  Future<List<String>> searchCities(String query) async {
    if (query.length < 3) return [];
    try {
      final url =
          '${AppConstants.geocodingUrl}?name=$query&count=5&language=en&format=json';
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['results'] != null) {
          return (data['results'] as List)
              .map((e) => "${e['name']}, ${e['country'] ?? ''}")
              .toList();
        }
      }
    } catch (_) {}
    return [];
  }

  // MAIN WEATHER
  Future<void> setMainLocation(bool gpsEnabled, {String? cityName}) async {
    useGPS = gpsEnabled;
    if (cityName != null) manualMainCity = cityName;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('use_gps', useGPS);
    if (manualMainCity != null)
      await prefs.setString('manual_main_city', manualMainCity!);

    isMainLoading = true;
    notifyListeners();

    await _fetchMainWeather();
  }

  Future<void> _fetchMainWeather({bool silent = false}) async {
    if (!silent) {
      isMainLoading = true;
      notifyListeners();
    }

    try {
      double lat, lon;
      String mainTitle;
      String? subTitle;

      if (useGPS) {
        Position pos = await _determinePosition();
        lat = pos.latitude;
        lon = pos.longitude;
        mainTitle = "Current Location";
        subTitle = await _getCityNameFromCoords(lat, lon);
      } else {
        if (manualMainCity == null) return;
        final coords = await _getCoords(manualMainCity!);
        if (coords == null) return;
        lat = coords['lat']!;
        lon = coords['lon']!;
        mainTitle = manualMainCity!;
        subTitle = null;
      }

      final url = _buildUrl(lat, lon);
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        mainWeather = WeatherModel.fromOpenMeteo(
          jsonDecode(response.body),
          mainTitle,
          subTitle: subTitle,
          lat: lat,
          lon: lon,
        );
        lastMainUpdate = DateTime.now(); // Record Time
        errorMessage = null;
      }
    } catch (e) {
      errorMessage = e.toString();
    }

    isMainLoading = false;
    notifyListeners();
  }

  Future<String?> _getCityNameFromCoords(double lat, double lon) async {
    try {
      final url =
          'https://geocoding-api.open-meteo.com/v1/reverse?latitude=$lat&longitude=$lon&count=1&format=json&language=en';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['results'] != null && data['results'].isNotEmpty) {
          return data['results'][0]['name'] ?? data['results'][0]['admin1'];
        }
      }
    } catch (_) {}
    return null;
  }

  // SAVED LOCATIONS
  Future<void> addSavedCity(String fullCityName) async {
    isAddingCity = true;
    notifyListeners();

    final simpleName = fullCityName.split(',')[0];
    final coords = await _getCoords(simpleName);

    if (coords != null) {
      final saveString = "$simpleName|${coords['lat']}|${coords['lon']}";
      final prefs = await SharedPreferences.getInstance();
      List<String> list =
          prefs.getStringList(AppConstants.savedCitiesKey) ?? [];

      if (!list.any((e) => e.startsWith(simpleName))) {
        list.add(saveString);
        if (list.length > 3) list.removeAt(0);
        await prefs.setStringList(AppConstants.savedCitiesKey, list);
        await _refreshSavedList();
      }
    }
    isAddingCity = false;
    notifyListeners();
  }

  Future<void> removeCity(String cityName) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> list = prefs.getStringList(AppConstants.savedCitiesKey) ?? [];
    list.removeWhere((item) => item.split('|')[0] == cityName);
    await prefs.setStringList(AppConstants.savedCitiesKey, list);
    savedLocations.removeWhere((w) => w.cityName == cityName);
    notifyListeners();
  }

  Future<void> _loadSavedCities() async {
    await _refreshSavedList();
  }

  Future<void> _refreshSavedList({bool silent = false}) async {
    if (!silent) {
      isListLoading = true;
      notifyListeners();
    }

    final prefs = await SharedPreferences.getInstance();
    List<String> list = prefs.getStringList(AppConstants.savedCitiesKey) ?? [];
    List<WeatherModel> temp = [];

    for (var item in list) {
      final parts = item.split('|');
      if (parts.length == 3) {
        final url = _buildUrl(double.parse(parts[1]), double.parse(parts[2]));
        try {
          final res = await http.get(Uri.parse(url));
          if (res.statusCode == 200) {
            temp.add(
              WeatherModel.fromOpenMeteo(jsonDecode(res.body), parts[0]),
            );
          }
        } catch (_) {}
      }
    }
    savedLocations = temp;
    lastListUpdate = DateTime.now(); // Record Time
    isListLoading = false;
    notifyListeners();
  }

  // HELPERS
  String _buildUrl(double lat, double lon) {
    return '${AppConstants.weatherUrl}?latitude=$lat&longitude=$lon&current=temperature_2m,wind_speed_10m,weather_code&hourly=temperature_2m,relative_humidity_2m,wind_speed_10m';
  }

  Future<Map<String, double>?> _getCoords(String city) async {
    try {
      final url =
          '${AppConstants.geocodingUrl}?name=$city&count=1&language=en&format=json';
      final res = await http.get(Uri.parse(url));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['results'] != null && data['results'].isNotEmpty) {
          return {
            'lat': data['results'][0]['latitude'],
            'lon': data['results'][0]['longitude'],
          };
        }
      }
    } catch (_) {}
    return null;
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return Future.error('Location services disabled.');
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied)
      permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.deniedForever)
      return Future.error('Permission denied.');
    return await Geolocator.getCurrentPosition();
  }

  @override
  void dispose() {
    _mainTimer?.cancel();
    _savedTimer?.cancel();
    super.dispose();
  }
}
