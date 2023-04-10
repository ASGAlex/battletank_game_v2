import 'dart:async';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame_spatial_grid/flame_spatial_grid.dart';
import 'package:tank_game/world/core/actor.dart';
import 'package:tank_game/world/core/behaviors/movement/movement_behavior.dart';

class MovementForwardCollisionBehavior extends MovementBehavior {
  MovementForwardCollisionBehavior({
    required Vector2 hitboxRelativePosition,
    required Vector2 hitboxSize,
    required bool Function(PositionComponent) typeCheck,
  }) {
    movementHitbox = MovementHitbox(
      position: hitboxRelativePosition,
      size: hitboxSize,
      typeCheck: typeCheck,
    );
  }

  @override
  void update(double dt) {
    if (movementHitbox.isMovementBlocked) {
      parent.coreState = ActorCoreState.idle;
    }
    super.update(dt);
  }

  late final MovementHitbox movementHitbox;

  @override
  FutureOr<void> onLoad() {
    parent.add(movementHitbox);
    return super.onLoad();
  }

  @override
  void onRemove() {
    movementHitbox.removeFromParent();
    super.onRemove();
  }
}

class MovementHitbox extends BoundingHitbox {
  MovementHitbox({
    required super.position,
    required super.size,
    required this.typeCheck,
  }) {
    collisionType = CollisionType.active;
  }

  bool get isMovementBlocked => activeCollisions.isNotEmpty;

  bool get isMovementAllowed => activeCollisions.isEmpty;

  bool Function(PositionComponent) typeCheck;

  @override
  bool onComponentTypeCheck(PositionComponent other) {
    if (other is MovementHitbox) {
      return false;
    }
    final checkResult = typeCheck(other);
    if (checkResult) {
      return super.onComponentTypeCheck(other);
    }

    return checkResult;
  }
}
