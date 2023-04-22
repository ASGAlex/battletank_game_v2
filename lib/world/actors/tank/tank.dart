import 'dart:async';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/experimental.dart';
import 'package:flame_behaviors/flame_behaviors.dart';
import 'package:flame_spatial_grid/flame_spatial_grid.dart';
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
import 'package:tank_game/world/core/behaviors/interaction/interaction_set_player.dart';
import 'package:tank_game/world/core/behaviors/movement/movement_forward_collision.dart';
import 'package:tank_game/world/core/faction.dart';
import 'package:tank_game/world/environment/spawn/spawn_entity.dart';
import 'package:tank_game/world/environment/tree/tree.dart';

class TankEntity extends SpriteAnimationGroupComponent<ActorCoreState>
    with
        CollisionCallbacks,
        EntityMixin,
        HasGridSupport,
        HasTrailSupport,
        ActorMixin,
        AnimationGroupCoreStateListenerMixin,
        HasGameReference<MyGame> {
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
  }

  final String _tileType;
  late final SmokeBehavior smoke;

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
      hitboxRelativePosition: Vector2(1, -2),
      hitboxSize: Vector2(12, 2),
      typeCheck: (other) {
        if (other.parent is SpawnEntity ||
                other.parent is BulletEntity ||
                other.parent is TreeEntity
            // other is MovementSideHitbox ||
            // other.parent is Spawn ||
            // other.parent is Bullet ||
            // other.parent is Tree) {
            ) {
          return false;
        }
        return true;
      },
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
    add(KillableBehavior());
    add(InteractionSetPlayer());
    add(TankStepTrailBehavior());
    smoke = SmokeBehavior(game.world.skyLayer);
    add(smoke);
    super.onLoad();
    add(ShadowBehavior());
    // if enemy
    if (!data.factions.contains(Faction(name: 'Player'))) {
      add(ColorFilterBehavior());
      add(DetectorBehavior(
          distance: 200,
          detectionType: DetectionType.visual,
          factionsToDetect: [Faction(name: 'Player')]));
    } else {
      add(DetectableBehavior(detectionType: DetectionType.visual));
    }
    boundingBox.collisionType = CollisionType.active;
  }

  @override
  void onCoreStateChanged() {
    super.onCoreStateChanged();
    if (data.coreState == ActorCoreState.removing) {
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
