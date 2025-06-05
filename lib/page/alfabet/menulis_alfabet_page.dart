import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:ui' as ui;
import 'dart:io';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import 'dart:async';
import 'package:ML_Gweh/config/drawing_painter.dart';

class MenulisAlfabetPage extends StatefulWidget {
  const MenulisAlfabetPage({super.key});

  @override
  State<MenulisAlfabetPage> createState() => _MenulisAlfabetPageState();
}

class _MenulisAlfabetPageState extends State<MenulisAlfabetPage> {
  final List<Offset?> _points = [];
  final GlobalKey _canvasKey = GlobalKey();
  String _prediction = "";
  bool _isModelLoaded = false;
  Interpreter? _interpreter;
  List<String>? _labels;
  final List<String> _alphabet = [
    'A',
    'B',
    'C',
    'D',
    'E',
    'F',
    'G',
    'H',
    'I',
    'J',
    'K',
    'L',
    'M',
    'N',
    'O',
    'P',
    'Q',
    'R',
    'S',
    'T',
    'U',
    'V',
    'W',
    'X',
    'Y',
    'Z'
  ];
  int _currentIndex = 0;
  String _currentLetter = "A";
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
    _currentLetter = _alphabet[_currentIndex];
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
        print("Deleted: ${file.path}");
      }
    }
  }

  @override
  void dispose() {
    _clearSavedImages();
    _validationTimer?.cancel();
    _interpreter?.close();
    super.dispose();
  }

  Future<void> _loadModel() async {
    try {
      _interpreter =
          await Interpreter.fromAsset('assets/models/alphabet_model.tflite');

      final labelsData =
          await rootBundle.loadString('assets/models/handwriting_labels.txt');
      _labels = labelsData.split('\n').map((e) => e.trim()).toList();

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
    if (_points.isEmpty) {
      return _saveEmptyCanvas();
    }

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

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

      var outputTensor = List.generate(1, (_) => List.filled(26, 0.0));
      _interpreter!.run(processedImageData, outputTensor);

      var results = outputTensor[0];
      List<Map<String, String>> predictions = [];

      for (int i = 0; i < results.length; i++) {
        double probability = results[i] * 100;
        if (i < _labels!.length && probability > 0.10) {
          predictions.add({
            "label": _labels![i],
            "probability": "${probability.toStringAsFixed(2)}%"
          });
        }
      }

      predictions.sort((a, b) =>
          double.parse(b["probability"]!.replaceAll('%', ''))
              .compareTo(double.parse(a["probability"]!.replaceAll('%', ''))));

      bool isCorrect = false;
      String topPrediction =
          predictions.isNotEmpty ? predictions[0]["label"]! : "";

      if (topPrediction == _currentLetter) {
        isCorrect = true;
      }

      setState(() {
        _prediction = isCorrect
            ? "Benar! Itu huruf $_currentLetter"
            : "Coba lagi, sepertinya itu huruf $topPrediction";
      });

      print(predictions
          .map((e) => "${e['label']}: ${e['probability']}")
          .join("\n"));
    } catch (e) {
      print('Error during recognition: $e');
      setState(() {
        _prediction = "Error: $e";
      });
    }
  }

  void _goToPreviousLetter() {
    setState(() {
      _currentIndex = (_currentIndex - 1 + _alphabet.length) % _alphabet.length;
      _currentLetter = _alphabet[_currentIndex];
      _clearCanvas();
    });
  }

  void _goToNextLetter() {
    setState(() {
      _currentIndex = (_currentIndex + 1) % _alphabet.length;
      _currentLetter = _alphabet[_currentIndex];
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
          )),
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
                      image: AssetImage(
                          "assets/menulis/alfabet/bg_belajar_menulis.png"),
                      fit: BoxFit.fill)),
            ),
          ),
          Center(
            child: Align(
              alignment: Alignment.centerRight,
              child: Image.asset(
                "assets/menulis/alfabet/snow.gif",
                height: MediaQuery.of(context).size.height,
                width: MediaQuery.of(context).size.width,
                fit: BoxFit.fill,
              ),
            ),
          ),
          Center(
            child: Align(
              alignment: Alignment.topCenter,
              child: Image.asset(
                "assets/menulis/alfabet/kabut_gunung_bergerak 1.png",
                fit: BoxFit.contain,
              ),
            ),
          ),
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
          Center(
            child: Align(
              alignment: const Alignment(0, -0.4),
              child: Image.asset(
                "assets/menulis/alfabet/papan_canvas.png",
                fit: BoxFit.contain,
              ),
            ),
          ),
          Center(
            key: _canvasKey,
            child: Align(
              alignment: Alignment.center,
              child: Stack(
                children: [
                  Image.asset(
                    "assets/menulis/alfabet/huruf/$_currentLetter.png",
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
          if (_currentIndex > 0)
            Center(
              child: Align(
                alignment: const Alignment(-0.75, 0),
                child: InkWell(
                  onTap: _goToPreviousLetter,
                  child: Image.asset(
                    "assets/menulis/alfabet/button_prev.png",
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          if (_currentIndex < _alphabet.length - 1)
            Center(
              child: Align(
                alignment: const Alignment(0.8, 0),
                child: InkWell(
                  onTap: () {
                    _validationTimer?.cancel();
                    _goToNextLetter();
                  },
                  child: Image.asset(
                    "assets/menulis/alfabet/button_next.png",
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          Center(
            child: Align(
              alignment: const Alignment(-0.65, 0.93),
              child: Image.asset(
                "assets/menulis/alfabet/penguin.png",
                fit: BoxFit.contain,
              ),
            ),
          ),
          Center(
            child: Align(
              alignment: const Alignment(0.78, 0.93),
              child: Image.asset(
                "assets/menulis/alfabet/snowman.png",
                fit: BoxFit.contain,
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
