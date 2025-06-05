import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:ui' as ui;
import 'dart:io';
import 'dart:math' as math;
import 'package:ML_Gweh/config/drawing_painter.dart';

class MenulisAlfabetFirebasePage extends StatefulWidget {
  final String letter;

  const MenulisAlfabetFirebasePage({
    super.key,
    required this.letter,
  });

  @override
  State<MenulisAlfabetFirebasePage> createState() =>
      _MenulisAlfabetFirebasePageState();
}

class _MenulisAlfabetFirebasePageState
    extends State<MenulisAlfabetFirebasePage> {
  final List<Offset?> _points = [];
  bool _isUploading = false;
  String _uploadStatus = '';

  @override
  void initState() {
    super.initState();
    // Paksa ke landscape
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  void _clearCanvas() {
    setState(() {
      _points.clear();
    });
  }

  Future<void> _saveAndUpload() async {
    if (_points.isEmpty) {
      setState(() {
        _uploadStatus = 'Tidak ada gambar untuk disimpan';
      });
      return;
    }

    setState(() {
      _isUploading = true;
      _uploadStatus = 'Menyimpan gambar...';
    });

    try {
      // Simpan gambar
      final imagePath = await _captureCanvasToImage();
      if (imagePath == null) {
        setState(() {
          _isUploading = false;
          _uploadStatus = 'Gagal menyimpan gambar';
        });
        return;
      }

      // Upload ke Firebase
      setState(() {
        _uploadStatus = 'Mengupload ke Firebase...';
      });

      await _uploadToFirebase(imagePath, widget.letter);

      setState(() {
        _isUploading = false;
        _uploadStatus = 'Berhasil disimpan ke Firebase!';
        _points.clear(); // Clear canvas after successful upload
      });
    } catch (e) {
      setState(() {
        _isUploading = false;
        _uploadStatus = 'Error: $e';
      });
      print('Error in save and upload: $e');
    }
  }

  Future<String?> _captureCanvasToImage() async {
    try {
      // Render ke image
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      // Background putih
      canvas.drawRect(
        const Rect.fromLTWH(0, 0, 300, 300),
        Paint()..color = Colors.white,
      );

      // Gambar semua titik
      final paint = Paint()
        ..color = Colors.black
        ..strokeWidth = 8.0
        ..strokeCap = StrokeCap.round;

      for (int i = 0; i < _points.length - 1; i++) {
        if (_points[i] != null && _points[i + 1] != null) {
          canvas.drawLine(_points[i]!, _points[i + 1]!, paint);
        }
      }

      final picture = recorder.endRecording();
      final img = await picture.toImage(300, 300);
      final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
      final buffer = byteData!.buffer.asUint8List();

      // Simpan ke file
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filePath = '${directory.path}/${widget.letter}_$timestamp.png';

      final file = File(filePath);
      await file.writeAsBytes(buffer);

      return filePath;
    } catch (e) {
      print('Error capturing canvas: $e');
      return null;
    }
  }

  Future<void> _uploadToFirebase(String filePath, String letter) async {
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

      // 2. Generate and upload 4 additional variations
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
      rethrow;
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
  void dispose() {
    // Kembalikan ke orientasi default saat keluar dari halaman
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
          preferredSize: const Size.fromHeight(0),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
          )),
      body: Stack(
        children: [
          // Background
          GestureDetector(
            onTap: () {
              SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
                  overlays: [SystemUiOverlay.bottom]);
            },
            child: Container(
              decoration: const BoxDecoration(
                  image: DecorationImage(
                      image: AssetImage(
                          "assets/menulis/alfabet/bg_belajar_menulis.png"),
                      fit: BoxFit.fill)),
            ),
          ),
          // Kabut gunung
          Center(
            child: Align(
              alignment: Alignment.topCenter,
              child: Image.asset(
                "assets/menulis/alfabet/kabut_gunung_bergerak 1.png",
                fit: BoxFit.contain,
              ),
            ),
          ),
          // Snow
          Center(
            child: Align(
              alignment: Alignment.topCenter,
              child: Image.asset(
                "assets/menulis/alfabet/snow.gif",
                width: MediaQuery.of(context).size.width * 0.87,
              ),
            ),
          ),
          // Back button
          Center(
            child: Align(
              alignment: Alignment.topLeft,
              child: InkWell(
                onTap: () {
                  Navigator.pop(context);
                },
                child: Image.asset(
                  "assets/menulis/alfabet/button_back_home.png",
                  width: MediaQuery.of(context).size.width * 0.1,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          // Canvas board
          Center(
            child: Align(
              alignment: const Alignment(0, -0.4),
              child: Image.asset(
                "assets/menulis/alfabet/papan_canvas.png",
                fit: BoxFit.contain,
              ),
            ),
          ),
          // Letter drawing area
          Center(
            child: Align(
              alignment: Alignment.center,
              child: Stack(
                children: [
                  // Huruf templat
                  Image.asset(
                    "assets/menulis/alfabet/huruf/${widget.letter}.png", // Gunakan huruf dari parameter
                    fit: BoxFit.cover,
                  ),
                  // Drawing area
                  Positioned.fill(
                    child: GestureDetector(
                      onPanUpdate: (details) {
                        setState(() {
                          _points.add(details.localPosition);
                        });
                      },
                      onPanEnd: (details) {
                        _points.add(null);
                      },
                      child: CustomPaint(
                        painter: DrawingPainter(_points),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Penguin
          Center(
            child: Align(
              alignment: const Alignment(-0.65, 0.93),
              child: Image.asset(
                "assets/menulis/alfabet/penguin.png",
                fit: BoxFit.contain,
              ),
            ),
          ),
          // Snowman
          Center(
            child: Align(
              alignment: const Alignment(0.78, 0.93),
              child: Image.asset(
                "assets/menulis/alfabet/snowman.png",
                fit: BoxFit.contain,
              ),
            ),
          ),
          // Clear button
          // Clear button and Upload button
          Center(
            child: Align(
              alignment: const Alignment(0, 0.93),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Clear button
                  ElevatedButton(
                    onPressed: _clearCanvas,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                    ),
                    child: const Text("Clear"),
                  ),
                  const SizedBox(width: 20), // Spacer between buttons
                  // Upload button
                  ElevatedButton(
                    onPressed: _saveAndUpload,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                    ),
                    child: const Text("Upload"),
                  ),
                ],
              ),
            ),
          ),
          // Upload status
          if (_isUploading || _uploadStatus.isNotEmpty)
            Positioned(
              top: 60,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(8),
                color: _uploadStatus.contains('Berhasil')
                    ? Colors.green.withOpacity(0.7)
                    : _uploadStatus.contains('Error') ||
                            _uploadStatus.contains('Gagal')
                        ? Colors.red.withOpacity(0.7)
                        : Colors.blue.withOpacity(0.7),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_isUploading)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      ),
                    if (_isUploading) const SizedBox(width: 10),
                    Text(
                      _uploadStatus,
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
