import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:geolocator/geolocator.dart';

/// Service to generate LLM-powered contextual alerts using OpenAI and OpenWeatherMap APIs.
class LlmAlertService {
  final String openWeatherApiKey;
  final String openAiApiKey;
  final FlutterTts tts = FlutterTts();
  final String driverName;

  LlmAlertService({
    required this.openWeatherApiKey,
    required this.openAiApiKey,
    this.driverName = 'Driver',
  }) {
    _initializeTts();
  }

  void _initializeTts() async {
    await tts.setLanguage('en-US');
    await tts.setSpeechRate(0.5);
    await tts.setPitch(1.0);
  }

  /// Generates a contextual alert based on fatigue data and weather.
  /// Returns the LLM-generated message or a fallback message if the API fails.
  Future<String> generateContextualAlert({
    required double blinkRate,
    required int closedEyesFrameCount,
    required int noFaceFrameCount,
    required int drivingMinutes,
    String fallbackMessage = 'Please stay alert!',
  }) async {
    try {
      // Get current location
      final position = await _getCurrentLocation();
      if (position == null) {
        debugPrint('Location unavailable, using fallback message');
        await tts.speak(fallbackMessage);
        return fallbackMessage;
      }

      // Fetch weather data
      final weatherData = await _fetchWeatherData(position.latitude, position.longitude);
      if (weatherData == null) {
        debugPrint('Weather data unavailable, using fallback message');
        await tts.speak(fallbackMessage);
        return fallbackMessage;
      }

      // Construct prompt for OpenAI
      final prompt = _buildPrompt(
        blinkRate: blinkRate,
        closedEyesFrameCount: closedEyesFrameCount,
        noFaceFrameCount: noFaceFrameCount,
        drivingMinutes: drivingMinutes,
        weather: weatherData['weather'][0]['description'],
        temperature: weatherData['main']['temp'].toDouble(),
      );

      // Call OpenAI API
      final llmMessage = await _callOpenAiApi(prompt);
      if (llmMessage.isEmpty) {
        debugPrint('LLM response empty, using fallback message');
        await tts.speak(fallbackMessage);
        return fallbackMessage;
      }

      // Speak the message
      await tts.speak(llmMessage);
      debugPrint('LLM Alert: $llmMessage');
      return llmMessage;
    } catch (e) {
      debugPrint('Error generating alert: $e');
      await tts.speak(fallbackMessage);
      return fallbackMessage;
    }
  }

  /// Gets the current device location.
  Future<Position?> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint('Location services disabled');
      return null;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        debugPrint('Location permission denied');
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      debugPrint('Location permission permanently denied');
      return null;
    }

    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );
    } catch (e) {
      debugPrint('Error getting location: $e');
      return null;
    }
  }

  /// Fetches weather data from OpenWeatherMap API.
  Future<Map<String, dynamic>?> _fetchWeatherData(double latitude, double longitude) async {
    final url = Uri.parse(
      'https://api.openweathermap.org/data/2.5/weather?lat=$latitude&lon=$longitude&appid=$openWeatherApiKey&units=metric',
    );
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        debugPrint('Weather API error: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('Error fetching weather: $e');
      return null;
    }
  }

  /// Builds a prompt for the OpenAI API.
  String _buildPrompt({
    required double blinkRate,
    required int closedEyesFrameCount,
    required int noFaceFrameCount,
    required int drivingMinutes,
    required String weather,
    required double temperature,
  }) {
    return """
You are a friendly driving assistant for $driverName. The driver has been driving for $drivingMinutes minutes. Their blink rate is $blinkRate blinks per minute, eyes have been closed for $closedEyesFrameCount frames, and no face was detected for $noFaceFrameCount frames. Current weather is $weather with a temperature of $temperature°C. It’s ${DateTime.now().hour}:${DateTime.now().minute}. Generate a concise, friendly alert (1-2 sentences) suggesting a safety action (e.g., take a break, stay alert) tailored to the driver’s fatigue and weather conditions.
""";
  }

  /// Calls OpenAI ChatGPT API to generate a message.
  Future<String> _callOpenAiApi(String prompt) async {
    final url = Uri.parse('https://api.openai.com/v1/chat/completions');
    try {
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $openAiApiKey',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'model': 'gpt-4o-mini',
          'messages': [
            {'role': 'user', 'content': prompt},
          ],
          'max_tokens': 50,
          'temperature': 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['choices'][0]['message']['content'].trim();
      } else {
        debugPrint('OpenAI API error: ${response.statusCode}');
        print('☑️Response body: ${response.body}');

        return '';
      }
    } catch (e) {
      debugPrint('❌Error calling OpenAI: $e');
      print('❌Error calling OpenAI: $e');
      return '';
    }
  }

  /// Disposes resources.
  void dispose() {
    tts.stop();
  }
}