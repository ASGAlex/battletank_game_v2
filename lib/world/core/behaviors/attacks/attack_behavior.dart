import 'dart:async';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flame_behaviors/flame_behaviors.dart' hide CollisionBehavior;
import 'package:tank_game/world/actors/tank/tank.dart';
import 'package:tank_game/world/core/actor.dart';
import 'package:tank_game/world/core/behaviors/attacks/killable_behavior.dart';
import 'package:tank_game/world/core/behaviors/collision_behavior.dart';
import 'package:tank_game/world/environment/brick/brick.dart';
import 'package:tank_game/world/environment/brick/heavy_brick.dart';

class AttackBehavior extends CollisionBehavior {
  AttackBehavior(this.audio);

  var _hitTarget = false;
  final Map<String, AudioPool> audio;

  @override
  FutureOr<void> onLoad() {
    if (parent is SpriteAnimationGroupComponent) {
      final animatedParent = (parent as SpriteAnimationGroupComponent);
      final dyingAnimation = animatedParent.animations?[ActorCoreState.dying];
      final dyingAnimationTicker =
          animatedParent.animationTickers?[ActorCoreState.dying];
      if (dyingAnimation != null && dyingAnimationTicker != null) {
        dyingAnimation.loop = false;
        dyingAnimationTicker.onComplete = () {
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
        bool killed = killableBehavior.applyAttack(this);
        if (parent.data.health <= 0) {
          killParent();
          if (!killed) {
            _playSound(other as EntityMixin);
          }
        }
      } catch (e) {}
    } else {
      killParent();
    }
    _hitTarget = true;
    super.onCollision(intersectionPoints, other);
  }

  void _playSound(EntityMixin target) {
    if (target is HeavyBrickEntity) {
      audio['strong']?.start();
    } else if (target is BrickEntity) {
      audio['weak']?.start();
    } else if (target is TankEntity) {
      audio['tank']?.start();
    }
  }

  void killParent() {
    parent.boundingBox.collisionType = CollisionType.inactive;
    parent.coreState = ActorCoreState.dying;
  }
}
