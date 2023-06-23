import 'interface.dart';

class AudioEffectLoopImpl implements AudioEffectLoopInterface {
  AudioEffectLoopImpl(
      {required this.effectFile,
      required this.effectDuration,
      this.effectMode = EffectMode.audioPool});

  @override
  void dispose() => throw UnimplementedError();

  @override
  void play() => throw UnimplementedError();

  @override
  Future<void>? stop() => throw UnimplementedError();

  @override
  EffectMode effectMode;

  @override
  double volume = 1.0;

  @override
  final Duration effectDuration;

  @override
  final String effectFile;
}
