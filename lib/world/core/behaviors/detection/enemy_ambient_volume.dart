import 'dart:async';

import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';
import 'package:tank_game/services/audio/audio_effect_loop.dart';
import 'package:tank_game/services/audio/sfx.dart';
import 'package:tank_game/services/settings/controller.dart';

class EnemyAmbientVolume extends Component {
  EnemyAmbientVolume() {
    _squaredMaxDistance = _squaredMinDistance =
        _audioDetectionDistance * _audioDetectionDistance * 2;
  }

  double volume = 0;
  AudioEffectLoop? _audioEffectLoop;

  static const _audioDetectionDistance = 300.0;
  late final double _squaredMaxDistance;
  var _squaredMinDistance = 0.0;

  void onTankDetectedPlayer(double distanceX, double distanceY) {
    final squared = distanceX * distanceX + distanceY * distanceY;
    if (squared < _squaredMinDistance) {
      _squaredMinDistance = squared;
    }
  }

  @override
  FutureOr<void> onLoad() {
    if (SettingsController().soundEnabled) {
      _audioEffectLoop = AudioEffectLoop(
        effectFile: 'sfx/move_enemies.m4a',
        effectDuration: const Duration(seconds: 2),
        effectMode: kIsWeb ? EffectMode.webAudioAPI : EffectMode.audioPool,
      );
    }
    return super.onLoad();
  }

  @override
  void update(double dt) {
    volume = 0;
    if (_squaredMinDistance < _squaredMaxDistance) {
      volume = 1 - (_squaredMinDistance / _squaredMaxDistance);
      if (volume < 0) {
        volume = 0;
      }
      if (volume > 0.01) {
        _audioEffectLoop?.volume = volume;
        _audioEffectLoop?.play();
      }
    }
    if (volume == 0) {
      _audioEffectLoop?.volume = volume;
      _audioEffectLoop?.stop();
    }
    _squaredMinDistance = _squaredMaxDistance;
  }

  @override
  void onRemove() {
    if (!isRemoved) {
      // _audioEffectLoop?.dispose();
      super.onRemove();
    }
  }
}
