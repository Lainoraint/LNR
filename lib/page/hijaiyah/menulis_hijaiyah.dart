import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:ui' as ui;
import 'dart:io';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import 'dart:async';
import 'package:ML_Gweh/config/drawing_painter.dart';

class MenulisHijaiyah extends StatefulWidget {
  const MenulisHijaiyah({super.key});

  @override
  State<MenulisHijaiyah> createState() => _MenulisHijaiyahState();
}

class _MenulisHijaiyahState extends State<MenulisHijaiyah> {
  final List<Offset?> _points = [];
  final GlobalKey _canvasKey = GlobalKey();
  String _prediction = "";
  bool _isModelLoaded = false;
  Interpreter? _interpreter;
  List<String>? _labels;
  final List<String> _hijaiyah = [
    'alif',
    'ba',
    'ta',
    'tsa',
    'jim',
    'ha',
    'kho',
    'dal',
    'dzal',
    'ra',
    'za',
    'sin',
    'syin',
    'shod',
    'dhah',
    'tho',
    'dzo',
    'ain',
    'ghoin',
    'fa',
    'qof',
    'kaf',
    'lam',
    'mim',
    'nun',
    'wau',
    'haa',
    'lamalif',
    'hamzah',
    'ya'
  ];
  int _currentIndex = 0;
  Timer? _validationTimer;
  String _currentLetter = "alif";

  // Define canvas size constants
  final double canvasWidth = 280;
  final double canvasHeight = 280;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    _loadModel();
    _currentLetter = _hijaiyah[_currentIndex];
  }

  void _clearCanvas() {
    setState(() {
      _points.clear();
      _prediction = "";
    });
    _validationTimer?.cancel();
  }

  Future<void> _clearSavedImages() async {
    final dir = await getApplicationDocumentsDirectory();
    final files = dir.listSync();
    for (var file in files) {
      if (file is File && file.path.endsWith('.png')) {
        file.deleteSync();
      }
    }
  }

  @override
  void dispose() {
    // Cancel timers and clean up resources
    _validationTimer?.cancel();
    _points.clear();
    _clearSavedImages()
        .catchError((error) => print('Error clearing images: $error'));
    _interpreter?.close();
    super.dispose();
  }

  Future<void> _loadModel() async {
    try {
      _interpreter =
          await Interpreter.fromAsset('assets/models/hijaiyah_model.tflite');
      final labelsData =
          await rootBundle.loadString('assets/models/hijaiyah_labels.txt');
      _labels = labelsData.split('\n').map((e) => e.trim()).toList();
      setState(() {
        _isModelLoaded = true;
      });
    } catch (e) {
      print('Error loading model: $e');
    }
  }

  // Process the image to match model input requirements
  Future<List<List<List<List<double>>>>> _processImageForRecognition(
      String imagePath) async {
    // Read the image file
    final imageFile = File(imagePath);
    final imageBytes = await imageFile.readAsBytes();

    // Decode the image
    final image = img.decodeImage(imageBytes)!;

    // Resize to model input size (assuming 28x28 for handwriting recognition)
    final resizedImage = img.copyResize(image, width: 28, height: 28);

    // Convert to grayscale
    final grayscaleImage = img.grayscale(resizedImage);

    // Convert to normalized float tensor [1, 28, 28, 1]
    var tensor = List.generate(
      1,
      (_) => List.generate(
        28,
        (y) => List.generate(
          28,
          (x) => List.generate(
            1,
            (c) {
              // Normalize pixel value to [0, 1]
              var pixel = grayscaleImage.getPixel(x, y);
              return pixel.b.toDouble() / 255.0;
            },
          ),
        ),
      ),
    );

    return tensor;
  }

  Future<String> _saveImage() async {
    // Ensure we have points to draw
    if (_points.isEmpty) {
      // Return empty canvas if no drawing
      return _saveEmptyCanvas();
    }

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // Fill with white background
    canvas.drawRect(Rect.fromLTWH(0, 0, canvasWidth, canvasHeight),
        Paint()..color = Colors.white);

    final paint = Paint()
      ..color = Colors.black
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 8.0;

    for (int i = 0; i < _points.length - 1; i++) {
      if (_points[i] != null && _points[i + 1] != null) {
        canvas.drawLine(_points[i]!, _points[i + 1]!, paint);
      }
    }

    final picture = recorder.endRecording();
    final img =
        await picture.toImage(canvasWidth.toInt(), canvasHeight.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    final buffer = byteData!.buffer.asUint8List();

    final dir = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final filePath = '${dir.path}/drawing_$timestamp.png';

    final file = File(filePath);
    await file.writeAsBytes(buffer);

    print('Image saved to: $filePath');
    return filePath;
  }

  Future<String> _saveEmptyCanvas() async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // Fill with white background
    canvas.drawRect(Rect.fromLTWH(0, 0, canvasWidth, canvasHeight),
        Paint()..color = Colors.white);

    final picture = recorder.endRecording();
    final img =
        await picture.toImage(canvasWidth.toInt(), canvasHeight.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    final buffer = byteData!.buffer.asUint8List();

    final dir = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final filePath = '${dir.path}/drawing_empty_$timestamp.png';

    final file = File(filePath);
    await file.writeAsBytes(buffer);

    return filePath;
  }

  // Recognize the drawn letter
  Future<void> _recognizeDrawing() async {
    if (!_isModelLoaded ||
        _points.isEmpty ||
        _interpreter == null ||
        _labels == null) {
      setState(() {
        _prediction = "Tidak ada gambar atau model belum dimuat";
      });
      return;
    }

    try {
      final imagePath = await _saveImage();
      final processedImageData = await _processImageForRecognition(imagePath);

      // Change output tensor size to 30 to match number of Hijaiyah letters
      var outputTensor = List.generate(1, (_) => List<double>.filled(30, 0.0));

      _interpreter!.run(processedImageData, outputTensor);

      var results = outputTensor[0];
      List<Map<String, dynamic>> predictions = [];

      for (int i = 0; i < results.length; i++) {
        double probability = results[i] * 100;
        if (i < _labels!.length && probability > 0.10) {
          predictions.add({
            "label": _hijaiyah[i], // Use _hijaiyah instead of _labels
            "probability": probability
          });
        }
      }

      // Sort by highest probability
      predictions.sort((a, b) => b["probability"].compareTo(a["probability"]));

      String topPrediction =
          predictions.isNotEmpty ? predictions[0]["label"] : "";
      bool isCorrect = topPrediction == _currentLetter;

      setState(() {
        _prediction = isCorrect
            ? "Benar! Itu huruf $_currentLetter"
            : "Coba lagi, sepertinya itu huruf $topPrediction";
      });

      // Debug output
      print("Predictions:");
      for (var pred in predictions) {
        print("${pred['label']}: ${pred['probability'].toStringAsFixed(2)}%");
      }
    } catch (e) {
      print('Error during recognition: $e');
      setState(() {
        _prediction = "Error: $e";
      });
    }
  }

  void _goToPreviousLetter() {
    setState(() {
      _currentIndex = (_currentIndex - 1 + _hijaiyah.length) % _hijaiyah.length;
      _currentLetter = _hijaiyah[_currentIndex];
      _clearCanvas();
    });
  }

  void _goToNextLetter() {
    setState(() {
      _currentIndex = (_currentIndex + 1) % _hijaiyah.length;
      _currentLetter = _hijaiyah[_currentIndex];
      _clearCanvas();
    });
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
        ),
      ),
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
                  image: AssetImage("assets/menulis/hijaiyah/bg_hijaiyah.png"),
                  fit: BoxFit.fill,
                ),
              ),
            ),
          ),

          // Writing Board
          Center(
            child: Align(
              alignment: const Alignment(0.02, 0),
              child: Image.asset(
                "assets/menulis/hijaiyah/papan_huruf.png",
                width: MediaQuery.of(context).size.width * 0.34,
                height: MediaQuery.of(context).size.height * 0.84,
                fit: BoxFit.contain,
              ),
            ),
          ),

          // Back Button
          Center(
            child: Align(
              alignment: Alignment.topLeft,
              child: InkWell(
                onTap: () => Navigator.pop(context),
                child: Image.asset(
                  "assets/menulis/hijaiyah/back.png",
                  width: MediaQuery.of(context).size.width * 0.09,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),

          // Drawing Area with Letter Template
          Center(
            key: _canvasKey,
            child: Align(
              alignment: const Alignment(0, 0.1),
              child: Stack(
                children: [
                  Image.asset(
                    "assets/menulis/hijaiyah/huruf/$_currentLetter.png",
                    fit: BoxFit.cover,
                  ),
                  Positioned.fill(
                    child: GestureDetector(
                      onPanUpdate: (details) {
                        setState(() {
                          _points.add(details.localPosition);
                        });
                        _validationTimer?.cancel();
                      },
                      onPanEnd: (details) {
                        setState(() {
                          _points.add(null);
                        });
                        _validationTimer?.cancel();
                        _validationTimer =
                            Timer(const Duration(seconds: 5), () {
                          if (_points.isNotEmpty) {
                            _recognizeDrawing().then((_) {
                              if (_prediction.contains("Benar!")) {
                                Future.delayed(const Duration(seconds: 2), () {
                                  _goToNextLetter();
                                });
                              }
                            });
                          }
                        });
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

          // Navigation Buttons
          if (_currentIndex > 0)
            Center(
              child: Align(
                alignment: const Alignment(-0.4, 0),
                child: InkWell(
                  onTap: _goToPreviousLetter,
                  child: Image.asset(
                    "assets/menulis/hijaiyah/prev_button.png",
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),

          if (_currentIndex < _hijaiyah.length - 1)
            Center(
              child: Align(
                alignment: const Alignment(0.4, 0),
                child: InkWell(
                  onTap: () {
                    _validationTimer?.cancel();
                    _goToNextLetter();
                  },
                  child: Image.asset(
                    "assets/menulis/hijaiyah/next_button.png",
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),

          // Clear Button
          Center(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: ElevatedButton(
                onPressed: _clearCanvas,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.withOpacity(0.7),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
                child:
                    const Text("Hapus", style: TextStyle(color: Colors.white)),
              ),
            ),
          ),

          // Prediction Display
          if (_prediction.isNotEmpty)
            Center(
              child: Align(
                alignment: const Alignment(0, 0.7),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white70,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.blue),
                  ),
                  child: Text(
                    _prediction,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _prediction.contains("Benar!")
                          ? Colors.green
                          : Colors.red,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
