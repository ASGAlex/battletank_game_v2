import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame_spatial_grid/flame_spatial_grid.dart';
import 'package:flame_tiled/flame_tiled.dart';
import 'package:tank_game/game.dart';
import 'package:tank_game/world/core/scenario/scenario_component.dart';
import 'package:tank_game/world/core/scenario/scripts/moving_path.dart';
import 'package:tank_game/world/environment/buildings/brick.dart';
import 'package:tank_game/world/environment/buildings/heavy_brick.dart';
import 'package:tank_game/world/environment/buildings/radar.dart';
import 'package:tank_game/world/environment/ground/asphalt.dart';
import 'package:tank_game/world/environment/spawn/actor_factory.dart';
import 'package:tank_game/world/environment/spawn/spawn_teleport.dart';
import 'package:tank_game/world/environment/tree/tree.dart';
import 'package:tank_game/world/environment/water/water.dart';
import 'package:tank_game/world/world.dart';

import 'environment/ground/sand.dart';

class GameMapLoader extends TiledMapLoader {
  GameMapLoader([String fileName = '']) {
    this.fileName = fileName;
  }

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
        'sand_slow': onBuildSand,
        'asphalt': onBuildAsphalt,
        'brick': onBuildBrick,
        'heavy_brick': onBuildHeavyBrick,
        'spawn': onBuildSpawn,
        'spawn_human': onBuildSpawnHuman,
        'target': onBuildTarget,
        'scenario': onBuildScenario,
        'moving_path': onBuildMovingPath,
        'move_path': onBuildMovingPath,
        'radar_head': onBuildRadar,
      };

  @override
  // TODO: implement globalObjectBuilder
  Map<String, TileBuilderFunction>? get globalObjectBuilder => null;

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

  static Future<void> noMapBuilder(
    MyGame game,
    Cell cell,
    Component rootComponent,
    Iterable<Rect> mapRects,
  ) async {
    if (game.scenario.name == 'Tutorial') {
      if (cell.rect.left < 1 && cell.rect.top > 750) {
        buildWaterCell(game, cell, rootComponent, mapRects);
      } else if ((cell.rect.left > 700 && cell.rect.top > 0) ||
          (cell.rect.left > 370 && cell.rect.top > 750)) {
        buildTreesAndGrassCell(game, cell, rootComponent, mapRects);
      } else if (cell.rect.left > 700 &&
          cell.rect.top > -700 &&
          cell.rect.top < 200) {
        buildWaterGrassTreeSandCell(game, cell, rootComponent, mapRects);
      } else if (cell.rect.left < 450 && cell.rect.top < 450) {
        buildTreeCell(game, cell, rootComponent, mapRects);
      } else if (cell.rect.left < -300 &&
          cell.rect.top > 450 &&
          cell.rect.top < 750) {
        buildWaterGrassTreeSandCell(game, cell, rootComponent, mapRects);
      }
    } else {
      noMapBuilderFullRandom(game, cell, rootComponent, mapRects);
    }
  }

  static bool canPlaceTile(
      Iterable<Rect> mapRects, Vector2 position, Vector2 size) {
    final tileRect = Rect.fromLTWH(position.x, position.y, size.x, size.y);
    for (final map in mapRects) {
      if (map.overlaps(tileRect)) {
        return false;
      }
    }
    return true;
  }

  static Future<void> buildWaterGrassTreeSandCell(
    MyGame game,
    Cell cell,
    Component rootComponent,
    Iterable<Rect> mapRects,
  ) async {
    final grass = game.tilesetManager.getTile('ground', 'grass');
    final sand = game.tilesetManager.getTile('ground', 'sand');
    final sandSlow = game.tilesetManager.getTile('ground', 'sand_slow');
    if (grass == null || sand == null || sandSlow == null) {
      throw 'Background tiles not found!';
    }
    var filled = false;
    var filledWidth = 0.0;
    var filledHeight = 0.0;
    while (!filled) {
      final p = Random().nextInt(100);
      TileCache tile;
      if (p < 20) {
        tile = sand;
      } else if (p < 30) {
        tile = sandSlow;
      } else {
        tile = grass;
      }

      final position = Vector2(filledWidth, filledHeight);
      final size = Vector2(8, 8);

      if (canPlaceTile(
        mapRects,
        Vector2(cell.rect.left + filledWidth, cell.rect.top + filledHeight),
        size,
      )) {
        if (tile == sandSlow) {
          final animation = sandSlow.spriteAnimation;
          if (animation == null) return;
          final sand = SandEntity(
            animation: animation,
            size: size,
            position: position,
          );
          sand.currentCell = cell;
          game.layersManager.addComponent(
              component: sand,
              layerType: MapLayerType.animated,
              absolutePosition: false,
              layerName: 'Sand',
              priority: RenderPriority.ground.priority + 1);
        } else {
          final sprite = tile.sprite;
          if (sprite == null) {
            throw 'Background sprites not found!';
          }

          final component = TileComponent(tile);
          component.currentCell = cell;
          component.position = Vector2(filledWidth, filledHeight);
          component.size.setFrom(sprite.srcSize);

          game.layersManager.addComponent(
            component: component,
            absolutePosition: false,
            layerName: 'static-ground-procedural',
            layerType: MapLayerType.static,
            componentsStorageMode:
                LayerComponentsStorageMode.removeAfterCompile,
            optimizeCollisions: false,
            priority: -100,
          );
        }

        if (tile == grass) {
          final random = Random().nextInt(100);
          if (random < 20) {
            final sprite =
                game.tilesetManager.getTile('bricks', 'tree')?.sprite;
            if (sprite == null) return;
            final tree = TreeEntity(
              sprite: sprite,
              position: position,
              size: size,
            );
            tree.currentCell = cell;

            game.layersManager.addComponent(
              component: tree,
              layerType: MapLayerType.static,
              absolutePosition: false,
              layerName: 'Tree',
              renderMode: LayerRenderMode.image,
              priority: RenderPriority.tree.priority,
            );
          } else if (random < 30) {
            final animation =
                game.tilesetManager.getTile('bricks', 'water')?.spriteAnimation;
            if (animation == null) return;
            final water = WaterEntity(
              animation: animation,
              size: size,
              position: position,
            );
            water.currentCell = cell;
            game.layersManager.addComponent(
                component: water,
                layerType: MapLayerType.animated,
                absolutePosition: false,
                layerName: 'Water',
                priority: RenderPriority.water.priority);
          }
        }
      }

      filledWidth += size.x.floor();
      if (filledWidth >= cell.rect.width) {
        filledHeight += size.y.floor();
        filledWidth = 0;
        if (filledHeight >= cell.rect.height) {
          filled = true;
        }
      }
    }
  }

  static void buildTreesAndGrassCell(
    MyGame game,
    Cell cell,
    Component rootComponent,
    Iterable<Rect> mapRects,
  ) {
    final grass = game.tilesetManager.getTile('ground', 'grass');

    if (grass == null) {
      throw 'Background tiles not found!';
    }
    var filled = false;
    var filledWidth = 0.0;
    var filledHeight = 0.0;
    while (!filled) {
      TileCache tile;
      tile = grass;

      final sprite = tile.sprite;
      if (sprite == null) {
        throw 'Background sprites not found!';
      }

      if (canPlaceTile(
          mapRects,
          Vector2(cell.rect.left + filledWidth, cell.rect.top + filledHeight),
          sprite.srcSize)) {
        final component = TileComponent(tile);
        component.currentCell = cell;
        component.position = Vector2(filledWidth, filledHeight);
        component.size.setFrom(sprite.srcSize);

        game.layersManager.addComponent(
          component: component,
          absolutePosition: false,
          layerName: 'static-ground-procedural',
          layerType: MapLayerType.static,
          componentsStorageMode: LayerComponentsStorageMode.removeAfterCompile,
          optimizeCollisions: false,
          priority: -100,
        );

        if (mapRects.isEmpty) {
          if (tile == grass) {
            final random = Random().nextInt(100);
            if (random < 40) {
              final sprite =
                  game.tilesetManager.getTile('bricks', 'tree')?.sprite;
              if (sprite == null) return;
              final tree = TreeEntity(
                sprite: sprite,
                position: component.position,
                size: component.size,
              );
              tree.currentCell = cell;

              game.layersManager.addComponent(
                component: tree,
                layerType: MapLayerType.static,
                absolutePosition: false,
                layerName: 'Tree',
                renderMode: LayerRenderMode.image,
                priority: RenderPriority.tree.priority,
              );
            }
          }
        }
      }

      filledWidth += sprite.srcSize.x.floor();
      if (filledWidth >= cell.rect.width) {
        filledHeight += sprite.srcSize.y.floor();
        filledWidth = 0;
        if (filledHeight >= cell.rect.height) {
          filled = true;
        }
      }
    }
  }

  static void buildTreeCell(
    MyGame game,
    Cell cell,
    Component rootComponent,
    Iterable<Rect> mapRects,
  ) {
    final tree = game.tilesetManager.getTile('bricks', 'tree');
    if (tree == null) {
      return;
    }

    var filled = false;
    var filledWidth = 0.0;
    var filledHeight = 0.0;
    final srcSize = Vector2(8, 8);

    CellLayer? layer;
    var componentsCount = 0;
    while (!filled) {
      if (canPlaceTile(
          mapRects,
          Vector2(cell.rect.left + filledWidth, cell.rect.top + filledHeight),
          srcSize)) {
        final grass = game.tilesetManager.getTile('ground', 'grass');
        if (grass == null) {
          return;
        }
        var component = TileComponent(grass);
        component.currentCell = cell;
        component.position = Vector2(filledWidth, filledHeight);
        component.size.setFrom(grass.sprite!.srcSize);

        game.layersManager.addComponent(
          component: component,
          absolutePosition: false,
          layerName: 'static-ground-procedural',
          layerType: MapLayerType.static,
          componentsStorageMode: LayerComponentsStorageMode.removeAfterCompile,
          optimizeCollisions: false,
          priority: -100,
        );

        component = TileComponent(tree);
        component.currentCell = cell;
        component.position = Vector2(filledWidth, filledHeight);
        component.size.setFrom(srcSize);
        final treeComponent = TreeEntity(
          sprite: tree.sprite,
          size: component.size,
          position: component.position,
        );
        treeComponent.currentCell = cell;
        layer = game.layersManager.addComponent(
            component: treeComponent,
            layerType: MapLayerType.static,
            absolutePosition: false,
            layerName: 'Tree',
            priority: RenderPriority.tree.priority);
        componentsCount++;
      }
      filledWidth += srcSize.x.floor();
      if (filledWidth >= cell.rect.width) {
        filledHeight += srcSize.y.floor();
        filledWidth = 0;
        if (filledHeight >= cell.rect.height) {
          filled = true;
        }
      }
    }
    layer?.collisionOptimizer.maximumItemsInGroup = componentsCount;
  }

  static void buildWaterCell(
    MyGame game,
    Cell cell,
    Component rootComponent,
    Iterable<Rect> mapRects,
  ) {
    final water = game.tilesetManager.getTile('bricks', 'water');
    if (water == null) {
      return;
    }

    var filled = false;
    var filledWidth = 0.0;
    var filledHeight = 0.0;
    final srcSize = Vector2(8, 8);

    final tile = water;
    CellLayer? layer;
    var componentsCount = 0;
    while (!filled) {
      if (canPlaceTile(
          mapRects,
          Vector2(cell.rect.left + filledWidth, cell.rect.top + filledHeight),
          srcSize)) {
        final component = TileComponent(tile);
        component.currentCell = cell;
        component.position = Vector2(filledWidth, filledHeight);
        component.size.setFrom(srcSize);
        final waterComponent = WaterEntity(
          animation: water.spriteAnimation,
          size: component.size,
          position: component.position,
        );
        waterComponent.currentCell = cell;
        layer = game.layersManager.addComponent(
            component: waterComponent,
            layerType: MapLayerType.animated,
            absolutePosition: false,
            layerName: 'Water',
            priority: RenderPriority.water.priority);
        componentsCount++;
      }

      filledWidth += srcSize.x.floor();
      if (filledWidth >= cell.rect.width) {
        filledHeight += srcSize.y.floor();
        filledWidth = 0;
        if (filledHeight >= cell.rect.height) {
          filled = true;
        }
      }
    }
    layer?.collisionOptimizer.maximumItemsInGroup = componentsCount;
  }

  static Future<void> noMapBuilderFullRandom(
    MyGame game,
    Cell cell,
    Component rootComponent,
    Iterable<Rect> mapRects,
  ) async {
    final grass = game.tilesetManager.getTile('ground', 'grass');
    final sand = game.tilesetManager.getTile('ground', 'sand');
    if (grass == null || sand == null) {
      throw 'Background tiles not found!';
    }
    var filled = false;
    var filledWidth = 0.0;
    var filledHeight = 0.0;
    while (!filled) {
      final p = Random().nextInt(100);
      TileCache tile;
      if (p < 20) {
        tile = sand;
      } else {
        tile = grass;
      }
      final sprite = tile.sprite;
      if (sprite == null) {
        throw 'Background sprites not found!';
      }

      if (canPlaceTile(
          mapRects,
          Vector2(cell.rect.left + filledWidth, cell.rect.top + filledHeight),
          sprite.srcSize)) {
        final component = TileComponent(tile);
        component.currentCell = cell;
        component.position = Vector2(filledWidth, filledHeight);
        component.size.setFrom(sprite.srcSize);

        game.layersManager.addComponent(
          component: component,
          absolutePosition: false,
          layerName: 'static-ground-procedural',
          layerType: MapLayerType.static,
          componentsStorageMode: LayerComponentsStorageMode.removeAfterCompile,
          optimizeCollisions: false,
          priority: -100,
        );

        if (mapRects.isEmpty) {
          if (tile == grass) {
            final random = Random().nextInt(100);
            if (random < 20) {
              final sprite =
                  game.tilesetManager.getTile('bricks', 'tree')?.sprite;
              if (sprite == null) return;
              final tree = TreeEntity(
                sprite: sprite,
                position: component.position,
                size: component.size,
              );
              tree.currentCell = cell;

              game.layersManager.addComponent(
                component: tree,
                layerType: MapLayerType.static,
                absolutePosition: false,
                layerName: 'Tree',
                renderMode: LayerRenderMode.image,
                priority: RenderPriority.tree.priority,
              );
            } else if (random < 30) {
              final animation = game.tilesetManager
                  .getTile('bricks', 'water')
                  ?.spriteAnimation;
              if (animation == null) return;
              final water = WaterEntity(
                animation: animation,
                size: component.size,
                position: component.position,
              );
              water.currentCell = cell;
              game.layersManager.addComponent(
                  component: water,
                  layerType: MapLayerType.animated,
                  absolutePosition: false,
                  layerName: 'Water',
                  priority: RenderPriority.water.priority);
            }
          }
        }
      }
      filledWidth += sprite.srcSize.x.floor();
      if (filledWidth >= cell.rect.width) {
        filledHeight += sprite.srcSize.y.floor();
        filledWidth = 0;
        if (filledHeight >= cell.rect.height) {
          filled = true;
        }
      }
    }
  }

  Future groundBuilder(TileBuilderContext context) async {
    context.priorityOverride = RenderPriority.ground.priority;
    (await genericTileBuilder(context))?.renderMode = LayerRenderMode.image;
  }

  Future onBuildTree(TileBuilderContext context) async {
    // return;
    final sprite = await context.tileDataProvider?.getSprite();
    if (sprite == null) return;
    final tree = TreeEntity(
      sprite: sprite,
      position: context.absolutePosition,
      size: context.size,
    );
    tree.currentCell = context.cell;

    game.layersManager.addComponent(
        component: tree,
        layerType: MapLayerType.static,
        layerName: 'Tree',
        renderMode: LayerRenderMode.image,
        priority: RenderPriority.tree.priority);
  }

  Future onBuildWater(TileBuilderContext context) async {
    // return;
    final data = context.tileDataProvider;
    if (data == null) return;
    final animation = await data.getSpriteAnimation();
    final water = WaterEntity(
      animation: animation,
      position: context.absolutePosition,
      size: context.size,
    );
    water.currentCell = context.cell;

    game.layersManager.addComponent(
        component: water,
        layerType: MapLayerType.animated,
        layerName: 'Water',
        priority: RenderPriority.water.priority);
  }

  Future onBuildSand(TileBuilderContext context) async {
    // return;
    final data = context.tileDataProvider;
    if (data == null) return;
    final animation = await data.getSpriteAnimation();
    final sand = SandEntity(
      animation: animation,
      position: context.absolutePosition,
      size: context.size,
    );
    sand.currentCell = context.cell;

    game.layersManager.addComponent(
        component: sand,
        layerType: MapLayerType.animated,
        layerName: 'Sand',
        priority: RenderPriority.ground.priority + 1);
  }

  Future onBuildBrick(TileBuilderContext context) async {
    // return;
    final data = context.tileDataProvider;
    if (data == null) {
      return;
    }
    final sprite = await data.getSprite();
    final brick = BrickEntity(
        sprite: sprite, position: context.absolutePosition, size: context.size);
    brick.currentCell = context.cell;

    game.layersManager.addComponent(
        component: brick,
        layerType: MapLayerType.static,
        layerName: 'Brick',
        priority: RenderPriority.walls.priority);
  }

  Future onBuildAsphalt(TileBuilderContext context) async {
    // return;
    final data = context.tileDataProvider;
    if (data == null) {
      return;
    }
    final sprite = await data.getSprite();
    final asphalt = AsphaltEntity(
        sprite: sprite, position: context.absolutePosition, size: context.size);
    asphalt.currentCell = context.cell;

    game.layersManager.addComponent(
        component: asphalt,
        layerType: MapLayerType.static,
        layerName: 'Asphalt',
        priority: RenderPriority.ground.priority + 1);
  }

  Future onBuildRadar(TileBuilderContext context) async {
    final radar =
        RadarEntity(position: context.absolutePosition + Vector2(0, -8));
    radar.currentCell = context.cell;
    radar.size = Vector2.all(16);
    game.world.skyLayer.add(radar);
  }

  Future onBuildHeavyBrick(TileBuilderContext context) async {
    // return;
    final data = context.tileDataProvider;
    if (data == null) return;
    final sprite = await data.getSprite();
    final heavyBrick = HeavyBrickEntity(
        sprite: sprite, position: context.absolutePosition, size: context.size);

    heavyBrick.currentCell = context.cell;
    game.layersManager.addComponent(
        component: heavyBrick,
        layerType: MapLayerType.static,
        layerName: 'HeavyBrick',
        priority: RenderPriority.walls.priority);
  }

  Future onBuildSpawn(TileBuilderContext context) async {
    final newSpawn = SpawnTeleport(
      rootComponent: game.world.tankLayer,
      buildContext: context,
      actorFactory: SpawnActorFactory.tankFromContext(
              game: game, spawnBuilderContext: context)
          .call,
    );

    newSpawn.userData!.factions.clear();
    newSpawn.userData!.factions.addAll(newSpawn.userData!.allowedFactions);

    game.world.addSpawn(newSpawn);
    game.spawnManager.add(newSpawn);
  }

  Future onBuildSpawnHuman(TileBuilderContext context) async {
    bool isRandomMovement =
        context.tiledObject?.properties.getValue<bool>('randomMovement') ??
            false;
    final newSpawn = SpawnTeleport(
      rootComponent: game.world.tankLayer,
      buildContext: context,
      actorFactory: isRandomMovement
          ? SpawnActorFactory.humanRandomCrowd().call
          : SpawnActorFactory.human().call,
    );
    // newSpawn.userData!.allowedFactions.add(Faction(name: 'Player'));

    game.world.addSpawn(newSpawn);
    game.spawnManager.add(newSpawn);
  }

  // Future onBuildSpawnNeutral(TileBuilderContext context) async {
  //   final newSpawn = SpawnTeleport(
  //     rootComponent: game.world.tankLayer,
  //     buildContext: context,
  //     actorFactory: SpawnActorFactory.tankFromContext(
  //             game: game, spawnBuilderContext: context)
  //         .call,
  //   );
  //
  //   final faction = Faction(name: 'Neutral');
  //
  //   newSpawn.userData!.factions.clear();
  //   newSpawn.userData!.factions.add(faction);
  //   newSpawn.userData!.allowedFactions.clear();
  //   newSpawn.userData!.allowedFactions.add(faction);
  //
  //   game.world.addSpawn(newSpawn);
  //   game.spawnManager.add(newSpawn);
  // }

  Future onBuildTarget(TileBuilderContext context) async {
    // final properties = context.tiledObject?.properties;
    // if (properties == null) return;
    // var primary = true;
    // var protectFromEnemies = false;
    // for (final property in properties) {
    //   switch (property.name) {
    //     case 'primary':
    //       primary = property.value == "true" ? true : false;
    //       break;
    //     case 'protectFromEnemies':
    //       protectFromEnemies = property.value == "true" ? true : false;
    //       break;
    //   }
    // }
    // final newTarget = Target(
    //     position: context.absolutePosition,
    //     primary: primary,
    //     protectFromEnemies: protectFromEnemies);
    // game.world.addSpawn(newTarget);
  }

  Future onBuildScenario(TileBuilderContext context) async {
    final tiledObject = context.tiledObject;
    if (tiledObject == null) return;

    final scenario = ScenarioComponent.fromTiled(tiledObject);
    scenario.position = context.absolutePosition;
    scenario.size = context.size;
    scenario.currentCell = context.cell;

    game.world.addScenario(scenario);
  }

  Future onBuildMovingPath(TileBuilderContext context) async {
    final tiledObject = context.tiledObject;
    if (tiledObject == null) return;

    if (tiledObject.polyline.isEmpty) return;

    final initialPosition = context.absolutePosition;
    final points = tiledObject.polyline
        .map((e) => Vector2(initialPosition.x + e.x, initialPosition.y + e.y))
        .toList(growable: false);
    MovingPathScript.namedLists[tiledObject.name] = points;
  }
}
