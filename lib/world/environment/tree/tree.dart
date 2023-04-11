import 'dart:async';
import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame_behaviors/flame_behaviors.dart';
import 'package:flame_spatial_grid/flame_spatial_grid.dart';
import 'package:tank_game/world/core/actor.dart';
import 'package:tank_game/world/core/behaviors/effects/shadow_behavior.dart';
import 'package:tank_game/world/world.dart';

class TreeEntity extends SpriteComponent
    with
        CollisionCallbacks,
        EntityMixin,
        HasGridSupport,
        HasTrailSupport,
        ActorMixin {
  TreeEntity({required super.sprite, super.position, super.size})
      : super(priority: RenderPriority.tree.priority) {
    boundingBox.collisionType =
        boundingBox.defaultCollisionType = CollisionType.passive;
    boundingBox.isSolid = true;
    paint.filterQuality = FilterQuality.none;
    paint.isAntiAlias = false;
  }

  @override
  FutureOr<void> onLoad() {
    add(ShadowBehavior(shadowKey: 'tree'));
    super.onLoad();
    anchor = Anchor.topLeft;
  }
}
