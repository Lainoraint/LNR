import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:ML_Gweh/page/home.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late VideoPlayerController _videoController;
  Color background = const Color.fromARGB(
      255, 255, 249, 210); // Replace with your design color

  @override
  void initState() {
    super.initState();

    _initializeVideo();

    // Set system UI and orientation settings
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: [
      SystemUiOverlay.bottom,
    ]);
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    // Delay for navigation to HomePage
    Future.delayed(const Duration(milliseconds: 4000), () {
      if (mounted && _videoController.value.isInitialized) {
        _navigateToHome();
      }
    });
  }

  void _initializeVideo() {
    _videoController = VideoPlayerController.asset('assets/splashscreen.mp4')
      ..initialize().then((_) {
        if (mounted) {
          setState(() {});
          _videoController.play();
        }
      });
  }

  void _navigateToHome() {
    // Replace this with your HomePage widget
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const Home()),
    );
  }

  @override
  void dispose() {
    _videoController.dispose();
    // Reset preferred orientations (adjust as needed for your app)
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
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
        ),
      ),
      backgroundColor: background,
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              if (_videoController.value.isInitialized)
                FractionallySizedBox(
                  widthFactor: 1.0,
                  heightFactor: 1.0,
                  child: AspectRatio(
                    aspectRatio: _videoController.value.aspectRatio,
                    child: VideoPlayer(_videoController),
                  ),
                )
            ],
          );
        },
      ),
    );
  }
}
