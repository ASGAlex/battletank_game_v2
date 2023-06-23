import 'platform_impl/interface.dart';
import 'platform_impl/stub_effect_loop.dart'
    if (dart.library.io) 'platform_impl/io_effect_loop.dart'
    if (dart.library.html) 'platform_impl/web_effect_loop.dart';

class AudioEffectLoop implements AudioEffectLoopInterface {
  AudioEffectLoop(
      {required String effectFile,
      required Duration effectDuration,
      EffectMode effectMode = EffectMode.audioPool})
      : _loopImpl = AudioEffectLoopImpl(
          effectFile: effectFile,
          effectDuration: effectDuration,
          effectMode: effectMode,
        );

  final AudioEffectLoopImpl _loopImpl;

  @override
  void dispose() => _loopImpl.dispose();

  @override
  EffectMode get effectMode => _loopImpl.effectMode;

  @override
  double get volume => _loopImpl.volume;

  @override
  set volume(double value) {
    _loopImpl.volume = value;
  }

  @override
  Duration get effectDuration => _loopImpl.effectDuration;

  @override
  String get effectFile => _loopImpl.effectFile;

  @override
  void play() => _loopImpl.play();

  @override
  Future<void>? stop() => _loopImpl.stop();
}
