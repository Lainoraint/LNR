import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:ui' as ui;
import 'dart:io';

class DrawPage extends StatefulWidget {
  final String letter;
  const DrawPage({super.key, required this.letter});

  @override
  _DrawPageState createState() => _DrawPageState();
}

class _DrawPageState extends State<DrawPage> {
  List<Offset?> _points = [];
  // Define canvas size constants
  final double canvasWidth = 280;
  final double canvasHeight = 280;
  final GlobalKey _canvasKey = GlobalKey();

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
    final filePath =
        '${dir.path}/${widget.letter}_${DateTime.now().millisecondsSinceEpoch}.png';

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
    final filePath =
        '${dir.path}/${widget.letter}_empty_${DateTime.now().millisecondsSinceEpoch}.png';

    final file = File(filePath);
    await file.writeAsBytes(buffer);

    print('Empty image saved to: $filePath');
    return filePath;
  }

  void _clearCanvas() {
    setState(() {
      _points = [];
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
      appBar: AppBar(title: Text('Draw: ${widget.letter}')),
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
                  onPressed: () async {
                    final imagePath = await _saveImage();
                    Navigator.pop(context, imagePath);
                  },
                  icon: const Icon(Icons.save),
                  label: const Text('Save'),
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
