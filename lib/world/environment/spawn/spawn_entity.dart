import 'dart:async';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame_behaviors/flame_behaviors.dart';
import 'package:flame_spatial_grid/flame_spatial_grid.dart';
import 'package:flame_tiled/flame_tiled.dart';
import 'package:tank_game/game.dart';
import 'package:tank_game/world/actors/tank/tank.dart';
import 'package:tank_game/world/core/actor.dart';
import 'package:tank_game/world/core/behaviors/animation/animation_behavior.dart';
import 'package:tank_game/world/core/faction.dart';
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

  MyGame? game;

  factory SpawnEntity.fromContext({
    required Component rootComponent,
    required CellBuilderContext context,
    required MyGame game,
  }) {
    final tiledObject = context.tiledObject;
    if (tiledObject == null) throw 'tiledObject must be set!';

    final newSpawn = SpawnEntity.fromProperties(
        rootComponent: game.world.tankLayer, properties: tiledObject.properties)
      ..position = Vector2(context.absolutePosition.x + context.size.x / 2,
          context.absolutePosition.y + context.size.y / 2);
    newSpawn.game = game;
    newSpawn.currentCell = context.cell;
    Faction faction;
    if (tiledObject.name == 'spawn') {
      faction = Faction(name: 'Enemy');
      newSpawn.boundingBox.isDistanceCallbackEnabled = true;
      newSpawn.spawnData.triggerCallback = newSpawn.spawnCallback;
    } else {
      faction = Faction(name: 'Player');
      newSpawn.spawnData.secondsBetweenSpawns = 2;
    }
    newSpawn.spawnData.factions.add(faction);
    newSpawn.spawnData.allowedFactions.add(faction);
    return newSpawn;
  }

  void spawnCallback(SpawnEntity activeSpawn) {
    if (game != null) {
      final tank =
          TankEntity(activeSpawn.spawnData.typeOfTank, game!.tilesetManager);
      tank.currentCell = currentCell;
      tank.data.factions.addAll(activeSpawn.data.factions);
      activeSpawn.spawnBehavior.objectToSpawn = tank;

      activeSpawn.spawnData.state = SpawnState.spawning;
    }
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
    anchor = Anchor.center;
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
}
