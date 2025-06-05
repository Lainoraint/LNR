import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:ui' as ui;
import 'dart:io';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import 'package:flutter/services.dart';

class Prediksi extends StatefulWidget {
  const Prediksi({super.key});

  @override
  _PrediksiState createState() => _PrediksiState();
}

class _PrediksiState extends State<Prediksi> {
  List<Offset?> _points = [];
  // Define canvas size constants
  final double canvasWidth = 280;
  final double canvasHeight = 280;
  final GlobalKey _canvasKey = GlobalKey();
  String _prediction = "";
  bool _isModelLoaded = false;
  Interpreter? _interpreter;
  List<String>? _labels;

  @override
  void initState() {
    super.initState();
    _loadModel();
  }

  @override
  void dispose() {
    _interpreter?.close();
    super.dispose();
  }

  // Load TFLite model
  Future<void> _loadModel() async {
    try {
      // Load interpreter
      _interpreter =
          await Interpreter.fromAsset('assets/models/alphabet_model.tflite');

      // Load labels from assets
      final labelsData =
          await rootBundle.loadString('assets/models/handwriting_labels.txt');
      _labels = labelsData.split('\n').map((e) => e.trim()).toList();

      setState(() {
        _isModelLoaded = true;
      });
      print('Model loaded successfully');
      print('Input shape: ${_interpreter!.getInputTensor(0).shape}');
      print('Output shape: ${_interpreter!.getOutputTensor(0).shape}');
    } catch (e) {
      print('Error loading model: $e');
    }
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
      // Save the drawing as image
      final imagePath = await _saveImage();

      // Process the image for the model
      final processedImageData = await _processImageForRecognition(imagePath);

      // Get input and output tensors shape
      // var inputShape = _interpreter!.getInputTensor(0).shape;
      // var outputShape = _interpreter!.getOutputTensor(0).shape;

      // Prepare input tensor
      var inputTensor = processedImageData;

      // Prepare output tensor
      var outputTensor = List.generate(1, (_) => List.filled(26, 0.0));

      // Run inference
      _interpreter!.run(inputTensor, outputTensor);

      // Get prediction result
      var results = outputTensor[0];

      // Find the index with highest probability
      List<Map<String, String>> predictions = [];

      for (int i = 0; i < results.length; i++) {
        double probability = results[i] * 100;
        if (i < _labels!.length && probability > 1) {
          // Ubah batas minimum
          predictions.add({
            "label": _labels![i],
            "probability": "${probability.toStringAsFixed(2)}%"
          });
        }
      }

      // Urutkan berdasarkan probabilitas tertinggi
      predictions.sort((a, b) =>
          double.parse(b["probability"]!.replaceAll('%', ''))
              .compareTo(double.parse(a["probability"]!.replaceAll('%', ''))));

      setState(() {
        _prediction = predictions
            .map((e) => "${e['label']}: ${e['probability']}")
            .join("\n");
      });
    } catch (e) {
      print('Error during recognition: $e');
      setState(() {
        _prediction = "Error: $e";
      });
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

    print('Empty image saved to: $filePath');
    return filePath;
  }

  void _clearCanvas() {
    setState(() {
      _points = [];
      _prediction = "";
    });
  }

  // Convert global position to local canvas position
  Offset _getLocalPosition(Offset globalPosition) {
    RenderBox renderBox =
        _canvasKey.currentContext!.findRenderObject() as RenderBox;
    return renderBox.globalToLocal(globalPosition);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Handwriting Recognition')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              key: _canvasKey,
              width: canvasWidth,
              height: canvasHeight,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                color: Colors.white,
              ),
              child: Stack(
                children: [
                  // The drawing canvas
                  CustomPaint(
                    size: Size(canvasWidth, canvasHeight),
                    painter: _DrawingPainter(_points),
                  ),
                  // Transparent touch detector over the canvas
                  Positioned.fill(
                    child: GestureDetector(
                      onPanStart: (details) {
                        final localPosition =
                            _getLocalPosition(details.globalPosition);
                        if (_isPositionInCanvas(localPosition)) {
                          setState(() {
                            _points.add(localPosition);
                          });
                        }
                      },
                      onPanUpdate: (details) {
                        final localPosition =
                            _getLocalPosition(details.globalPosition);
                        if (_isPositionInCanvas(localPosition)) {
                          setState(() {
                            _points.add(localPosition);
                          });
                        }
                      },
                      onPanEnd: (_) {
                        setState(() {
                          _points.add(null); // Add null to mark end of a stroke
                        });
                      },
                      behavior: HitTestBehavior.opaque,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Display prediction result
            Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: _prediction.isEmpty
                      ? [const Text("Gambar huruf untuk prediksi")]
                      : _prediction
                          .split("\n")
                          .map((text) => Text(text))
                          .toList(),
                )),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: _clearCanvas,
                  icon: const Icon(Icons.clear),
                  label: const Text('Clear'),
                ),
                const SizedBox(width: 20),
                ElevatedButton.icon(
                  onPressed: _recognizeDrawing,
                  icon: const Icon(Icons.search),
                  label: const Text('Recognize'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  bool _isPositionInCanvas(Offset position) {
    return position.dx >= 0 &&
        position.dx <= canvasWidth &&
        position.dy >= 0 &&
        position.dy <= canvasHeight;
  }
}

class _DrawingPainter extends CustomPainter {
  final List<Offset?> points;

  _DrawingPainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 8.0;

    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        canvas.drawLine(points[i]!, points[i + 1]!, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
