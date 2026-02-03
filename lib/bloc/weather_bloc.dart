import 'dart:async';
import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'weather_event.dart';
import 'weather_state.dart';
import '../models/weather_model.dart';
import '../constants/app_constants.dart';

class WeatherBloc extends Bloc<WeatherEvent, WeatherState> {
  Timer? _mainTimer;
  Timer? _savedTimer;

  WeatherBloc() : super(WeatherInitial()) {
    on<InitializeWeather>(_onInitialize);
    on<FetchMainWeather>(_onFetchMainWeather);
    on<SetMainLocation>(_onSetMainLocation);
    on<ToggleTemperatureUnit>(_onToggleTemperatureUnit);
    on<SearchCities>(_onSearchCities);
    on<AddSavedCity>(_onAddSavedCity);
    on<RemoveSavedCity>(_onRemoveSavedCity);
    on<RefreshSavedLocations>(_onRefreshSavedLocations);
    on<MainWeatherTimerTick>(_onMainWeatherTimerTick);
    on<SavedWeatherTimerTick>(_onSavedWeatherTimerTick);
  }

  Future<void> _onInitialize(
    InitializeWeather event,
    Emitter<WeatherState> emit,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final useGPS = prefs.getBool('use_gps') ?? true;
    final manualMainCity = prefs.getString('manual_main_city');
    final isCelsius = prefs.getBool('is_celsius') ?? true;

    emit(
      WeatherLoaded(
        useGPS: useGPS,
        manualMainCity: manualMainCity,
        isCelsius: isCelsius,
        isMainLoading: true,
      ),
    );

    // Fetch main weather
    await _fetchMainWeatherData(emit);

    // Load saved cities
    await _refreshSavedListData(emit);

    // Start timers
    _startTimers();
  }

  void _startTimers() {
    _mainTimer?.cancel();
    _savedTimer?.cancel();

    // 1 Minute Timer for main weather
    _mainTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => add(MainWeatherTimerTick()),
    );

    // 5 Minute Timer for saved locations
    _savedTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => add(SavedWeatherTimerTick()),
    );
  }

  Future<void> _onFetchMainWeather(
    FetchMainWeather event,
    Emitter<WeatherState> emit,
  ) async {
    await _fetchMainWeatherData(emit, silent: event.silent);
  }

  Future<void> _onSetMainLocation(
    SetMainLocation event,
    Emitter<WeatherState> emit,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('use_gps', event.useGPS);
    if (event.cityName != null) {
      await prefs.setString('manual_main_city', event.cityName!);
    }

    final currentState = state;
    if (currentState is WeatherLoaded) {
      emit(
        currentState.copyWith(
          useGPS: event.useGPS,
          manualMainCity: event.cityName ?? currentState.manualMainCity,
          isMainLoading: true,
        ),
      );
    }

    await _fetchMainWeatherData(emit);
  }

  Future<void> _onToggleTemperatureUnit(
    ToggleTemperatureUnit event,
    Emitter<WeatherState> emit,
  ) async {
    final currentState = state;
    if (currentState is WeatherLoaded) {
      final newIsCelsius = !currentState.isCelsius;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_celsius', newIsCelsius);

      emit(currentState.copyWith(isCelsius: newIsCelsius));
    }
  }

  Future<void> _onSearchCities(
    SearchCities event,
    Emitter<WeatherState> emit,
  ) async {
    if (event.query.length < 3) {
      final currentState = state;
      if (currentState is WeatherLoaded) {
        emit(currentState.copyWith(searchResults: []));
      }
      return;
    }

    try {
      final url =
          '${AppConstants.geocodingUrl}?name=${event.query}&count=5&language=en&format=json';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final results = <String>[];

        if (data['results'] != null) {
          results.addAll(
            (data['results'] as List)
                .map((e) => "${e['name']}, ${e['country'] ?? ''}")
                .toList(),
          );
        }

        final currentState = state;
        if (currentState is WeatherLoaded) {
          emit(currentState.copyWith(searchResults: results));
        }
      }
    } catch (_) {
      // Silently fail search
    }
  }

  Future<void> _onAddSavedCity(
    AddSavedCity event,
    Emitter<WeatherState> emit,
  ) async {
    final currentState = state;
    if (currentState is! WeatherLoaded) return;

    emit(currentState.copyWith(isAddingCity: true));

    final simpleName = event.cityName.split(',')[0];
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
        await _refreshSavedListData(emit);
      }
    }

    final newState = state;
    if (newState is WeatherLoaded) {
      emit(newState.copyWith(isAddingCity: false));
    }
  }

  Future<void> _onRemoveSavedCity(
    RemoveSavedCity event,
    Emitter<WeatherState> emit,
  ) async {
    final currentState = state;
    if (currentState is! WeatherLoaded) return;

    final prefs = await SharedPreferences.getInstance();
    List<String> list = prefs.getStringList(AppConstants.savedCitiesKey) ?? [];
    list.removeWhere((item) => item.split('|')[0] == event.cityName);
    await prefs.setStringList(AppConstants.savedCitiesKey, list);

    final newSavedLocations = currentState.savedLocations
        .where((w) => w.cityName != event.cityName)
        .toList();

    emit(currentState.copyWith(savedLocations: newSavedLocations));
  }

  Future<void> _onRefreshSavedLocations(
    RefreshSavedLocations event,
    Emitter<WeatherState> emit,
  ) async {
    await _refreshSavedListData(emit, silent: event.silent);
  }

  Future<void> _onMainWeatherTimerTick(
    MainWeatherTimerTick event,
    Emitter<WeatherState> emit,
  ) async {
    await _fetchMainWeatherData(emit, silent: true);
  }

  Future<void> _onSavedWeatherTimerTick(
    SavedWeatherTimerTick event,
    Emitter<WeatherState> emit,
  ) async {
    await _refreshSavedListData(emit, silent: true);
  }

  // Helper Methods

  Future<void> _fetchMainWeatherData(
    Emitter<WeatherState> emit, {
    bool silent = false,
  }) async {
    final currentState = state;
    if (currentState is! WeatherLoaded) return;

    if (!silent) {
      emit(currentState.copyWith(isMainLoading: true));
    }

    try {
      double lat, lon;
      String mainTitle;
      String? subTitle;

      if (currentState.useGPS) {
        Position pos = await _determinePosition();
        lat = pos.latitude;
        lon = pos.longitude;
        mainTitle = "Current Location";
        subTitle = await _getCityNameFromCoords(lat, lon);
      } else {
        if (currentState.manualMainCity == null) {
          emit(currentState.copyWith(isMainLoading: false));
          return;
        }
        final coords = await _getCoords(currentState.manualMainCity!);
        if (coords == null) {
          emit(currentState.copyWith(isMainLoading: false));
          return;
        }
        lat = coords['lat']!;
        lon = coords['lon']!;
        mainTitle = currentState.manualMainCity!;
        subTitle = null;
      }

      final url = _buildUrl(lat, lon);
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final mainWeather = WeatherModel.fromOpenMeteo(
          jsonDecode(response.body),
          mainTitle,
          subTitle: subTitle,
          lat: lat,
          lon: lon,
        );

        final newState = state;
        if (newState is WeatherLoaded) {
          emit(
            newState.copyWith(
              mainWeather: mainWeather,
              lastMainUpdate: DateTime.now(),
              isMainLoading: false,
              clearError: true,
            ),
          );
        }
      }
    } catch (e) {
      final newState = state;
      if (newState is WeatherLoaded) {
        emit(
          newState.copyWith(errorMessage: e.toString(), isMainLoading: false),
        );
      }
    }
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

  Future<void> _refreshSavedListData(
    Emitter<WeatherState> emit, {
    bool silent = false,
  }) async {
    final currentState = state;
    if (currentState is! WeatherLoaded) return;

    if (!silent) {
      emit(currentState.copyWith(isListLoading: true));
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

    final newState = state;
    if (newState is WeatherLoaded) {
      emit(
        newState.copyWith(
          savedLocations: temp,
          lastListUpdate: DateTime.now(),
          isListLoading: false,
        ),
      );
    }
  }

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
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      return Future.error('Permission denied.');
    }
    return await Geolocator.getCurrentPosition();
  }

  @override
  Future<void> close() {
    _mainTimer?.cancel();
    _savedTimer?.cancel();
    return super.close();
  }
}
