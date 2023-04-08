import 'dart:async';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame_behaviors/flame_behaviors.dart';
import 'package:flame_spatial_grid/flame_spatial_grid.dart';
import 'package:flame_tiled/flame_tiled.dart';
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

  factory SpawnEntity.fromProperties({
    required Component rootComponent,
    required CustomProperties properties,
  }) {
    final spawn = SpawnEntity(rootComponent: rootComponent);
    for (final property in properties) {
      switch (property.name) {
        case 'cooldown_seconds':
          spawn.spawnData.secondsBetweenSpawns =
              double.parse(property.value.toString());
          break;
        case 'tanks_inside':
          spawn.spawnData.capacity = int.parse(property.value.toString());
          break;
        case 'trigger_distance':
          final distance = double.parse(property.value.toString());
          spawn.spawnData.triggerDistanceSquared = distance * distance;
          break;
        case 'tank_type':
          spawn.spawnData.typeOfTank = property.value.toString();
          break;
      }
    }
    return spawn;
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
