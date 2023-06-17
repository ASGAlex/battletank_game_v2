import 'dart:async';

import 'package:tank_game/world/core/actor.dart';
import 'package:tank_game/world/core/behaviors/core_behavior.dart';

class SpeedPenaltyBehavior extends CoreBehavior<ActorMixin> {
  SpeedPenaltyBehavior({required this.penalty, required this.duration});

  final double penalty;
  final double duration;

  double _time = 0;
  double _originalSpeed = 0;

  @override
  FutureOr<void> onLoad() {
    _originalSpeed = parent.data.speed;
    if (penalty > _originalSpeed) {
      parent.data.speed = 0;
    } else {
      parent.data.speed = _originalSpeed - penalty;
    }
  }

  @override
  void update(double dt) {
    if (_time >= duration) {
      _restoreSpeed();
      removeFromParent();
      return;
    }
    _time += dt;
  }

  void _restoreSpeed() {
    parent.data.speed = _originalSpeed;
  }
}
