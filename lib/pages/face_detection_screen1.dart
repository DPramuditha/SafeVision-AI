import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:http/http.dart' as http;
import 'package:safe_vision/weather_service/openweather_service.dart';
import 'face_overlay_painter.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:safe_vision/llm_alert/llm_alert_service.dart'; // Add this import

class FaceDetectionScreen extends StatefulWidget {
  const FaceDetectionScreen({super.key});

  @override
  State<FaceDetectionScreen> createState() => _FaceDetectionScreenState();
}

class _FaceDetectionScreenState extends State<FaceDetectionScreen> with TickerProviderStateMixin {
  OpenweatherService? _OpenweatherService;

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

      final url = "https://api.openweathermap.org/data/2.5/weather?q=$city&appid=$apiKey&units=metric";
      final response = await http.get(Uri.parse(url));

      if(response.statusCode == 200){
        final decodebody = utf8.decode(response.bodyBytes);
        final jsondecode = jsonDecode(decodebody);
        print("✅Weather data fetched successfully: $jsondecode");
        setState(() {
          _OpenweatherService = OpenweatherService.fromJson(jsondecode);
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

  String? fullname;

  // Add this variable to track if LLM service is initialized
  bool _isLLMServiceInitialized = false;
  
  // Update _getUserInfo method
  Future<void> _getUserInfo() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print("❌No user is currently logged in.");
        return;
      }

      String email = user.email ?? '';
      
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        var userData = snapshot.docs.first.data() as Map<String, dynamic>;
        setState(() {
          fullname = userData['name'] ?? 'Unknown User';
        });
        
        // Initialize LLM service after getting user name
        _initializeLLMService();
        
        print("✅User data found for email: $email");
        print("✅Full Name: $fullname");
      } else {
        print("❌No user data found for email: $email");
        setState(() {
          fullname = 'Unknown User';
        });
        _initializeLLMService(); // Initialize with Unknown User
      }
    } catch (e) {
      print("❌Error fetching user data: $e");
      setState(() {
        fullname = 'Error Loading User';
      });
      _initializeLLMService(); // Initialize with error message
    }
  }

  // Add this method to initialize LLM service
  void _initializeLLMService() {
    if (!_isLLMServiceInitialized) {
      _llmAlertService = LlmAlertService(
        openWeatherApiKey: dotenv.env['WEATHER_API_KEY'] ?? '',
        openAiApiKey: dotenv.env['OPENAI_API_KEY'] ?? '',
        driverName: fullname ?? 'Unknown Driver',
      );
      _isLLMServiceInitialized = true;
      print('✅ LLM Service initialized with driver name: ${fullname ?? 'Unknown Driver'}');
    }
  }

  CameraController? _cameraController;
  FaceDetector? _faceDetector;
  bool _isDetecting = false;
  bool _isCameraInitialized = false;
  bool _isAlertActive = false;
  bool _isMonitoringActive = false;
  
  // Tracking variables
  List<Face> _faces = [];
  String _alertMessage = "";
  int _closedEyesFrameCount = 0;
  int _noFaceFrameCount = 0;
  final int _closedEyesThreshold = 15; // ~1 second at 15fps
  final int _noFaceThreshold = 45; // ~3 seconds at 15fps
  
  // Animation controllers
  late AnimationController _pulseAnimationController;
  late AnimationController _alertAnimationController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _alertAnimation;
  
  // Timer for periodic checks
  Timer? _fatigueCheckTimer;
  
  // Statistics
  int _totalBlinkCount = 0;
  DateTime? _sessionStartTime;
  double _blinkRate = 0.0; // blinks per minute
  
  // Toggle for testing with mock faces
  bool _useMockFaces = true; // Set to true for emulator testing
  
  // Audio player for alerts
  final AudioPlayer _audioPlayer = AudioPlayer();
  DateTime? _eyesClosedStartTime;
  bool _alertPlaying = false;

  // Add LLM service
  late LlmAlertService _llmAlertService;
  
  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _getUserInfo(); // This will now initialize LLM service after getting user data
    _initializeCameraAndDetector();
    fetchWeather();
  }

  void _initializeAnimations() {
    _pulseAnimationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.5,
    ).animate(CurvedAnimation(
      parent: _pulseAnimationController,
      curve: Curves.easeInOut,
    ));
    
    _alertAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    _alertAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _alertAnimationController,
      curve: Curves.easeInOut,
    ));
  }

  Future<void> _initializeCameraAndDetector() async {
    try {
      // Optimized settings for emulator
      final options = FaceDetectorOptions(
        enableContours: true,
        enableClassification: true,
        enableTracking: true,
        performanceMode: FaceDetectorMode.fast,
        minFaceSize: 0.05,
      );
      _faceDetector = FaceDetector(options: options);
      
      // Get available cameras
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        debugPrint('No cameras available');
        _showErrorMessage('No cameras found on this device');
        return;
      }
      
      debugPrint('Available cameras: ${cameras.length}');
      for (var camera in cameras) {
        debugPrint('Camera: ${camera.name}, Direction: ${camera.lensDirection}');
      }
      
      // Prefer front camera
      CameraDescription camera;
      try {
        camera = cameras.firstWhere(
          (camera) => camera.lensDirection == CameraLensDirection.front,
        );
      } catch (e) {
        debugPrint('No front camera found, using first available: $e');
        camera = cameras.first;
      }
      
      debugPrint('Using camera: ${camera.name}, Direction: ${camera.lensDirection}');
      
      // Initialize camera with medium resolution
      _cameraController = CameraController(
        camera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.nv21, // Force NV21 format
      );
      
      // Initialize with increased timeout
      await _cameraController!.initialize().timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Camera initialization timed out after 30 seconds');
        },
      );
      
      debugPrint('Camera initialized: resolution=${_cameraController!.value.previewSize}');
      
      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
        
        // Start monitoring after a short delay
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted && !_isMonitoringActive) {
            _startMonitoring();
          }
        });
      }
    } catch (e) {
      debugPrint('Error initializing camera: $e');
        _showErrorMessage('Camera initialization failed: $e');
    }
  }

  void _showErrorMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'Retry',
            textColor: Colors.white,
            onPressed: () {
              _initializeCameraAndDetector();
            },
          ),
        ),
      );
    }
  }
  void _startMonitoring() {
    if (_isMonitoringActive || !_isCameraInitialized) {
      return;
    }
    
    setState(() {
      _isMonitoringActive = true;
      _sessionStartTime = DateTime.now();
      _totalBlinkCount = 0;
      _blinkRate = 0.0;
    });
    
    try {
      _cameraController?.startImageStream(_processCameraImage);
      debugPrint('Image stream started');
    } catch (e) {
      debugPrint('Error starting image stream: $e');
      _showErrorMessage('Failed to start face detection: $e');
    }
    
    _fatigueCheckTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _updateBlinkRate();
      _checkFatigueIndicators();
    });
  }

  void _stopMonitoring() {
    if (!_isMonitoringActive) {
      return;
    }
    
    try {
      _cameraController?.stopImageStream();
      debugPrint('Image stream stopped');
    } catch (e) {
      debugPrint('Error stopping image stream: $e');
    }
    
    _fatigueCheckTimer?.cancel();
    
    setState(() {
      _isMonitoringActive = false;
      _faces = [];
      _closedEyesFrameCount = 0;
      _noFaceFrameCount = 0;
    });
  }

  void _processCameraImage(CameraImage image) {
    if (_isDetecting || !_isMonitoringActive) {
      return;
    }
    _isDetecting = true;
    
    try {
      final inputImage = _getInputImageFromCameraImage(image);
      if (inputImage == null) {
        debugPrint('Failed to create InputImage');
        _isDetecting = false;
        return;
      }
      
      _processImage(inputImage);
    } catch (e) {
      debugPrint('Error processing camera image: $e');
      _isDetecting = false;
    }
  }

  InputImage?_getInputImageFromCameraImage(CameraImage image) {
    try {
      // Validate plane data
      if (image.planes.isEmpty || image.planes[0].bytes.isEmpty) {
        debugPrint('Invalid CameraImage: empty planes or bytes');
        return null;
      }

      // Convert to NV21
      final bytes = _convertToNV21(image);
      if (bytes == null) {
        debugPrint('Failed to convert to NV21');
        return null;
      }

      // Log plane details
      debugPrint('CameraImage: planes=${image.planes.length}, '
          'bytesPerRow=${image.planes[0].bytesPerRow}, '
          'width=${image.width}, height=${image.height}');

      // Dynamically determine rotation
      final camera = _cameraController!.description;
      InputImageRotation rotation;
      switch (camera.sensorOrientation) {
        case 0:
          rotation = InputImageRotation.rotation0deg;
          break;
        case 90:
          rotation = InputImageRotation.rotation90deg;
        break;
        case 180:
          rotation = InputImageRotation.rotation180deg;
        break;
        case 270:
          rotation = InputImageRotation.rotation270deg;
          break;
        default:
          rotation = InputImageRotation.rotation0deg;
      }

      // Adjust for front-facing camera mirroring
      if (camera.lensDirection == CameraLensDirection.front) {
        rotation = InputImageRotation.values[
            (InputImageRotation.values.indexOf(rotation) + InputImageRotation.values.indexOf(rotation)) % 4];
      }

      final metadata = InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: InputImageFormat.nv21,
        bytesPerRow: image.planes[0].bytesPerRow,
      );

      debugPrint('InputImage created: size=${image.width}x${image.height}, '
          'rotation=$rotation, format=InputImageFormat.nv21, '
          'bytesLength=${bytes.length}');

      return InputImage.fromBytes(bytes: bytes, metadata: metadata);
    } catch (e) {
      debugPrint('Error creating InputImage: $e');
      return null;
    }
  }

  Uint8List?_convertToNV21(CameraImage image) {
    try {
      final yPlane = image.planes[0];
      final uPlane = image.planes[1];
      final vPlane = image.planes[2];

      final yBytes = yPlane.bytes;
      final uBytes = uPlane.bytes;
      final vBytes = vPlane.bytes;

      // NV21: Y plane followed by interleaved VU plane
      final ySize = yBytes.length;
      final uvSize = uBytes.length;

      // Validate sizes
      if (ySize < image.width * image.height || uvSize < (image.width * image.height) ~/ 4) {
        debugPrint('Invalid plane sizes: ySize=$ySize, uvSize=$uvSize');
        return null;
      }

      final nv21 = Uint8List(ySize + uvSize * 2);
      // Copy Y plane
      nv21.setRange(0, ySize, yBytes);

      // Interleave VU plane
      for (var i = 0; i < uvSize; i++) {
        nv21[ySize + i * 2] = vBytes[i]; // V
        nv21[ySize + i * 2 + 1] = uBytes[i]; // U
      }

      return nv21;
    } catch (e) {
      debugPrint('Error converting to NV21: $e');
      return null;
    }
  }

  Future<void> _processImage(InputImage inputImage) async {
    try {
      List<Face> detectedFaces = [];

      if (_useMockFaces) {
        final mockFace = await FaceDetector(
          options: FaceDetectorOptions(
            enableClassification: true,
            enableTracking: true,
          ),
        ).processImage(inputImage);

        if (mockFace.isEmpty) {
          detectedFaces = [_createMockFace()];
          debugPrint('Using mock face for testing');
        } else {
          detectedFaces = mockFace;
          debugPrint('Mock detection found ${mockFace.length} faces');
        }
      } else {
        final faces = await _faceDetector?.processImage(inputImage);
        detectedFaces = faces ?? [];
        debugPrint('Real detection found ${detectedFaces.length} faces');
        if (detectedFaces.isNotEmpty) {
          debugPrint('Face details: boundingBox=${detectedFaces.first.boundingBox}, '
              'leftEyeOpen=${detectedFaces.first.leftEyeOpenProbability}, '
              'rightEyeOpen=${detectedFaces.first.rightEyeOpenProbability}');
        }
      }

      if (mounted && _isMonitoringActive) {
        setState(() {
          _faces = detectedFaces;

          if (_faces.isEmpty) {
            _noFaceFrameCount++;
            debugPrint('No face detected, frame count: $_noFaceFrameCount');
            if (_noFaceFrameCount > _noFaceThreshold) {
              _triggerFatigueAlert("No face detected! Please look at the camera.");
            }
          } else {
            _noFaceFrameCount = 0;
            debugPrint('Processing face data for ${_faces.length} faces');
            _processFaceData(_faces.first);
          }
        });
      }
    } catch (e) {
      debugPrint('Error in ML processing: $e');
    } finally {
      _isDetecting = false;
    }
  }

  Face _createMockFace() {
    return Face(
      boundingBox: Rect.fromCenter(
        center: const Offset(100, 100),
        width: 100,
        height: 150,
      ),
      landmarks: <FaceLandmarkType, FaceLandmark>{},
      contours: <FaceContourType, FaceContour>{},
      headEulerAngleY: 0.0,
      headEulerAngleZ: 0.0,
      leftEyeOpenProbability: 0.95,
      rightEyeOpenProbability: 0.95,
      trackingId: 1,
      smilingProbability: 0.8,
    );
  }

  void _processFaceData(Face face) {
    final leftEyeOpen = face.leftEyeOpenProbability ?? 1.0;
    final rightEyeOpen = face.rightEyeOpenProbability ?? 1.0;
    final averageEyeOpenness = (leftEyeOpen + rightEyeOpen) / 2.0;
    
    debugPrint('Eye openness: Left=$leftEyeOpen, Right=$rightEyeOpen, Avg=$averageEyeOpenness');
    
    // Add this line to check eye status for audio alert
    _onEyeStateChanged(averageEyeOpenness < 0.3);
    
    if (averageEyeOpenness < 0.3) {
      _closedEyesFrameCount++;
      debugPrint('Eyes closed count: $_closedEyesFrameCount');
      
      if (_closedEyesFrameCount > _closedEyesThreshold) {
        _triggerFatigueAlert("Wake up! Your eyes have been closed too long!");
      }
    } else if (averageEyeOpenness > 0.7) {
      if (_closedEyesFrameCount >= 3 && _closedEyesFrameCount <= _closedEyesThreshold) {
        _totalBlinkCount++;
        debugPrint('Blink detected! Total blinks: $_totalBlinkCount');
      }
      _closedEyesFrameCount = 0;
    }
  }

  void _updateBlinkRate() {
    if (_sessionStartTime != null) {
      final sessionDuration = DateTime.now().difference(_sessionStartTime!);
      final minutes = sessionDuration.inMinutes;
      if (minutes > 0) {
        _blinkRate = _totalBlinkCount / minutes;
        debugPrint('Blink rate updated: $_blinkRate blinks/min');
      }
    }
  }

  void _checkFatigueIndicators() {
    // Check for various fatigue indicators
    if (_blinkRate < 12 || _blinkRate > 30) {
      // Abnormal blink rate
      debugPrint('Abnormal blink rate detected: $_blinkRate');
    }
    
    // Check driving duration
    if (_sessionStartTime != null) {
      final drivingMinutes = DateTime.now().difference(_sessionStartTime!).inMinutes;
      if (drivingMinutes > 60) {
        // Driving for over an hour
        debugPrint('Long driving session: ${drivingMinutes} minutes');
      }
    }
    
    // Additional fatigue checks can be added here
    debugPrint('Fatigue indicators check completed');
  }

  void _onEyeStateChanged(bool eyesClosed) {
    if (eyesClosed) {
      if (_eyesClosedStartTime == null) {
        _eyesClosedStartTime = DateTime.now();
        _alertPlaying = false;
      } else {
        final duration = DateTime.now().difference(_eyesClosedStartTime!);
        if (duration.inSeconds >= 2 && !_alertPlaying) {
          _playAlertSound();
          _alertPlaying = true;
        }
      }
    } else {
      _eyesClosedStartTime = null;
      _alertPlaying = false;
    }
  }

  Future<void> _playAlertSound() async {
    try {
      await _audioPlayer.play(AssetSource('alert.mp3'));
      debugPrint('✅Alert sound played');
    } catch (e) {
      debugPrint('❌Error playing alert sound: $e');
    }
  }

  // Replace the existing _triggerFatigueAlert method
  void _triggerFatigueAlert(String defaultMessage) async {
    if (!_isAlertActive) {
      _isAlertActive = true;

      // Calculate driving duration
      final duration = _sessionStartTime != null
          ? DateTime.now().difference(_sessionStartTime!).inMinutes
          : 0;

      // Show loading popup first
      _showLoadingAlert();

      try {
        // Generate LLM alert
        final llmMessage = await _llmAlertService.generateContextualAlert(
          blinkRate: _blinkRate,
          closedEyesFrameCount: _closedEyesFrameCount,
          noFaceFrameCount: _noFaceFrameCount,
          drivingMinutes: duration,
          fallbackMessage: defaultMessage,
        );

        // Close loading popup and show main alert
        Navigator.of(context).pop(); // Close loading dialog
        _showMainAlert(llmMessage);

      } catch (e) {
        // Close loading popup and show fallback alert
        Navigator.of(context).pop(); // Close loading dialog
        _showMainAlert(defaultMessage);
        debugPrint('Error generating LLM alert: $e');
      }

      debugPrint('FATIGUE ALERT: $_alertMessage');
      HapticFeedback.heavyImpact();

      _alertAnimationController.forward().then((_) {
        _alertAnimationController.reverse().then((_) {
          _alertAnimationController.forward();
        });
      });
    }
  }

  // Show loading popup while generating LLM response
  void _showLoadingAlert() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.orange.shade600,
                Colors.deepOrange.shade700,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.orange.withOpacity(0.5),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                strokeWidth: 3,
              ).animate()
                .scale(duration: 600.ms, curve: Curves.elasticOut),
              
              SizedBox(height: 20),
              
              Text(
                'Analyzing Driving Conditions...',
                style: GoogleFonts.spaceGrotesk(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ).animate()
                .fadeIn(duration: 800.ms, delay: 200.ms)
                .slideY(begin: 0.3, duration: 600.ms),
              
              SizedBox(height: 10),
              
              Text(
                'Generating personalized alert...',
                style: GoogleFonts.spaceGrotesk(
                  color: Colors.white70,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ).animate()
                .fadeIn(duration: 800.ms, delay: 400.ms)
                .slideY(begin: 0.3, duration: 600.ms),
            ],
          ),
        ),
      ),
    );
  }

  // Show main alert popup with LLM message
  void _showMainAlert(String message) {
    setState(() {
      _alertMessage = message;
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 20),
          padding: EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFFFF6B6B),
                Color(0xFFE55353),
                Color(0xFFCC4B4B),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: Color(0xFFFF6B6B).withOpacity(0.6),
                blurRadius: 25,
                spreadRadius: 8,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Alert Icon with animation
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.white,
                  size: 48,
                ),
              ).animate()
                .scale(duration: 600.ms, curve: Curves.elasticOut)
                .then()
                .animate(onPlay: (controller) => controller.repeat())
                .shake(duration: 500.ms, delay: 1.seconds),
              
              SizedBox(height: 20),
              
              // Alert Title
              Text(
                '⚠️ DROWSINESS ALERT',
                style: GoogleFonts.spaceGrotesk(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
                textAlign: TextAlign.center,
              ).animate()
                .fadeIn(duration: 800.ms, delay: 200.ms)
                .slideY(begin: 0.3, duration: 600.ms),
              
              SizedBox(height: 16),
              
              // LLM Generated Message
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  message,
                  style: GoogleFonts.spaceGrotesk(
                    color: Colors.white,
                    fontSize: 16,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
              ).animate()
                .fadeIn(duration: 1000.ms, delay: 400.ms)
                .slideY(begin: 0.4, duration: 700.ms, curve: Curves.easeOutBack),
              
              SizedBox(height: 24),
              
              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        setState(() {
                          _isAlertActive = false;
                          _alertMessage = '';
                        });
                        _alertAnimationController.reset();
                      },
                      icon: Icon(Icons.check_circle, color: Color(0xFFFF6B6B)),
                      label: Text(
                        'I\'m Awake',
                        style: GoogleFonts.spaceGrotesk(
                          color: Color(0xFFFF6B6B),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        elevation: 5,
                      ),
                    ),
                  ),
                  
                  SizedBox(width: 12),
                  
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _stopMonitoring();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Take a break and rest well!'),
                            backgroundColor: Colors.green,
                            duration: Duration(seconds: 3),
                          ),
                        );
                      },
                      icon: Icon(Icons.local_hotel, color: Colors.white),
                      label: Text(
                        'Take Break',
                        style: GoogleFonts.spaceGrotesk(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.2),
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                          side: BorderSide(color: Colors.white, width: 1),
                        ),
                        elevation: 5,
                      ),
                    ),
                  ),
                ],
              ).animate()
                .fadeIn(duration: 1200.ms, delay: 600.ms)
                .slideY(begin: 0.5, duration: 800.ms, curve: Curves.easeOutBack),
              
              SizedBox(height: 12),
              
              // Driving Stats
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildAlertStat('Blinks/min', _blinkRate.toStringAsFixed(1)),
                    _buildAlertStat('Driving Time', 
                      _sessionStartTime != null 
                        ? '${DateTime.now().difference(_sessionStartTime!).inMinutes}m'
                        : '0m'
                    ),
                    _buildAlertStat('Eyes Closed', '${_closedEyesFrameCount}f'),
                  ],
                ),
              ).animate()
                .fadeIn(duration: 1000.ms, delay: 800.ms)
                .slideY(begin: 0.3, duration: 600.ms),
            ],
          ),
        ),
      ).animate()
        .scale(begin: Offset(0.8, 0.8), duration: 600.ms, curve: Curves.elasticOut)
        .fadeIn(duration: 400.ms),
    );

    // Auto-close after 10 seconds if no action taken
    Future.delayed(Duration(seconds: 10), () {
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
        setState(() {
          _isAlertActive = false;
          _alertMessage = '';
        });
        _alertAnimationController.reset();
      }
    });
  }

  // Helper widget for alert stats
  Widget _buildAlertStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.spaceGrotesk(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.spaceGrotesk(
            color: Colors.white70,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _pulseAnimationController.dispose();
    _alertAnimationController.dispose();
    _cameraController?.stopImageStream();
    _cameraController?.dispose();
    _faceDetector?.close();
    _fatigueCheckTimer?.cancel();
    _audioPlayer.dispose();
    _llmAlertService.dispose(); // Add this line
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF1A1F25),
                  Color(0xFF101418),
                ],
              ),
            ),
          ),
          
          SafeArea(
            child: Column(
              children: [
                _buildAppHeader(),
                
                const SizedBox(height: 16),
                
                Expanded(
                  child: _isCameraInitialized ? _buildCameraPreview() : _buildLoadingScreen(),
                ),
                
                const SizedBox(height: 20),
                
                _buildStatsAndControls(),
                
                const SizedBox(height: 20),

                // Weather Card
                Row(
                  children: [
                    // Weather Card
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.only(left: 20, right: 10, top: 4, bottom: 4),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFF4ECDC4).withOpacity(0.8),
                              const Color(0xFF2BAF9A).withOpacity(0.9),
                              const Color(0xFF1A8B7A),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF4ECDC4).withOpacity(0.2),
                              blurRadius: 10,
                              spreadRadius: 2,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.wb_sunny_rounded,
                                  color: Colors.yellow.shade200,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${_OpenweatherService?.temp?.toStringAsFixed(1) ?? '0.0'}°C ${_OpenweatherService?.main ?? ''}',
                                      style: GoogleFonts.spaceGrotesk(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    Text(
                                      '${_OpenweatherService?.description ?? 'Loading...'}',
                                      style: GoogleFonts.spaceGrotesk(
                                        fontSize: 10,
                                        color: Colors.white70,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    
                    // Emergency Card
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.only(left: 10, right: 20, top: 4, bottom: 4),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFFFF6B6B).withOpacity(0.9),
                              const Color(0xFFE55353),
                              const Color(0xFFCC4B4B),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFF6B6B).withOpacity(0.2),
                              blurRadius: 10,
                              spreadRadius: 2,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.emergency_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Emergency',
                                      style: GoogleFonts.spaceGrotesk(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    Text(
                                      'Quick access',
                                      style: GoogleFonts.spaceGrotesk(
                                        fontSize: 10,
                                        color: Colors.white70,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 20),
              ],
            ),
          ),
          
          _buildAlertOverlay(),
        ],
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(
            color: Color(0xFF4ECDC4),
          ),
          const SizedBox(height: 32),
          Text(
            'Initializing camera...',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'This may take a few moments',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Icon(
            Icons.visibility,
            color: const Color(0xFF4ECDC4),
            size: 28,
          ),
          const SizedBox(width: 12),
          Text(
            'Driver Fatigue Monitor',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _isMonitoringActive ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _isMonitoringActive ? 'ACTIVE' : 'STOPPED',
              style: TextStyle(
                color: _isMonitoringActive ? Colors.green : Colors.red,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraPreview() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 15,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          fit: StackFit.expand,
          children: [
            CameraPreview(_cameraController!),
            
            if (_isMonitoringActive)
              CustomPaint(
                painter: FaceOverlayPainter(
                  faces: _faces,
                  imageSize: Size(
                    _cameraController!.value.previewSize?.height ?? 480,
                    _cameraController!.value.previewSize?.width ?? 640,
                  ),
                  rotation: _cameraController!.description.sensorOrientation,
                  isLensfront: _cameraController!.description.lensDirection == CameraLensDirection.front,
                  pulseAnimation: _pulseAnimation.value,
                ),
              ),
              
            Positioned(
              top: 16,
              left: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _faces.isNotEmpty ? Icons.face : Icons.face_retouching_off,
                      color: _faces.isNotEmpty ? Colors.green : Colors.red,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _faces.isNotEmpty ? 'Face Detected' : 'No Face',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Add this method to your _FaceDetectionScreenState class
  void _testLLMAlert() async {
    debugPrint('🧪 Testing LLM Alert Service...');
    
    // Show loading popup first
    _showLoadingAlert();

    try {
      // Generate test LLM alert with mock data
      final testMessage = await _llmAlertService.generateContextualAlert(
        blinkRate: 18.5, // Mock blink rate
        closedEyesFrameCount: 25, // Mock closed eyes count
        noFaceFrameCount: 1, // Mock no face count
        drivingMinutes: 45, // Mock driving time
        fallbackMessage: "Test Alert: Please stay alert while driving!",
      );

      // Close loading popup and show main alert
      Navigator.of(context).pop(); // Close loading dialog
      _showMainAlert(testMessage);

      debugPrint('✅ LLM Test Alert Generated: $testMessage');

    } catch (e) {
      // Close loading popup and show fallback alert
      Navigator.of(context).pop(); // Close loading dialog
      _showMainAlert("Test Alert: LLM service is working! Please stay alert while driving.");
      debugPrint('❌ Error testing LLM alert: $e');
    }
  }

  Widget _buildStatsAndControls() {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white12,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatusIndicator(
                icon: Icons.face,
                label: 'Faces',
                value: '${_faces.length}',
                status: _faces.isNotEmpty,
              ),
              _buildStatusIndicator(
                icon: Icons.remove_red_eye,
                label: 'Eyes',
                value: _closedEyesFrameCount > 5 ? 'Closed' : 'Open',
                status: _closedEyesFrameCount <= 5,
              ),
              _buildStatusIndicator(
                icon: Icons.autorenew,
                label: 'Blinks',
                value: '$_totalBlinkCount',
                status: true,
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 20),
        
        // Main Control Button
        GestureDetector(
          onTap: () {
            if (_isMonitoringActive) {
              _stopMonitoring();
            } else {
              _startMonitoring();
            }
          },
          child: Container(
            width: 200,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _isMonitoringActive 
                    ? [const Color(0xFFFF6B6B), const Color(0xFFC23B22)]
                    : [const Color(0xFF4ECDC4), const Color(0xFF2BAF9A)],
              ),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: _isMonitoringActive 
                      ? const Color(0xFFFF6B6B).withOpacity(0.4)
                      : const Color(0xFF4ECDC4).withOpacity(0.4),
                  blurRadius: 10,
                  spreadRadius: 1,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _isMonitoringActive ? Icons.stop_rounded : Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  _isMonitoringActive ? 'Stop Monitoring' : 'Start Monitoring',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Test LLM Alert Button (only this button remains)
        GestureDetector(
          onTap: _testLLMAlert,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.purple.shade600,
                  Colors.purple.shade800,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.purple.withOpacity(0.4),
                  blurRadius: 8,
                  spreadRadius: 1,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.psychology_rounded,
                  color: Colors.white,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  'Test LLM Alert',
                  style: GoogleFonts.spaceGrotesk(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ).animate()
          .fadeIn(duration: 800.ms, delay: 200.ms)
          .slideY(begin: 0.3, duration: 600.ms),
      ],
    );
  }

  Widget _buildAlertOverlay() {
    return AnimatedBuilder(
      animation: _alertAnimationController,
      builder: (context, child) {
        return _isAlertActive ? Container(
          color: Colors.black54,
          child: FadeTransition(
            opacity: _alertAnimation,
            child: Center(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 40),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6B6B),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF6B6B).withOpacity(0.5),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.white,
                      size: 64,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      _alertMessage,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _isAlertActive = false;
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFFFF6B6B),
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                      ),
                      child: const Text(
                        'I\'m Awake',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ) : const SizedBox.shrink();
      },
    );
  }

  Widget _buildStatusIndicator({
    required IconData icon,
    required String label,
    required String value,
    required bool status,
  }) {
    Color statusColor = status ? const Color(0xFF4ECDC4) : const Color(0xFFFF6B6B);
    
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                statusColor.withOpacity(0.3),
                statusColor.withOpacity(0.1),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: statusColor.withOpacity(0.4),
                blurRadius: 12,
                spreadRadius: 2,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(
            icon,
            color: statusColor,
            size: 24,
          ),
        )
        .animate(onPlay: (controller) => controller.repeat())
        .shimmer(
          duration: 2.seconds,
          delay: 1.seconds,
          color: statusColor.withOpacity(0.5),
        )
        .then()
        .animate()
        .scale(
          begin: const Offset(1.0, 1.0),
          end: const Offset(1.1, 1.1),
          duration: 1.seconds,
          curve: Curves.easeInOut,
        )
        .then()
        .scale(
          begin: const Offset(1.1, 1.1),
          end: const Offset(1.0, 1.0),
          duration: 1.seconds,
          curve: Curves.easeInOut,
        ),
        
        const SizedBox(height: 12),
        
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        )
        .animate()
        .fadeIn(duration: 800.ms, delay: 200.ms)
        .slideY(begin: 0.3, duration: 600.ms),
        
        const SizedBox(height: 6),
        
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: statusColor.withOpacity(0.4),
              width: 1,
            ),
          ),
          child: Text(
            value,
            style: TextStyle(
              color: statusColor,
              fontSize: 15,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        )
        .animate()
        .fadeIn(duration: 1000.ms, delay: 400.ms)
        .slideY(begin: 0.4, duration: 700.ms, curve: Curves.easeOutBack)
        .then()
        .animate(onPlay: (controller) => controller.repeat())
        .shimmer(
          duration: 3.seconds,
          delay: 2.seconds,
          color: statusColor.withOpacity(0.3),
        ),
      ],
    )
    .animate()
    .fadeIn(duration: 1200.ms)
    .slideY(begin: 0.5, duration: 800.ms, curve: Curves.easeOutCubic);
  }
}

class EyeDetectionService {
  final AudioPlayer _audioPlayer = AudioPlayer();
  DateTime? _eyesClosedStartTime;
  bool _alertPlayed = false;
  
  void checkEyeStatus(bool eyesOpen) {
    if (!eyesOpen) {
      // Eyes are closed
      if (_eyesClosedStartTime == null) {
        _eyesClosedStartTime = DateTime.now();
        _alertPlayed = false;
      } else {
        // Check if eyes have been closed for 2 seconds
        final duration = DateTime.now().difference(_eyesClosedStartTime!);
        if (duration.inSeconds >= 2 && !_alertPlayed) {
          _playAlertSound();
          _alertPlayed = true;
        }
      }
    } else {
      // Eyes are open
      _eyesClosedStartTime = null;
      _alertPlayed = false;
    }
  }

  Future<void> _playAlertSound() async {
    try {
      await _audioPlayer.play(AssetSource('alert.mp3'));
      print('✅Audio played successfully');
    } catch (e) {
      print('❌Error playing audio: $e');
    }
  }
}

class EyeDetectionScreen extends StatefulWidget {
  @override
  _EyeDetectionScreenState createState() => _EyeDetectionScreenState();
}

class _EyeDetectionScreenState extends State<EyeDetectionScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  DateTime? _eyesClosedStartTime;
  bool _alertPlayed = false;
  bool _eyesOpen = true;

  @override
  void initState() {
    super.initState();
    // Start your eye detection timer
    _startEyeDetection();
  }

  void _startEyeDetection() {
    // Simulate eye detection - replace with your actual detection logic
    Stream.periodic(Duration(milliseconds: 100), (i) => i)
        .listen((_) {
      // Replace this with your actual eye detection result
      bool detectedEyesOpen = _eyesOpen; // Your detection logic here
      _checkEyeStatus(detectedEyesOpen);
    });
  }

  void _checkEyeStatus(bool eyesOpen) {
    if (!eyesOpen) {
      // Eyes are closed
      if (_eyesClosedStartTime == null) {
        _eyesClosedStartTime = DateTime.now();
        _alertPlayed = false;
        print('☑️Eyes closed - starting timer');
      } else {
        // Check if eyes have been closed for 2 seconds
        final duration = DateTime.now().difference(_eyesClosedStartTime!);
        if (duration.inSeconds >= 2 && !_alertPlayed) {
          print('☑️Eyes closed for 2 seconds - playing alert');
          _playAlertSound();
          _alertPlayed = true;
        }
      }
    } else {
      // Eyes are open, reset timer
      if (_eyesClosedStartTime != null) {
        print('Eyes opened - resetting timer');
      }
      _eyesClosedStartTime = null;
      _alertPlayed = false;
    }
  }

  Future<void> _playAlertSound() async {
    try {
      await _audioPlayer.play(AssetSource('alert.mp3'));
      print('✅Alert sound played');
    } catch (e) {
      print('❌Error playing alert sound: $e');
    }
  }

  @override
  dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Eye Detection')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Eyes: ${_eyesOpen ? "Open" : "Closed"}'),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _eyesOpen = !_eyesOpen;
                });
              },
              child: Text('Toggle Eyes (Testing)'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _playAlertSound,
              child: Text('Test Alert Sound'),
            ),
          ],
        ),
      ),
    );
  }
}