import 'dart:async';

import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';
import 'package:tank_game/world/core/actor.dart';
import 'package:tank_game/world/core/behaviors/core_behavior.dart';

mixin DistanceCallbackMixin on CoreBehavior<ActorMixin> {
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
    try {
      if (disableCallbackOnRemove) {
        parent.boundingBox.isDistanceCallbackEnabled = false;
      }
      if (registerDistanceFunction) {
        parent.distanceFunctions.remove(onCalculateDistance);
      }
    } catch (_) {}
  }

  void onCalculateDistance(
      Component other, double distanceX, double distanceY) {}
}
