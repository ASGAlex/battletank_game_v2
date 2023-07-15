import 'dart:async';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/experimental.dart';
import 'package:flame/extensions.dart';
import 'package:flame_behaviors/flame_behaviors.dart';
import 'package:flame_spatial_grid/flame_spatial_grid.dart';
import 'package:flutter/material.dart';
import 'package:tank_game/game.dart';
import 'package:tank_game/world/actors/tank/tank_step_trail.dart';
import 'package:tank_game/world/core/actor.dart';
import 'package:tank_game/world/core/behaviors/animation/animation_behavior.dart';
import 'package:tank_game/world/core/behaviors/animation/animation_group_behavior.dart';
import 'package:tank_game/world/core/behaviors/attacks/attacker_data.dart';
import 'package:tank_game/world/core/behaviors/attacks/bullet.dart';
import 'package:tank_game/world/core/behaviors/attacks/killable_behavior.dart';
import 'package:tank_game/world/core/behaviors/detection/detectable_behavior.dart';
import 'package:tank_game/world/core/behaviors/detection/detector_behavior.dart';
import 'package:tank_game/world/core/behaviors/effects/color_filter_behavior.dart';
import 'package:tank_game/world/core/behaviors/effects/shadow_behavior.dart';
import 'package:tank_game/world/core/behaviors/effects/smoke_behavior.dart';
import 'package:tank_game/world/core/behaviors/effects/smoke_start_moving_behavior.dart';
import 'package:tank_game/world/core/behaviors/interaction/interaction_set_player.dart';
import 'package:tank_game/world/core/behaviors/movement/movement_factory_mixin.dart';
import 'package:tank_game/world/core/behaviors/movement/movement_forward_collision.dart';
import 'package:tank_game/world/core/behaviors/movement/random_movement_behavior.dart';
import 'package:tank_game/world/core/behaviors/movement/speed_penalty.dart';
import 'package:tank_game/world/core/behaviors/movement/targeted_movement_behavior.dart';
import 'package:tank_game/world/core/behaviors/player_controlled_behavior.dart';
import 'package:tank_game/world/core/faction.dart';
import 'package:tank_game/world/core/scenario/components/area_collision_high_precision.dart';
import 'package:tank_game/world/core/scenario/components/scenario_event_emitter_mixin.dart';
import 'package:tank_game/world/environment/ground/slowdown_by_sand_behavior.dart';
import 'package:tank_game/world/environment/tree/hide_in_trees_behavior.dart';

class TankEntity extends SpriteAnimationGroupComponent<ActorCoreState>
    with
        CollisionCallbacks,
        EntityMixin,
        HasGridSupport,
        HasTrailSupport,
        ActorMixin,
        ActorWithSeparateBody,
        AnimationGroupCoreStateListenerMixin,
        MovementFactoryMixin,
        HasGameReference<MyGame>,
        CollisionPrecisionMixin,
        ScenarioEventEmitter {
  static const _tileset = 'tank';

  factory TankEntity(String type, TilesetManager tilesetManager) {
    final entity = TankEntity.generic(type);

    final tileCache = tilesetManager.getTile(_tileset, type);
    if (tileCache == null) {
      return entity;
    }
    final attackerData = (entity.data as AttackerData);

    for (final property in tileCache.properties) {
      switch (property.name) {
        case 'damage':
          attackerData.ammoHealth = double.parse(property.value.toString());
          break;

        case 'fireDelay':
          attackerData.secondsBetweenFire =
              double.parse(property.value.toString()) / 1000;
          break;

        case 'health':
          attackerData.health = double.parse(property.value.toString());
          break;

        case 'speed':
          attackerData.speed = double.parse(property.value.toString());
          break;

        case 'zoom':
          attackerData.zoom = double.parse(property.value.toString());
          break;

        case 'cameraSpeed':
          attackerData.speed = double.parse(property.value.toString());
          break;
      }
    }

    return entity;
  }

  TankEntity.generic(this._tileType) {
    data = AttackerData();
    data.speed = 50;
    (data as AttackerData)
      ..secondsBetweenFire = 1
      ..ammoHealth = 1
      ..ammoRange = 200;

    boundingBox.collisionType =
        boundingBox.defaultCollisionType = CollisionType.inactive;
  }

  final String _tileType;
  late final SmokeBehavior smoke;
  late final SmokeStartMovingBehavior smokeStartMoving;

  @override
  BoundingHitboxFactory get boundingHitboxFactory => () => TankBoundingHitbox();

  @override
  FutureOr<void> onLoad() {
    anchor = Anchor.center;
    add(AnimationGroupBehavior<ActorCoreState>(animationConfigs: {
      ActorCoreState.idle: AnimationConfig(
          tileset: _tileset, tileType: '${_tileType}_idle', loop: true),
      ActorCoreState.move:
          AnimationConfig(tileset: _tileset, tileType: _tileType, loop: true),
      ActorCoreState.dying: AnimationConfig(
          tileset: 'boom',
          tileType: 'boom',
          onComplete: () {
            coreState = ActorCoreState.wreck;
            smoke.isEnabled = true;
          }),
      ActorCoreState.wreck: AnimationConfig(
          tileset: _tileset, tileType: '${_tileType}_wreck', loop: true),
      ActorCoreState.removing: AnimationConfig(
          tileset: _tileset, tileType: '${_tileType}_wreck', loop: true),
    }));
    current = ActorCoreState.idle;

    add(MovementForwardCollisionBehavior(
      hitboxRelativePosition: Vector2(1, 1),
      hitboxSize: Vector2(12, 2),
    ));
    add(FireBulletBehavior(
      bulletsRootComponent: game.world.bulletLayer,
      haloRadius: size.x / 2,
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
      bulletOffset: Vector2(0, 0),
    ));
    add(KillableBehavior(customApplyAttack: (attackedBy, killable) {
      if (attackedBy is BulletEntity) {
        final penalty = (attackedBy.data as BulletData).speedPenalty;
        final duration = (attackedBy.data as BulletData).speedPenaltyDuration;
        killable
            .add(SpeedPenaltyBehavior(penalty: penalty, duration: duration));

        if (hasBehavior<PlayerControlledBehavior>()) {
          game.colorFilter?.animateTo(Colors.red,
              blendMode: BlendMode.colorBurn,
              duration: const Duration(milliseconds: 250), onFinish: () {
            game.colorFilter?.config.color = null;
          });
        }
      }
      return false;
    }, onBeingKilled: (attackedBy, killable) {
      if (attackedBy != null) {
        scenarioEvent(EventKilled(
          name: 'tankKilled',
          emitter: killable,
          data: attackedBy,
        ));
      }
    }));
    add(SlowDownBySandBehavior());
    add(InteractionSetPlayer());
    add(TankStepTrailBehavior());

    smokeStartMoving = SmokeStartMovingBehavior(game.world.skyLayer);
    add(smokeStartMoving);

    smoke = SmokeBehavior(game.world.skyLayer);
    add(smoke);

    super.onLoad();
    add(ShadowBehavior());
    if (data.factions.contains(Faction(name: 'Player'))) {
      add(DetectableBehavior(detectionType: DetectionType.audial));
      add(DetectableBehavior(detectionType: DetectionType.visual));
      add(HideInTreesBehavior());
    } else {
      add(ColorFilterBehavior());
      if (data.factions.contains(Faction(name: 'Enemy'))) {
        add(createRandomMovement());
        add(DetectorBehavior(
            distance: 300,
            detectionType: DetectionType.audial,
            factionsToDetect: [Faction(name: 'Player')],
            maxMomentum: 120,
            // pauseBetweenChecks: 5,
            onDetection: (player, x, y) {
              game.enemyAmbientVolume.onTankDetectedPlayer(x, y);
              if (player is TankEntity) {
                final forceIdle = _targetedMovementBehavior?.forceIdle ?? false;
                if (!forceIdle) {
                  coreState = ActorCoreState.move;
                }
                if (_targetedMovementBehavior == null) {
                  _randomMovementBehavior?.pauseBehavior = false;
                }
              }
            }));

        add(DetectorBehavior(
            distance: 150,
            detectionType: DetectionType.visual,
            factionsToDetect: [Faction(name: 'Player')],
            maxMomentum: 0,
            pauseBetweenChecks: 2,
            onDetection: _trackDetectedTarget,
            onNothingDetected: () {
              if (_targetedMovementBehavior != null) {
                _targetedMovementBehavior?.removeFromParent();
                _targetedMovementBehavior = null;
              }
            }));
      }
      setCollisionHighPrecision(false);
    }
  }

  @override
  List<BoundingHitbox> setCollisionHighPrecision(bool highPrecision,
      [List<String> tags = const []]) {
    final hitboxes = super.setCollisionHighPrecision(highPrecision, tags);
    if (!highPrecision && !hasBehavior<PlayerControlledBehavior>()) {
      for (final hitbox in hitboxes) {
        hitbox.groupCollisionsTags.addAll(['Water', 'Brick', 'HeavyBrick']);
      }
    }
    return hitboxes;
  }

  TargetedMovementBehavior? _targetedMovementBehavior;
  RandomMovementBehavior? _randomMovementBehavior;

  void _trackDetectedTarget(
      ActorMixin target, double distanceX, double distanceY) {
    final forceIdle = _targetedMovementBehavior?.forceIdle ?? false;
    if (!forceIdle) {
      coreState = ActorCoreState.move;
    }

    if (_targetedMovementBehavior == null) {
      _targetedMovementBehavior = createTargetedMovement(
        targetPosition: target.data.positionCenter,
        targetSize: target.data.size,
      );
      add(_targetedMovementBehavior!);
    } else {
      _targetedMovementBehavior!.targetPosition
          .setFrom(target.data.positionCenter);
    }
  }

  @override
  void onCoreStateChanged() {
    super.onCoreStateChanged();
    if (data.coreState == ActorCoreState.move) {
      smokeStartMoving.isEnabled = true;
    } else if (data.coreState == ActorCoreState.dying) {
      resetCamera();
      try {
        findBehaviors<RandomMovementBehavior>().forEach((element) {
          element.removeFromParent();
        });
      } catch (_) {}
      try {
        findBehaviors<ColorFilterBehavior>().forEach((element) {
          element.removeFromParent();
        });
      } catch (_) {}
      try {
        findBehaviors<TankStepTrailBehavior>().forEach((element) {
          element.removeFromParent();
        });
      } catch (_) {}
      try {
        findBehaviors<DetectableBehavior>().forEach((element) {
          element.removeFromParent();
        });
      } catch (_) {}
      try {
        findBehaviors<DetectorBehavior>().forEach((element) {
          element.removeFromParent();
        });
      } catch (_) {}
      try {
        findBehaviors<MovementForwardCollisionBehavior>().forEach((element) {
          element.removeFromParent();
        });
      } catch (_) {}
      try {
        findBehaviors<InteractionSetPlayer>().forEach((element) {
          element.removeFromParent();
        });
      } catch (_) {}
      try {
        findBehaviors<FireBulletBehavior>().forEach((element) {
          element.removeFromParent();
        });
      } catch (_) {}
      try {
        findBehaviors<TargetedMovementBehavior>().forEach((element) {
          element.removeFromParent();
        });
        if (_targetedMovementBehavior != null) {
          _targetedMovementBehavior?.removeFromParent();
          _targetedMovementBehavior = null;
        }
      } catch (_) {}
    } else if (data.coreState == ActorCoreState.removing) {
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

  @override
  RandomMovementBehavior createRandomMovement() => RandomMovementBehavior(
        maxDirectionDistance: 300,
        minDirectionDistance: 50,
      );

  @override
  TargetedMovementBehavior createTargetedMovement(
          {required Vector2 targetPosition, required Vector2 targetSize}) =>
      TargetedMovementBehavior(
        targetPosition: targetPosition,
        targetSize: targetSize,
        maxRandomMovementTime: 15,
        onShouldFire: () {
          findBehavior<FireBulletBehavior>().tryFire();
        },
        stopAtTarget: true,
      );

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    // if (_targetedMovementBehavior != null) {
    //   canvas.drawRect(
    //       Rect.fromPoints(Offset.zero, size.toOffset()),
    //       Paint()
    //         ..color = Colors.red
    //         ..style = PaintingStyle.stroke
    //         ..strokeWidth = 3);
    //   final tp = _targetedMovementBehavior!.targetPosition;
    //   final local = transform.globalToLocal(tp);
    //   canvas.drawLine(
    //       Offset.zero, local.toOffset(), Paint()..color = Colors.red);
    // }
  }
}

class TankBoundingHitbox extends BodyHitbox {
  TankBoundingHitbox() {
    triggersParentCollision = false;
  }
}
