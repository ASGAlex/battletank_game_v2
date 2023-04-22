import 'dart:async';

import 'package:flame/components.dart';
import 'package:flame_behaviors/flame_behaviors.dart';
import 'package:flutter/foundation.dart';
import 'package:tank_game/world/core/actor.dart';

mixin DistanceCallbackMixin on Behavior<ActorMixin> {
  bool get registerDistanceFunction => true;
  bool disableCallbackOnRemove = true;

  @override
  @mustCallSuper
  FutureOr<void> onLoad() {
    parent.boundingBox.isDistanceCallbackEnabled = true;
    if (registerDistanceFunction) {
      parent.distanceFunctions.add(onCalculateDistance);
    }
  }

  @override
  @mustCallSuper
  void onRemove() {
    if (disableCallbackOnRemove) {
      parent.boundingBox.isDistanceCallbackEnabled = false;
    }
    if (registerDistanceFunction) {
      parent.distanceFunctions.remove(onCalculateDistance);
    }
  }

  void onCalculateDistance(
      Component other, double distanceX, double distanceY) {}
}
