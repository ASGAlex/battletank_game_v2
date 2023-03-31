import 'dart:async';

import 'package:flame/collisions.dart';
import 'package:flame_behaviors/flame_behaviors.dart';
import 'package:tank_game/world/core/actor.dart';

abstract class CollisionBehavior extends Behavior<ActorMixin>
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
