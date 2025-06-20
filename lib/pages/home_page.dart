import 'dart:convert';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http show get;
import 'package:lottie/lottie.dart';
import 'package:safe_vision/pages/face_detection_screen.dart';
import 'package:safe_vision/pages/face_detection_screen1.dart';
import 'package:safe_vision/weather_service/current_location.dart';
import 'package:safe_vision/weather_service/openweather_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {


  OpenweatherService? _openweatherService;

  @override
  void initState() {
    super.initState();
    fetchWeather();
  }

  void fetchWeather() async{
    try{
      print("Fetching weather data...");
      // final city = await CurrentLocation().getCurrentLocation();
      String city = "Colombo";

      if(city.startsWith('❌') || city.contains('denied')){
        print("❌Error fetching weather data: $city");
        return;
      }
      String apiKey = dotenv.env['WEATHER_API_KEY'] ?? "";
      print('✅Current Location: $city');

      // final url = "http://api.weatherapi.com/v1/current.json?key=$apiKey&q=$city&aqi=yes";
      final url = "https://api.openweathermap.org/data/2.5/weather?q=$city&appid=$apiKey&units=metric";
      final response = await http.get(Uri.parse(url));

      if(response.statusCode == 200){
        final decodebody = utf8.decode(response.bodyBytes);
        final jsondecode = jsonDecode(decodebody);
        print("✅Weather data fetched successfully: $jsondecode");
        setState(() {
          _openweatherService = OpenweatherService.fromJson(jsondecode);
        });
        print("✅Weather fetched successfully}");
      }
      else{
        print("❌Error fetching weather data: ${response.statusCode}");
      }
    }
    catch (e) {
      print("❌Error fetching weather data: $e");
    }

  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Container(
                width: double.infinity,
                height: 290,
                decoration: BoxDecoration(
                gradient: LinearGradient(
            colors: [
            Colors.deepPurple,
            Colors.purple,
            Colors.indigo,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
            BoxShadow(
            color: Colors.deepPurple.withOpacity(0.4),
            blurRadius: 20,
            spreadRadius: 5,
            offset: Offset(0, 10),
            ),
                ],
                ),
                child: Column(
            children: [
              SizedBox(height: 20),
              Row(
                children: [
            Lottie.asset('animation_assets/face_detection.json', 
              width: 100,
              height: 100,
              fit: BoxFit.cover,
            ),
            Text(
              'Safe Vision AI',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                foreground: Paint()
            ..shader = LinearGradient(
              colors: <Color>[
                Colors.cyan,
                Colors.blue,
                Colors.purple,
              ],
            ).createShader(
              Rect.fromLTWH(0.0, 0.0, 200.0, 70.0),
            ),
              ),
            ).animate(onPlay: (controller) => controller.repeat())
              .shimmer(duration: 3.seconds, color: Colors.white70)
              .fadeIn(duration: 800.ms)
              .slideX(begin: 0.2, duration: 600.ms, curve: Curves.easeOutBack),
                ],
              ),
              Text(
                textAlign: TextAlign.center,
                'Welcome to AI-powered face detection\nBuilding intelligent solutions for a Driving safety',
                style: GoogleFonts.spaceGrotesk(
            fontSize: 15,
            color: Colors.white70,
                ),
              ).animate()
                .fadeIn(duration: 1200.ms, delay: 400.ms)
                .slideY(begin: 0.3, duration: 800.ms, curve: Curves.easeOutBack)
                .then()
                .shimmer(duration: 4.seconds, delay: 2.seconds),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.cyan, Colors.blue],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(50),
            boxShadow: [
              BoxShadow(
                color: Colors.cyan.withOpacity(0.4),
                blurRadius: 10,
                offset: Offset(0, 5),
              ),
            ],
              ),
              child: GestureDetector(
  onTap: () {
    _showProfileBottomSheet(context);
  },
  child: Container(
    width: 50,
    height: 50,
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [Colors.cyan, Colors.blue],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(50),
      boxShadow: [
        BoxShadow(
          color: Colors.cyan.withOpacity(0.4),
          blurRadius: 10,
          offset: Offset(0, 5),
        ),
      ],
    ),
    child: Icon(
      Icons.person,
      size: 30,
      color: Colors.white,
    ),
  ),
            ),
              ),
            ),
            const SizedBox(width: 10),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20.0),
              child: Column(
                children: [
            Text(
              'Dimuthu Pramuditha',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ).animate()
              .fadeIn(duration: 800.ms, delay: 600.ms)
              .slideX(begin: 0.3, duration: 600.ms),
            Text(
              "Bus Number: 1234",
              style: GoogleFonts.spaceGrotesk(  
                fontSize: 16,
                color: Colors.white70,
              ),
            ).animate()
              .fadeIn(duration: 800.ms, delay: 800.ms)
              .slideX(begin: 0.3, duration: 600.ms),
            Text(
              "Route: Colombo - Galle",
              style: GoogleFonts.spaceGrotesk(
                fontSize: 16,
                color: Colors.white70,
              ),
            ).animate()
              .fadeIn(duration: 800.ms, delay: 1000.ms)
              .slideX(begin: 0.3, duration: 600.ms),
                ],
              ),
            ),
                ],
              ),
            ],
                ),
              )
            .animate(onPlay: (controller) => controller.repeat())
            .fadeIn(duration: 600.ms)
            .slideY(begin: -0.2, duration: 1200.ms, curve: Curves.easeOutBack)
            .shimmer(duration: 8.seconds, delay: 3.seconds)
            .then()
            .scale(begin: Offset(1.0, 1.0), end: Offset(1.02, 1.02), duration: 3.seconds)
            .then()
            .scale(begin: Offset(1.02, 1.02), end: Offset(1.0, 1.0), duration: 3.seconds),
            ),
            SizedBox(height: 10),
            Container(
              height: MediaQuery.of(context).size.height * 0.40,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Quantum energy field background
                  Container(
                    width: MediaQuery.of(context).size.width * 0.9,
                    height: MediaQuery.of(context).size.width * 0.9,
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        colors: [
                          Colors.deepPurple.withOpacity(0.2),
                          Colors.purple.withOpacity(0.1),
                          Colors.indigo.withOpacity(0.05),
                          Colors.transparent,
                        ],
                        stops: [0.0, 0.4, 0.7, 1.0],
                      ),
                    ),
                  )
                      .animate(onPlay: (controller) => controller.repeat(reverse: true))
                      .scale(
                        begin: const Offset(0.6, 0.6),
                        end: const Offset(1.4, 1.4),
                        duration: 6.seconds,
                        curve: Curves.easeInOut,
                      )
                      .then()
                      .animate(onPlay: (controller) => controller.repeat())
                      .rotate(
                        begin: 0,
                        end: 1,
                        duration: 20.seconds,
                      ),

                  // Neural network connections
                  ...List.generate(12, (index) {
                    final angle = (index * 30) * (3.14159 / 180);
                    final radius = MediaQuery.of(context).size.width * 0.25;
                    final x = radius * cos(angle);
                    final y = radius * sin(angle);
                    
                    return Positioned(
                      left: (MediaQuery.of(context).size.width * 0.5) + x - 1,
                      top: (MediaQuery.of(context).size.width * 0.25) + y - 1,
                      child: Container(
                        width: 2,
                        height: 60,
                        // decoration: BoxDecoration(
                        //   gradient: LinearGradient(
                        //     colors: [
                        //       Colors.deepPurple.withOpacity(0.8),
                        //       Colors.transparent,
                        //     ],
                        //   ),
                        // ),
                      )
                          .animate(delay: Duration(milliseconds: index * 100))
                          .fadeIn(duration: 1.seconds)
                          .then()
                          .animate(onPlay: (controller) => controller.repeat())
                          .shimmer(
                            duration: 3.seconds,
                            delay: Duration(milliseconds: index * 200),
                            color: Colors.cyan.withOpacity(0.5),
                          ),
                    );
                  }),

                  // Central AI core
                  Container(
                    width: MediaQuery.of(context).size.width * 0.5,
                    height: MediaQuery.of(context).size.width * 0.5,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withOpacity(0.1),
                          Colors.deepPurple.withOpacity(0.05),
                          Colors.white.withOpacity(0.02),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(MediaQuery.of(context).size.width * 0.25),
                      border: Border.all(
                        color: Colors.deepPurple.withOpacity(0.3),
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.deepPurple.withOpacity(0.4),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // AI brain icon with neural effect
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            gradient: RadialGradient(
                              colors: [
                                Colors.cyan.withOpacity(0.3),
                                Colors.transparent,
                              ],
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.psychology,
                            color: Colors.white,
                            size: 60,
                          ),
                        )
                            .animate(onPlay: (controller) => controller.repeat(reverse: true))
                            .tint(
                              begin: 0.0,
                              end: 1.0,
                              duration: 3.seconds,
                              color: Colors.cyan,
                            )
                            .then()
                            .animate(onPlay: (controller) => controller.repeat())
                            .scale(
                              begin: const Offset(1.0, 1.0),
                              end: const Offset(1.2, 1.2),
                              duration: 2.seconds,
                            ),

                        // Holographic scanning rings
                        ...List.generate(4, (index) {
                          return Container(
                            width: (MediaQuery.of(context).size.width * 0.5) + (index * 30),
                            height: (MediaQuery.of(context).size.width * 0.5) + (index * 30),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.cyan.withOpacity(0.6 - (index * 0.15)),
                                width: 2,
                              ),
                            ),
                          )
                              .animate(onPlay: (controller) => controller.repeat())
                              .scale(
                                begin: const Offset(0.3, 0.3),
                                end: const Offset(1.8, 1.8),
                                duration: Duration(seconds: 4 + index),
                                curve: Curves.easeInOut,
                              )
                              .fadeOut(delay: Duration(milliseconds: 2000 + (index * 800)))
                              .then()
                              .animate(onPlay: (controller) => controller.repeat())
                              .rotate(
                                begin: 0,
                                end: 1,
                                duration: Duration(seconds: 15 + (index * 5)),
                              );
                        }),
                      ],
                    ),
                  ),

                  // Orbiting AI sensors with advanced animations
                  ...List.generate(8, (index) {
                    final angle = (index * 45) * (3.14159 / 180);
                    final radius = MediaQuery.of(context).size.width * 0.32;
                    final x = radius * cos(angle);
                    final y = radius * sin(angle);
                    
                    return Positioned(
                      left: (MediaQuery.of(context).size.width * 0.44) + x - 25,
                      top: (MediaQuery.of(context).size.width * 0.43) + y - 25,
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.deepPurple,
                              Colors.cyan,
                              Colors.purple,
                            ][index % 3] == Colors.deepPurple 
                              ? [Colors.deepPurple, Colors.purple.shade300]
                              : [Colors.cyan, Colors.blue.shade300],
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: [
                                Colors.deepPurple,
                                Colors.cyan,
                                Colors.purple,
                              ][index % 3].withOpacity(0.6),
                              blurRadius: 15,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Icon(
                          [
                            Icons.remove_red_eye,
                            Icons.speed,
                            Icons.psychology_alt,
                            Icons.security,
                            Icons.analytics_outlined,
                            Icons.notifications_active,
                            Icons.face_6,
                            Icons.shield_moon,
                          ][index],
                          color: Colors.white,
                          size: 25,
                        ),
                      )
                          .animate(delay: Duration(milliseconds: index * 200))
                          .fadeIn(duration: 1.seconds)
                          .scale(duration: 800.ms, curve: Curves.elasticOut)
                          .then()
                          .animate(onPlay: (controller) => controller.repeat())
                          .rotate(
                            begin: 0,
                            end: 1,
                            duration: Duration(seconds: 12 + (index * 2)),
                          )
                          .then()
                          .animate(onPlay: (controller) => controller.repeat(reverse: true))
                          .moveY(
                            begin: 0,
                            end: -15,
                            duration: Duration(seconds: 3 + (index % 4)),
                            curve: Curves.easeInOut,
                          )
                          .then()
                          .animate(onPlay: (controller) => controller.repeat())
                          .shimmer(
                            duration: 4.seconds,
                            delay: Duration(seconds: index % 3),
                            color: Colors.white.withOpacity(0.8),
                          ),
                    );
                  }),

                  // Data stream particles
                  ...List.generate(20, (index) {
                    return Positioned(
                      left: Random().nextDouble() * MediaQuery.of(context).size.width * 0.8,
                      top: Random().nextDouble() * MediaQuery.of(context).size.width * 0.8,
                      child: Container(
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.cyan.withOpacity(0.7),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.cyan.withOpacity(0.5),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                      )
                          .animate(delay: Duration(milliseconds: index * 100))
                          .fadeIn(duration: 500.ms)
                          .then()
                          .animate(onPlay: (controller) => controller.repeat())
                          .moveY(
                            begin: 0,
                            end: -MediaQuery.of(context).size.height * 0.1,
                            duration: Duration(seconds: 8 + (index % 5)),
                          )
                          .fadeOut(delay: Duration(seconds: 6)),
                    );
                  }),
                ],
              ),
            ),
            Text("Advanced Driver\nFatigue Detection",
              style: GoogleFonts.spaceGrotesk(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ).animate()
              .fadeIn(duration: 800.ms, delay: 1200.ms)
              .slideY(begin: 0.3, duration: 600.ms, curve: Curves.easeOutBack),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text("Protect lives with AI-powered real-time monitoring\nthat detects drowsiness and prevents accidents",
                textAlign: TextAlign.center,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 16,
                  color: Colors.deepPurple.shade700,
                ),
              ).animate()
                .fadeIn(duration: 800.ms, delay: 1400.ms)
                .slideY(begin: 0.3, duration: 600.ms, curve: Curves.easeOutBack),
            ),
        
          // Feature Cards Section
            _buildFeatureCards(),

            //Emergency Contact Section
            Container(
              width: double.infinity,
              height: 170,
              margin: EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.red.shade600,
                    Colors.red.shade700,
                    Colors.red.shade800,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withOpacity(0.4),
                    blurRadius: 20,
                    spreadRadius: 5,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10.0),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.white.withOpacity(0.1),
                          ),
                          child: Icon(Icons.emergency,
                            size: 30,
                            color: Colors.white,
                          ),
                        ).animate()
                          .fadeIn(duration: 800.ms, delay: 1600.ms)
                          .scale(duration: 600.ms, curve: Curves.elasticOut)
                          .animate(onPlay: (controller) => controller.repeat())
                          .scale(
                            begin: Offset(1.0, 1.0),
                            end: Offset(1.05, 1.05),
                            duration: 2.seconds,
                            curve: Curves.easeInOut,
                          ),
                        SizedBox(width: 20),
                        Text(
                          "Emergency Contacts",
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ).animate()
                          .fadeIn(duration: 800.ms, delay: 1800.ms)
                          .slideY(begin: 0.3, duration: 600.ms, curve: Curves.easeOutBack),
                      ],
                    ),
                    SizedBox(height: 10),
                    Container(
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withOpacity(0.3),
                            blurRadius: 10,
                            spreadRadius: 2,
                            offset: Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.phone,
                            size: 30,
                            color: Colors.white,
                          ),
                          SizedBox(width: 10),
                          Text(
                            "Call Emergency",
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Spacer(),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              "Call Now 119",
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 14,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ).animate(onPlay: (controller) => controller.repeat())
                          .shimmer(duration: 2.seconds, delay: 1.seconds),
                        ],
                      ),
                    ).animate()
                      .fadeIn(duration: 800.ms, delay: 2000.ms)
                      .slideY(begin: 0.3, duration: 600.ms, curve: Curves.easeOutBack),
                  ],
                ),
              ),
                  ).animate()
                  .fadeIn(duration: 800.ms, delay: 2000.ms)
                  .slideY(begin: 0.3, duration: 600.ms, curve: Curves.easeOutBack),

                              // Weather Display Section
            Container(
              margin: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.blue.shade400,
                    Colors.blue.shade500,
                    Colors.blue.shade600,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.4),
                    blurRadius: 15,
                    spreadRadius: 3,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.wb_sunny,
                            color: Colors.yellow.shade200,
                            size: 30,
                          ),
                        ).animate(onPlay: (controller) => controller.repeat())
                          .rotate(duration: 4.seconds)
                          .then()
                          .scale(begin: Offset(1.0, 1.0), end: Offset(1.1, 1.1), duration: 1.seconds)
                          .then()
                          .scale(begin: Offset(1.1, 1.1), end: Offset(1.0, 1.0), duration: 1.seconds),
                        const SizedBox(width: 15),
                        Text(
                          'Weather Conditions',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ).animate()
                          .fadeIn(duration: 800.ms, delay: 200.ms)
                          .slideX(begin: 0.3, duration: 600.ms),
                      ],
                    ),
                    const SizedBox(height: 15),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${_openweatherService?.name ?? 'Loading...'}',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 16,
                                color: Colors.white70,
                              ),
                            ).animate()
                              .fadeIn(duration: 800.ms, delay: 400.ms)
                              .slideY(begin: 0.3, duration: 600.ms),
                            Text(
                              '${_openweatherService?.temp?.toStringAsFixed(1) ?? '0.0'}°C',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ).animate()
                              .fadeIn(duration: 800.ms, delay: 500.ms)
                              .slideY(begin: 0.3, duration: 600.ms)
                              .then()
                              .animate(onPlay: (controller) => controller.repeat())
                              .shimmer(duration: 3.seconds, delay: 2.seconds),
                            Text(
                              '${_openweatherService?.description ?? 'Loading...'}',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 14,
                                color: Colors.white70,
                              ),
                            ).animate()
                              .fadeIn(duration: 800.ms, delay: 600.ms)
                              .slideY(begin: 0.3, duration: 600.ms),
                          ],
                        ),
                        Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.visibility, color: Colors.white, size: 16),
                                  const SizedBox(width: 5),
                                  Text(
                                    '${_openweatherService?.humidity?.toString() ?? '0'}%',
                                    style: GoogleFonts.spaceGrotesk(
                                      fontSize: 12,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ).animate()
                              .fadeIn(duration: 800.ms, delay: 700.ms)
                              .slideX(begin: 0.3, duration: 600.ms),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.air, color: Colors.white, size: 16),
                                  const SizedBox(width: 5),
                                  Text(
                                    '${_openweatherService?.windSpeed?.toStringAsFixed(1) ?? '0.0'} km/h',
                                    style: GoogleFonts.spaceGrotesk(
                                      fontSize: 12,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ).animate()
                              .fadeIn(duration: 800.ms, delay: 800.ms)
                              .slideX(begin: 0.3, duration: 600.ms),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ).animate()
              .fadeIn(duration: 1000.ms, delay: 800.ms)
              .slideY(begin: 0.4, duration: 800.ms, curve: Curves.easeOutBack),
        
            const SizedBox(height: 20),
            Text('Powered by Safe Vision AI',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ).animate()
              .slideY(begin: 0.3, duration: 600.ms, curve: Curves.easeOutBack),
            Text(
              '© 2025 Safe Vision AI. All rights reserved.',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 12,
                color: Colors.grey[500],
              ),
            ).animate()
              .slideY(begin: 0.3, duration: 600.ms, curve: Curves.easeOutBack),
                
              ],
            ),
          ),
          floatingActionButton: Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: Colors.deepPurple.withOpacity(0.3),
                  blurRadius: 30,
                  spreadRadius: 10,
                  offset: Offset(0, 15),
                ),
                BoxShadow(
                  color: Colors.white.withOpacity(0.1),
                  blurRadius: 20,
                  spreadRadius: 1,
                  offset: Offset(-5, -5),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(25),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withOpacity(0.25),
                        Colors.white.withOpacity(0.1),
                        Colors.deepPurple.withOpacity(0.1),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 1.5,
                    ),
                  ),
                  child: FloatingActionButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => FaceDetectionScreen()),
                      );
                    },
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    splashColor: Colors.white.withOpacity(0.3),
                    highlightElevation: 0,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 45,
                          height: 45,
                          decoration: BoxDecoration(
                            gradient: RadialGradient(
                              colors: [
                                Colors.white.withOpacity(0.3),
                                Colors.white.withOpacity(0.1),
                                Colors.transparent,
                              ],
                              stops: [0.0, 0.7, 1.0],
                            ),
                            borderRadius: BorderRadius.circular(22.5),
                          ),
                        ),
                        Container(
                          width: 35,
                          height: 35,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(17.5),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.camera_alt,
                          size: 28,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              color: Colors.deepPurple.withOpacity(0.5),
                              blurRadius: 10,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.4),
                              borderRadius: BorderRadius.circular(6),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.white.withOpacity(0.3),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ).animate(onPlay: (controller) => controller.repeat())
            .scale(
              begin: Offset(1.0, 1.0),
              end: Offset(1.05, 1.05),
              duration: 3.seconds,
              curve: Curves.easeInOut,
            )
            .then()
            .scale(
              begin: Offset(1.05, 1.05),
              end: Offset(1.0, 1.0),
              duration: 3.seconds,
              curve: Curves.easeInOut,
            )
            .animate()
            .shimmer(
              duration: 4.seconds,
              delay: 2.seconds,
              color: Colors.white.withOpacity(0.3),
            )
    );
  }

  Widget _buildFeatureCards(){
    final feature = [
      {
        'icon': Icons.directions_bus,
        'title': 'Eye Tracking',
        'description': 'Real-time eye tracking to monitor driver alertness.',
      },
      {
        'icon': Icons.face,
        'title': 'Face Detection',
        'description': 'AI-powered face detection for driver monitoring.',
      },
      {
        'icon': Icons.warning,
        'title': 'Fatigue Detection',
        'description': 'Detects driver fatigue to prevent accidents.',
      },

    ];

    return Container(
      height: 220,
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: feature.length,
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        itemBuilder: (context, index) {
          final currentFeature = feature[index];
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 5.0),
            child: Container(
              width: 220,
              margin: const EdgeInsets.symmetric(horizontal: 8.0),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white,
                    Colors.deepPurple.shade50,
                    Colors.purple.shade50,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.deepPurple.withOpacity(0.2),
                  width: 2.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.deepPurple.withOpacity(0.3),
                    blurRadius: 15,
                    spreadRadius: 3,
                    offset: Offset(0, 8),
                  ),
                  BoxShadow(
                    color: Colors.white.withOpacity(0.8),
                    blurRadius: 5,
                    spreadRadius: 1,
                    offset: Offset(-2, -2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Stack(
                  children: [
                    // Background pattern
                    Positioned(
                      top: -20,
                      right: -20,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.deepPurple.withOpacity(0.1),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.deepPurple, Colors.purple],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(15),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.deepPurple.withOpacity(0.4),
                                  blurRadius: 10,
                                  offset: Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Icon(
                              currentFeature['icon'] as IconData,
                              size: 35,
                              color: Colors.white,
                            ),
                          ).animate(delay: Duration(milliseconds: 300 * index))
                            .scale(duration: 600.ms, curve: Curves.elasticOut)
                            .then()
                            .shimmer(duration: 2.seconds, color: Colors.white54)
                            .animate(onPlay: (controller) => controller.repeat())
                            .shimmer(duration: 2.seconds, color: Colors.white54, delay: Duration(seconds: 10)),
                          const SizedBox(height: 15),
                          Text(
                            currentFeature['title'] as String,
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.deepPurple.shade800,
                            ),
                          ).animate(delay: Duration(milliseconds: 400 * index))
                            .fadeIn(duration: 800.ms)
                            .slideY(begin: 0.3, duration: 600.ms),
                          const SizedBox(height: 8),
                          Text(
                            currentFeature['description'] as String,
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 13,
                              color: Colors.grey[600],
                              height: 1.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ).animate(delay: Duration(milliseconds: 500 * index))
                            .fadeIn(duration: 1000.ms)
                            .slideY(begin: 0.4, duration: 700.ms),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ).animate(delay: Duration(milliseconds: 200 * index))
              .fadeIn(duration: 1000.ms)
              .slideX(begin: 0.5, duration: 800.ms, curve: Curves.easeOutBack)
              .animate(onPlay: (controller) => controller.repeat())
              .scale(
              begin: Offset(1.0, 1.0),
              end: Offset(1.03, 1.03),
              duration: 2.seconds,
              curve: Curves.easeInOut,
              )
              .then()
              .scale(
              begin: Offset(1.03, 1.03),
              end: Offset(1.0, 1.0),
              duration: 2.seconds,
              curve: Curves.easeInOut,
              ),
          );
        },
      ),
    );
  }

  void _showProfileBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.white,
              Colors.deepPurple.shade50,
              Colors.purple.shade50,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.deepPurple.withOpacity(0.3),
              blurRadius: 20,
              spreadRadius: 5,
              offset: Offset(0, -10),
            ),
          ],
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              width: 50,
              height: 5,
              margin: EdgeInsets.only(top: 15, bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            
            // Profile Header
            Container(
              padding: EdgeInsets.all(20),
              child: Column(
                children: [
                  // Profile Avatar
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.cyan, Colors.blue, Colors.purple],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.deepPurple.withOpacity(0.4),
                          blurRadius: 15,
                          offset: Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.person,
                      size: 50,
                      color: Colors.white,
                    ),
                  ).animate()
                    .scale(duration: 600.ms, curve: Curves.elasticOut)
                    .fadeIn(duration: 800.ms),
                
                  SizedBox(height: 15),
                
                  Text(
                    'Dimuthu Pramuditha',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple.shade800,
                    ),
                  ).animate()
                    .fadeIn(duration: 800.ms, delay: 200.ms)
                    .slideY(begin: 0.3, duration: 600.ms),
                
                  Text(
                    'Professional Driver',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ).animate()
                    .fadeIn(duration: 800.ms, delay: 400.ms)
                    .slideY(begin: 0.3, duration: 600.ms),
                ],
              ),
            ),
            
            // Profile Details & Settings
            Expanded(
              child: ListView(
                padding: EdgeInsets.symmetric(horizontal: 20),
                children: [
                  _buildProfileDetailCard(
                    icon: Icons.directions_bus,
                    title: 'Bus Information',
                    subtitle: 'Bus Number: 1234\nRoute: Colombo - Galle',
                    color: Colors.blue,
                  ),
                
                  _buildProfileDetailCard(
                    icon: Icons.phone,
                    title: 'Contact Information',
                    subtitle: '+94 77 123 4567\ndimuthu@safevision.lk',
                    color: Colors.green,
                  ),
                
                  _buildProfileDetailCard(
                    icon: Icons.security,
                    title: 'License Information',
                    subtitle: 'License No: DL123456789\nExpiry: 2025-12-31',
                    color: Colors.orange,
                  ),
                
                  // Settings Section
                  Container(
                    margin: EdgeInsets.only(top: 20, bottom: 10),
                    child: Text(
                      'Settings',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple.shade800,
                      ),
                    ),
                  ),
                
                  _buildSettingItem(
                    icon: Icons.notifications,
                    title: 'Notifications',
                    subtitle: 'Manage alert settings',
                    onTap: () {

                    },
                  ),
                
                  _buildSettingItem(
                    icon: Icons.volume_up,
                    title: 'Audio Settings',
                    subtitle: 'Alert sounds and volume',
                    onTap: () {
                    },
                  ),
                
                  _buildSettingItem(
                    icon: Icons.security,
                    title: 'Safety Settings',
                    subtitle: 'Detection sensitivity',
                    onTap: () {
                    },
                  ),
                
                  _buildSettingItem(
                    icon: Icons.help,
                    title: 'Help & Support',
                    subtitle: 'Get help and support',
                    onTap: () {
                    },
                  ),
                
                  SizedBox(height: 20),
                
                  // Logout Button
                  Container(
                    width: double.infinity,
                    height: 50,
                    margin: EdgeInsets.symmetric(vertical: 10),
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _showLogoutDialog(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade600,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        elevation: 5,
                      ),
                      child: Text(
                        'Logout',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ).animate()
                    .fadeIn(duration: 800.ms, delay: 1000.ms)
                    .slideY(begin: 0.3, duration: 600.ms),
                
                  SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ).animate()
        .slideY(begin: 1, duration: 600.ms, curve: Curves.easeOutBack)
        .fadeIn(duration: 400.ms),
  );
}

  // Helper method for profile detail cards
  Widget _buildProfileDetailCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 15),
      padding: EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 25),
          ),
          SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple.shade800,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate();
      // .fadeIn(duration: 800.ms);
      // .slideX(begin: 0.3, duration: 600.ms);
  }

  // Helper method for settings items
  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.deepPurple.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.deepPurple, size: 20),
        ),
        title: Text(
          title,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.deepPurple.shade800,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
      ),
    ).animate()
      .fadeIn(duration: 600.ms)
      .slideX(begin: 0.2, duration: 400.ms);
  }

  // Logout confirmation dialog
  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Logout',
          style: GoogleFonts.spaceGrotesk(
            fontWeight: FontWeight.bold,
            color: Colors.deepPurple.shade800,
          ),
        ),
        content: Text(
          'Are you sure you want to logout?',
          style: GoogleFonts.spaceGrotesk(color: Colors.grey[600]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.spaceGrotesk(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Handle logout logic here
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Logged out successfully')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(
              'Logout',
              style: GoogleFonts.spaceGrotesk(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}