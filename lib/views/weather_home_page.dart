import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/weather_bloc.dart';
import '../bloc/weather_event.dart';
import '../bloc/weather_state.dart';
import '../widgets/current_weather_card.dart';
import '../widgets/small_weather_tile.dart';
import '../constants/app_constants.dart';
import '../utils/weather_utils.dart';

class WeatherHomePage extends StatefulWidget {
  const WeatherHomePage({super.key});

  @override
  State<WeatherHomePage> createState() => _WeatherHomePageState();
}

class _WeatherHomePageState extends State<WeatherHomePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WeatherBloc>().add(InitializeWeather());
    });
  }

  // --- SEARCH SHEET ---
  void _showSearchSheet(BuildContext context, {bool isForMain = false}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          height: MediaQuery.of(ctx).size.height * 0.85,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                isForMain ? "Set Main Location" : "Add Saved Location",
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Autocomplete<String>(
                optionsBuilder: (TextEditingValue val) async {
                  if (val.text.length < 3)
                    return const Iterable<String>.empty();
                  context.read<WeatherBloc>().add(SearchCities(val.text));

                  // Get the current search results from the state
                  final state = context.read<WeatherBloc>().state;
                  if (state is WeatherLoaded) {
                    return state.searchResults;
                  }
                  return const Iterable<String>.empty();
                },
                onSelected: (String selection) {
                  Navigator.pop(ctx);
                  if (isForMain) {
                    context.read<WeatherBloc>().add(
                      SetMainLocation(
                        useGPS: false,
                        cityName: selection.split(',')[0],
                      ),
                    );
                  } else {
                    context.read<WeatherBloc>().add(AddSavedCity(selection));
                  }
                },
                fieldViewBuilder:
                    (context, textController, focusNode, onFieldSubmitted) {
                      return TextField(
                        controller: textController,
                        focusNode: focusNode,
                        autofocus: true,
                        decoration: InputDecoration(
                          hintText: "Search City (e.g. London)",
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 16,
                          ),
                        ),
                      );
                    },
                optionsViewBuilder: (context, onSelected, options) {
                  return Align(
                    alignment: Alignment.topLeft,
                    child: Material(
                      elevation: 8.0,
                      borderRadius: BorderRadius.circular(15),
                      color: Colors.white,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight: 250,
                          maxWidth: MediaQuery.of(context).size.width - 40,
                        ),
                        child: ListView.separated(
                          padding: EdgeInsets.zero,
                          shrinkWrap: true,
                          itemCount: options.length,
                          separatorBuilder: (ctx, i) =>
                              const Divider(height: 1, color: Colors.grey),
                          itemBuilder: (BuildContext context, int index) {
                            final String option = options.elementAt(index);
                            return ListTile(
                              title: Text(
                                option,
                                style: const TextStyle(fontSize: 16),
                              ),
                              leading: const Icon(
                                Icons.location_on_outlined,
                                color: Colors.blue,
                              ),
                              onTap: () => onSelected(option),
                            );
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WeatherBloc, WeatherState>(
      builder: (context, state) {
        if (state is! WeatherLoaded) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final bgColors = WeatherUtils.getBackgroundColors(
          state.mainWeather?.weatherCode ?? 0,
        );

        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: const Text(
              AppConstants.appTitle,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            centerTitle: true,
            actions: [
              // C/F Toggle Button
              TextButton(
                onPressed: () =>
                    context.read<WeatherBloc>().add(ToggleTemperatureUnit()),
                child: Text(
                  state.isCelsius ? "°C" : "°F",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.settings, color: Colors.white),
                onSelected: (value) {
                  if (value == 'GPS') {
                    context.read<WeatherBloc>().add(
                      const SetMainLocation(useGPS: true),
                    );
                  } else {
                    _showSearchSheet(context, isForMain: true);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'GPS',
                    child: Row(
                      children: [
                        Icon(Icons.gps_fixed),
                        SizedBox(width: 10),
                        Text("Use GPS"),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'City',
                    child: Row(
                      children: [
                        Icon(Icons.edit_location),
                        SizedBox(width: 10),
                        Text("Set City"),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          body: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: bgColors,
              ),
            ),
            child: SafeArea(
              child: RefreshIndicator(
                onRefresh: () async =>
                    context.read<WeatherBloc>().add(InitializeWeather()),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20.0,
                            vertical: 10.0,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 20),
                              if (state.isMainLoading)
                                const SizedBox(
                                  height: 300,
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                    ),
                                  ),
                                )
                              else
                                CurrentWeatherCard(
                                  weather: state.mainWeather,
                                  isCelsius: state.isCelsius, // Pass unit
                                  lastUpdated:
                                      state.lastMainUpdate, // Pass timer
                                ),

                              const SizedBox(height: 40),

                              // Header Row
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        "Saved Locations",
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white70,
                                        ),
                                      ),
                                      // Proof of 5 min timer
                                      if (state.lastListUpdate != null)
                                        Text(
                                          "Updated: ${state.lastListUpdate!.hour}:${state.lastListUpdate!.minute.toString().padLeft(2, '0')}",
                                          style: const TextStyle(
                                            fontSize: 10,
                                            color: Colors.white38,
                                          ),
                                        ),
                                    ],
                                  ),
                                  if (state.isAddingCity)
                                    const SizedBox(
                                      width: 15,
                                      height: 15,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 15),

                              SizedBox(
                                height: 170,
                                child: state.savedLocations.isEmpty
                                    ? _buildEmptyState()
                                    : ListView.builder(
                                        scrollDirection: Axis.horizontal,
                                        itemCount: state.savedLocations.length,
                                        physics: const BouncingScrollPhysics(),
                                        itemBuilder: (ctx, index) {
                                          final weather =
                                              state.savedLocations[index];
                                          return Padding(
                                            padding: const EdgeInsets.only(
                                              right: 12.0,
                                            ),
                                            child: Stack(
                                              children: [
                                                SmallWeatherTile(
                                                  weather: weather,
                                                  isCelsius: state
                                                      .isCelsius, // Pass unit
                                                ),
                                                Positioned(
                                                  right: 0,
                                                  top: 0,
                                                  child: InkWell(
                                                    onTap: () => context
                                                        .read<WeatherBloc>()
                                                        .add(
                                                          RemoveSavedCity(
                                                            weather.cityName,
                                                          ),
                                                        ),
                                                    child: Container(
                                                      padding:
                                                          const EdgeInsets.all(
                                                            6,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color: Colors.black
                                                            .withOpacity(0.1),
                                                        shape: BoxShape.circle,
                                                      ),
                                                      child: const Icon(
                                                        Icons.close,
                                                        size: 12,
                                                        color: Colors.white54,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                              ),
                              const SizedBox(height: 80),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _showSearchSheet(context, isForMain: false),
            icon: const Icon(Icons.add_location_alt_outlined),
            label: const Text("Add City"),
            elevation: 4,
            backgroundColor: Colors.white,
            foregroundColor: Colors.black87,
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.bookmark_border, color: Colors.white54, size: 30),
          SizedBox(height: 10),
          Text(
            "No saved locations yet.",
            style: TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}
