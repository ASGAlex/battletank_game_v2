import 'dart:async';
import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame_spatial_grid/flame_spatial_grid.dart';
import 'package:tank_game/packages/behaviors/lib/flame_behaviors.dart';
import 'package:tank_game/world/core/actor.dart';
import 'package:tank_game/world/core/behaviors/attacks/killable_behavior.dart';
import 'package:tank_game/world/environment/ground/speed_up_by_asphalt_behavior.dart';
import 'package:tank_game/world/world.dart';

class AsphaltEntity extends SpriteComponent
    with
        CollisionCallbacks,
        EntityMixin,
        HasGridSupport,
        ComponentWithUpdate,
        ActorMixin,
        ActorWithBoundingBody,
        UpdateOnDemand {
  AsphaltEntity({
    required super.sprite,
    super.position,
    super.size,
  }) : super(priority: RenderPriority.player.priority) {
    paint.filterQuality = FilterQuality.none;
    noVisibleChildren = true;
    paint.isAntiAlias = false;
  }

  @override
  BoundingHitboxFactory get boundingHitboxFactory => () => AsphaltHitbox();

  @override
  FutureOr<void> onLoad() {
    add(KillableBehavior(customApplyAttack: applyAttack));
    super.onLoad();
    boundingBox.collisionType =
        boundingBox.defaultCollisionType = CollisionType.passive;
    boundingBox.isSolid = true;
  }

  bool applyAttack(ActorMixin attackedBy, ActorMixin killable) {
    if (attackedBy.data.coreState == ActorCoreState.move) {
      data.health -= attackedBy.data.health;
      attackedBy.data.health = 0;
      removeFromParent();
    }
    return true;
  }

  @override
  bool onComponentTypeCheck(PositionComponent other) {
    if (other is! SpeedUpByAsphaltOptimizedCheckerMixin) {
      return false;
    }
    if (other.canBeSpeedUpByAsphalt) {
      return true;
    }
    return true;
  }

  @override
  void onCollisionStart(
      Set<Vector2> intersectionPoints, PositionComponent other) {
    if (other is SpeedUpByAsphaltOptimizedCheckerMixin &&
        other.speedUpByAsphaltBehavior != null) {
      other.speedUpByAsphaltBehavior!.collisionsWithAsphalt++;
    }
    super.onCollisionStart(intersectionPoints, other);
  }

  @override
  void onCollisionEnd(PositionComponent other) {
    if (other is SpeedUpByAsphaltOptimizedCheckerMixin &&
        other.speedUpByAsphaltBehavior != null) {
      if (other.speedUpByAsphaltBehavior!.collisionsWithAsphalt > 0) {
        other.speedUpByAsphaltBehavior!.collisionsWithAsphalt--;
      }
    }
    super.onCollisionEnd(other);
  }
}

class AsphaltHitbox extends ActorDefaultHitbox {
  @override
  FutureOr<void> onLoad() {
    collisionType = defaultCollisionType = CollisionType.passive;
    return super.onLoad();
  }
}
