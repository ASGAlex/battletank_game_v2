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
        ComponentWithUpdate,
        ActorMixin,
        ActorWithBoundingBody,
        UpdateOnDemand {
  BrickEntity({
    required super.sprite,
    super.position,
    super.size,
    this.resizeOnHit = true,
  }) : super(priority: RenderPriority.player.priority) {
    paint.filterQuality = FilterQuality.none;
    noVisibleChildren = true;
    paint.isAntiAlias = false;
  }

  final Vector2 _halfSize = Vector2.zero();
  final bool resizeOnHit;
  late final double _halfHealth;
  double _accumulatedDamage = 0;

  @override
  FutureOr<void> onLoad() {
    add(ShadowBehavior(shadowKey: 'brick'));
    add(KillableBehavior(customApplyAttack: applyAttack));
    super.onLoad();
    boundingBox.collisionType =
        boundingBox.defaultCollisionType = CollisionType.passive;
    boundingBox.isSolid = true;
    _halfSize.setFrom(size / 2);
    _halfHealth = data.health / 2;
  }

  void _resizeOnHit(ActorMixin attackedBy) {
    final attackerData = attackedBy.data;
    switch (attackerData.lookDirection) {
      case DirectionExtended.right:
        size.x -= _halfSize.x;
        position.x += _halfSize.x;
        break;
      case DirectionExtended.up:
        size.y -= _halfSize.y;
        break;
      case DirectionExtended.left:
        size.x -= _halfSize.x;
        break;
      case DirectionExtended.down:
        size.y -= _halfSize.y;
        position.y += _halfSize.y;
        break;
    }
    if (size.x <= 0 || size.y <= 0) {
      removeFromParent();
    }
  }

  bool applyAttack(ActorMixin attackedBy, ActorMixin killable) {
    if (attackedBy.data.coreState == ActorCoreState.move) {
      data.health -= attackedBy.data.health;
      if (resizeOnHit) {
        _accumulatedDamage += attackedBy.data.health;
        if (_accumulatedDamage >= _halfHealth) {
          _resizeOnHit(attackedBy);
          _accumulatedDamage = 0;
        }
        isUpdateNeeded = true;
        if (parent is CellLayer) {
          (parent as CellLayer).isUpdateNeeded = true;
        }
      } else if (data.health <= 0) {
        removeFromParent();
      }
      attackedBy.data.health = 0;
    }
    return true;
  }
}
