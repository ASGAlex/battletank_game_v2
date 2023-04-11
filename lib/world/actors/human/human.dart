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
import 'package:tank_game/world/core/behaviors/effects/shadow_behavior.dart';
import 'package:tank_game/world/core/behaviors/interaction/interactable.dart';
import 'package:tank_game/world/core/behaviors/movement/movement_forward_collision.dart';
import 'package:tank_game/world/environment/spawn/spawn_entity.dart';

class HumanEntity extends SpriteAnimationGroupComponent<ActorCoreState>
    with
        CollisionCallbacks,
        EntityMixin,
        HasGridSupport,
        HasTrailSupport,
        ActorMixin,
        Interactor,
        AnimationGroupCoreStateListenerMixin,
        HasGameReference<MyGame> {
  HumanEntity() {
    data = AttackerData();
    data.speed = 10;
    (data as AttackerData)
      ..secondsBetweenFire = 0.2
      ..ammoHealth = 0.001
      ..ammoRange = 200;
  }

  @override
  FutureOr<void> onLoad() {
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

    add(MovementForwardCollisionBehavior(
      hitboxRelativePosition: Vector2(1, -2),
      hitboxSize: Vector2(12, 2),
      typeCheck: (other) {
        if (other.parent is SpawnEntity || other.parent is BulletEntity
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
    add(HumanStepTrailBehavior());
    add(FireBulletBehavior(
      bulletsRootComponent: game.world.bulletLayer,
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
      bulletOffset: Vector2(4, -2),
    ));
    add(ShadowBehavior());
    super.onLoad();
    boundingBox.collisionType = CollisionType.active;
  }

  @override
  void onCoreStateChanged() {
    super.onCoreStateChanged();
    if (data.coreState == ActorCoreState.wreck) {
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