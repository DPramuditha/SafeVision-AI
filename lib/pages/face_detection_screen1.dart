import 'dart:async';
import 'dart:convert';
import 'dart:io';
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
  
  @override
  void initState() {
    super.initState();
    _initializeAnimations();
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

  void _triggerFatigueAlert(String message) {
    if (!_isAlertActive) {
      _isAlertActive = true;
      _alertMessage = message;
      
      debugPrint('FATIGUE ALERT: $message');
      
      HapticFeedback.heavyImpact();
      
      _alertAnimationController.forward().then((_) {
        _alertAnimationController.reverse().then((_) {
          _alertAnimationController.forward();
        });
      });
      
      Future.delayed(const Duration(seconds: 5), () {
        if (mounted) {
          setState(() {
            _isAlertActive = false;
            _alertMessage = "";
          });
          _alertAnimationController.reset();
        }
      });
    }
  }

  void _updateBlinkRate() {
    if (_sessionStartTime != null) {
      final sessionDuration = DateTime.now().difference(_sessionStartTime!).inMinutes;
      if (sessionDuration > 0) {
        setState(() {
          _blinkRate = _totalBlinkCount / sessionDuration;
        });
        debugPrint('Blink rate updated: $_blinkRate blinks/min');
      }
    }
  }

  void _checkFatigueIndicators() {
    if (_blinkRate > 0 && _blinkRate < 5) {
      _triggerFatigueAlert("Low blink rate detected. You may be getting tired.");
    }
  }

  @override
  void dispose() {
    _pulseAnimationController.dispose();
    _alertAnimationController.dispose();
    _cameraController?.stopImageStream();
    _cameraController?.dispose();
    _faceDetector?.close();
    _fatigueCheckTimer?.cancel();
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

        
        // ElevatedButton(
        //   onPressed: () {
        //     debugPrint('Camera initialized: $_isCameraInitialized');
        //     debugPrint('Monitoring active: $_isMonitoringActive');
        //     debugPrint('Camera controller null? ${_cameraController == null}');
        //     if (_cameraController != null) {
        //       debugPrint('Preview size: ${_cameraController!.value.previewSize}');
        //       debugPrint('Camera direction: ${_cameraController!.description.lensDirection}');
        //     }
        //     _faceDetector?.close();
        //     final options = FaceDetectorOptions(
        //       enableContours: true,
        //       enableClassification: true,
        //       enableTracking: true,
        //       performanceMode: FaceDetectorMode.fast,
        //       minFaceSize: 0.05,
        //     );
        //     _faceDetector = FaceDetector(options: options);
            
        //     ScaffoldMessenger.of(context).showSnackBar(
        //       const SnackBar(content: Text('Face detector reset')),
        //     );
        //   },
        //   style: ElevatedButton.styleFrom(
        //     backgroundColor: Colors.blue[800],
        //     padding: const EdgeInsets.all(12),
        //   ),
        //   child: const Text('Reset Detector'),
        // ),
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