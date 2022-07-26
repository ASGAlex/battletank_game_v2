import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/image_composition.dart';
import 'package:flame/input.dart';
import 'package:flame_tiled/flame_tiled.dart';
import 'package:flutter/material.dart';
import 'package:tank_game/services/color_filter/color_filter.dart';
import 'package:tank_game/services/lazy_collision/lazy_collision.dart';
import 'package:tank_game/services/sound/sound.dart';
import 'package:tank_game/services/tiled_utils/tiled_utils.dart';
import 'package:tank_game/world/environment/brick.dart';
import 'package:tank_game/world/environment/heavy_brick.dart';
import 'package:tank_game/world/environment/spawn.dart';
import 'package:tank_game/world/environment/water.dart';
import 'package:tank_game/world/tank/tank.dart';
import 'package:tank_game/world/world.dart';
import 'package:tiled/tiled.dart';

import 'services/collision_quad_tree/collision_quad_tree.dart';

class MyGame extends FlameGame
    with
        ColorFilterMix,
        HasKeyboardHandlerComponents,
        SingleGameInstance,
        HasQuadTreeCollisionDetection,
        ScrollDetector,
        ObjectLayers {
  MyGame(this.mapFile);

  static final fpsTextPaint = TextPaint(
    style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
  );

  String mapFile;

  final lazyCollisionService = LazyCollisionsService();

  bool isPlayerHiddenFromEnemy = false;
  List<Enemy> enemies = [];
  Player? player;

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
    backgroundColor: Colors.black12,
  ));

  @override
  Future<void> onLoad() async {
    print('Start loading!');
    super.onLoad();
    initColorFilter<MyGame>();

    print('loading sounds...');
    loadSounds();
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
    // collisionDetection =
    //     OptimizedCollisionDetection.fromMap(tiledComponent.tileMap);
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
          'brick': ((tile, position, size) {
            add(Brick(tile, position: position, size: size));
          }),
          'heavy_brick': ((tile, position, size) {
            add(HeavyBrick(tile, position: position, size: size));
          }),
        },
        layersToLoad: [
          'tree',
          'collision'
        ]);
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
    camera.viewport = FixedResolutionViewport(Vector2(1366, 768));
    camera.zoom = 2;

    restorePlayer();
    print('done.');

    // Future.delayed(const Duration(seconds: 5)).then((value) {
    //   for (var i = 0; i < 1; i++) {
    //     spawnEnemy();
    //   }
    // });

    print('Prepare UI...');
    add(FpsTextComponent(textRenderer: hudTextPaintDanger)
      ..x = 0
      ..y = 0);
    print('done.');

    print('All done, game started!');
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

  loadSounds() {
    final sound = Sound();
    sound.playMusic('intro.m4a');
    final sfxList = [
      () => SfxLongLoop('move_player.m4a'),
      () => SfxLongLoop('move_enemies.m4a'),
      () => Sfx('explosion_player.m4a', 2),
      () => Sfx('explosion_enemy.m4a', 10),
      () => Sfx('player_fire_bullet.m4a', 50),
      () => Sfx('player_bullet_wall.m4a', 25),
      () => Sfx('player_bullet_strong_wall.m4a', 25),
      () => Sfx('bullet_strong_tank.m4a', 25),
    ];
    sound.init(sfxList);
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
    //
    // final cd = collisionDetection as QuadTreeCollisionDetection;
    // final boxes = cd.collisionQuadBoxes;
    // final boxPaint = Paint();
    // boxPaint.color = Colors.blue.withOpacity(0.5);
    // boxPaint.strokeWidth = 2;
    // boxPaint.style = PaintingStyle.stroke;
    // camera.viewport.apply(canvas);
    // for (final rect in boxes) {
    //   canvas.drawRect(rect.rect, boxPaint);
    //   for (final hb in rect.hitboxes) {
    //     canvas.drawRect(
    //         Rect.fromLTRB(
    //             hb.aabb.min.x, hb.aabb.min.y, hb.aabb.max.x, hb.aabb.max.y),
    //         boxPaint);
    //   }
    //   hudTextPaintNormal.render(
    //       canvas, rect.count.toString(), rect.rect.topCenter.toVector2());
    // }
    // final playerPos = player?.absoluteTopLeftPosition.toOffset();
    // if (playerPos != null) {
    //   canvas.drawCircle(playerPos, 3, boxPaint);
    // }
    // if (isPlayerHiddenFromEnemy) {
    //   hudTextPaintGood.render(canvas, 'HIDDEN', Vector2(70, 2));
    // } else {
    //   hudTextPaintNormal.render(canvas, 'VISIBLE', Vector2(70, 2));
    // }
  }

  static const zoomPerScrollUnit = 0.02;
  late double startZoom;

  @override
  void onScroll(PointerScrollInfo info) {
    camera.zoom += info.scrollDelta.game.y.sign * zoomPerScrollUnit;
    clampZoom();
  }

  void clampZoom() {
    camera.zoom = camera.zoom.clamp(0.05, 5.0);
  }
}
