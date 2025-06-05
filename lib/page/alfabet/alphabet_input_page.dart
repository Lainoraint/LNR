import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:path_provider/path_provider.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:ui' as ui;
import 'package:ML_Gweh/config/draw_page.dart';
import 'dart:io';

class AlphabetInputApp extends StatelessWidget {
  const AlphabetInputApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Alphabet Data Input',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const AlphabetInputPage(),
    );
  }
}

class AlphabetInputPage extends StatefulWidget {
  const AlphabetInputPage({super.key});

  @override
  State<AlphabetInputPage> createState() => _AlphabetInputPageState();
}

class _AlphabetInputPageState extends State<AlphabetInputPage> {
  Future<void> _navigateToDrawPage(String letter) async {
    final imagePath = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => DrawPage(letter: letter)),
    );
    if (imagePath != null) {
      print('Image drawn for $letter: $imagePath');
      await uploadToFirebase(imagePath, letter);
    }
  }

  Future<void> uploadToFirebase(String filePath, String letter) async {
    try {
      // Load original image
      final imageFile = File(filePath);
      final timestamp = DateTime.now().millisecondsSinceEpoch;

      // 1. Upload original image
      final mainRef = FirebaseStorage.instance
          .ref()
          .child('alphabet_dataset/$letter/$timestamp.png');
      await mainRef.putFile(imageFile);
      print('Main image uploaded: ${await mainRef.getDownloadURL()}');

      // 2. Generate and upload 4 additional variations with clean names
      final additionalImages =
          await _generateImageVariations(filePath, letter, timestamp);

      for (int i = 0; i < additionalImages.length; i++) {
        final additionalFile = File(additionalImages[i]);
        // Use timestamp + index to ensure unique filenames
        final additionalRef = FirebaseStorage.instance
            .ref()
            .child('alphabet_dataset/$letter/${timestamp + i + 1}.png');
        await additionalRef.putFile(additionalFile);
        print(
            'Additional image ${i + 1} uploaded: ${await additionalRef.getDownloadURL()}');
      }

      print('All ${additionalImages.length + 1} images uploaded successfully');
    } catch (e) {
      print('Error uploading to Firebase: $e');
    }
  }

  Future<List<String>> _generateImageVariations(
      String originalPath, String letter, int timestamp) async {
    final additionalImages = <String>[];

    try {
      // Load original image
      final bytes = await File(originalPath).readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frameInfo = await codec.getNextFrame();
      final sourceImage = frameInfo.image;

      // Generate 4 additional images with different modifications
      final modifications = [
        {'type': 'rotate', 'min': -5.0, 'max': 5.0}, // Slight rotation
        {'type': 'scale', 'min': 0.9, 'max': 1.1}, // Slight scaling
        {'type': 'shift', 'min': -10.0, 'max': 10.0}, // Position shift
        {
          'type': 'combination',
          'rotate': true,
          'scale': true,
          'shift': false
        } // Combined modifications
      ];

      for (int i = 0; i < modifications.length; i++) {
        final mod = modifications[i];
        final modifiedImage = await _applyModification(sourceImage, mod);
        final modifiedPath = await _saveImageToFile(
            modifiedImage, letter, '${timestamp}_${i + 1}');
        additionalImages.add(modifiedPath);
      }
    } catch (e) {
      print('Error generating additional images: $e');
    }

    return additionalImages;
  }

  Future<String> _saveImageToFile(
      ui.Image image, String letter, String suffix) async {
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final buffer = byteData!.buffer.asUint8List();

    final dir = await getApplicationDocumentsDirectory();
    final filePath = '${dir.path}/${letter}_$suffix.png';

    final file = File(filePath);
    await file.writeAsBytes(buffer);

    return filePath;
  }

  Future<ui.Image> _applyModification(
      ui.Image image, Map<String, dynamic> modification) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final width = image.width.toDouble();
    final height = image.height.toDouble();
    final random = math.Random();

    // Fill with white background
    canvas.drawRect(
        Rect.fromLTWH(0, 0, width, height), Paint()..color = Colors.white);

    // Apply the modification
    canvas.save();
    canvas.translate(width / 2, height / 2); // Move to center

    if (modification['type'] == 'rotate') {
      // Convert to radians for rotation
      final minRad = modification['min'] * math.pi / 180;
      final maxRad = modification['max'] * math.pi / 180;
      final angle = minRad + random.nextDouble() * (maxRad - minRad);
      canvas.rotate(angle);
    } else if (modification['type'] == 'scale') {
      final minScale = modification['min'];
      final maxScale = modification['max'];
      final scale = minScale + random.nextDouble() * (maxScale - minScale);
      canvas.scale(scale);
    } else if (modification['type'] == 'shift') {
      final minShift = modification['min'];
      final maxShift = modification['max'];
      final shiftX = minShift + random.nextDouble() * (maxShift - minShift);
      final shiftY = minShift + random.nextDouble() * (maxShift - minShift);
      canvas.translate(shiftX, shiftY);
    } else if (modification['type'] == 'combination') {
      // Apply multiple modifications for more variety
      if (modification['rotate'] == true) {
        final angle = (-5.0 + random.nextDouble() * 10.0) * math.pi / 180;
        canvas.rotate(angle);
      }
      if (modification['scale'] == true) {
        final scale = 0.9 + random.nextDouble() * 0.2;
        canvas.scale(scale);
      }
      if (modification['shift'] == true) {
        final shiftX = -10.0 + random.nextDouble() * 20.0;
        final shiftY = -10.0 + random.nextDouble() * 20.0;
        canvas.translate(shiftX, shiftY);
      }
    }

    canvas.translate(-width / 2, -height / 2); // Move back from center
    canvas.drawImage(image, Offset.zero, Paint());
    canvas.restore();

    final picture = recorder.endRecording();
    return picture.toImage(image.width, image.height);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Input Alphabet Data')),
      body: GridView.builder(
        padding: const EdgeInsets.all(16.0),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
        ),
        itemCount: 26,
        itemBuilder: (context, index) {
          String letter = String.fromCharCode(65 + index);
          return ElevatedButton(
            onPressed: () => _navigateToDrawPage(letter),
            child: Text(letter, style: const TextStyle(fontSize: 24)),
          );
        },
      ),
    );
  }
}
