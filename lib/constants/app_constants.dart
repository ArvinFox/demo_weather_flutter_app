class AppConstants {
  // Open-Meteo URLs (No Key Needed)
  static const String weatherUrl = 'https://api.open-meteo.com/v1/forecast';
  static const String geocodingUrl =
      'https://geocoding-api.open-meteo.com/v1/search';

  static const String savedCitiesKey = 'saved_cities';

  static const String appTitle = 'Weather';
  static const String errorLocation = 'Location services disabled.';
  static const String errorFetch = 'Failed to load data.';
}
