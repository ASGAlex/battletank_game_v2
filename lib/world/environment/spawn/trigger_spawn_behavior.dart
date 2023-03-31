import 'dart:async';

import 'package:flame_behaviors/flame_behaviors.dart';
import 'package:tank_game/world/core/actor.dart';

class TriggerSpawnBehavior extends Behavior<ActorMixin> {
  @override
  FutureOr<void> onLoad() {
    parent.boundingBox.isDistanceCallbackEnabled = true;
  }

  @override
  void onRemove() {
    parent.boundingBox.isDistanceCallbackEnabled = false;
  }
}
