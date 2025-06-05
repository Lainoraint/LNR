import 'package:ML_Gweh/page/main_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ML_Gweh/config/audio_controller.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _animationControllerZoom;
  late AnimationController _animationControllerAwan;

  late Animation<double> _animation;
  late Animation<double> _animationawan;
  late Animation<double> _animationawan2;

  bool isBackgroundAudioEnabled = true;

  @override
  void initState() {
    super.initState();

    _animationController =
        AnimationController(duration: const Duration(seconds: 350), vsync: this)
          ..repeat();

    _animationControllerZoom = AnimationController(
        duration: const Duration(milliseconds: 1400), vsync: this)
      ..repeat(reverse: true);

    _animationControllerAwan =
        AnimationController(duration: const Duration(seconds: 17), vsync: this)
          ..repeat(reverse: true);

    _animationawan =
        Tween(begin: 3.0, end: -3.0).animate(_animationControllerAwan);
    _animationawan2 =
        Tween(begin: 5.0, end: -8.0).animate(_animationControllerAwan);

    _animation = Tween(begin: 1.1, end: 1.0).animate(CurvedAnimation(
        parent: _animationControllerZoom, curve: Curves.easeInOutCubic));

    WidgetsBinding.instance.addObserver(this);
  }

  Future<void> _playBackgroundAudio() async {
    if (isBackgroundAudioEnabled) {
      await AudioMusicManager.instance.playBackgroundSound();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      if (isBackgroundAudioEnabled) {
        AudioMusicManager.instance.stopBackgroundAudio();
      }
    } else if (state == AppLifecycleState.resumed) {
      if (isBackgroundAudioEnabled) {
        _playBackgroundAudio();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _animationControllerZoom.dispose();
    _animationControllerAwan.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _handlePlayButtonTap() {
    _playButtonSoundAndSetPageType();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const MainMenuPage()),
    );
  }

  void _playButtonSoundAndSetPageType() {
    AudioMusicManager.instance.playButtonTapSound("assets/button_click.wav");
    AudioMusicManager.instance.setPageType(PageType.musik1);
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
      backgroundColor: const Color.fromARGB(
          255, 210, 247, 253), // Replace with your theme color
      body: Stack(
        children: [
          buildBackground(),
          buildAnimasiAwan(),
          buildAnimasiAwanDua(),
          buildBumiBerputar(),
          buildAbelLogo(),
          buildHomeTitle(),
          buildPlayButton(),
        ],
      ),
    );
  }

  Widget buildBackground() {
    return GestureDetector(
      onTap: () {
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: [
          SystemUiOverlay.bottom,
        ]);
      },
      child: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/home/bg_home_screen.png'),
            fit: BoxFit.fill,
          ),
        ),
      ),
    );
  }

  Widget buildAnimasiAwan() {
    return Center(
      child: AnimatedBuilder(
        animation: _animationawan,
        builder: (context, child) {
          return Align(
            alignment: Alignment(_animationawan.value, -0.3),
            child: FractionallySizedBox(
              widthFactor: 0.25,
              heightFactor: 0.25,
              child: child,
            ),
          );
        },
        child: Image.asset(
          'assets/home/awan.png',
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  Widget buildAnimasiAwanDua() {
    return Center(
      child: AnimatedBuilder(
        animation: _animationawan2,
        builder: (context, child) {
          return Align(
            alignment: Alignment(_animationawan2.value, -0.8),
            child: FractionallySizedBox(
              widthFactor: 0.25,
              heightFactor: 0.25,
              child: child,
            ),
          );
        },
        child: Image.asset(
          'assets/home/awan.png',
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  Widget buildBumiBerputar() {
    return Center(
      child: Align(
        alignment: const Alignment(0, 12.7),
        child: FractionallySizedBox(
          widthFactor: 0.44,
          heightFactor: 0.44,
          child: RotationTransition(
            turns: _animationController,
            child: Transform.scale(
              scale: 16,
              child: Image.asset(
                'assets/home/bumi.png',
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildAbelLogo() {
    return Center(
      child: Align(
        alignment: const Alignment(0, -0.8),
        child: FractionallySizedBox(
          widthFactor: 0.20,
          heightFactor: 0.20,
          child: ScaleTransition(
            scale: _animation,
            child: Image.asset(
              'assets/home/abel.png',
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }

  Widget buildHomeTitle() {
    return Center(
      child: Align(
        alignment: const Alignment(0, -0.4),
        child: FractionallySizedBox(
          widthFactor: 0.44,
          heightFactor: 0.44,
          child: ScaleTransition(
            scale: _animation,
            child: Image.asset(
              'assets/home/judul.png',
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }

  Widget buildPlayButton() {
    return Center(
      child: Align(
        alignment: const Alignment(0, 0.5),
        child: InkWell(
          onTap: _handlePlayButtonTap,
          child: FractionallySizedBox(
            widthFactor: 0.1,
            heightFactor: 0.2,
            child: Image.asset(
              'assets/home/button_play.png',
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }
}
