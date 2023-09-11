import 'dart:async';
import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/experimental.dart';
import 'package:flame/extensions.dart';
import 'package:flame_spatial_grid/flame_spatial_grid.dart';
import 'package:flutter/material.dart';
import 'package:tank_game/world/actors/human/human.dart';
import 'package:tank_game/world/actors/tank/tank.dart';
import 'package:tank_game/world/core/actor.dart';
import 'package:tank_game/world/core/behaviors/movement/movement_behavior.dart';
import 'package:tank_game/world/core/direction.dart';
import 'package:tank_game/world/core/faction.dart';
import 'package:tank_game/world/core/scenario/scenario_component.dart';
import 'package:tank_game/world/environment/ground/asphalt.dart';
import 'package:tank_game/world/environment/ground/sand.dart';
import 'package:tank_game/world/environment/spawn/spawn_core_entity.dart';
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

abstract class MovementCheckerHitbox extends ActorDefaultHitbox {
  MovementCheckerHitbox({super.position, super.size}) {
    triggersParentCollision = false;
    // debugMode = true;
    paint.color = Colors.white;
    paint.strokeWidth = 1;
    paint.style = PaintingStyle.stroke;
  }

  DirectionExtended get direction;

  bool get isMovementBlocked => activeCollisions.isNotEmpty;

  bool get isMovementAllowed => activeCollisions.isEmpty;

  Set<Vector2>? _lastIntersectionPoints;
  ShapeHitbox? _lastHitbox;
  DirectionExtended? _lastDirection;

  Map<DirectionExtended, double> get alternativeDirectionShortest {
    final diffList = _findDiff();
    if (diffList.isNotEmpty) {
      final type = diffList[0];
      if (type > 0) {
        final diffTop = diffList[1];
        final diffBottom = diffList[2];
        if (diffTop > diffBottom) {
          return <DirectionExtended, double>{
            DirectionExtended.down: diffBottom,
            // DirectionExtended.up: diffTop,
          };
        } else {
          return <DirectionExtended, double>{
            DirectionExtended.up: diffTop,
            // DirectionExtended.down: diffBottom,
          };
        }
      } else {
        final diffLeft = diffList[1];
        final diffRight = diffList[2];
        if (diffLeft > diffRight) {
          return <DirectionExtended, double>{
            // DirectionExtended.left: diffLeft,
            DirectionExtended.right: diffRight,
          };
        } else {
          return <DirectionExtended, double>{
            DirectionExtended.left: diffLeft,
            // DirectionExtended.right: diffRight,
          };
        }
      }
    }
    return {};
  }

  Map<DirectionExtended, double> get alternativeDirectionLongest {
    final diffList = _findDiff();
    if (diffList.isNotEmpty) {
      final type = diffList[0];
      if (type > 0) {
        final diffTop = diffList[1];
        final diffBottom = diffList[2];
        if (diffTop > diffBottom) {
          return <DirectionExtended, double>{
            // DirectionExtended.down: diffBottom,
            DirectionExtended.up: diffTop,
          };
        } else {
          return <DirectionExtended, double>{
            // DirectionExtended.up: diffTop,
            DirectionExtended.down: diffBottom,
          };
        }
      } else {
        final diffLeft = diffList[1];
        final diffRight = diffList[2];
        if (diffLeft > diffRight) {
          return <DirectionExtended, double>{
            DirectionExtended.left: diffLeft,
            // DirectionExtended.right: diffRight,
          };
        } else {
          return <DirectionExtended, double>{
            // DirectionExtended.left: diffLeft,
            DirectionExtended.right: diffRight,
          };
        }
      }
    }
    return {};
  }

  List<double> _findDiff() {
    if (_lastHitbox != null &&
        _lastDirection != null &&
        _lastIntersectionPoints != null) {
      final alternativeDirections = _lastDirection!.perpendicular;
      final polygon = Polygon(_lastIntersectionPoints!.toList(), convex: true);
      final bounding = _lastHitbox as BoundingHitbox;
      Rect boundingRect;
      if (bounding.optimized) {
        boundingRect = bounding.group!.aabb.toRect();
      } else {
        boundingRect = bounding.aabb.toRect();
      }

      if (alternativeDirections.contains(DirectionExtended.up)) {
        final diffTop = (polygon.center.y - boundingRect.top).abs();
        final diffBottom = (polygon.center.y - boundingRect.bottom).abs();
        return [1, diffTop, diffBottom];
      } else {
        final diffLeft = (polygon.center.x - boundingRect.left).abs();
        final diffRight = (polygon.center.x - boundingRect.right).abs();
        return [-1, diffLeft, diffRight];
      }
    }

    return [];
  }

  DirectionExtended get globalMapDirection {
    var globalValue =
        direction.value + (parent as ActorMixin).data.lookDirection.value;
    if (globalValue > 3) {
      return DirectionExtended.fromValue(globalValue - 4);
    }
    return DirectionExtended.fromValue(globalValue);
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, ShapeHitbox other) {
    _lastIntersectionPoints = intersectionPoints;
    _lastHitbox = other;
    _lastDirection = (parent as ActorMixin).data.lookDirection;
    super.onCollision(intersectionPoints, other);
  }

  @override
  void render(Canvas canvas) {
    final offsetPoints = <Offset>[];
    if (_lastIntersectionPoints != null) {
      for (final point in _lastIntersectionPoints!) {
        final offset = absoluteToLocal(point).toOffset();
        offsetPoints.add(offset);
      }
      canvas.drawPoints(PointMode.points, offsetPoints, paint);
      renderDebugMode(canvas);
    }
    super.render(canvas);
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
  final DirectionExtended direction = DirectionExtended.up;

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
        other == AsphaltHitbox ||
        // other == HumanBodyHitbox ||
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
    if (parent == null) {
      return false;
    }
    final component = other.parent;
    if (component is HumanEntity) {
      final factions = component.data.factions;
      final myFactions = (parent as ActorMixin).data.factions;
      if (myFactions.contains(Faction(name: 'Friendly')) &&
          factions.contains(Faction(name: 'Player'))) {
        return true;
      }
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
