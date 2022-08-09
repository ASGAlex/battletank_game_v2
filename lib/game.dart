import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/flame.dart';
import 'package:flame/game.dart';
import 'package:flame/image_composition.dart';
import 'package:flame/input.dart';
import 'package:flame_tiled/flame_tiled.dart';
import 'package:flutter/material.dart';
import 'package:tank_game/packages/lazy_collision/lib/lazy_collision.dart';
import 'package:tank_game/packages/tiled_utils/lib/tiled_utils.dart';
import 'package:tank_game/ui/joystick.dart';
import 'package:tank_game/ui/keyboard.dart';
import 'package:tank_game/world/environment/spawn.dart';
import 'package:tank_game/world/tank/tank.dart';
import 'package:tank_game/world/world.dart';
import 'package:tiled/tiled.dart';

import 'packages/collision_quad_tree/lib/collision_quad_tree.dart';
import 'packages/collision_quad_tree/lib/src/collision_detection.dart';
import 'packages/color_filter/lib/color_filter.dart';
import 'services/sound/library.dart';
import 'world/environment/brick.dart';
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

  bool isPlayerHiddenFromEnemy = false;
  List<Enemy> enemies = [];
  Player? player;

  BrickRenderController? brickRenderer;

  RenderableTiledMap? currentMap;

  final hudTextPaintNormal = TextPaint(
      style: const TextStyle(
    fontWeight: FontWeight.bold,
    color: Colors.black,
    backgroundColor: Colors.white,
  ));

  final hudTextPaintGood = TextPaint(
      style: const TextStyle(
    fontWeight: FontWeight.bold,
    color: Colors.green,
    backgroundColor: Colors.black12,
  ));

  final hudTextPaintDanger = TextPaint(
      style: const TextStyle(
    fontWeight: FontWeight.bold,
    color: Colors.red,
    fontSize: 24,
    backgroundColor: Colors.black12,
  ));

  @override
  Future<void> onLoad() async {
    print('Start loading!');
    super.onLoad();
    initColorFilter<MyGame>();

    print('loading sounds...');
    SoundLibrary().init();
    print('done.');

    print('loading map...');
    var tiledComponent = await TiledComponent.load(mapFile, Vector2.all(8));
    currentMap = tiledComponent.tileMap;
    initCollisionDetection(Rect.fromLTWH(
        0,
        0,
        (tiledComponent.tileMap.map.width *
                tiledComponent.tileMap.map.tileWidth)
            .toDouble(),
        (tiledComponent.tileMap.map.height *
                tiledComponent.tileMap.map.tileHeight)
            .toDouble()));
    print('done.');

    print('Compiling ground layer...');
    final imageCompiler = ImageBatchCompiler();
    final ground = await imageCompiler.compileMapLayer(
        tileMap: tiledComponent.tileMap, layerNames: ['ground']);
    ground.priority = RenderPriority.ground.priority;
    add(ground);
    print('done.');

    print('Compiling tree layer...');
    final tree = await imageCompiler
        .compileMapLayer(tileMap: tiledComponent.tileMap, layerNames: ['tree']);
    tree.priority = RenderPriority.tree.priority;
    add(tree);
    print('done.');

    print('Preparing back buffer...');
    final trackController = TrackTrailController();
    await trackController.init(tiledComponent.tileMap);
    add(trackController);
    print('done.');

    print('Starting lazy collision service...');
    await lazyCollisionService.run({
      'tree': const Duration(milliseconds: 100),
    });
    print('done.');

    print('Creating trees and collision tiles...');
    brickRenderer = BrickRenderController(
        ((currentMap?.map.width ?? 0) * (currentMap?.map.tileWidth ?? 0))
            .toInt(),
        ((currentMap?.map.height ?? 0) * (currentMap?.map.tileHeight ?? 0))
            .toInt());
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
            brickRenderer?.sprite ??= await tile.getSprite();
            brickRenderer?.bricks.add(brick);
          }),
          'heavy_brick': ((tile, position, size) {
            // add(HeavyBrick(tile, position: position, size: size));
          }),
        },
        layersToLoad: [
          'tree',
          'collision'
        ]);
    add(brickRenderer!);
    print('done.');

    print('Creating water tiles...');
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
    print('done.');

    print('Compiling water animation...');
    final animatedWater = await animationCompiler.compile();
    animatedWater.priority = RenderPriority.water.priority;
    add(animatedWater);
    print('done.');

    print('Loading spawns...');
    loadSpawns(tiledComponent);
    print('done.');

    print('Spawning the Player...');
    camera.viewport = FixedResolutionViewport(Vector2(400, 250));
    // camera.zoom = 1;

    initJoystick(() {
      player?.onFire();
    });

    restorePlayer();
    SoundLibrary().playIntro();
    print('done.');

    print('All done, game started!');
    Flame.device.setLandscape();
    Flame.device.fullScreen();
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

  Future<Player> restorePlayer() async {
    var spawn = await Spawn.waitFree(true);
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

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    // brickRenderer.render(canvas);
    if (false) {
      final cd = collisionDetection as QuadTreeCollisionDetection;
      final boxes = cd.collisionQuadBoxes;
      final boxPaint = Paint();
      boxPaint.color = Colors.blue.withOpacity(0.5);
      boxPaint.strokeWidth = 2;
      boxPaint.style = PaintingStyle.stroke;

      final boxRootPaint = Paint();
      boxRootPaint.color = Colors.red.withOpacity(0.8);
      boxRootPaint.strokeWidth = 2;
      boxRootPaint.style = PaintingStyle.stroke;

      camera.viewport.apply(canvas);
      for (final rect in boxes) {
        canvas.drawRect(rect.rect, boxPaint);
        for (final hb in rect.hitboxes) {
          if (rect.hasChildren) {
            canvas.drawRect(
                Rect.fromLTRB(
                    hb.aabb.min.x, hb.aabb.min.y, hb.aabb.max.x, hb.aabb.max.y),
                boxRootPaint);
          } else {
            canvas.drawRect(
                Rect.fromLTRB(
                    hb.aabb.min.x, hb.aabb.min.y, hb.aabb.max.x, hb.aabb.max.y),
                boxPaint);
          }
        }
        hudTextPaintNormal.render(
            canvas, rect.count.toString(), rect.rect.topCenter.toVector2());
      }
      final playerPos = player?.absoluteTopLeftPosition.toOffset();
      if (playerPos != null) {
        canvas.drawCircle(playerPos, 3, boxPaint);
      }
    } else {
      // if (isPlayerHiddenFromEnemy) {
      //   hudTextPaintGood.render(canvas, 'HIDDEN', Vector2(70, 2));
      // } else {
      //   hudTextPaintNormal.render(canvas, 'VISIBLE', Vector2(70, 2));
      // }
    }
  }
}
