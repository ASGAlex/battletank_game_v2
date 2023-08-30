import 'dart:async';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/experimental.dart';
import 'package:flame_behaviors/flame_behaviors.dart' hide CollisionBehavior;
import 'package:tank_game/game.dart';
import 'package:tank_game/services/audio/sfx/sfx.dart';
import 'package:tank_game/world/actors/tank/tank.dart';
import 'package:tank_game/world/core/actor.dart';
import 'package:tank_game/world/core/behaviors/attacks/killable_behavior.dart';
import 'package:tank_game/world/core/behaviors/collision_behavior.dart';
import 'package:tank_game/world/core/scenario/components/scenario_event_emitter_mixin.dart';
import 'package:tank_game/world/core/scenario/scripts/event.dart';
import 'package:tank_game/world/environment/buildings/brick.dart';
import 'package:tank_game/world/environment/buildings/heavy_brick.dart';

class AttackBehavior extends CollisionBehavior
    with HasGameReference<MyGame>, ScenarioEventEmitter {
  AttackBehavior(this.audio);

  var _hitTarget = false;
  final Map<String, Sfx> audio;
  bool emitEventOnHit = false;

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
        if (emitEventOnHit && other is ActorMixin) {
          scenarioEvent(AttackHitTargetEvent(emitter: parent, target: other));
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
      audio['strong']?.play();
    } else if (target is BrickEntity) {
      audio['weak']?.play();
    } else if (target is TankEntity) {
      audio['tank']?.play();
    }
  }

  void killParent() {
    parent.boundingBox.collisionType = CollisionType.inactive;
    parent.coreState = ActorCoreState.dying;
  }
}

class AttackHitTargetEvent extends ScenarioEvent {
  const AttackHitTargetEvent(
      {required super.emitter, required ActorMixin target})
      : super(name: 'AttackHitTargetEvent', data: target);
}
