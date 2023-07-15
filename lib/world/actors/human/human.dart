import 'dart:async';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/experimental.dart';
import 'package:flame_behaviors/flame_behaviors.dart';
import 'package:flame_spatial_grid/flame_spatial_grid.dart';
import 'package:tank_game/game.dart';
import 'package:tank_game/world/actors/human/human_step_trail.dart';
import 'package:tank_game/world/core/actor.dart';
import 'package:tank_game/world/core/behaviors/animation/animation_behavior.dart';
import 'package:tank_game/world/core/behaviors/animation/animation_group_behavior.dart';
import 'package:tank_game/world/core/behaviors/attacks/attacker_data.dart';
import 'package:tank_game/world/core/behaviors/attacks/bullet.dart';
import 'package:tank_game/world/core/behaviors/attacks/killable_behavior.dart';
import 'package:tank_game/world/core/behaviors/detection/detectable_behavior.dart';
import 'package:tank_game/world/core/behaviors/detection/detector_behavior.dart';
import 'package:tank_game/world/core/behaviors/effects/shadow_behavior.dart';
import 'package:tank_game/world/core/behaviors/interaction/interactable.dart';
import 'package:tank_game/world/core/behaviors/movement/movement_forward_collision.dart';
import 'package:tank_game/world/core/direction.dart';
import 'package:tank_game/world/core/faction.dart';
import 'package:tank_game/world/core/scenario/components/scenario_event_emitter_mixin.dart';
import 'package:tank_game/world/environment/brick/brick.dart';
import 'package:tank_game/world/environment/brick/heavy_brick.dart';
import 'package:tank_game/world/environment/water/water.dart';

class HumanEntity extends SpriteAnimationGroupComponent<ActorCoreState>
    with
        CollisionCallbacks,
        EntityMixin,
        HasGridSupport,
        HasTrailSupport,
        ActorMixin,
        ActorWithSeparateBody,
        Interactor,
        AnimationGroupCoreStateListenerMixin,
        HasGameReference<MyGame>,
        ScenarioEventEmitter {
  HumanEntity() {
    data = AttackerData();
    data.speed = 20;
    data.zoom = 5;
    (data as AttackerData)
      ..secondsBetweenFire = 0.2
      ..ammoHealth = 0.25
      ..ammoRange = 15;

    bodyHitbox.onCollisionStartCallback = onWeakBodyCollision;
    bodyHitbox.collisionType = CollisionType.passive;
  }

  @override
  final bodyHitbox = WeakBodyHitbox();

  void onWeakBodyCollision(Set<Vector2> intersectionPoints, ShapeHitbox other) {
    if (coreState == ActorCoreState.idle || coreState == ActorCoreState.move) {
      try {
        final killable = findBehavior<KillableBehavior>();
        killable.killParent();
      } catch (_) {}
    }
  }

  @override
  FutureOr<void> onLoad() {
    super.onLoad();
    anchor = Anchor.center;
    add(AnimationGroupBehavior<ActorCoreState>(animationConfigs: {
      ActorCoreState.idle: const AnimationConfig(
          tileset: 'tank', tileType: 'human_idle', loop: true),
      ActorCoreState.move:
          const AnimationConfig(tileset: 'tank', tileType: 'human', loop: true),
      ActorCoreState.dying: const AnimationConfig(
          tileset: 'tank', tileType: 'human_wreck', loop: true),
      ActorCoreState.wreck: const AnimationConfig(
          tileset: 'tank', tileType: 'human_wreck', loop: true),
      ActorCoreState.removing: const AnimationConfig(
          tileset: 'tank', tileType: 'human_wreck', loop: true),
    }));
    current = ActorCoreState.idle;
    autoResize = false;
    scale = Vector2.all(0.5);

    final movementForward = MovementForwardCollisionBehavior(
      hitboxRelativePosition: Vector2(0, -2),
      hitboxSize: Vector2(14, 2),
    );
    add(movementForward);
    add(HumanStepTrailBehavior());
    add(FireBulletBehavior(
      scale: 0.4,
      bulletsRootComponent: game.world.bulletLayer,
      speedPenalty: 40,
      speedPenaltyDuration: 1,
      animationFactory: () => {
        ActorCoreState.idle: const AnimationConfig(
            tileset: 'bullet', tileType: 'bullet', loop: true),
        ActorCoreState.move: const AnimationConfig(
            tileset: 'bullet', tileType: 'bullet', loop: true),
        ActorCoreState.dying: const AnimationConfig(
            tileset: 'boom', tileType: 'boom', loop: true),
        ActorCoreState.wreck: const AnimationConfig(
            tileset: 'boom', tileType: 'crater', loop: true),
      },
      bulletOffset: Vector2(2.5, -2),
    ));
    add(ShadowBehavior());
    add(KillableBehavior(onBeingKilled: (attackedBy, killable) {
      if (attackedBy != null) {
        scenarioEvent(EventKilled(
          name: 'humanKilled',
          emitter: killable,
          data: attackedBy,
        ));
      }
    }));
    if (data.factions.contains(Faction(name: 'Player'))) {
      add(DetectableBehavior(detectionType: DetectionType.audial));
    }
    boundingBox.collisionType = CollisionType.active;
    boundingBox.parentSpeedGetter = _getCurrentSpeed;
    bodyHitbox.parentSpeedGetter = _getCurrentSpeed;
  }

  double _getCurrentSpeed() {
    if (coreState == ActorCoreState.move) {
      return data.speed;
    }
    return 0;
  }

  @override
  void onCoreStateChanged() {
    super.onCoreStateChanged();
    if (data.coreState == ActorCoreState.wreck ||
        data.coreState == ActorCoreState.removing ||
        data.coreState == ActorCoreState.dying) {
      lookDirection = DirectionExtended.up;
      resetCamera();
      try {
        final shadow = findBehavior<ShadowBehavior>();
        shadow.removeFromParent();
      } catch (_) {}
      boundingBox.collisionType = CollisionType.inactive;
      final layer = sgGame.layersManager.addComponent(
        component: this,
        layerType: MapLayerType.trail,
        layerName: 'trail',
        optimizeCollisions: false,
      );
      if (layer is CellTrailLayer) {
        layer.fadeOutConfig = (sgGame as MyGame).world.fadeOutConfig;
      }
    }
  }
}

class WeakBodyHitbox extends BodyHitbox {
  @override
  bool pureTypeCheck(Type other) {
    if (other == BodyHitbox) {
      return true;
    }
    return false;
  }

  @override
  bool onComponentTypeCheck(PositionComponent other) {
    if (other.parent is BrickEntity ||
        other.parent is WaterEntity ||
        other.parent is HeavyBrickEntity) {
      return false;
    }

    return true;
  }
}
