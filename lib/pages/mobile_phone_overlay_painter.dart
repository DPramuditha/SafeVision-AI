import 'package:flutter/material.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';

class MobilePhoneOverlayPainter extends CustomPainter {
  final List<DetectedObject> objects;
  final Size imageSize;
  final int rotation;
  final bool isLensFront;
  final double pulseAnimation;

  MobilePhoneOverlayPainter({
    required this.objects,
    required this.imageSize,
    required this.rotation,
    required this.isLensFront,
    required this.pulseAnimation,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (objects.isEmpty) return;

    final scaleX = size.width / imageSize.width;
    final scaleY = size.height / imageSize.height;

    for (final detectedObject in objects) {
      // Check if the detected object is a mobile phone (based on labels)
      final hasMobilePhoneLabel = detectedObject.labels.any(
        (label) => label.text.toLowerCase().contains('phone') && label.confidence > 0.6,
      );

      if (!hasMobilePhoneLabel) continue;

      final boundingBox = detectedObject.boundingBox;

      // Transform coordinates
      Rect transformedRect = _transformRect(boundingBox, size, scaleX, scaleY);

      // Draw bounding box for mobile phone
      final phonePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0
        ..color = Colors.redAccent.withOpacity(0.8);

      // Apply pulse animation to bounding box
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
        const Radius.circular(10),
      );
      canvas.drawRRect(rRect, phonePaint);

      // Draw warning message
      _drawWarningMessage(canvas, transformedRect);
    }
  }

  void _drawWarningMessage(Canvas canvas, Rect rect) {
    const textStyle = TextStyle(
      color: Colors.red,
      fontSize: 16,
      fontWeight: FontWeight.bold,
      backgroundColor: Colors.black54,
    );

    const warningText = 'WARNING: Mobile phone detected! Focus on driving.';
    final textSpan = TextSpan(
      text: warningText,
      style: textStyle,
    );

    final textPainter = TextPainter(
      text: textSpan,
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );

    textPainter.layout(
      minWidth: 0,
      maxWidth: rect.width,
    );

    // Position the warning message above the bounding box
    final offset = Offset(
      rect.left,
      rect.top - textPainter.height - 10,
    );

    textPainter.paint(canvas, offset);
  }

  Rect _transformRect(Rect rect, Size size, double scaleX, double scaleY) {
    final isFrontCamera = isLensFront;
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
  bool shouldRepaint(MobilePhoneOverlayPainter oldDelegate) {
    return oldDelegate.objects != objects ||
           oldDelegate.pulseAnimation != pulseAnimation;
  }
}