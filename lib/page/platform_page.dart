import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:ML_Gweh/page/splash_screen.dart';

class PlatformPage extends StatefulWidget {
  const PlatformPage({super.key});

  @override
  State<PlatformPage> createState() => _PlatformPageState();
}

class _PlatformPageState extends State<PlatformPage> {
  late VideoPlayerController _videoController;
  Color background = const Color.fromRGBO(255, 255, 255, 1);

  @override
  void initState() {
    super.initState();
    _initializeController();
  }

  void _initializeController() {
    // Initialize video controller
    _videoController = VideoPlayerController.asset('assets/platform.mp4')
      ..initialize().then((_) {
        if (mounted) {
          setState(() {});
          _videoController.play();
        }
      });

    // Navigate to splash screen after 5 seconds
    Future.delayed(const Duration(milliseconds: 5000), () {
      if (mounted) {
        _navigateToSplash();
      }
    });

    // Set system UI overlays
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: [
      SystemUiOverlay.bottom,
    ]);

    // Set system UI overlay style
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    // Set preferred orientations to landscape
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  void _navigateToSplash() {
    if (mounted && _videoController.value.isInitialized) {
      // Replace this navigation with your preferred method
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const SplashScreen()),
      );
    }
  }

  @override
  void dispose() {
    _videoController.dispose();
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
