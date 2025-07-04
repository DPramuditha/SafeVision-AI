class RegisterUser {
  String name;
  String email;
  String busNumber;
  String route;
  int emergencyContact;
  DateTime dateTime;

  RegisterUser({
    required this.name,
    required this.email,
    required this.busNumber,
    required this.route,
    required this.emergencyContact,
    required this.dateTime,
  });

  factory RegisterUser.fromJson(Map<String, dynamic> json, String id) {
    return RegisterUser(
      name: json['name'] as String? ?? 'Unknown',
      email: json['email'] as String? ?? '',
      busNumber: json['busNumber'] as String? ?? 'N/A',
      route: json['route'] as String? ?? 'N/A',
      emergencyContact: _parseToInt(json['emergencyContact']),
      dateTime: _parseToDateTime(json['dateTime']),
    );
  }

  // Helper method to safely parse different types to int
  static int _parseToInt(dynamic value) {
    if (value is int) {
      return value;
    } else if (value is String) {
      return int.tryParse(value) ?? 0;
    } else {
      return 0;
    }
  }

  // Helper method to safely parse different types to DateTime
  static DateTime _parseToDateTime(dynamic value) {
    if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.now();
    } else if (value is DateTime) {
      return value;
    } else {
      return DateTime.now();
    }
  }
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'busNumber': busNumber,
      'route': route,
      'emergencyContact': emergencyContact,
      'dateTime': dateTime.toIso8601String(),
    };
  }


}
