import 'dart:async';
import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame_behaviors/flame_behaviors.dart';
import 'package:flame_spatial_grid/flame_spatial_grid.dart';
import 'package:tank_game/world/core/actor.dart';
import 'package:tank_game/world/core/behaviors/effects/smoke_start_moving_behavior.dart';
import 'package:tank_game/world/environment/ground/slowdown_by_sand_behavior.dart';
import 'package:tank_game/world/world.dart';

class SandEntity extends SpriteAnimationComponent
    with
        CollisionCallbacks,
        EntityMixin,
        HasGridSupport,
        ActorMixin,
        ActorWithBoundingBody,
        UpdateOnDemand {
  SandEntity({required super.animation, super.position, super.size})
      : super(priority: RenderPriority.ground.priority) {
    paint.filterQuality = FilterQuality.none;
    paint.isAntiAlias = false;
  }

  @override
  FutureOr<void> onLoad() {
    super.onLoad();
    boundingBox.collisionType =
        boundingBox.defaultCollisionType = CollisionType.passive;
    boundingBox.isSolid = true;
  }

  @override
  BoundingHitboxFactory get boundingHitboxFactory => () => SandBoundingHitbox();

  @override
  bool onComponentTypeCheck(PositionComponent other) {
    if (other is! SlowDownBySandOptimizedCheckerMixin) {
      return false;
    }
    if (other.canBeSlowedDownBySand) {
      return true;
    }
    return true;
  }

  @override
  void onCollisionStart(
      Set<Vector2> intersectionPoints, PositionComponent other) {
    if (other is SlowDownBySandOptimizedCheckerMixin &&
        other.slowDownBySandBehavior != null) {
      other.slowDownBySandBehavior!.collisionsWithSand++;
      final smokeBehavior = other.findBehavior<SmokeStartMovingBehavior>();
      smokeBehavior.isEnabled = true;
    }
    super.onCollisionStart(intersectionPoints, other);
  }

  @override
  void onCollisionEnd(PositionComponent other) {
    if (other is SlowDownBySandOptimizedCheckerMixin &&
        other.slowDownBySandBehavior != null) {
      if (other.slowDownBySandBehavior!.collisionsWithSand > 0) {
        other.slowDownBySandBehavior!.collisionsWithSand--;
      }
    }
    super.onCollisionEnd(other);
  }
}

class SandBoundingHitbox extends BoundingHitbox {
  @override
  FutureOr<void> onLoad() {
    collisionType = defaultCollisionType = CollisionType.passive;
    return super.onLoad();
  }
}
