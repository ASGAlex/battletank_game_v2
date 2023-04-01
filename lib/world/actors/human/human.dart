import 'dart:async';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame_behaviors/flame_behaviors.dart';
import 'package:flame_spatial_grid/flame_spatial_grid.dart';
import 'package:tank_game/world/core/actor.dart';
import 'package:tank_game/world/core/behaviors/animation/animation_behavior.dart';
import 'package:tank_game/world/core/behaviors/animation/animation_group_behavior.dart';
import 'package:tank_game/world/core/behaviors/attacks/range_attack_behavior.dart';
import 'package:tank_game/world/core/behaviors/movement/movement_behavior.dart';
import 'package:tank_game/world/core/behaviors/movement/movement_forward_collision.dart';
import 'package:tank_game/world/environment/spawn/spawn_entity.dart';

class HumanEntity extends SpriteAnimationGroupComponent<ActorCoreState>
    with CollisionCallbacks, EntityMixin, HasGridSupport, ActorMixin {
  HumanEntity() {
    data.speed = 10;
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
    }));
    current = ActorCoreState.idle;

    add(MovementForwardCollisionBehavior(
      hitboxRelativePosition: Vector2(1, -2),
      hitboxSize: Vector2(12, 2),
      typeCheck: (other) {
        if (other is MovementHitbox || other.parent is SpawnEntity
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
    add(MovementBehavior());
    add(RangeAttackBehavior());
    super.onLoad();
  }

  @override
  void onCoreStateChanged() {
    current = data.coreState;
  }
}
