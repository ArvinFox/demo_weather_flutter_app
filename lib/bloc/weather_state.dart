import 'package:equatable/equatable.dart';
import '../models/weather_model.dart';

abstract class WeatherState extends Equatable {
  const WeatherState();

  @override
  List<Object?> get props => [];
}

class WeatherInitial extends WeatherState {}

class WeatherLoaded extends WeatherState {
  final WeatherModel? mainWeather;
  final List<WeatherModel> savedLocations;
  final String? errorMessage;
  final DateTime? lastMainUpdate;
  final DateTime? lastListUpdate;
  final bool isCelsius;
  final bool isMainLoading;
  final bool isListLoading;
  final bool isAddingCity;
  final bool useGPS;
  final String? manualMainCity;
  final List<String> searchResults;

  const WeatherLoaded({
    this.mainWeather,
    this.savedLocations = const [],
    this.errorMessage,
    this.lastMainUpdate,
    this.lastListUpdate,
    this.isCelsius = true,
    this.isMainLoading = false,
    this.isListLoading = false,
    this.isAddingCity = false,
    this.useGPS = true,
    this.manualMainCity,
    this.searchResults = const [],
  });

  WeatherLoaded copyWith({
    WeatherModel? mainWeather,
    List<WeatherModel>? savedLocations,
    String? errorMessage,
    DateTime? lastMainUpdate,
    DateTime? lastListUpdate,
    bool? isCelsius,
    bool? isMainLoading,
    bool? isListLoading,
    bool? isAddingCity,
    bool? useGPS,
    String? manualMainCity,
    List<String>? searchResults,
    bool clearError = false,
    bool clearMainWeather = false,
  }) {
    return WeatherLoaded(
      mainWeather: clearMainWeather ? null : mainWeather ?? this.mainWeather,
      savedLocations: savedLocations ?? this.savedLocations,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      lastMainUpdate: lastMainUpdate ?? this.lastMainUpdate,
      lastListUpdate: lastListUpdate ?? this.lastListUpdate,
      isCelsius: isCelsius ?? this.isCelsius,
      isMainLoading: isMainLoading ?? this.isMainLoading,
      isListLoading: isListLoading ?? this.isListLoading,
      isAddingCity: isAddingCity ?? this.isAddingCity,
      useGPS: useGPS ?? this.useGPS,
      manualMainCity: manualMainCity ?? this.manualMainCity,
      searchResults: searchResults ?? this.searchResults,
    );
  }

  @override
  List<Object?> get props => [
    mainWeather,
    savedLocations,
    errorMessage,
    lastMainUpdate,
    lastListUpdate,
    isCelsius,
    isMainLoading,
    isListLoading,
    isAddingCity,
    useGPS,
    manualMainCity,
    searchResults,
  ];
}
