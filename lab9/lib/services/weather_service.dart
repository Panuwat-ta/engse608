import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/weather_forecast_model.dart';

class WeatherService {
  Future<WeatherForecast> fetchWeather(
    double latitude,
    double longitude,
  ) async {
    final response = await http.get(
      Uri.parse(
        'https://api.open-meteo.com/v1/forecast?latitude=$latitude&longitude=$longitude&current=temperature_2m,weather_code&daily=weather_code,temperature_2m_max,temperature_2m_min&forecast_days=10&timezone=Asia%2FBangkok',
      ),
    );

    if (response.statusCode == 200) {
      return WeatherForecast.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load weather data');
    }
  }
}
