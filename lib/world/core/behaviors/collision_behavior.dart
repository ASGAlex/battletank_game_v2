import 'dart:async';

import 'package:flame/collisions.dart';
import 'package:tank_game/world/core/actor.dart';
import 'package:tank_game/world/core/behaviors/core_behavior.dart';

abstract class CollisionBehavior extends CoreBehavior<ActorMixin>
    with CollisionCallbacks {
  CollisionBehavior();

  @override
  FutureOr<void> onLoad() {
    assert(parent is CollisionCallbacks);
    (parent as CollisionCallbacks)
      ..onCollisionCallback = onCollision
      ..onCollisionStartCallback = onCollisionStart
      ..onCollisionEndCallback = onCollisionEnd;
  }
}
