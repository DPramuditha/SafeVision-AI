class OpenweatherService {
  final String name;
  final String main;
  final String description;
  final double temp;
  final double feelsLike;
  final double humidity;
  final double windSpeed;
  final double rain;

  OpenweatherService({
    required this.name, 
    required this.main, 
    required this.description, 
    required this.temp, 
    required this.feelsLike, 
    required this.humidity, 
    required this.windSpeed, 
    required this.rain
    });

    factory OpenweatherService.fromJson(Map<String, dynamic> json) {
    return OpenweatherService(
      name: json['name'] ?? 'Unknown',
      main: json['weather'][0]['main'] ?? 'Unknown',
      description: json['weather'][0]['description'] ?? 'No description available',
      temp: (json['main']['temp'] as num).toDouble(),
      feelsLike: (json['main']['feels_like'] as num).toDouble(),
      humidity: (json['main']['humidity'] as num).toDouble(),
      windSpeed: (json['wind']['speed'] as num).toDouble(),
      rain: (json['rain']?['1h'] as num?)?.toDouble() ?? 0.0,
    );
    }

    Map<String, dynamic> toJson() {
      return {
        'name': name,
        'main': main,
        'description': description,
        'temp': temp,
        'feels_like': feelsLike,
        'humidity': humidity,
        'wind_speed': windSpeed,
        'rain': rain,
      };
    }



}