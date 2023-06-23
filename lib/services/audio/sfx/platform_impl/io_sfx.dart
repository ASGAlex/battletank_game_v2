import 'package:flame_audio/flame_audio.dart';
import 'package:tank_game/services/audio/sfx/platform_impl/interface.dart';

class SfxImpl implements SfxInterface {
  SfxImpl({
    required this.effectName,
    this.poolSize = 2,
  }) {
    FlameAudio.createPool(effectName, maxPlayers: poolSize).then((pool) {
      _audioPool = pool;
    });
  }

  AudioPool? _audioPool;

  @override
  final String effectName;
  @override
  final int poolSize;

  @override
  void play() {
    _audioPool?.start();
  }

  @override
  void dispose() {
    _audioPool?.dispose();
  }
}
