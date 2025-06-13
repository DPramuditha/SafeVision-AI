// import 'dart:async';
// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:camera/camera.dart';
// import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
// import 'package:flutter/foundation.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter_animate/flutter_animate.dart';

// class FaceDetectionScreen extends StatefulWidget {
//   const FaceDetectionScreen({super.key});

//   @override
//   State<FaceDetectionScreen> createState() => _FaceDetectionScreenState();
// }

// class _FaceDetectionScreenState extends State<FaceDetectionScreen> with TickerProviderStateMixin {
//   CameraController? _cameraController;
//   FaceDetector? _faceDetector;
//   bool _isDetecting = false;
//   bool _isCameraInitialized = false;
//   bool _isAlertActive = false;
//   bool _isMonitoringActive = false;
  
//   // Tracking variables
//   List<Face> _faces = [];
//   String _alertMessage = "";
//   int _closedEyesFrameCount = 0;
//   int _noFaceFrameCount = 0;
//   final int _closedEyesThreshold = 15; // ~1 second at 15fps
//   final int _noFaceThreshold = 45; // ~3 seconds at 15fps
  
//   // Animation controllers
//   late AnimationController _pulseAnimationController;
//   late AnimationController _alertAnimationController;
//   late Animation<double> _pulseAnimation;
//   late Animation<double> _alertAnimation;
  
//   // Timer for periodic checks and session timer
//   Timer? _fatigueCheckTimer;
//   Timer? _sessionTimer;
//   int _sessionDurationSeconds = 0;
//   String _formattedSessionTime = "00:00:00";
  
//   // Statistics
//   int _totalBlinkCount = 0;
//   DateTime? _sessionStartTime;
//   double _blinkRate = 0.0; // blinks per minute
  
//   // Toggle for testing with mock faces
//   bool _useMockFaces = true; // Set to true for emulator testing
  
//   @override
//   void initState() {
//     super.initState();
//     _initializeAnimations();
//     _initializeCameraAndDetector();
//   }

//   void _initializeAnimations() {
//     _pulseAnimationController = AnimationController(
//       duration: const Duration(seconds: 2),
//       vsync: this,
//     )..repeat(reverse: true);
    
//     _pulseAnimation = Tween<double>(
//       begin: 1.0,
//       end: 1.5,
//     ).animate(CurvedAnimation(
//       parent: _pulseAnimationController,
//       curve: Curves.easeInOut,
//     ));
    
//     _alertAnimationController = AnimationController(
//       duration: const Duration(milliseconds: 500),
//       vsync: this,
//     );
    
//     _alertAnimation = Tween<double>(
//       begin: 0.0,
//       end: 1.0,
//     ).animate(CurvedAnimation(
//       parent: _alertAnimationController,
//       curve: Curves.easeInOut,
//     ));
//   }

//   Future<void> _initializeCameraAndDetector() async {
//     try {
//       // Optimized settings for emulator
//       final options = FaceDetectorOptions(
//         enableContours: true,
//         enableClassification: true,
//         enableTracking: true,
//         performanceMode: FaceDetectorMode.fast,
//         minFaceSize: 0.05,
//       );
//       _faceDetector = FaceDetector(options: options);
      
//       // Get available cameras
//       final cameras = await availableCameras();
//       if (cameras.isEmpty) {
//         debugPrint('No cameras available');
//         _showErrorMessage('No cameras found on this device');
//         return;
//       }
      
//       debugPrint('Available cameras: ${cameras.length}');
//       for (var camera in cameras) {
//         debugPrint('Camera: ${camera.name}, Direction: ${camera.lensDirection}');
//       }
      
//       // Prefer front camera
//       CameraDescription camera;
//       try {
//         camera = cameras.firstWhere(
//           (camera) => camera.lensDirection == CameraLensDirection.front,
//         );
//       } catch (e) {
//         debugPrint('No front camera found, using first available: $e');
//         camera = cameras.first;
//       }
      
//       debugPrint('Using camera: ${camera.name}, Direction: ${camera.lensDirection}');
      
//       // Initialize camera with medium resolution
//       _cameraController = CameraController(
//         camera,
//         ResolutionPreset.medium,
//         enableAudio: false,
//         imageFormatGroup: ImageFormatGroup.nv21, // Force NV21 format
//       );
      
//       // Initialize with increased timeout
//       await _cameraController!.initialize().timeout(
//         const Duration(seconds: 30),
//         onTimeout: () {
//           throw Exception('Camera initialization timed out after 30 seconds');
//         },
//       );
      
//       debugPrint('Camera initialized: resolution=${_cameraController!.value.previewSize}');
      
//       if (mounted) {
//         setState(() {
//           _isCameraInitialized = true;
//         });
        
//         // Start monitoring after a short delay
//         Future.delayed(const Duration(milliseconds: 500), () {
//           if (mounted && !_isMonitoringActive) {
//             _startMonitoring();
//           }
//         });
//       }
//     } catch (e) {
//       debugPrint('Error initializing camera: $e');
//       _showErrorMessage('Camera initialization failed: ${e.toString()}');
//     }
//   }

//   void _showErrorMessage(String message) {
//     if (mounted) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text(message),
//           backgroundColor: Colors.red,
//           duration: const Duration(seconds: 5),
//           action: SnackBarAction(
//             label: 'Retry',
//             textColor: Colors.white,
//             onPressed: () {
//               _initializeCameraAndDetector();
//             },
//           ),
//         ),
//       );
//     }
//   }

//   void _startMonitoring() {
//     if (_isMonitoringActive || !_isCameraInitialized) return;
    
//     setState(() {
//       _isMonitoringActive = true;
//       _sessionStartTime = DateTime.now();
//       _sessionDurationSeconds = 0;
//       _totalBlinkCount = 0;
//       _blinkRate = 0.0;
//       _formattedSessionTime = "00:00:00";
//     });
    
//     try {
//       _cameraController?.startImageStream(_processCameraImage);
//       debugPrint('Image stream started');
//     } catch (e) {
//       debugPrint('Error starting image stream: $e');
//       _showErrorMessage('Failed to start face detection: $e');
//     }
    
//     _sessionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
//       if (mounted) {
//         setState(() {
//           _sessionDurationSeconds++;
//           _formattedSessionTime = _formatDuration(_sessionDurationSeconds);
//         });
//       }
//     });
    
//     _fatigueCheckTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
//       _updateBlinkRate();
//       _checkFatigueIndicators();
//     });
//   }

//   void _stopMonitoring() {
//     if (!_isMonitoringActive) return;
    
//     try {
//       _cameraController?.stopImageStream();
//       debugPrint('Image stream stopped');
//     } catch (e) {
//       debugPrint('Error stopping image stream: $e');
//     }
    
//     _fatigueCheckTimer?.cancel();
//     _sessionTimer?.cancel();
    
//     setState(() {
//       _isMonitoringActive = false;
//       _faces = [];
//       _closedEyesFrameCount = 0;
//       _noFaceFrameCount = 0;
//     });
//   }

//   String _formatDuration(int totalSeconds) {
//     final hours = (totalSeconds ~/ 3600).toString().padLeft(2, '0');
//     final minutes = ((totalSeconds % 3600) ~/ 60).toString().padLeft(2, '0');
//     final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
//     return "$hours:$minutes:$seconds";
//   }

//   void _processCameraImage(CameraImage image) {
//     if (_isDetecting || !_isMonitoringActive) return;
//     _isDetecting = true;
    
//     try {
//       final inputImage = _getInputImageFromCameraImage(image);
//       if (inputImage == null) {
//         debugPrint('Failed to create InputImage');
//         _isDetecting = false;
//         return;
//       }
      
//       _processImage(inputImage);
//     } catch (e) {
//       debugPrint('Error processing camera image: $e');
//       _isDetecting = false;
//     }
//   }

//   InputImage? _getInputImageFromCameraImage(CameraImage image) {
//     try {
//       // Validate plane data
//       if (image.planes.isEmpty || image.planes[0].bytes.isEmpty) {
//         debugPrint('Invalid CameraImage: empty planes or bytes');
//         return null;
//       }

//       // Combine planes for YUV420 (NV21)
//       final WriteBuffer allBytes = WriteBuffer();
//       for (final Plane plane in image.planes) {
//         allBytes.putUint8List(plane.bytes);
//       }
//       final bytes = allBytes.done().buffer.asUint8List();

//       // Log plane details
//       debugPrint('CameraImage planes: ${image.planes.length}, '
//           'bytesPerRow: ${image.planes[0].bytesPerRow}, '
//           'width: ${image.width}, height: ${image.height}');

//       // Dynamically determine rotation
//       final camera = _cameraController!.description;
//       InputImageRotation rotation;
//       switch (camera.sensorOrientation) {
//         case 0:
//           rotation = InputImageRotation.rotation0deg;
//           break;
//         case 90:
//           rotation = InputImageRotation.rotation90deg;
//           break;
//         case 180:
//           rotation = InputImageRotation.rotation180deg;
//           break;
//         case 270:
//           rotation = InputImageRotation.rotation270deg;
//           break;
//         default:
//           rotation = InputImageRotation.rotation0deg;
//       }

//       // Adjust for front-facing camera mirroring
//       if (camera.lensDirection == CameraLensDirection.front) {
//         rotation = InputImageRotation.values[
//             (InputImageRotation.values.indexOf(rotation) + 2) % 4];
//       }

//       // Force NV21 format
//       const inputImageFormat = InputImageFormat.nv21;

//       final metadata = InputImageMetadata(
//         size: Size(image.width.toDouble(), image.height.toDouble()),
//         rotation: rotation,
//         format: inputImageFormat,
//         bytesPerRow: image.planes.isNotEmpty ? image.planes[0].bytesPerRow : 0,
//       );

//       debugPrint('InputImage created: size=${image.width}x${image.height}, '
//           'rotation=$rotation, format=$inputImageFormat, '
//           'bytesLength=${bytes.length}');

//       return InputImage.fromBytes(bytes: bytes, metadata: metadata);
//     } catch (e) {
//       debugPrint('Error creating InputImage: $e');
//       return null;
//     }
//   }

//   Future<void> _processImage(InputImage inputImage) async {
//     try {
//       List<Face> detectedFaces = [];

//       if (_useMockFaces) {
//         final mockFace = await FaceDetector(
//           options: FaceDetectorOptions(
//             enableClassification: true,
//             enableTracking: true,
//           ),
//         ).processImage(inputImage);

//         if (mockFace.isEmpty) {
//           detectedFaces = [_createMockFace()];
//           debugPrint('Using mock face for testing');
//         } else {
//           detectedFaces = mockFace;
//           debugPrint('Mock detection found ${mockFace.length} faces');
//         }
//       } else {
//         final faces = await _faceDetector?.processImage(inputImage);
//         detectedFaces = faces ?? [];
//         debugPrint('Real detection found ${detectedFaces.length} faces');
//         if (detectedFaces.isNotEmpty) {
//           debugPrint('Face details: boundingBox=${detectedFaces.first.boundingBox}, '
//               'leftEyeOpen=${detectedFaces.first.leftEyeOpenProbability}, '
//               'rightEyeOpen=${detectedFaces.first.rightEyeOpenProbability}');
//         }
//       }

//       if (mounted && _isMonitoringActive) {
//         setState(() {
//           _faces = detectedFaces;

//           if (_faces.isEmpty) {
//             _noFaceFrameCount++;
//             debugPrint('No face detected, frame count: $_noFaceFrameCount');
//             if (_noFaceFrameCount > _noFaceThreshold) {
//               _triggerFatigueAlert("No face detected! Please look at the camera.");
//             }
//           } else {
//             _noFaceFrameCount = 0;
//             debugPrint('Processing face data for ${_faces.length} faces');
//             _processFaceData(_faces.first);
//           }
//         });
//       }
//     } catch (e) {
//       debugPrint('Error in ML processing: $e');
//     } finally {
//       _isDetecting = false;
//     }
//   }

//   // Test with a static image (for debugging)
//   Future<void> _testWithStaticImage() async {
//     try {
//       // Replace with the path to a test image in your assets
//       const imagePath = 'assets/test_face.jpg';
//       final byteData = await DefaultAssetBundle.of(context).load(imagePath);
//       final bytes = byteData.buffer.asUint8List();

//       final inputImage = InputImage.fromBytes(
//         bytes: bytes,
//         metadata: InputImageMetadata(
//           size: const Size(640, 480), // Adjust based on your test image
//           rotation: InputImageRotation.rotation0deg,
//           format: InputImageFormat.nv21,
//           bytesPerRow: 640, // Adjust based on image width
//         ),
//       );

//       final faces = await _faceDetector?.processImage(inputImage);
//       debugPrint('Static image detection found ${faces?.length ?? 0} faces');
//       if (faces != null && faces.isNotEmpty) {
//         debugPrint('Static image face details: boundingBox=${faces.first.boundingBox}');
//       }

//       if (mounted) {
//         setState(() {
//           _faces = faces ?? [];
//         });
//       }
//     } catch (e) {
//       debugPrint('Error processing static image: $e');
//       _showErrorMessage('Static image detection failed: $e');
//     }
//   }

//   Face _createMockFace() {
//     return Face(
//       boundingBox: Rect.fromCenter(
//         center: const Offset(100, 100),
//         width: 100,
//         height: 150,
//       ),
//       landmarks: <FaceLandmarkType, FaceLandmark>{},
//       contours: <FaceContourType, FaceContour>{},
//       headEulerAngleY: 0.0,
//       headEulerAngleZ: 0.0,
//       leftEyeOpenProbability: 0.95,
//       rightEyeOpenProbability: 0.95,
//       trackingId: 1,
//       smilingProbability: 0.8,
//     );
//   }

//   void _processFaceData(Face face) {
//     final leftEyeOpen = face.leftEyeOpenProbability ?? 1.0;
//     final rightEyeOpen = face.rightEyeOpenProbability ?? 1.0;
//     final averageEyeOpenness = (leftEyeOpen + rightEyeOpen) / 2.0;
    
//     debugPrint('Eye openness: Left=$leftEyeOpen, Right=$rightEyeOpen, Avg=$averageEyeOpenness');
    
//     if (averageEyeOpenness < 0.3) {
//       _closedEyesFrameCount++;
//       debugPrint('Eyes closed count: $_closedEyesFrameCount');
      
//       if (_closedEyesFrameCount > _closedEyesThreshold) {
//         _triggerFatigueAlert("Wake up! Your eyes have been closed too long!");
//       }
//     } else if (averageEyeOpenness > 0.7) {
//       if (_closedEyesFrameCount >= 3 && _closedEyesFrameCount <= _closedEyesThreshold) {
//         _totalBlinkCount++;
//         debugPrint('Blink detected! Total blinks: $_totalBlinkCount');
//       }
//       _closedEyesFrameCount = 0;
//     }
//   }

//   void _triggerFatigueAlert(String message) {
//     if (!_isAlertActive) {
//       _isAlertActive = true;
//       _alertMessage = message;
      
//       debugPrint('FATIGUE ALERT: $message');
      
//       HapticFeedback.heavyImpact();
      
//       _alertAnimationController.forward().then((_) {
//         _alertAnimationController.reverse().then((_) {
//           _alertAnimationController.forward();
//         });
//       });
      
//       Future.delayed(const Duration(seconds: 5), () {
//         if (mounted) {
//           setState(() {
//             _isAlertActive = false;
//             _alertMessage = "";
//           });
//           _alertAnimationController.reset();
//         }
//       });
//     }
//   }

//   void _updateBlinkRate() {
//     if (_sessionStartTime != null) {
//       final sessionDuration = DateTime.now().difference(_sessionStartTime!).inMinutes;
//       if (sessionDuration > 0) {
//         setState(() {
//           _blinkRate = _totalBlinkCount / sessionDuration;
//         });
//         debugPrint('Blink rate updated: $_blinkRate blinks/min');
//       }
//     }
//   }

//   void _checkFatigueIndicators() {
//     if (_blinkRate > 0 && _blinkRate < 5) {
//       _triggerFatigueAlert("Low blink rate detected. You may be getting tired.");
//     }
//   }

//   @override
//   void dispose() {
//     _pulseAnimationController.dispose();
//     _alertAnimationController.dispose();
//     _cameraController?.stopImageStream();
//     _cameraController?.dispose();
//     _faceDetector?.close();
//     _fatigueCheckTimer?.cancel();
//     _sessionTimer?.cancel();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.black,
//       body: Stack(
//         fit: StackFit.expand,
//         children: [
//           Container(
//             decoration: const BoxDecoration(
//               gradient: LinearGradient(
//                 begin: Alignment.topCenter,
//                 end: Alignment.bottomCenter,
//                 colors: [
//                   Color(0xFF1A1F25),
//                   Color(0xFF101418),
//                 ],
//               ),
//             ),
//           ),
          
//           SafeArea(
//             child: Column(
//               children: [
//                 _buildAppHeader(),
                
//                 const SizedBox(height: 16),
                
//                 Expanded(
//                   child: _isCameraInitialized ? _buildCameraPreview() : _buildLoadingScreen(),
//                 ),
                
//                 const SizedBox(height: 20),
                
//                 _buildSessionTimer(),
                
//                 const SizedBox(height: 20),
                
//                 _buildStatsAndControls(),
                
//                 const SizedBox(height: 20),
//               ],
//             ),
//           ),
          
//           _buildAlertOverlay(),
//         ],
//       ),
//     );
//   }

//   Widget _buildLoadingScreen() {
//     return Center(
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           const CircularProgressIndicator(
//             color: Color(0xFF4ECDC4),
//           ),
//           const SizedBox(height: 32),
//           Text(
//             'Initializing camera...',
//             style: TextStyle(
//               color: Colors.white,
//               fontSize: 18,
//               fontWeight: FontWeight.w500,
//             ),
//           ),
//           const SizedBox(height: 16),
//           Text(
//             'This may take a few moments',
//             style: TextStyle(
//               color: Colors.white70,
//               fontSize: 14,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildAppHeader() {
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
//       child: Row(
//         children: [
//           Icon(
//             Icons.visibility,
//             color: const Color(0xFF4ECDC4),
//             size: 28,
//           ),
//           const SizedBox(width: 12),
//           Text(
//             'Driver Fatigue Monitor',
//             style: TextStyle(
//               color: Colors.white,
//               fontSize: 20,
//               fontWeight: FontWeight.bold,
//               letterSpacing: 0.5,
//             ),
//           ),
//           const Spacer(),
//           Container(
//             padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//             decoration: BoxDecoration(
//               color: _isMonitoringActive ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
//               borderRadius: BorderRadius.circular(8),
//             ),
//             child: Text(
//               _isMonitoringActive ? 'ACTIVE' : 'STOPPED',
//               style: TextStyle(
//                 color: _isMonitoringActive ? Colors.green : Colors.red,
//                 fontSize: 12,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildCameraPreview() {
//     return Container(
//       margin: const EdgeInsets.symmetric(horizontal: 20),
//       decoration: BoxDecoration(
//         borderRadius: BorderRadius.circular(24),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.5),
//             blurRadius: 15,
//             spreadRadius: 2,
//           ),
//         ],
//       ),
//       child: ClipRRect(
//         borderRadius: BorderRadius.circular(24),
//         child: Stack(
//           fit: StackFit.expand,
//           children: [
//             CameraPreview(_cameraController!),
            
//             if (_isMonitoringActive)
//               CustomPaint(
//                 painter: FaceOverlayPainter(
//                   faces: _faces,
//                   imageSize: Size(
//                     _cameraController!.value.previewSize?.height ?? 480,
//                     _cameraController!.value.previewSize?.width ?? 640,
//                   ),
//                   rotation: _cameraController!.description.sensorOrientation,
//                   isLensfront: _cameraController!.description.lensDirection == CameraLensDirection.front,
//                   pulseAnimation: _pulseAnimation.value,
//                 ),
//               ),
              
//             Positioned(
//               top: 16,
//               left: 16,
//               child: Container(
//                 padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//                 decoration: BoxDecoration(
//                   color: Colors.black.withOpacity(0.7),
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//                 child: Row(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     Icon(
//                       _faces.isNotEmpty ? Icons.face : Icons.face_retouching_off,
//                       color: _faces.isNotEmpty ? Colors.green : Colors.red,
//                       size: 16,
//                     ),
//                     const SizedBox(width: 8),
//                     Text(
//                       _faces.isNotEmpty ? 'Face Detected' : 'No Face',
//                       style: TextStyle(
//                         color: Colors.white,
//                         fontSize: 12,
//                         fontWeight: FontWeight.w500,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildSessionTimer() {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
//       margin: const EdgeInsets.symmetric(horizontal: 20),
//       decoration: BoxDecoration(
//         color: Colors.black.withOpacity(0.5),
//         borderRadius: BorderRadius.circular(16),
//         border: Border.all(
//           color: _isMonitoringActive ? const Color(0xFF4ECDC4).withOpacity(0.5) : Colors.grey.withOpacity(0.3),
//           width: 1,
//         ),
//       ),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(
//             Icons.timer_outlined,
//             color: _isMonitoringActive ? const Color(0xFF4ECDC4) : Colors.grey,
//             size: 24,
//           ),
//           const SizedBox(width: 12),
//           Text(
//             _formattedSessionTime,
//             style: TextStyle(
//               color: Colors.white,
//               fontSize: 28,
//               fontWeight: FontWeight.bold,
//               letterSpacing: 2,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildStatsAndControls() {
//     return Column(
//       children: [
//         Container(
//           margin: const EdgeInsets.symmetric(horizontal: 20),
//           padding: const EdgeInsets.all(16),
//           decoration: BoxDecoration(
//             color: Colors.black.withOpacity(0.3),
//             borderRadius: BorderRadius.circular(16),
//             border: Border.all(
//               color: Colors.white12,
//               width: 1,
//             ),
//           ),
//           child: Row(
//             mainAxisAlignment: MainAxisAlignment.spaceAround,
//             children: [
//               _buildStatusIndicator(
//                 icon: Icons.face,
//                 label: 'Faces',
//                 value: '${_faces.length}',
//                 status: _faces.isNotEmpty,
//               ),
//               _buildStatusIndicator(
//                 icon: Icons.remove_red_eye,
//                 label: 'Eyes',
//                 value: _closedEyesFrameCount > 5 ? 'Closed' : 'Open',
//                 status: _closedEyesFrameCount <= 5,
//               ),
//               _buildStatusIndicator(
//                 icon: Icons.autorenew,
//                 label: 'Blinks',
//                 value: '$_totalBlinkCount',
//                 status: true,
//               ),
//             ],
//           ),
//         ),
        
//         const SizedBox(height: 20),
        
//         GestureDetector(
//           onTap: () {
//             if (_isMonitoringActive) {
//               _stopMonitoring();
//             } else {
//               _startMonitoring();
//             }
//           },
//           child: Container(
//             width: 200,
//             padding: const EdgeInsets.symmetric(vertical: 16),
//             decoration: BoxDecoration(
//               gradient: LinearGradient(
//                 colors: _isMonitoringActive 
//                     ? [const Color(0xFFFF6B6B), const Color(0xFFC23B22)]
//                     : [const Color(0xFF4ECDC4), const Color(0xFF2BAF9A)],
//               ),
//               borderRadius: BorderRadius.circular(30),
//               boxShadow: [
//                 BoxShadow(
//                   color: _isMonitoringActive 
//                       ? const Color(0xFFFF6B6B).withOpacity(0.4)
//                       : const Color(0xFF4ECDC4).withOpacity(0.4),
//                   blurRadius: 10,
//                   spreadRadius: 1,
//                   offset: const Offset(0, 4),
//                 ),
//               ],
//             ),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 Icon(
//                   _isMonitoringActive ? Icons.stop_rounded : Icons.play_arrow_rounded,
//                   color: Colors.white,
//                   size: 24,
//                 ),
//                 const SizedBox(width: 8),
//                 Text(
//                   _isMonitoringActive ? 'Stop Monitoring' : 'Start Monitoring',
//                   style: const TextStyle(
//                     color: Colors.white,
//                     fontSize: 16,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
        
//         const SizedBox(height: 10),
        
//         ElevatedButton(
//           onPressed: () {
//             debugPrint('Camera initialized: $_isCameraInitialized');
//             debugPrint('Monitoring active: $_isMonitoringActive');
//             debugPrint('Camera controller null? ${_cameraController == null}');
//             if (_cameraController != null) {
//               debugPrint('Preview size: ${_cameraController!.value.previewSize}');
//               debugPrint('Camera direction: ${_cameraController!.description.lensDirection}');
//             }
//             _faceDetector?.close();
//             final options = FaceDetectorOptions(
//               enableContours: true,
//               enableClassification: true,
//               enableTracking: true,
//               performanceMode: FaceDetectorMode.fast,
//               minFaceSize: 0.05,
//             );
//             _faceDetector = FaceDetector(options: options);
            
//             ScaffoldMessenger.of(context).showSnackBar(
//               const SnackBar(content: Text('Face detector reset')),
//             );
//           },
//           style: ElevatedButton.styleFrom(
//             backgroundColor: Colors.blue[800],
//             padding: const EdgeInsets.all(12),
//           ),
//           child: const Text('Reset Detector'),
//         ),
        
//         const SizedBox(height: 10),
        
//         ElevatedButton(
//           onPressed: _testWithStaticImage,
//           style: ElevatedButton.styleFrom(
//             backgroundColor: Colors.purple[800],
//             padding: const EdgeInsets.all(12),
//           ),
//           child: const Text('Test Static Image'),
//         ),
//       ],
//     );
//   }

//   Widget _buildAlertOverlay() {
//     return AnimatedBuilder(
//       animation: _alertAnimationController,
//       builder: (context, child) {
//         return _isAlertActive ? Container(
//           color: Colors.black54,
//           child: FadeTransition(
//             opacity: _alertAnimation,
//             child: Center(
//               child: Container(
//                 margin: const EdgeInsets.symmetric(horizontal: 40),
//                 padding: const EdgeInsets.all(24),
//                 decoration: BoxDecoration(
//                   color: const Color(0xFFFF6B6B),
//                   borderRadius: BorderRadius.circular(20),
//                   boxShadow: [
//                     BoxShadow(
//                       color: const Color(0xFFFF6B6B).withOpacity(0.5),
//                       blurRadius: 20,
//                       spreadRadius: 5,
//                     ),
//                   ],
//                 ),
//                 child: Column(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     Icon(
//                       Icons.warning_amber_rounded,
//                       color: Colors.white,
//                       size: 64,
//                     ),
//                     const SizedBox(height: 24),
//                     Text(
//                       _alertMessage,
//                       textAlign: TextAlign.center,
//                       style: const TextStyle(
//                         color: Colors.white,
//                         fontSize: 22,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                     const SizedBox(height: 20),
//                     ElevatedButton(
//                       onPressed: () {
//                         setState(() {
//                           _isAlertActive = false;
//                         });
//                       },
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: Colors.white,
//                         foregroundColor: const Color(0xFFFF6B6B),
//                         padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
//                       ),
//                       child: const Text(
//                         'I\'m Awake',
//                         style: TextStyle(
//                           fontSize: 16,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         ) : const SizedBox.shrink();
//       },
//     );
//   }

//   Widget _buildStatusIndicator({
//     required IconData icon,
//     required String label,
//     required String value,
//     required bool status,
//   }) {
//     Color statusColor = status ? const Color(0xFF4ECDC4) : const Color(0xFFFF6B6B);
    
//     return Column(
//       children: [
//         Container(
//           padding: const EdgeInsets.all(8),
//           decoration: BoxDecoration(
//             color: statusColor.withOpacity(0.1),
//             shape: BoxShape.circle,
//           ),
//           child: Icon(
//             icon,
//             color: statusColor,
//             size: 20,
//           ),
//         ),
//         const SizedBox(height: 8),
//         Text(
//           label,
//           style: const TextStyle(
//             color: Colors.white70,
//             fontSize: 12,
//           ),
//         ),
//         const SizedBox(height: 4),
//         Text(
//           value,
//           style: TextStyle(
//             color: statusColor,
//             fontSize: 14,
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//       ],
//     );
//   }
// }

// class FaceOverlayPainter extends CustomPainter {
//   final List<Face> faces;
//   final Size imageSize;
//   final int rotation;
//   final bool isLensfront;
//   final double pulseAnimation;

//   FaceOverlayPainter({
//     required this.faces,
//     required this.imageSize,
//     required this.rotation,
//     required this.isLensfront,
//     required this.pulseAnimation,
//   });

//   @override
//   void paint(Canvas canvas, Size size) {
//     if (faces.isEmpty) return;
    
//     final scaleX = size.width / imageSize.width;
//     final scaleY = size.height / imageSize.height;
    
//     for (final face in faces) {
//       final faceRect = face.boundingBox;
      
//       // Transform coordinates
//       Rect transformedRect = _transformRect(faceRect, size, scaleX, scaleY);
      
//       // Draw face bounding box
//       final facePaint = Paint()
//         ..style = PaintingStyle.stroke
//         ..strokeWidth = 3.0
//         ..color = Colors.greenAccent.withOpacity(0.8);
      
//       // Apply pulse animation
//       final center = Offset(
//         transformedRect.left + transformedRect.width / 2,
//         transformedRect.top + transformedRect.height / 2,
//       );
      
//       final animatedWidth = transformedRect.width * pulseAnimation;
//       final animatedHeight = transformedRect.height * pulseAnimation;
      
//       final animatedRect = Rect.fromCenter(
//         center: center,
//         width: animatedWidth,
//         height: animatedHeight,
//       );
      
//       final rRect = RRect.fromRectAndRadius(
//         animatedRect,
//         const Radius.circular(15),
//       );
//       canvas.drawRRect(rRect, facePaint);
      
//       if (face.leftEyeOpenProbability != null && face.rightEyeOpenProbability != null) {
//         final leftEyeOpen = face.leftEyeOpenProbability! > 0.5;
//         final rightEyeOpen = face.rightEyeOpenProbability! > 0.5;
        
//         final eyeSize = size.width * 0.02;
//         final leftEyePosition = Offset(
//           transformedRect.left + transformedRect.width * 0.35,
//           transformedRect.top + transformedRect.height * 0.4,
//         );
        
//         final rightEyePosition = Offset(
//           transformedRect.left + transformedRect.width * 0.65,
//           transformedRect.top + transformedRect.height * 0.4,
//         );
        
//         _drawEyeIndicator(canvas, leftEyePosition, eyeSize, leftEyeOpen);
//         _drawEyeIndicator(canvas, rightEyePosition, eyeSize, rightEyeOpen);
//       }
//     }
//   }

//   void _drawEyeIndicator(Canvas canvas, Offset position, double size, bool isOpen) {
//     final eyePaint = Paint()
//       ..style = PaintingStyle.fill
//       ..color = isOpen ? Colors.green : Colors.red;
      
//     canvas.drawCircle(position, size, eyePaint);
    
//     final borderPaint = Paint()
//       ..style = PaintingStyle.stroke
//       ..strokeWidth = 1.0
//       ..color = Colors.white;
      
//     canvas.drawCircle(position, size, borderPaint);
//   }

//   Rect _transformRect(Rect rect, Size size, double scaleX, double scaleY) {
//     final isFrontCamera = isLensfront;
//     final adjustedRect = Rect.fromLTRB(
//       isFrontCamera ? size.width - rect.right * scaleX : rect.left * scaleX,
//       rect.top * scaleY,
//       isFrontCamera ? size.width - rect.left * scaleX : rect.right * scaleX,
//       rect.bottom * scaleY,
//     );

//     debugPrint('Transformed rect: $adjustedRect, isFrontCamera: $isFrontCamera');
//     return adjustedRect;
//   }

//   @override
//   bool shouldRepaint(FaceOverlayPainter oldDelegate) {
//     return oldDelegate.faces != faces ||
//            oldDelegate.pulseAnimation != pulseAnimation;
//   }
// }