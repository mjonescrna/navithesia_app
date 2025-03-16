import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

/// A utility class to generate app icons from the existing logo image
class IconGenerator {
  /// Generate app icons from the logo
  static Future<void> generateIcons(BuildContext context) async {
    try {
      // First, load the logo image
      final ByteData imageData = await rootBundle.load(
        'assets/images/navisthesia_logo_transparent.png',
      );
      final ui.Codec codec = await ui.instantiateImageCodec(
        imageData.buffer.asUint8List(),
      );
      final ui.FrameInfo fi = await codec.getNextFrame();
      final ui.Image logoImage = fi.image;

      // Android icon sizes
      final Map<String, int> androidSizes = {
        'mipmap-mdpi': 48,
        'mipmap-hdpi': 72,
        'mipmap-xhdpi': 96,
        'mipmap-xxhdpi': 144,
        'mipmap-xxxhdpi': 192,
      };

      // Generate Android icons
      for (final entry in androidSizes.entries) {
        final folder = entry.key;
        final size = entry.value;
        await _generateAndroidIcon(logoImage, folder, size);
      }

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('App icons generated successfully!')),
      );
    } catch (e) {
      print('Error generating icons: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error generating icons: $e')));
    }
  }

  /// Generate an Android icon at the specified size
  static Future<void> _generateAndroidIcon(
    ui.Image logoImage,
    String folder,
    int size,
  ) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // Draw a white background circle
    final paint =
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.fill;

    // Draw white background
    canvas.drawCircle(Offset(size / 2, size / 2), size / 2, paint);

    // Draw the logo in the center, scaled to 70% of the icon size
    final logoSize = size * 0.7;
    final src = Rect.fromLTWH(
      0,
      0,
      logoImage.width.toDouble(),
      logoImage.height.toDouble(),
    );
    final dst = Rect.fromLTWH(
      (size - logoSize) / 2,
      (size - logoSize) / 2,
      logoSize,
      logoSize,
    );
    canvas.drawImageRect(logoImage, src, dst, Paint());

    // Convert to image
    final picture = recorder.endRecording();
    final img = await picture.toImage(size, size);
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);

    if (byteData != null) {
      final buffer = byteData.buffer.asUint8List();

      // Get app directory
      final appDir = await getApplicationDocumentsDirectory();
      final iconDir = Directory('${appDir.path}/icons/$folder');
      await iconDir.create(recursive: true);

      // Save file
      final File iconFile = File('${iconDir.path}/ic_launcher.png');
      await iconFile.writeAsBytes(buffer);

      print('Generated icon at ${iconFile.path}');
    }
  }
}
