import 'package:tank_game/services/audio/howl_interop.dart';

import 'interface.dart';

class AudioEffectLoopImpl implements AudioEffectLoopInterface {
  AudioEffectLoopImpl(
      {required this.effectFile,
      required this.effectDuration,
      this.effectMode = EffectMode.audioPool}) {
    _howlPlayer = Howl(HowlOptions(
      src: ['/assets/audio/$effectFile'],
      html5: false,
      preload: true,
      loop: true,
    ));
  }

  Howl? _howlPlayer;
  bool _playing = false;

  @override
  void dispose() {
    stop();
    _howlPlayer?.stop();
    _howlPlayer?.unload();
  }

  @override
  void play() {
    _howlPlayer?.volume(volume);
    if (!_playing) {
      _howlPlayer?.play();
      _playing = true;
    }
  }

  @override
  Future<void>? stop() {
    if (_playing) {
      _howlPlayer?.pause();
      _playing = false;
    }
    return null;
  }

  @override
  EffectMode effectMode;

  @override
  double volume = 1.0;

  @override
  final Duration effectDuration;

  @override
  final String effectFile;
}
