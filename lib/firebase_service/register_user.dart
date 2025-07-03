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
      name: json['name'] as String,
      email: json['email'] as String,
      busNumber: json['busNumber'] as String,
      route: json['route'] as String,
      emergencyContact: json['emergencyContact'] as int,
      dateTime: DateTime.parse(json['dateTime'] as String),
    );
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
