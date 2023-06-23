import 'dart:async';

abstract interface class AudioEffectLoopInterface {
  AudioEffectLoopInterface(
      {required this.effectFile,
      required this.effectDuration,
      required this.effectMode});

  final EffectMode effectMode;

  final Duration effectDuration;
  final String effectFile;
  double volume = 1.0;

  void play();

  Future<void>? stop();

  void dispose();
}

enum EffectMode {
  standard,
  audioPool,
}
