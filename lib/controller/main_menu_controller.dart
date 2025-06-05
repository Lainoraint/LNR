import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:ML_Gweh/config/audio_controller.dart';

class MainMenuController {
  late AnimationController _controllerawan;
  late AnimationController _controlleropsi1;
  late AnimationController _controlleropsi2;
  late AnimationController _controlleropsi3;

  late Animation<double> animationawan;
  late Animation<double> animationawan2;
  late Animation<double> animation1;
  late Animation<double> animation2;
  late Animation<double> animation3;

  void initialize(TickerProvider vsync) {
    // Initialize wakelock and system UI
    _setupSystemUI();

    _controllerawan =
        AnimationController(duration: const Duration(seconds: 9), vsync: vsync)
          ..repeat(reverse: true);

    _controlleropsi1 = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: vsync,
    );

    _controlleropsi2 = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: vsync,
    );

    _controlleropsi3 = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: vsync,
    );

    animation1 = Tween(begin: 0.0, end: 1.0).animate(_controlleropsi1)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _controlleropsi2.forward();
        }
      });

    animation2 = Tween(begin: 0.0, end: 1.0).animate(_controlleropsi2)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _controlleropsi3.forward();
        }
      });

    animation3 = Tween(begin: 0.0, end: 1.0).animate(_controlleropsi3);
    animationawan = Tween(begin: 2.0, end: -2.0).animate(_controllerawan);
    animationawan2 = Tween(begin: 3.0, end: -3.0).animate(_controllerawan);

    startAnimations();
  }

  void _setupSystemUI() {
    WakelockPlus.enable();

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: [
      SystemUiOverlay.bottom,
    ]);

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
  }

  void startAnimations() {
    _controlleropsi1.reset();
    _controlleropsi2.reset();
    _controlleropsi3.reset();

    Future.delayed(const Duration(milliseconds: 400), () {
      _controlleropsi1.forward();
    });
  }

  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      AudioMusicManager.instance.stopAudio();
    }
  }

  void disposeResource() {
    WakelockPlus.disable();
    _controllerawan.dispose();
    _controlleropsi1.dispose();
    _controlleropsi2.dispose();
    _controlleropsi3.dispose();
  }
}
