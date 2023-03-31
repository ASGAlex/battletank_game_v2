import 'package:flame/game.dart';
import 'package:flame_spatial_grid/flame_spatial_grid.dart';
import 'package:flame_tiled/flame_tiled.dart';
import 'package:tank_game/game.dart';
import 'package:tank_game/world/core/faction.dart';
import 'package:tank_game/world/environment/spawn.dart';
import 'package:tank_game/world/environment/spawn/spawn_entity.dart';
import 'package:tank_game/world/environment/spawn/spawn_manager.dart';
import 'package:tank_game/world/environment/tree.dart';
import 'package:tank_game/world/world.dart';

import 'environment/brick.dart';
import 'environment/heavy_brick.dart';
import 'environment/target.dart';
import 'environment/water.dart';
import 'tank/core/tank_type_controller.dart';

class GameMapLoader extends TiledMapLoader {
  GameMapLoader(String fileName) {
    this.fileName = fileName;
  }

  Vector2 cameraInitialPosition = Vector2.zero();

  @override
  TileBuilderFunction? get cellPostBuilder => null;

  @override
  Vector2 get destTileSize => Vector2.all(8);

  @override
  TileBuilderFunction? get notFoundBuilder => groundBuilder;

  @override
  Map<String, TileBuilderFunction>? get tileBuilders => {
        'tree': onBuildTree,
        'water': onBuildWater,
        'brick': onBuildBrick,
        'heavy_brick': onBuildHeavyBrick,
        'spawn': onBuildSpawn,
        'spawn_player': onBuildSpawnPlayer,
        'target': onBuildTarget,
      };

  @override
  Map<String, TileBuilderFunction>? get globalObjectBuilder => {
        'spawn_player': onSetupInitialPosition,
      };

  @override
  MyGame get game => super.game as MyGame;

  double mapWidth = 0;
  double mapHeight = 0;

  @override
  Future<TiledComponent<FlameGame>> init(HasSpatialGridFramework game) {
    return super.init(game).then((renderableTiledMap) {
      mapWidth = (renderableTiledMap.tileMap.map.width *
              renderableTiledMap.tileMap.map.tileWidth)
          .toDouble();
      mapHeight = (renderableTiledMap.tileMap.map.height *
              renderableTiledMap.tileMap.map.tileHeight)
          .toDouble();

      return renderableTiledMap;
    });
  }

  Future groundBuilder(CellBuilderContext context) async {
    context.priorityOverride = RenderPriority.ground.priority;
    return genericTileBuilder(context);
  }

  Future onBuildTree(CellBuilderContext context) async {
    // return;
    final data = context.tileDataProvider;
    if (data == null) return;
    final tree =
        Tree(data, position: context.absolutePosition, size: context.size);
    tree.currentCell = context.cell;

    final layer = game.layersManager.addComponent(
        component: tree,
        layerType: MapLayerType.static,
        layerName: 'Tree',
        priority: RenderPriority.tree.priority);
    (layer as CellStaticLayer).renderAsImage = true;
  }

  Future onBuildWater(CellBuilderContext context) async {
    // return;
    final data = context.tileDataProvider;
    if (data == null) return;
    final water =
        Water(data, position: context.absolutePosition, size: context.size);
    water.currentCell = context.cell;

    game.layersManager.addComponent(
        component: water,
        layerType: MapLayerType.animated,
        layerName: 'Water',
        priority: RenderPriority.water.priority);
  }

  Future onBuildBrick(CellBuilderContext context) async {
    // return;
    final data = context.tileDataProvider;
    if (data == null) {
      print('return!!!');

      return;
    }
    final brick =
        Brick(data, position: context.absolutePosition, size: context.size);
    brick.currentCell = context.cell;

    game.layersManager.addComponent(
        component: brick,
        layerType: MapLayerType.static,
        layerName: 'Brick',
        optimizeGraphics: false,
        priority: RenderPriority.walls.priority);
  }

  Future onBuildHeavyBrick(CellBuilderContext context) async {
    // return;
    final data = context.tileDataProvider;
    if (data == null) return;
    final heavyBrick = HeavyBrick(data,
        position: context.absolutePosition, size: context.size);

    heavyBrick.currentCell = context.cell;
    game.layersManager.addComponent(
        component: heavyBrick,
        layerType: MapLayerType.static,
        optimizeGraphics: false,
        layerName: 'HeavyBrick',
        priority: RenderPriority.walls.priority);
  }

  Future onBuildSpawn(CellBuilderContext context) async {
    final properties = context.tiledObject?.properties;
    if (properties == null) return;
    final newSpawn = Spawn(
        position: Vector2(context.absolutePosition.x + context.size.x / 2,
            context.absolutePosition.y + context.size.y / 2),
        isForPlayer: false);

    newSpawn.currentCell = context.cell;
    _setupSpawnProperties(newSpawn, properties);

    game.world.addSpawn(newSpawn);
  }

  Future onBuildSpawnPlayer(CellBuilderContext context) async {
    final properties = context.tiledObject?.properties;
    if (properties == null) return;
    // final newSpawn = Spawn(
    //     position: Vector2(context.absolutePosition.x + context.size.x / 2,
    //         context.absolutePosition.y + context.size.y / 2),
    //     isForPlayer: true);
    //
    // newSpawn.currentCell = context.cell;
    // _setupSpawnProperties(newSpawn, properties);
    //
    // game.cameraComponent.moveTo(newSpawn.position);
    // game.world.addSpawn(newSpawn);

    final newSpawn2 = SpawnEntity(rootComponent: game.world.tankLayer)
      ..position = Vector2(context.absolutePosition.x + context.size.x / 2,
          context.absolutePosition.y + context.size.y / 2);
    newSpawn2.spawnData.factions.add(Faction(name: 'Player'));
    newSpawn2.spawnData.allowedFactions.add(Faction(name: 'Player'));
    game.world.addSpawn(newSpawn2);
    SpawnManager().add(newSpawn2);
  }

  Future onSetupInitialPosition(CellBuilderContext context) async {
    cameraInitialPosition.setFrom(context.absolutePosition);
  }

  void _setupSpawnProperties(Spawn spawn, CustomProperties properties) {
    for (final property in properties) {
      switch (property.name) {
        case 'cooldown_seconds':
          spawn.cooldown =
              Duration(seconds: int.parse(property.value.toString()));
          break;
        case 'tanks_inside':
          spawn.tanksInside = int.parse(property.value.toString());
          break;
        case 'trigger_distance':
          final distance = double.parse(property.value.toString());
          spawn.triggerDistanceSquared = distance * distance;
          break;
        case 'tank_type':
          spawn.createTanksOfType =
              TankType.fromString(property.value.toString());
          break;
      }
    }
  }

  Future onBuildTarget(CellBuilderContext context) async {
    final properties = context.tiledObject?.properties;
    if (properties == null) return;
    var primary = true;
    var protectFromEnemies = false;
    for (final property in properties) {
      switch (property.name) {
        case 'primary':
          primary = property.value == "true" ? true : false;
          break;
        case 'protectFromEnemies':
          protectFromEnemies = property.value == "true" ? true : false;
          break;
      }
    }
    final newTarget = Target(
        position: context.absolutePosition,
        primary: primary,
        protectFromEnemies: protectFromEnemies);
    game.world.addSpawn(newTarget);
  }
}
