class WeatherForecast {
  final double latitude;
  final double longitude;
  final String timezone;
  final Current? current;
  final Daily? daily;

  WeatherForecast({
    required this.latitude,
    required this.longitude,
    required this.timezone,
    this.current,
    this.daily,
  });

  factory WeatherForecast.fromJson(Map<String, dynamic> json) {
    return WeatherForecast(
      latitude: json['latitude'],
      longitude: json['longitude'],
      timezone: json['timezone'],
      current: json['current'] != null
          ? Current.fromJson(json['current'])
          : null,
      daily: json['daily'] != null ? Daily.fromJson(json['daily']) : null,
    );
  }
}

class Current {
  final String time;
  final int interval;
  final double temperature2m;
  final int weatherCode;

  Current({
    required this.time,
    required this.interval,
    required this.temperature2m,
    required this.weatherCode,
  });

  factory Current.fromJson(Map<String, dynamic> json) {
    return Current(
      time: json['time'],
      interval: json['interval'],
      temperature2m: json['temperature_2m'],
      weatherCode: json['weather_code'],
    );
  }
}

class Daily {
  final List<String> time;
  final List<int> weatherCode;
  final List<double> temperature2mMax;
  final List<double> temperature2mMin;

  Daily({
    required this.time,
    required this.weatherCode,
    required this.temperature2mMax,
    required this.temperature2mMin,
  });

  factory Daily.fromJson(Map<String, dynamic> json) {
    return Daily(
      time: List<String>.from(json['time']),
      weatherCode: List<int>.from(json['weather_code']),
      temperature2mMax: List<double>.from(json['temperature_2m_max']),
      temperature2mMin: List<double>.from(json['temperature_2m_min']),
    );
  }
}
