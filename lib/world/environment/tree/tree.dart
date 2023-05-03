import 'dart:async';
import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame_behaviors/flame_behaviors.dart';
import 'package:flame_spatial_grid/flame_spatial_grid.dart';
import 'package:tank_game/world/core/actor.dart';
import 'package:tank_game/world/core/behaviors/attacks/bullet.dart';
import 'package:tank_game/world/core/behaviors/effects/shadow_behavior.dart';
import 'package:tank_game/world/environment/tree/hide_in_trees_behavior.dart';
import 'package:tank_game/world/world.dart';

class TreeEntity extends SpriteComponent
    with CollisionCallbacks, EntityMixin, HasGridSupport, ActorMixin {
  TreeEntity({required super.sprite, super.position, super.size})
      : super(priority: RenderPriority.tree.priority) {
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
    if (!(other as ActorMixin).hasBehavior<HideInTreesBehavior>()) {
      return false;
    }
    return super.onComponentTypeCheck(other);
  }

  @override
  void onCollisionStart(
      Set<Vector2> intersectionPoints, PositionComponent other) {
    if (other is ActorMixin) {
      try {
        final hideBehavior = other.findBehavior<HideInTreesBehavior>();
        hideBehavior.collisionsWithTrees++;
      } catch (_) {}
    }
    super.onCollisionStart(intersectionPoints, other);
  }

  @override
  void onCollisionEnd(PositionComponent other) {
    if (other is ActorMixin) {
      final hideBehavior = other.findBehavior<HideInTreesBehavior>();
      if (hideBehavior.collisionsWithTrees > 0) {
        hideBehavior.collisionsWithTrees--;
      }
    }
    super.onCollisionEnd(other);
  }

  @override
  FutureOr<void> onLoad() {
    add(ShadowBehavior(shadowKey: 'tree'));
    super.onLoad();
  }
}
