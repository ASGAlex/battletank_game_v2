import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/flame.dart';
import 'package:flame/game.dart';
import 'package:flame/image_composition.dart';
import 'package:flame/input.dart';
import 'package:flame_tiled/flame_tiled.dart';
import 'package:flutter/material.dart';
import 'package:tank_game/packages/back_buffer/lib/batch_components.dart';
import 'package:tank_game/packages/lazy_collision/lib/lazy_collision.dart';
import 'package:tank_game/packages/tiled_utils/lib/tiled_utils.dart';
import 'package:tank_game/ui/console_messages.dart';
import 'package:tank_game/ui/joystick.dart';
import 'package:tank_game/ui/keyboard.dart';
import 'package:tank_game/ui/visibility_indicator.dart';
import 'package:tank_game/world/environment/spawn.dart';
import 'package:tank_game/world/tank/tank.dart';
import 'package:tank_game/world/world.dart';
import 'package:tiled/tiled.dart';

import 'packages/back_buffer/lib/back_buffer.dart';
import 'packages/collision_quad_tree/lib/collision_quad_tree.dart';
import 'packages/color_filter/lib/color_filter.dart';
import 'services/sound/library.dart';
import 'world/environment/brick.dart';
import 'world/environment/heavy_brick.dart';
import 'world/environment/water.dart';

abstract class MyGameFeatures extends FlameGame
    with
        ColorFilterMix,
        KeyboardEvents,
        SingleGameInstance,
        HasQuadTreeCollisionDetection,
        ScrollDetector,
        HasDraggables,
        HasTappables,
        ObjectLayers {}

class MyGame extends MyGameFeatures with MyJoystickMix, GameHardwareKeyboard {
  MyGame(this.mapFile);

  static final fpsTextPaint = TextPaint(
    style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
  );

  String mapFile;

  final lazyCollisionService = LazyCollisionsService();

  List<Enemy> enemies = [];
  Player? player;

  BatchComponentRenderer? batchRenderer;

  RenderableTiledMap? currentMap;

  BackBuffer? backBuffer;
  final consoleMessages = ConsoleMessages();

  final hudVisibility = VisibilityIndicator();

  @override
  Future<void> onLoad() async {
    Flame.device.setLandscape();
    Flame.device.fullScreen();
    consoleMessages.sendMessage('Start loading!');
    // print('Start loading!');
    super.onLoad();
    initColorFilter<MyGame>();

    consoleMessages.sendMessage('loading sounds...');
    // print('loading sounds...');
    SoundLibrary().init();
    consoleMessages.sendMessage('done.');
    // print('done.');

    consoleMessages.sendMessage('loading map...');
    var tiledComponent = await TiledComponent.load(mapFile, Vector2.all(8));
    currentMap = tiledComponent.tileMap;
    final mapWidth = (tiledComponent.tileMap.map.width *
            tiledComponent.tileMap.map.tileWidth)
        .toDouble();
    final mapHeight = (tiledComponent.tileMap.map.height *
            tiledComponent.tileMap.map.tileHeight)
        .toDouble();
    initCollisionDetection(Rect.fromLTWH(0, 0, mapWidth, mapHeight));
    consoleMessages.sendMessage('done.');

    consoleMessages.sendMessage('Compiling ground layer...');
    final imageCompiler = ImageBatchCompiler();
    final ground = await imageCompiler.compileMapLayer(
        tileMap: tiledComponent.tileMap, layerNames: ['ground']);
    ground.priority = RenderPriority.ground.priority;
    add(ground);
    consoleMessages.sendMessage('done.');

    consoleMessages.sendMessage('Compiling tree layer...');
    final tree = await imageCompiler
        .compileMapLayer(tileMap: tiledComponent.tileMap, layerNames: ['tree']);
    tree.priority = RenderPriority.tree.priority;
    add(tree);
    consoleMessages.sendMessage('done.');

    consoleMessages.sendMessage('Preparing back buffer...');
    backBuffer = BackBuffer(mapWidth.toInt(), mapHeight.toInt(), 2, 10);
    add(backBuffer!);
    consoleMessages.sendMessage('done.');

    consoleMessages.sendMessage('Starting lazy collision service...');
    await lazyCollisionService.run({
      'tree': const Duration(milliseconds: 100),
    });
    consoleMessages.sendMessage('done.');

    consoleMessages.sendMessage('Creating trees and collision tiles...');
    batchRenderer = BatchComponentRenderer(mapWidth.toInt(), mapHeight.toInt());
    TileProcessor.processTileType(
        tileMap: tiledComponent.tileMap,
        processorByType: <String, TileProcessorFunc>{
          'tree': ((tile, position, size) {
            final collision = tile.getCollisionRect();
            if (collision != null) {
              collision.position = position;
              lazyCollisionService.addHitbox(
                  position: position, size: size, layer: 'tree');
            }
          }),
          'water': ((tile, position, size) {
            add(WaterCollide(tile, position: position, size: size));
          }),
          'brick': ((tile, position, size) async {
            final brick = Brick(tile, position: position, size: size);
            add(brick);
            batchRenderer?.batchedComponents.add(brick);
          }),
          'heavy_brick': ((tile, position, size) async {
            final brick = HeavyBrick(tile, position: position, size: size);
            add(brick);
            batchRenderer?.batchedComponents.add(brick);
          }),
        },
        layersToLoad: [
          'tree',
          'collision'
        ]);
    add(batchRenderer!);
    consoleMessages.sendMessage('done.');

    consoleMessages.sendMessage('Creating water tiles...');
    final animationCompiler = AnimationBatchCompiler();
    TileProcessor.processTileType(
        tileMap: tiledComponent.tileMap,
        processorByType: <String, TileProcessorFunc>{
          'water': ((tile, position, size) {
            animationCompiler.addTile(position, tile);
          }),
        },
        layersToLoad: [
          'water',
        ]);
    consoleMessages.sendMessage('done.');

    consoleMessages.sendMessage('Compiling water animation...');
    final animatedWater = await animationCompiler.compile();
    animatedWater.priority = RenderPriority.water.priority;
    add(animatedWater);
    consoleMessages.sendMessage('done.');

    consoleMessages.sendMessage('Loading spawns...');
    loadSpawns(tiledComponent);
    consoleMessages.sendMessage('done.');

    consoleMessages.sendMessage('Starting UI');
    initJoystick(() {
      player?.onFire();
    });
    hudVisibility.setVisibility(true);
    hudVisibility.x = 2;
    hudVisibility.y = 2;
    add(hudVisibility);
    consoleMessages.sendMessage('done.');

    consoleMessages.sendMessage('Spawning the Player...');
    camera.viewport = FixedResolutionViewport(Vector2(400, 250));
    // camera.zoom = 1;

    final playerSpawn = await Spawn.waitFree(true);
    camera.followComponent(playerSpawn);
    restorePlayer(playerSpawn);
    SoundLibrary().playIntro();
    consoleMessages.sendMessage('done.');
    consoleMessages.sendMessage('All done, game started!');
  }

  loadSpawns(TiledComponent tiledComponent) {
    final spawns =
        tiledComponent.tileMap.getLayer<ObjectGroup>('spawn')?.objects;
    if (spawns != null) {
      for (final spawnObject in spawns) {
        final newSpawn = Spawn(
            position: Vector2(spawnObject.x + spawnObject.width / 2,
                spawnObject.y + spawnObject.height / 2),
            isForPlayer: spawnObject.name == 'spawn_player');
        for (final property in spawnObject.properties) {
          switch (property.name) {
            case 'cooldown_seconds':
              newSpawn.cooldown = Duration(seconds: int.parse(property.value));
              break;
            case 'tanks_inside':
              newSpawn.tanksInside = int.parse(property.value);
              break;
            case 'trigger_distance':
              newSpawn.triggerDistance = double.parse(property.value);
              break;
          }
        }
        addSpawn(newSpawn);
      }
    }
  }

  Future<Player> restorePlayer([Spawn? spawn]) async {
    spawn ??= await Spawn.waitFree(true);
    final object = Player(position: spawn.position.clone());
    await spawn.createTank(object, true);
    camera.followComponent(object);
    player = object;
    return object;
  }

  Future<Enemy> spawnEnemy() async {
    var spawn = await Spawn.waitFree();
    final object = Enemy(position: spawn.position.clone());
    await spawn.createTank(object, true);
    enemies.add(object);
    return object;
  }
}
