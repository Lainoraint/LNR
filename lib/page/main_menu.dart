import 'package:ML_Gweh/page/alfabet/menulis_alfabet_page.dart';
import 'package:ML_Gweh/page/angka/prediksi/menu_angka.dart';
import 'package:ML_Gweh/page/hijaiyah/menulis_hijaiyah.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ML_Gweh/controller/main_menu_controller.dart';
import 'package:ML_Gweh/config/audio_controller.dart';

class MainMenuPage extends StatefulWidget {
  const MainMenuPage({super.key});

  // Route definition for navigation
  static Route<dynamic> route() {
    return MaterialPageRoute(builder: (_) => const MainMenuPage());
  }

  @override
  State<MainMenuPage> createState() => _MainMenuPageState();
}

class _MainMenuPageState extends State<MainMenuPage>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  late MainMenuController _controller;

  @override
  void initState() {
    super.initState();
    _controller = MainMenuController();
    _controller.initialize(this);

    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    _controller.disposeResource();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _controller.didChangeAppLifecycleState(state);
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          GestureDetector(
            onTap: () {
              SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
                  overlays: [
                    SystemUiOverlay.bottom,
                  ]);
            },
            child: Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(
                      'assets/menu/bg.png'), // Replace with your asset path
                  fit: BoxFit.fill,
                ),
              ),
            ),
          ),
          Center(
            child: AnimatedBuilder(
              animation: _controller.animationawan2,
              builder: (context, child) {
                return Align(
                  alignment: Alignment(_controller.animationawan2.value, -0.90),
                  child: FractionallySizedBox(
                    widthFactor: 0.15,
                    heightFactor: 0.13,
                    child: child,
                  ),
                );
              },
              child: Image.asset(
                'assets/menu/awan.png', // Replace with your asset path
                fit: BoxFit.contain,
              ),
            ),
          ),
          Center(
            child: AnimatedBuilder(
              animation: _controller.animationawan,
              builder: (context, child) {
                return Align(
                  alignment: Alignment(_controller.animationawan.value, -0.60),
                  child: FractionallySizedBox(
                    widthFactor: 0.15,
                    heightFactor: 0.13,
                    child: child,
                  ),
                );
              },
              child: Image.asset(
                'assets/menu/awan.png', // Replace with your asset path
                fit: BoxFit.contain,
              ),
            ),
          ),
          Stack(
            children: [
              Positioned(
                top: 0,
                bottom: 0,
                left: 0,
                child: Image.asset(
                  'assets/menu/pohon_kiri.png', // Replace with your asset path
                  fit: BoxFit.fitHeight,
                ),
              ),
            ],
          ),
          Stack(
            children: [
              Positioned(
                top: 0,
                bottom: 0,
                right: 0,
                child: Image.asset(
                  'assets/menu/pohon_kanan.png', // Replace with your asset path
                  fit: BoxFit.fitHeight,
                ),
              ),
            ],
          ),
          Center(
            child: Align(
              alignment: const Alignment(0, -0.9),
              child: FractionallySizedBox(
                widthFactor: 0.18,
                heightFactor: 0.18,
                child: Image.asset(
                  'assets/menu/pilih.png', // Replace with your asset path
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          AnimatedBuilder(
            animation: _controller.animation1,
            builder: (context, child) {
              return Align(
                alignment: const Alignment(-0.54, 0.16),
                child: Transform.scale(
                  scale: _controller.animation1.value,
                  child: const AlfabetButton(),
                ),
              );
            },
          ),
          AnimatedBuilder(
            animation: _controller.animation2,
            builder: (context, child) {
              return Align(
                alignment: const Alignment(0, 0.16),
                child: Transform.scale(
                  scale: _controller.animation2.value,
                  child: const HijaiyahButton(),
                ),
              );
            },
          ),
          AnimatedBuilder(
            animation: _controller.animation3,
            builder: (context, child) {
              return Align(
                alignment: const Alignment(0.54, 0.16),
                child: Transform.scale(
                  scale: _controller.animation3.value,
                  child: const AngkaButton(),
                ),
              );
            },
          ),
          const Align(
            alignment: Alignment.topLeft,
            child: Padding(
              padding: EdgeInsets.only(left: 6.0, top: 1.0),
              child: BackButtonWidget(),
            ),
          ),
        ],
      ),
    );
  }
}

class AlfabetButton extends StatelessWidget {
  const AlfabetButton({super.key});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        // Navigate to MenuHurufAlfabetPage
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                const MenulisAlfabetPage(), // Replace with MenuHurufAlfabetPage()
          ),
        );

        // Play button sound and set page type
        AudioMusicManager.instance.playButtonTapSound('menu/button_click.wav');
        AudioMusicManager.instance.setPageType(PageType.musik1);
      },
      child: FractionallySizedBox(
        widthFactor: 0.2,
        child: AspectRatio(
          aspectRatio: 1 / 1.2,
          child: Image.asset(
            'assets/menu/belajar_huruf_alfabet.png', // Replace with your asset path
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}

class HijaiyahButton extends StatelessWidget {
  const HijaiyahButton({super.key});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        // Navigate to MenuHurufHijaiyahPage
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                const MenulisHijaiyah(), // Replace with MenuHurufHijaiyahPage()
          ),
        );

        // Play button sound and set page type
        AudioMusicManager.instance
            .playButtonTapSound('assets/button_click.wav');
        AudioMusicManager.instance.setPageType(PageType.musik2);
      },
      child: FractionallySizedBox(
        widthFactor: 0.2,
        child: AspectRatio(
          aspectRatio: 1 / 1.2,
          child: Image.asset(
            'assets/menu/belajar_huruf_hijaiyah.png', // Replace with your asset path
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}

class AngkaButton extends StatelessWidget {
  const AngkaButton({super.key});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        // Navigate to MenuBelajarAngkaPage
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                const MenuAngka(), // Replace with MenuBelajarAngkaPage()
          ),
        );

        //Play button sound
        AudioMusicManager.instance
            .playButtonTapSound('assets/button_click.wav');
      },
      child: FractionallySizedBox(
        widthFactor: 0.2,
        child: AspectRatio(
          aspectRatio: 1 / 1.2,
          child: Image.asset(
            'assets/menu/belajar_angka.png', // Replace with your asset path
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}

class BackButtonWidget extends StatelessWidget {
  const BackButtonWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.of(context).pop();

        // Play button sound and set page type
        AudioMusicManager.instance
            .playButtonTapSound('assets/button_click.wav');
        AudioMusicManager.instance.setPageType(PageType.musik1);
      },
      child: SizedBox(
        width: MediaQuery.of(context).size.width * 0.08,
        height: MediaQuery.of(context).size.width * 0.08,
        child: Image.asset(
          'assets/menu/button_back_home.png', // Replace with your asset path
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
