import 'dart:core';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

enum PageType {
  musik1,
  musik2,
  musik3,
}

class AudioMusicManager with WidgetsBindingObserver {
  static final AudioMusicManager _instance = AudioMusicManager._internal();
  static AudioMusicManager get instance => _instance;

  final AudioPlayer backgroundAudioPlayer = AudioPlayer();
  final AudioPlayer buttonTapAudioPlayer = AudioPlayer();

  bool isBackgroundAudioEnabled = true;
  bool isButtonTapAudioEnabled = true;

  double backgroundVolume = 0.5;
  double buttonTapVolume = 0.5;

  Map<PageType, String> pageMusics = {
    PageType.musik1: 'assets/musik1.mp3',
    PageType.musik2: 'assets/musik2.mp3',
    PageType.musik3: 'assets/musik3.mp3',
  };

  PageType currentPageType = PageType.musik1;

  AudioMusicManager._internal();

  Future<void> initialize() async {
    backgroundAudioPlayer.setAudioContext(AudioContext(
      android: const AudioContextAndroid(
        isSpeakerphoneOn: true,
        stayAwake: true,
        contentType: AndroidContentType.music,
        usageType: AndroidUsageType.media,
        audioFocus: AndroidAudioFocus.gain,
      ),
    ));

    backgroundAudioPlayer.setVolume(backgroundVolume);
    buttonTapAudioPlayer.setVolume(buttonTapVolume);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.resumed) {
      if (isBackgroundAudioEnabled &&
          backgroundAudioPlayer.state == PlayerState.paused) {
        Duration? lastPosition =
            await backgroundAudioPlayer.getCurrentPosition();
        await backgroundAudioPlayer.resume();
        if (lastPosition != null && lastPosition.inMilliseconds > 0) {
          await backgroundAudioPlayer.seek(lastPosition);
        }
      }
    } else if (state == AppLifecycleState.paused) {
      if (isBackgroundAudioEnabled &&
          backgroundAudioPlayer.state == PlayerState.playing) {
        await backgroundAudioPlayer.pause();
      }
    }
  }

  double get getBackgroundVolume => backgroundVolume;
  set setBackgroundVolume(double volume) {
    backgroundVolume = volume;
    if (isBackgroundAudioEnabled) {
      backgroundAudioPlayer.setVolume(backgroundVolume);
    }
  }

  double get getButtonTapVolume => buttonTapVolume;
  set setButtonTapVolume(double volume) {
    buttonTapVolume = volume;
    buttonTapAudioPlayer.setVolume(buttonTapVolume);
  }

  Future<void> stopAudio() async {
    {
      await backgroundAudioPlayer.stop();
    }
  }

  Future<void> toggleBackgroundAudio() async {
    isBackgroundAudioEnabled = !isBackgroundAudioEnabled;
    if (!isBackgroundAudioEnabled) {
      await backgroundAudioPlayer.stop();
    } else {
      await playBackgroundSound();
    }
  }

  void toggleButtonTapAudio() {
    isButtonTapAudioEnabled = !isButtonTapAudioEnabled;
  }

  Future<void> playBackgroundSound({bool restart = false}) async {
    backgroundAudioPlayer.audioCache = AudioCache(prefix: "");

    try {
      if (isBackgroundAudioEnabled) {
        String audioPath = pageMusics[currentPageType] ?? '';
        if (audioPath.isNotEmpty) {
          if (!restart && backgroundAudioPlayer.state == PlayerState.playing) {
            return;
          }

          await backgroundAudioPlayer.stop();

          await backgroundAudioPlayer.setAudioContext(AudioContext(
            android: const AudioContextAndroid(
              isSpeakerphoneOn: true,
              stayAwake: true,
              contentType: AndroidContentType.music,
              usageType: AndroidUsageType.media,
              audioFocus: AndroidAudioFocus.none,
            ),
          ));

          await backgroundAudioPlayer.setVolume(backgroundVolume);
          await backgroundAudioPlayer.play(AssetSource(audioPath));

          backgroundAudioPlayer.onPlayerComplete.listen((event) {
            playBackgroundSound(restart: true);
          });
        }
      } else {
        await backgroundAudioPlayer.stop();
      }
      // ignore: empty_catches
    } catch (e, stacktrace) {
      log("message: $e, stacktrace: $stacktrace");
    }
  }

  Future<void> setPageType(PageType pageType) async {
    try {
      if (pageType != currentPageType) {
        currentPageType = pageType;
        await playBackgroundSound(restart: true);
      }
    } catch (e) {
      log("Error setting page type: $e");
    }
  }

  Future<void> stopBackgroundAudio() async {
    await backgroundAudioPlayer.stop();
  }

  Future<void> stopMusicOnTap() async {
    if (isBackgroundAudioEnabled) {
      await backgroundAudioPlayer.stop();
    }
  }

  Future<void> playButtonTapSound(String soundPath) async {
    if (isButtonTapAudioEnabled) {
      try {
        buttonTapAudioPlayer.audioCache = AudioCache(prefix: "");
        buttonTapAudioPlayer.play(AssetSource(soundPath));
      } catch (e) {
        log("Error button tap sound: $e");
      }
    }
  }

  Future<void> menurunkanBackgroundVolume(double decrement) async {
    if (backgroundVolume > 0) {
      backgroundVolume -= decrement;

      if (backgroundVolume < 0) {
        backgroundVolume = 0;
      }

      await backgroundAudioPlayer.setVolume(backgroundVolume);
    }
  }

  Future<void> pauseBackgroundAudio() async {
    await backgroundAudioPlayer.pause();
  }

  Future<void> resumeBackgroundAudio() async {
    await backgroundAudioPlayer.resume();
  }
}
