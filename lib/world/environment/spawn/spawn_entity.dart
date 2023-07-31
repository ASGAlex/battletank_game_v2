import 'dart:async';
import 'dart:math';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/experimental.dart';
import 'package:flame_behaviors/flame_behaviors.dart';
import 'package:flame_spatial_grid/flame_spatial_grid.dart';
import 'package:flame_tiled/flame_tiled.dart';
import 'package:tank_game/game.dart';
import 'package:tank_game/world/actors/tank/tank.dart';
import 'package:tank_game/world/core/actor.dart';
import 'package:tank_game/world/core/behaviors/animation/animation_behavior.dart';
import 'package:tank_game/world/core/faction.dart';
import 'package:tank_game/world/core/scenario/components/scenario_event_emitter_mixin.dart';
import 'package:tank_game/world/core/visibility_mixin.dart';
import 'package:tank_game/world/environment/spawn/spawn_behavior.dart';

import 'spawn_data.dart';

class SpawnEntity extends SpriteAnimationComponent
    with
        CollisionCallbacks,
        EntityMixin,
        HasGridSupport,
        VisibilityMixin,
        ActorMixin,
        RestorableStateMixin<SpawnData>,
        HasGameReference<MyGame>,
        ScenarioEventEmitter {
  SpawnEntity({required this.rootComponent}) {
    data = SpawnData();
    noVisibleChildren = true;
  }

  @override
  SpawnData? get userData => spawnData;

  factory SpawnEntity.fromContext({
    required Component rootComponent,
    required TileBuilderContext context,
    required MyGame game,
  }) {
    final tiledObject = context.tiledObject;
    if (tiledObject == null) throw 'tiledObject must be set!';

    final newSpawn = SpawnEntity.fromProperties(
        rootComponent: game.world.tankLayer, properties: tiledObject.properties)
      ..position = Vector2(context.absolutePosition.x + context.size.x / 2,
          context.absolutePosition.y + context.size.y / 2);
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
    if (context.userData != null) {
      newSpawn.data = context.userData;
    }
    return newSpawn;
  }

  void spawnCallback(SpawnEntity activeSpawn) {
    final tank =
        TankEntity(activeSpawn.spawnData.typeOfTank, game.tilesetManager);
    tank.currentCell = currentCell;
    tank.data.factions.addAll(activeSpawn.data.factions);
    activeSpawn.spawnBehavior.objectToSpawn = tank;

    activeSpawn.spawnData.state = SpawnState.spawning;
  }

  factory SpawnEntity.fromProperties({
    required Component rootComponent,
    required CustomProperties properties,
  }) {
    final spawn = SpawnEntity(rootComponent: rootComponent);
    spawn.spawnData.secondsBetweenSpawns =
        properties.getValue<double>('cooldown_seconds') ?? 0.0;
    spawn.spawnData.secondsDuringSpawn =
        properties.getValue<double>('spawn_seconds') ?? 0.0;
    spawn.spawnData.capacity = properties.getValue<int>('tanks_inside') ?? 1;
    spawn.spawnData.triggerFactions.addAll(
        (properties.getValue<String>('triggerFactions') ?? '')
            .split(',')
            .map((e) => Faction(name: e)));
    final distance = properties.getValue<double>('trigger_distance') ?? 0;
    spawn.spawnData.triggerDistanceSquared = distance * distance;
    spawn.spawnData.typeOfTank =
        properties.getValue<String>('tank_type') ?? 'any';
    if (spawn.spawnData.typeOfTank == 'any' ||
        spawn.spawnData.typeOfTank.isEmpty) {
      spawn.spawnData.typeOfTank = {
            0: 'simple',
            1: 'middle',
            2: 'advanced',
            3: 'heavy',
            4: 'fast',
          }[Random().nextInt(4)] ??
          'simple';
    }
    return spawn;
  }

  SpawnData get spawnData => data as SpawnData;

  final Component rootComponent;
  final spawnBehavior = SpawnBehavior();

  @override
  BoundingHitboxFactory get boundingHitboxFactory =>
      () => SpawnBoundingHitbox();

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
    spawnBehavior.onSpawnComplete = (spawned) {
      scenarioEvent(
          EventSpawned(emitter: this, name: 'ActorSpawned', data: spawned));
    };
    super.onLoad();
  }
}

class SpawnBoundingHitbox extends BoundingHitbox {
  @override
  FutureOr<void> onLoad() {
    collisionType = defaultCollisionType = CollisionType.passive;
    return super.onLoad();
  }
}
