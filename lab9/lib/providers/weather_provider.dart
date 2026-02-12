import 'package:flutter/material.dart';
import '../models/weather_forecast_model.dart';
import '../models/province_model.dart';
import '../services/weather_service.dart';

class WeatherProvider with ChangeNotifier {
  final WeatherService _weatherService = WeatherService();
  WeatherForecast? _weather;
  bool _isLoading = false;
  String? _error;

  Province _selectedProvince = provinces[0]; // Default to Bangkok
  bool _showCurrentWeather = true;

  WeatherForecast? get weather => _weather;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Province get selectedProvince => _selectedProvince;
  bool get showCurrentWeather => _showCurrentWeather;

  Future<void> fetchWeather() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _weather = await _weatherService.fetchWeather(
        _selectedProvince.latitude,
        _selectedProvince.longitude,
      );
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void changeProvince(Province province) {
    if (_selectedProvince != province) {
      _selectedProvince = province;
      fetchWeather();
    }
  }

  void toggleViewMode(bool showCurrent) {
    if (_showCurrentWeather != showCurrent) {
      _showCurrentWeather = showCurrent;
      notifyListeners();
    }
  }
}
