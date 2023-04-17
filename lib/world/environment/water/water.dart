import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame_behaviors/flame_behaviors.dart';
import 'package:flame_spatial_grid/flame_spatial_grid.dart';
import 'package:tank_game/world/core/actor.dart';
import 'package:tank_game/world/core/behaviors/attacks/bullet.dart';
import 'package:tank_game/world/world.dart';

class WaterEntity extends SpriteAnimationComponent
    with CollisionCallbacks, EntityMixin, HasGridSupport, ActorMixin {
  WaterEntity({required super.animation, super.position, super.size})
      : super(priority: RenderPriority.water.priority) {
    boundingBox.collisionType =
        boundingBox.defaultCollisionType = CollisionType.passive;
    boundingBox.isSolid = true;
    paint.filterQuality = FilterQuality.none;
    paint.isAntiAlias = false;
  }

  @override
  bool onComponentTypeCheck(PositionComponent other) {
    if (other is BulletEntity) {
      return false;
    }
    return super.onComponentTypeCheck(other);
  }
}
