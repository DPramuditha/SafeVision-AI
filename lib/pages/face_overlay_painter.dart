import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class FaceOverlayPainter extends CustomPainter {
  final List<Face> faces;
  final Size imageSize;
  final int rotation;
  final bool isLensfront;
  final double pulseAnimation;

  FaceOverlayPainter({
    required this.faces,
    required this.imageSize,
    required this.rotation,
    required this.isLensfront,
    required this.pulseAnimation,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (faces.isEmpty) return;
    
    final scaleX = size.width / imageSize.width;
    final scaleY = size.height / imageSize.height;
    
    for (final face in faces) {
      final faceRect = face.boundingBox;
      
      // Transform coordinates
      Rect transformedRect = _transformRect(faceRect, size, scaleX, scaleY);
      
      // Draw face bounding box
      final facePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0
        ..color = Colors.greenAccent.withOpacity(0.8);
      
      // Apply pulse animation
      final center = Offset(
        transformedRect.left + transformedRect.width / 2,
        transformedRect.top + transformedRect.height / 2,
      );
      
      final animatedWidth = transformedRect.width * pulseAnimation;
      final animatedHeight = transformedRect.height * pulseAnimation;
      
      final animatedRect = Rect.fromCenter(
        center: center,
        width: animatedWidth,
        height: animatedHeight,
      );
      
      final rRect = RRect.fromRectAndRadius(
        animatedRect,
        const Radius.circular(15),
      );
      canvas.drawRRect(rRect, facePaint);
      
      if (face.leftEyeOpenProbability != null && face.rightEyeOpenProbability != null) {
        final leftEyeOpen = face.leftEyeOpenProbability! > 0.5;
        final rightEyeOpen = face.rightEyeOpenProbability! > 0.5;
        
        final eyeSize = size.width * 0.02;
        final leftEyePosition = Offset(
          transformedRect.left + transformedRect.width * 0.35,
          transformedRect.top + transformedRect.height * 0.4,
        );
        
        final rightEyePosition = Offset(
          transformedRect.left + transformedRect.width * 0.65,
          transformedRect.top + transformedRect.height * 0.4,
        );
        
        _drawEyeIndicator(canvas, leftEyePosition, eyeSize, leftEyeOpen);
        _drawEyeIndicator(canvas, rightEyePosition, eyeSize, rightEyeOpen);
      }
    }
  }

  void _drawEyeIndicator(Canvas canvas, Offset position, double size, bool isOpen) {
    final eyePaint = Paint()
      ..style = PaintingStyle.fill
      ..color = isOpen ? Colors.green : Colors.red;
      
    canvas.drawCircle(position, size, eyePaint);
    
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = Colors.white;
      
    canvas.drawCircle(position, size, borderPaint);
  }

  Rect _transformRect(Rect rect, Size size, double scaleX, double scaleY) {
    final isFrontCamera = isLensfront;
    final adjustedRect = Rect.fromLTRB(
      isFrontCamera ? size.width - rect.right * scaleX : rect.left * scaleX,
      rect.top * scaleY,
      isFrontCamera ? size.width - rect.left * scaleX : rect.right * scaleX,
      rect.bottom * scaleY,
    );

    debugPrint('Transformed rect: $adjustedRect, isFrontCamera: $isFrontCamera');
    return adjustedRect;
  }

  @override
  bool shouldRepaint(FaceOverlayPainter oldDelegate) {
    return oldDelegate.faces != faces ||
           oldDelegate.pulseAnimation != pulseAnimation;
  }
}