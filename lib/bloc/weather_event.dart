import 'package:equatable/equatable.dart';

abstract class WeatherEvent extends Equatable {
  const WeatherEvent();

  @override
  List<Object?> get props => [];
}

/// Initialize the app and load saved preferences
class InitializeWeather extends WeatherEvent {}

/// Fetch main weather (either from GPS or manual city)
class FetchMainWeather extends WeatherEvent {
  final bool silent;

  const FetchMainWeather({this.silent = false});

  @override
  List<Object?> get props => [silent];
}

/// Set main location
class SetMainLocation extends WeatherEvent {
  final bool useGPS;
  final String? cityName;

  const SetMainLocation({required this.useGPS, this.cityName});

  @override
  List<Object?> get props => [useGPS, cityName];
}

/// Toggle between Celsius and Fahrenheit
class ToggleTemperatureUnit extends WeatherEvent {}

/// Search cities for autocomplete
class SearchCities extends WeatherEvent {
  final String query;

  const SearchCities(this.query);

  @override
  List<Object?> get props => [query];
}

/// Add a saved city
class AddSavedCity extends WeatherEvent {
  final String cityName;

  const AddSavedCity(this.cityName);

  @override
  List<Object?> get props => [cityName];
}

/// Remove a saved city
class RemoveSavedCity extends WeatherEvent {
  final String cityName;

  const RemoveSavedCity(this.cityName);

  @override
  List<Object?> get props => [cityName];
}

/// Refresh saved locations list
class RefreshSavedLocations extends WeatherEvent {
  final bool silent;

  const RefreshSavedLocations({this.silent = false});

  @override
  List<Object?> get props => [silent];
}

/// Timer tick for main weather (every 1 minute)
class MainWeatherTimerTick extends WeatherEvent {}

/// Timer tick for saved locations (every 5 minutes)
class SavedWeatherTimerTick extends WeatherEvent {}
