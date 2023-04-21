import 'dart:async';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame_behaviors/flame_behaviors.dart' hide CollisionBehavior;
import 'package:tank_game/world/core/actor.dart';
import 'package:tank_game/world/core/behaviors/attacks/killable_behavior.dart';
import 'package:tank_game/world/core/behaviors/collision_behavior.dart';

class AttackBehavior extends CollisionBehavior {
  var _hitTarget = false;

  @override
  FutureOr<void> onLoad() {
    if (parent is SpriteAnimationGroupComponent) {
      final dyingAnimation = (parent as SpriteAnimationGroupComponent)
          .animations?[ActorCoreState.dying];
      if (dyingAnimation != null) {
        dyingAnimation.loop = false;
        dyingAnimation.onComplete = () {
          if (_hitTarget) {
            parent.removeFromParent();
          } else {
            parent.coreState = ActorCoreState.wreck;
          }
        };
      }
    }

    return super.onLoad();
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    if (other is EntityMixin) {
      try {
        final killableBehavior =
            (other as EntityMixin).findBehavior<KillableBehavior>();
        killableBehavior.applyAttack(this);
        if (parent.data.health <= 0) {
          killParent();
        }
      } catch (e) {}
    } else {
      killParent();
    }
    _hitTarget = true;
    super.onCollision(intersectionPoints, other);
  }

  void killParent() {
    parent.boundingBox.collisionType = CollisionType.inactive;
    parent.coreState = ActorCoreState.dying;
  }
}
