import 'dart:async';

import 'package:tank_game/world/core/actor.dart';
import 'package:tank_game/world/core/behaviors/core_behavior.dart';

class TriggerSpawnBehavior extends CoreBehavior<ActorMixin> {
  @override
  FutureOr<void> onLoad() {
    parent.boundingBox.isDistanceCallbackEnabled = true;
  }

  @override
  void onRemove() {
    parent.boundingBox.isDistanceCallbackEnabled = false;
  }
}
