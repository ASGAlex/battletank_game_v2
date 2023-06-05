import 'dart:async';
import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame_behaviors/flame_behaviors.dart';
import 'package:flame_spatial_grid/flame_spatial_grid.dart';
import 'package:tank_game/world/core/actor.dart';
import 'package:tank_game/world/core/behaviors/attacks/killable_behavior.dart';
import 'package:tank_game/world/core/behaviors/effects/shadow_behavior.dart';
import 'package:tank_game/world/core/direction.dart';
import 'package:tank_game/world/world.dart';

class BrickEntity extends SpriteComponent
    with
        CollisionCallbacks,
        EntityMixin,
        HasGridSupport,
        ActorMixin,
        ActorWithBoundingBody,
        UpdateOnDemand {
  BrickEntity({
    required super.sprite,
    super.position,
    super.size,
    this.resizeOnHit = true,
  }) : super(priority: RenderPriority.player.priority) {
    boundingBox.collisionType =
        boundingBox.defaultCollisionType = CollisionType.passive;
    boundingBox.isSolid = true;
    paint.filterQuality = FilterQuality.none;
    paint.isAntiAlias = false;
  }

  ActorMixin? _attackedBy;
  final Vector2 _halfSize = Vector2.zero();
  final bool resizeOnHit;

  @override
  FutureOr<void> onLoad() {
    add(ShadowBehavior(shadowKey: 'brick'));
    add(KillableBehavior(customApplyAttack: applyAttack));
    super.onLoad();
    _halfSize.setFrom(size / 2);
  }

  @override
  void update(double dt) {
    final attackerData = _attackedBy?.data;
    if (attackerData != null) {
      switch (attackerData.lookDirection) {
        case Direction.right:
          size.x -= _halfSize.x;
          position.x += _halfSize.x;
          break;
        case Direction.up:
          size.y -= _halfSize.y;
          break;
        case Direction.left:
          size.x -= _halfSize.x;
          break;
        case Direction.down:
          size.y -= _halfSize.y;
          position.y += _halfSize.y;
          break;
      }
      if (size.x <= 0 || size.y <= 0) {
        removeFromParent();
      }
    }
    super.update(dt);
  }

  bool applyAttack(ActorMixin attackedBy, ActorMixin killable) {
    if (attackedBy.data.coreState == ActorCoreState.move) {
      _attackedBy = attackedBy;
      data.health -= attackedBy.data.health;
      attackedBy.data.health = 0;
      if (resizeOnHit) {
        isUpdateNeeded = true;
        if (parent is CellLayer) {
          (parent as CellLayer).isUpdateNeeded = true;
        }
      } else if (data.health <= 0) {
        removeFromParent();
      }
    }
    return true;
  }
}
