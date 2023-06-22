import 'dart:async';
import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame_behaviors/flame_behaviors.dart';
import 'package:flame_spatial_grid/flame_spatial_grid.dart';
import 'package:tank_game/world/core/actor.dart';
import 'package:tank_game/world/environment/ground/slowdown_by_sand_behavior.dart';
import 'package:tank_game/world/world.dart';

class SandEntity extends SpriteAnimationComponent
    with
        CollisionCallbacks,
        EntityMixin,
        HasGridSupport,
        ActorMixin,
        ActorWithBoundingBody {
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
    if (!(other as ActorMixin).hasBehavior<SlowDownBySandBehavior>()) {
      return false;
    }
    return true;
  }

  @override
  void onCollisionStart(
      Set<Vector2> intersectionPoints, PositionComponent other) {
    if (other is ActorMixin) {
      try {
        final hideBehavior = other.findBehavior<SlowDownBySandBehavior>();
        hideBehavior.collisionsWithSand++;
      } catch (_) {}
    }
    super.onCollisionStart(intersectionPoints, other);
  }

  @override
  void onCollisionEnd(PositionComponent other) {
    if (other is ActorMixin) {
      try {
        final hideBehavior = other.findBehavior<SlowDownBySandBehavior>();
        if (hideBehavior.collisionsWithSand > 0) {
          hideBehavior.collisionsWithSand--;
        }
      } catch (_) {}
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
