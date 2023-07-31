import 'dart:async';
import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame_behaviors/flame_behaviors.dart';
import 'package:flame_spatial_grid/flame_spatial_grid.dart';
import 'package:tank_game/world/core/actor.dart';
import 'package:tank_game/world/core/behaviors/effects/shadow_behavior.dart';
import 'package:tank_game/world/environment/tree/hide_in_trees_behavior.dart';
import 'package:tank_game/world/world.dart';

class TreeEntity extends SpriteComponent
    with CollisionCallbacks, EntityMixin, HasGridSupport, ActorMixin {
  TreeEntity({required super.sprite, super.position, super.size})
      : super(priority: RenderPriority.tree.priority) {
    paint.filterQuality = FilterQuality.none;
    paint.isAntiAlias = false;
    noVisibleChildren = true;
  }

  @override
  BoundingHitboxFactory get boundingHitboxFactory => () => TreeBoundingHitbox();

  @override
  bool onComponentTypeCheck(PositionComponent other) {
    if (other is! HideInTreesOptimizedCheckerMixin) {
      return false;
    }
    if (other.canHideInTrees) {
      return true;
    }
    return false;
  }

  @override
  void onCollisionStart(
      Set<Vector2> intersectionPoints, PositionComponent other) {
    if (other is HideInTreesOptimizedCheckerMixin) {
      other.hideInTreesBehavior?.collisionsWithTrees++;
    }
    super.onCollisionStart(intersectionPoints, other);
  }

  @override
  void onCollisionEnd(PositionComponent other) {
    if (other is HideInTreesOptimizedCheckerMixin &&
        other.hideInTreesBehavior != null) {
      if (other.hideInTreesBehavior!.collisionsWithTrees > 0) {
        other.hideInTreesBehavior?.collisionsWithTrees--;
      }
    }
    super.onCollisionEnd(other);
  }

  @override
  FutureOr<void> onLoad() {
    add(ShadowBehavior(shadowKey: 'tree'));
    super.onLoad();
    boundingBox.collisionType =
        boundingBox.defaultCollisionType = CollisionType.passive;
    boundingBox.isSolid = true;
  }
}

class TreeBoundingHitbox extends BoundingHitbox {
  @override
  FutureOr<void> onLoad() {
    collisionType = defaultCollisionType = CollisionType.passive;
    return super.onLoad();
  }
}
