import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:ui' as ui;
import 'dart:io';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import 'dart:async';
import 'package:ML_Gweh/config/drawing_painter.dart';

class RibuanPage extends StatefulWidget {
  const RibuanPage({super.key});

  @override
  State<RibuanPage> createState() => _RibuanPageState();
}

class _RibuanPageState extends State<RibuanPage> {
  final List<Offset?> _points = [];
  final GlobalKey _canvasKey = GlobalKey();
  String _prediction = "";
  bool _isModelLoaded = false;
  Interpreter? _interpreter;
  final List<String> _numbers = [
    '1000',
    '2000',
    '3000',
    '4000',
    '5000',
    '6000',
    '7000',
    '8000',
    '9000'
  ];
  int _currentIndex = 0;
  String _currentNumber = "1000";
  Timer? _validationTimer;

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
    _currentNumber = _numbers[_currentIndex];
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
    _clearSavedImages();
    _validationTimer?.cancel();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    _interpreter?.close();
    super.dispose();
  }

  Future<void> _loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset(
          'assets/models/model_angka_ribuan.tflite');
      setState(() {
        _isModelLoaded = true;
      });
    } catch (e) {
      print('Error loading model: $e');
    }
  }

  Future<List<List<List<List<double>>>>> _processImageForRecognition(
      String imagePath) async {
    final imageFile = File(imagePath);
    final imageBytes = await imageFile.readAsBytes();
    final image = img.decodeImage(imageBytes)!;

    final resizedImage = img.copyResize(image, width: 28, height: 28);
    final grayscaleImage = img.grayscale(resizedImage);

    var tensor = List.generate(
      1,
      (_) => List.generate(
        28,
        (y) => List.generate(
          28,
          (x) => List.generate(
            1,
            (c) {
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
    if (_points.isEmpty) return _saveEmptyCanvas();

    try {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      const canvasSize = Size(300, 300);

      canvas.drawRect(
        Rect.fromLTWH(0, 0, canvasSize.width, canvasSize.height),
        Paint()..color = Colors.white,
      );

      final paint = Paint()
        ..color = Colors.black
        ..strokeWidth = 12.0
        ..strokeCap = StrokeCap.round;

      final bounds = _calculateBounds(_points);
      final dx = (canvasSize.width - bounds.width) / 2 - bounds.left;
      final dy = (canvasSize.height - bounds.height) / 2 - bounds.top;

      canvas.save();
      canvas.translate(dx, dy);
      for (int i = 0; i < _points.length - 1; i++) {
        if (_points[i] != null && _points[i + 1] != null) {
          canvas.drawLine(_points[i]!, _points[i + 1]!, paint);
        }
      }
      canvas.restore();

      final picture = recorder.endRecording();
      final img = await picture.toImage(
        canvasSize.width.toInt(),
        canvasSize.height.toInt(),
      );
      final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
      final buffer = byteData!.buffer.asUint8List();

      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filePath = '${directory.path}/drawing_$timestamp.png';

      final file = File(filePath);
      await file.writeAsBytes(buffer);

      return filePath;
    } catch (e) {
      print('Error saving image: $e');
      return _saveEmptyCanvas();
    }
  }

  Rect _calculateBounds(List<Offset?> points) {
    double? minX, minY, maxX, maxY;

    for (final point in points) {
      if (point != null) {
        if (minX == null || point.dx < minX) minX = point.dx;
        if (minY == null || point.dy < minY) minY = point.dy;
        if (maxX == null || point.dx > maxX) maxX = point.dx;
        if (maxY == null || point.dy > maxY) maxY = point.dy;
      }
    }

    if (minX == null || minY == null || maxX == null || maxY == null) {
      return Rect.zero;
    }

    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }

  Future<String> _saveEmptyCanvas() async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, canvasWidth, canvasHeight),
      Paint()..color = Colors.white,
    );

    final picture = recorder.endRecording();
    final img =
        await picture.toImage(canvasWidth.toInt(), canvasHeight.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    final buffer = byteData!.buffer.asUint8List();

    final dir = await getApplicationDocumentsDirectory();
    final filePath =
        '${dir.path}/drawing_empty_${DateTime.now().millisecondsSinceEpoch}.png';
    await File(filePath).writeAsBytes(buffer);

    return filePath;
  }

  Future<void> _recognizeDrawing() async {
    if (!_isModelLoaded || _points.isEmpty || _interpreter == null) {
      setState(() {
        _prediction = "Tidak ada gambar atau model belum dimuat";
      });
      return;
    }

    try {
      final imagePath = await _saveImage();
      final processedImageData = await _processImageForRecognition(imagePath);

      var outputTensor = List.generate(1, (_) => List.filled(9, 0.0));
      _interpreter!.run(processedImageData, outputTensor);

      var results = outputTensor[0];
      List<Map<String, dynamic>> predictions = [];

      for (int i = 0; i < results.length; i++) {
        double probability = results[i] * 100;
        if (probability > 0.10) {
          predictions.add({
            "label": ((i + 1) * 1000).toString(),
            "probability": probability
          });
        }
      }

      predictions.sort((a, b) => b["probability"].compareTo(a["probability"]));

      bool isCorrect = false;
      String topPrediction =
          predictions.isNotEmpty ? predictions[0]["label"] : "";
      double confidence =
          predictions.isNotEmpty ? predictions[0]["probability"] : 0.0;

      if (topPrediction == _currentNumber) {
        isCorrect = true;
      }

      setState(() {
        _prediction = isCorrect
            ? "Benar! Itu angka $_currentNumber (${confidence.toStringAsFixed(2)}%)"
            : "Coba lagi, sepertinya itu angka $topPrediction (${confidence.toStringAsFixed(2)}%)";
      });

      print("All predictions:");
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

  void _goToPreviousNumber() {
    setState(() {
      _currentIndex = (_currentIndex - 1 + _numbers.length) % _numbers.length;
      _currentNumber = _numbers[_currentIndex];
      _clearCanvas();
    });
  }

  void _goToNextNumber() {
    setState(() {
      _currentIndex = (_currentIndex + 1) % _numbers.length;
      _currentNumber = _numbers[_currentIndex];
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
          GestureDetector(
            onTap: () {
              SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
                  overlays: [SystemUiOverlay.bottom]);
            },
            child: Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image:
                      AssetImage('assets/menulis/angka/bg_menulis_angka.png'),
                  fit: BoxFit.fill,
                ),
              ),
            ),
          ),
          Center(
            child: Align(
              alignment: const Alignment(0, 0.6),
              child: InkWell(
                child: Image.asset(
                  'assets/menulis/angka/papan_ribuan.png',
                  height: MediaQuery.of(context).size.height * 0.7,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          Center(
            child: Align(
              alignment: const Alignment(0, -0.9),
              child: InkWell(
                child: Image.asset(
                  'assets/menulis/angka/papan_instruksi.png',
                  width: MediaQuery.of(context).size.width * 0.3,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          Center(
            key: _canvasKey,
            child: Align(
              alignment: const Alignment(0, 0.23),
              child: Stack(
                children: [
                  Image.asset(
                    'assets/menulis/angka/folder_angka/$_currentNumber.png',
                    width: MediaQuery.of(context).size.width * 0.32,
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
                                  _goToNextNumber();
                                });
                              }
                            });
                          }
                        });
                      },
                      child: CustomPaint(
                        painter: DrawingPainter(_points, pagetype: 'angka'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_currentIndex > 0)
            Center(
              child: Align(
                alignment: const Alignment(-0.6, 0.3),
                child: InkWell(
                  onTap: _goToPreviousNumber,
                  child: Image.asset(
                    'assets/menulis/angka/panah_kiri.png',
                    height: MediaQuery.of(context).size.height * 0.2,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          if (_currentIndex < _numbers.length - 1)
            Center(
              child: Align(
                alignment: const Alignment(0.6, 0.3),
                child: InkWell(
                  onTap: _goToNextNumber,
                  child: Image.asset(
                    'assets/menulis/angka/panah_kanan.png',
                    height: MediaQuery.of(context).size.height * 0.2,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          Center(
            child: Align(
              alignment: const Alignment(-0.97, -0.85),
              child: InkWell(
                onTap: () {
                  Navigator.pop(context);
                },
                child: Image.asset(
                  'assets/menulis/angka/back.png',
                  height: MediaQuery.of(context).size.height * 0.15,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
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
