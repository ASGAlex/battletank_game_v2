import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/foundation.dart';
import 'package:tank_game/services/audio/howl_interop.dart';

enum EffectMode {
  standard,
  audioPool,
  webAudioAPI,
}

class Sfx {
  Sfx({
    required this.effectName,
    this.poolSize = 2,
    this.mode = kIsWeb ? EffectMode.audioPool : EffectMode.webAudioAPI,
  }) {
    switch (mode) {
      case EffectMode.standard:
        throw UnimplementedError();
        break;
      case EffectMode.audioPool:
        FlameAudio.createPool(effectName, maxPlayers: poolSize).then((pool) {
          _audioPool = pool;
        });
        break;
      case EffectMode.webAudioAPI:
        _howlPlayer = Howl(HowlOptions(
          src: ['/assets/audio/$effectName'],
          html5: false,
          preload: true,
          loop: false,
        ));
        break;
    }
  }

  final String effectName;
  final int poolSize;
  final EffectMode mode;

  AudioPool? _audioPool;
  Howl? _howlPlayer;

  void play() {
    switch (mode) {
      case EffectMode.standard:
        throw UnimplementedError();
        break;
      case EffectMode.audioPool:
        _audioPool?.start();
        break;
      case EffectMode.webAudioAPI:
        _howlPlayer?.play();
        break;
    }
  }

  void dispose() {
    switch (mode) {
      case EffectMode.standard:
        throw UnimplementedError();
        break;
      case EffectMode.audioPool:
        _audioPool?.dispose();
        break;
      case EffectMode.webAudioAPI:
        _howlPlayer?.unload();
        break;
    }

    _audioPool = null;
    _howlPlayer = null;
  }
}
