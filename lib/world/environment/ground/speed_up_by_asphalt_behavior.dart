import 'dart:async';

import 'package:tank_game/world/core/actor.dart';
import 'package:tank_game/world/core/behaviors/collision_behavior.dart';

mixin SpeedUpByAsphaltOptimizedCheckerMixin on ActorMixin {
  bool canBeSpeedUpByAsphalt = false;
  SpeedUpByAsphaltBehavior? speedUpByAsphaltBehavior;
}

class SpeedUpByAsphaltBehavior extends CollisionBehavior {
  final minimumTiles = 2;

  bool _speedUp = false;
  bool _last = false;
  int _collisionsWithAsphalt = 0;

  int get collisionsWithAsphalt => _collisionsWithAsphalt;

  set collisionsWithAsphalt(int value) {
    _collisionsWithAsphalt = value;
    if (collisionsWithAsphalt >= minimumTiles) {
      _speedUp = true;
    } else {
      _speedUp = false;
    }
  }

  bool get isSpeedUp => _speedUp;
  double _originalSpeed = 0;

  @override
  FutureOr<void> onLoad() {
    if (parent is SpeedUpByAsphaltOptimizedCheckerMixin) {
      (parent as SpeedUpByAsphaltOptimizedCheckerMixin).canBeSpeedUpByAsphalt =
          true;
      (parent as SpeedUpByAsphaltOptimizedCheckerMixin)
          .speedUpByAsphaltBehavior = this;
    }
    return super.onLoad();
  }

  @override
  void onRemove() {
    if (parent is SpeedUpByAsphaltOptimizedCheckerMixin) {
      (parent as SpeedUpByAsphaltOptimizedCheckerMixin).canBeSpeedUpByAsphalt =
          false;
      (parent as SpeedUpByAsphaltOptimizedCheckerMixin)
          .speedUpByAsphaltBehavior = null;
    }
    super.onRemove();
  }

  @override
  void update(double dt) {
    if (isSpeedUp) {
      if (_originalSpeed == 0) {
        _originalSpeed = parent.data.speed;
      }
      parent.data.speed = _originalSpeed + 10;
      if (parent.data.speed < 0) {
        parent.data.speed = 0;
      }
    }

    if (isSpeedUp != _last) {
      if (!isSpeedUp) {
        parent.data.speed = _originalSpeed;
        _originalSpeed = 0;
      }
      _last = isSpeedUp;
    }
    super.update(dt);
  }
}
