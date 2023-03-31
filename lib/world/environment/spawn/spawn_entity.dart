import 'dart:async';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame_behaviors/flame_behaviors.dart';
import 'package:flame_spatial_grid/flame_spatial_grid.dart';
import 'package:tank_game/world/core/actor.dart';
import 'package:tank_game/world/core/behaviors/animation/animation_behavior.dart';
import 'package:tank_game/world/core/visibility_mixin.dart';
import 'package:tank_game/world/environment/spawn/spawn_behavior.dart';

import 'spawn_data.dart';

class SpawnEntity extends SpriteAnimationComponent
    with
        CollisionCallbacks,
        EntityMixin,
        HasGridSupport,
        VisibilityMixin,
        ActorMixin {
  SpawnEntity({required this.rootComponent}) {
    data = SpawnData();
  }

  SpawnData get spawnData => data as SpawnData;

  final Component rootComponent;
  final spawnBehavior = SpawnBehavior();

  @override
  FutureOr<void> onLoad() async {
    add(AnimationBehavior(
      config: const AnimationConfig(
        tileset: 'spawn',
        tileType: 'spawn',
        reversedLoop: true,
      ),
    ));
    add(spawnBehavior);
    super.onLoad();
  }

  @override
  void onCalculateDistance(
      Component other, double distanceX, double distanceY) {
    spawnBehavior.onCalculateDistance(other, distanceX, distanceY);
  }
}
