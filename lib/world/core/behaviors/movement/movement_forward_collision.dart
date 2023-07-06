import 'dart:async';
import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame_spatial_grid/flame_spatial_grid.dart';
import 'package:tank_game/world/actors/human/human.dart';
import 'package:tank_game/world/actors/tank/tank.dart';
import 'package:tank_game/world/core/actor.dart';
import 'package:tank_game/world/core/behaviors/movement/movement_behavior.dart';
import 'package:tank_game/world/core/direction.dart';
import 'package:tank_game/world/core/scenario/scenario_component.dart';
import 'package:tank_game/world/environment/ground/sand.dart';
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
    priority = 0;
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

abstract class MovementCheckerHitbox extends BoundingHitbox {
  MovementCheckerHitbox({super.position, super.size}) {
    triggersParentCollision = false;
    // debugMode = true;
  }

  Direction get direction;

  bool get isMovementBlocked => activeCollisions.isNotEmpty;

  bool get isMovementAllowed => activeCollisions.isEmpty;

  Direction get globalMapDirection {
    var globalValue =
        direction.value + (parent as ActorMixin).data.lookDirection.value;
    if (globalValue > 3) {
      return Direction.fromValue(globalValue - 4);
    }
    return Direction.fromValue(globalValue);
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

class MovementHitbox extends MovementCheckerHitbox {
  MovementHitbox({
    required super.position,
    required super.size,
  }) {
    collisionType = defaultCollisionType = CollisionType.active;
  }

  @override
  final Direction direction = Direction.up;

  @override
  FutureOr<void> onLoad() {
    isSolid = true;
    return super.onLoad();
  }

  @override
  bool pureTypeCheck(Type other) {
    if (other == SpawnBoundingHitbox ||
        other == TreeBoundingHitbox ||
        other == BoundingHitbox ||
        other == SandBoundingHitbox ||
        other == WeakBodyHitbox ||
        other == ScenarioHitbox ||
        other == MovementHitbox ||
        other == MovementCheckerHitbox ||
        other == TankBoundingHitbox) {
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
}
