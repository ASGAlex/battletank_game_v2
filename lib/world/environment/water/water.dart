import 'dart:async';
import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame_behaviors/flame_behaviors.dart';
import 'package:flame_spatial_grid/flame_spatial_grid.dart';
import 'package:tank_game/world/core/actor.dart';
import 'package:tank_game/world/world.dart';

class WaterEntity extends SpriteAnimationComponent
    with
        CollisionCallbacks,
        EntityMixin,
        HasGridSupport,
        ActorMixin,
        ActorWithBoundingBody,
        UpdateOnDemand {
  WaterEntity({required super.animation, super.position, super.size})
      : super(priority: RenderPriority.water.priority) {
    paint.filterQuality = FilterQuality.none;
    paint.isAntiAlias = false;
    noVisibleChildren = true;
  }

  @override
  BoundingHitboxFactory get boundingHitboxFactory =>
      () => WaterBoundingHitbox();

  @override
  FutureOr<void> onLoad() {
    super.onLoad();
    boundingBox.collisionType =
        boundingBox.defaultCollisionType = CollisionType.passive;
    boundingBox.isSolid = true;
  }
}

class WaterBoundingHitbox extends ActorDefaultHitbox {
  @override
  FutureOr<void> onLoad() {
    groupAbsoluteCacheByType = true;
    collisionType = defaultCollisionType = CollisionType.passive;
    return super.onLoad();
  }
}
