import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/weather_provider.dart';
import '../models/province_model.dart';
import '../models/weather_forecast_model.dart';

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<WeatherProvider>(context, listen: false).fetchWeather();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thailand Weather'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              Provider.of<WeatherProvider>(
                context,
                listen: false,
              ).fetchWeather();
            },
          ),
        ],
      ),
      body: Consumer<WeatherProvider>(
        builder: (context, provider, child) {
          return Column(
            children: [
              // Province Selector
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: DropdownButton<Province>(
                  isExpanded: true,
                  value: provider.selectedProvince,
                  onChanged: (Province? newValue) {
                    if (newValue != null) {
                      provider.changeProvince(newValue);
                    }
                  },
                  items: provinces.map<DropdownMenuItem<Province>>((
                    Province province,
                  ) {
                    return DropdownMenuItem<Province>(
                      value: province,
                      child: Text(province.name),
                    );
                  }).toList(),
                ),
              ),

              // View Toggle
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: ToggleButtons(
                  isSelected: [
                    provider.showCurrentWeather,
                    !provider.showCurrentWeather,
                  ],
                  onPressed: (int index) {
                    provider.toggleViewMode(index == 0);
                  },
                  borderRadius: BorderRadius.circular(8),
                  children: const [
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text('Current'),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text('10-Day Forecast'),
                    ),
                  ],
                ),
              ),

              const Divider(),

              // Content Area
              Expanded(child: _buildContent(provider)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildContent(WeatherProvider provider) {
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.error != null) {
      return Center(child: Text('Error: ${provider.error}'));
    }

    if (provider.weather == null) {
      return const Center(child: Text('No data available'));
    }

    if (provider.showCurrentWeather) {
      return _buildCurrentWeather(provider.weather!.current);
    } else {
      return _buildDailyForecast(provider.weather!.daily);
    }
  }

  Widget _buildCurrentWeather(Current? current) {
    if (current == null) {
      return const Center(child: Text('Current weather data unavailable'));
    }
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Temperature',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Text(
            '${current.temperature2m}°C',
            style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
          ),
          Text('Weather Code: ${current.weatherCode}'),
        ],
      ),
    );
  }

  Widget _buildDailyForecast(Daily? daily) {
    if (daily == null) {
      return const Center(child: Text('Forecast data unavailable'));
    }
    return ListView.builder(
      itemCount: daily.time.length,
      itemBuilder: (context, index) {
        return ListTile(
          leading: const Icon(Icons.calendar_today),
          title: Text(daily.time[index]),
          subtitle: Text(
            'Max: ${daily.temperature2mMax[index]}°C, Min: ${daily.temperature2mMin[index]}°C',
          ),
          trailing: Text('Code: ${daily.weatherCode[index]}'),
        );
      },
    );
  }
}
