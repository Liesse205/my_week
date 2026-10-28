import 'dart:convert';
import 'package:http/http.dart' as http;

class Weather {
  final double temperature;
  Weather({required this.temperature});

  factory Weather.fromJson(Map<String, dynamic> json) {
    return Weather(
      temperature: (json['current']['temperature_2m'] as num).toDouble(),
    );
  }
}

Future<Weather> fetchWeather() async {
  final url = Uri.parse(
    'https://api.open-meteo.com/v1/forecast?latitude=-1.9441&longitude=30.0619&current=temperature_2m&timezone=Africa%2FKigali',
  );
  final response = await http.get(url);
  if (response.statusCode != 200) {
    throw Exception('Server error');
  }
  final data = jsonDecode(response.body);
  return Weather.fromJson(data);
}