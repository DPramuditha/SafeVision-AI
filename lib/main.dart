import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:safe_vision/pages/face_detection_screen.dart';
import 'package:safe_vision/pages/home_page.dart';
import 'package:safe_vision/pages/login_page.dart';
import 'package:safe_vision/pages/signup_page.dart';
import 'package:safe_vision/pages/testaudio.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");

  try{
    await Firebase.initializeApp();
    print("✅Firebase initialized successfully");
  }
  catch (e) {
    print("❌Firebase initialization error: $e");
  }
  runApp(SafeVision());
}

class SafeVision extends StatelessWidget {
  const SafeVision({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Safe Vision',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      debugShowCheckedModeBanner: false,
      home: LoginPage(),

    );
  }
}
