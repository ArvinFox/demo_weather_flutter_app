# Demo Weather Flutter App

A modern, reactive weather application built with **Flutter** and **BLoC** architecture pattern. Get real-time weather data from Open-Meteo API with GPS support and saved locations.

## 🌟 Features

- **Real-time Weather Data** - Fetches current weather and hourly forecasts
- **GPS Integration** - Automatic location detection with Geolocator
- **Manual Location Search** - Search and add cities with autocomplete
- **Saved Locations** - Save up to 3 favorite locations
- **Temperature Unit Toggle** - Switch between Celsius and Fahrenheit
- **Auto-Refresh** - Automatic updates every 1 minute (main) and 5 minutes (saved)
- **Pull-to-Refresh** - Manual refresh with RefreshIndicator
- **Persistent Storage** - SharedPreferences for user preferences and saved cities
- **Glassmorphism UI** - Modern, elegant weather card design
- **BLoC State Management** - Clean, testable architecture with flutter_bloc

## 🏗️ Architecture

This app uses the **BLoC (Business Logic Component)** pattern for state management:

- **Events** - User actions and system triggers
- **States** - Immutable data models representing UI state
- **BLoC** - Business logic layer processing events and emitting states
- **UI Layers** - Widgets rebuilding reactively on state changes

### Project Structure

```
lib/
├── bloc/
│   ├── weather_event.dart      # All user events
│   ├── weather_state.dart      # State classes
│   └── weather_bloc.dart       # BLoC logic
├── models/
│   └── weather_model.dart      # Weather data model
├── views/
│   └── weather_home_page.dart  # Main UI
├── widgets/
│   ├── current_weather_card.dart
│   └── small_weather_tile.dart
├── constants/
│   └── app_constants.dart      # App configuration
├── routes/
│   └── app_routes.dart         # Navigation
├── utils/
│   └── weather_utils.dart      # Helper functions
├── controllers/
│   └── weather_controller.dart # (Legacy - Provider pattern)
├── app.dart                    # App setup
└── main.dart                   # Entry point
```

## 📦 Dependencies

- **flutter_bloc** (^8.1.3) - State management
- **equatable** (^2.0.5) - Value equality
- **http** (^1.2.0) - API requests
- **geolocator** (^10.1.0) - GPS location
- **shared_preferences** (^2.2.2) - Local storage

## 🚀 Getting Started

### Prerequisites

- Flutter SDK 3.9.2 or higher
- Dart 3.9.2 or higher
- Android SDK / Xcode (for respective platforms)

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/ArvinFox/demo_weather_flutter_app.git
   cd demo_weather_flutter_app
   ```

2. **Get dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the app**
   ```bash
   flutter run
   ```

## 🔧 Building

### Android APK
```bash
flutter build apk --release
```

### iOS IPA
```bash
flutter build ios --release
```

## 📡 API

Uses **Open-Meteo API** (free, no API key required):
- Weather: `https://api.open-meteo.com/v1/forecast`
- Geocoding: `https://geocoding-api.open-meteo.com/v1/search`

## 🛠️ Development

### Code Formatting
```bash
dart format lib/
```

### Analysis
```bash
flutter analyze
```

### Clean Build
```bash
flutter clean
flutter pub get
flutter run
```

## 📝 Key Events

- `InitializeWeather` - App startup
- `FetchMainWeather` - Refresh main location
- `SetMainLocation` - Change location (GPS/Manual)
- `ToggleTemperatureUnit` - Switch °C/°F
- `SearchCities` - City autocomplete
- `AddSavedCity` / `RemoveSavedCity` - Manage favorites
- `RefreshSavedLocations` - Update saved list
- Timer events - Auto-refresh triggers

## 🎨 UI Features

- Gradient backgrounds based on weather conditions
- Smooth animations and transitions
- Responsive layout for different screen sizes
- Material Design 3
- Glassmorphism card design

## 📱 Supported Platforms

- ✅ Android (5.0+)
- ✅ iOS (11.0+)
- ✅ Web
- ✅ Windows
- ✅ macOS
- ✅ Linux

## 🔐 Troubleshooting

### Gradle Cache Errors After Clean
If you see Kotlin daemon errors after `flutter clean`:
```bash
# The gradle.properties file has incremental compilation disabled
./android/gradlew.bat --stop
flutter clean
flutter pub get
flutter run
```

### Location Permission Issues
- Android: Check AndroidManifest.xml permissions
- iOS: Add NSLocationWhenInUseUsageDescription to Info.plist

## 📄 License

MIT License - see LICENSE file for details

## 👨‍💻 Author

ArvinFox

## 🤝 Contributing

Feel free to fork, submit issues, and create pull requests.

---

**Happy Weather Tracking!** 🌤️
