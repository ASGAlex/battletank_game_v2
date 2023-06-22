import 'dart:async';

import 'package:flame/components.dart';
import 'package:tank_game/services/settings/controller.dart';
import 'package:tank_game/world/core/audio_effect_loop.dart';

class EnemyAmbientVolume extends Component {
  EnemyAmbientVolume() {
    _squaredMaxDistance = _audioDetectionDistance * _audioDetectionDistance * 2;
  }

  double volume = 0;
  AudioEffectLoop? _audioEffectLoop;

  static const _audioDetectionDistance = 800.0;
  late final double _squaredMaxDistance;
  var _minDistanceX = _audioDetectionDistance + 1;
  var _minDistanceY = _audioDetectionDistance + 1;

  void onTankDetectedPlayer(double distanceX, double distanceY) {
    if (distanceX < _minDistanceX) {
      _minDistanceX = distanceX;
    }
    if (distanceY < _minDistanceY) {
      _minDistanceY = distanceY;
    }
  }

  @override
  FutureOr<void> onLoad() {
    if (SettingsController().soundEnabled) {
      _audioEffectLoop = AudioEffectLoop(
        effectFile: 'sfx/move_enemies.m4a',
        effectDuration: const Duration(seconds: 2),
      );
    }
    return super.onLoad();
  }

  @override
  void update(double dt) {
    volume = 0;
    if (_minDistanceX < _audioDetectionDistance &&
        _minDistanceY < _audioDetectionDistance) {
      final squaredDistance =
          _minDistanceX * _minDistanceX + _minDistanceY * _minDistanceY;
      volume = 1 - (squaredDistance / _squaredMaxDistance);
      if (volume > 0.01) {
        _audioEffectLoop?.volume = volume;
        _audioEffectLoop?.play();
      }
    }
    if (volume == 0) {
      _audioEffectLoop?.volume = volume;
      _audioEffectLoop?.stop();
    }
    _minDistanceX = _minDistanceY = _audioDetectionDistance + 1;
  }

  @override
  void onRemove() {
    _audioEffectLoop?.dispose();
    super.onRemove();
  }
}
