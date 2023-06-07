import 'dart:async';
import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame_spatial_grid/flame_spatial_grid.dart';
import 'package:tank_game/world/actors/human/human.dart';
import 'package:tank_game/world/core/actor.dart';
import 'package:tank_game/world/core/behaviors/movement/movement_behavior.dart';
import 'package:tank_game/world/environment/spawn/spawn_entity.dart';
import 'package:tank_game/world/environment/tree/tree.dart';

class MovementForwardCollisionBehavior extends MovementBehavior {
  MovementForwardCollisionBehavior({
    required Vector2 hitboxRelativePosition,
    required Vector2 hitboxSize,
  }) {
    movementHitbox = MovementHitbox(
      position: hitboxRelativePosition,
      size: hitboxSize,
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
  }) {
    collisionType = CollisionType.active;
    // debugMode = true;
  }

  bool get isMovementBlocked => activeCollisions.isNotEmpty;

  bool get isMovementAllowed => activeCollisions.isEmpty;

  @override
  FutureOr<void> onLoad() {
    isSolid = true;
    return super.onLoad();
  }

  @override
  bool pureTypeCheck(Type other) {
    if (other == SpawnEntity ||
        other == TreeEntity ||
        other == BoundingHitbox ||
        other == WeakBodyHitbox) {
      return false;
    }
    return true;
  }

  @override
  bool onComponentTypeCheck(PositionComponent other) {
    final component = other.parent;
    if (component is HumanEntity) {
      final factions = component.data.factions;
      final myFactions = (parent as ActorMixin).data.factions;
      var shouldCareAboutIt = false;
      for (final faction in factions) {
        if (myFactions.contains(faction)) {
          shouldCareAboutIt = true;
        }
      }
      return shouldCareAboutIt;
    }
    return true;
  }

  @override
  void renderDebugMode(Canvas canvas) {
    canvas.drawRect(
      Rect.fromLTWH(position.x, position.y, size.x, size.y),
      Paint()
        ..color = const Color.fromRGBO(119, 0, 255, 1.0)
        ..style = PaintingStyle.stroke,
    );
  }
}
