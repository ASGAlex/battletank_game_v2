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
import 'package:tank_game/world/tank/tank.dart';
import 'package:tank_game/world/world.dart';
import 'package:tiled/tiled.dart';

class MyGame extends FlameGame
    with
        FPSCounter,
        ColorFilterMix,
        HasKeyboardHandlerComponents,
        SingleGameInstance,
        HasCollisionDetection,
        ScrollDetector,
        ObjectLayers {
  MyGame(this.mapFile);

  static final fpsTextPaint = TextPaint(
    style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
  );

  String mapFile;

  final lazyCollisionService = LazyCollisionsService();

  // final treeController = TreeController();
  // final waterController = WaterController();

  bool isPlayerHiddenFromEnemy = false;

  // @override
  // bool debugMode = true;

  @override
  Future<void> onLoad() async {
    super.onLoad();
    initColorFilter<MyGame>();

    var tiledComponent = await TiledComponent.load(mapFile, Vector2.all(8));

    add(TileProcessor.getPictureComponent(
        tileMap: tiledComponent.tileMap, layerNames: ['ground']));

    add(TileProcessor.getPictureComponent(
        tileMap: tiledComponent.tileMap, layerNames: ['tree'])
      ..priority = RenderPriority.tree.priority);

    // add(TileProcessor.getPictureComponent(
    //     tileMap: tiledComponent.tileMap, layerNames: ['water'])
    //   ..priority = RenderPriority.water.priority);

    await lazyCollisionService.run({
      'tree': const Duration(milliseconds: 700),
      'water': const Duration(milliseconds: 50)
    });

    final compiler = AnimationBatchCompiler();

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
            final collision = tile.getCollisionRect();
            if (collision != null) {
              collision.position = position;
              lazyCollisionService.addHitbox(
                  position: position, size: size, layer: 'water');
            }
            compiler.addTile(position, tile);
          })
        },
        layersToLoad: [
          'tree',
          'water'
        ]);

    final animatedWater = await compiler.compile();
    animatedWater.priority = RenderPriority.water.priority;
    add(animatedWater);

    // tiledComponent.tileMap.map.layers.removeWhere((element) =>
    //     ['ground', 'collision', 'interaction'].contains(element.name));
    // tiledComponent.tileMap.refreshCache();
    // tiledComponent.priority = RenderPriority.tree.priority;
    //
    // add(tiledComponent);

    loadSpawns(tiledComponent);

    loadInteractiveObjects(tiledComponent);
    loadSounds();

    camera.viewport = FixedResolutionViewport(Vector2(1366, 768));
    camera.zoom = 2.5;
    restorePlayer();
    // spawnEnemy();
  }

  Map<String, ComponentBuilder> componentByType = {
    'brick': (tile, pos, size) => Brick(tile, position: pos, size: size),
    'heavy_brick': (tile, pos, size) =>
        HeavyBrick(tile, position: pos, size: size),
  };

  loadInteractiveObjects(TiledComponent tiledComponent) {
    const layersToLoad = ['collision'];

    TileProcessor.createComponentsFromTiles(
        tileMap: tiledComponent.tileMap,
        componentByType: componentByType,
        layersToLoad: layersToLoad,
        game: this);
  }

  loadSpawns(TiledComponent tiledComponent) {
    final spawns =
        tiledComponent.tileMap.getLayer<ObjectGroup>('spawn')?.objects;
    if (spawns != null) {
      for (final spawnObject in spawns) {
        addSpawn(Spawn(
            position: Vector2(spawnObject.x + spawnObject.width / 2,
                spawnObject.y + spawnObject.height / 2),
            isForPlayer: spawnObject.name == 'spawn_player'));
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
      () => Sfx('explosion_enemy.m4a', 3),
      () => Sfx('player_fire_bullet.m4a', 10),
      () => Sfx('player_bullet_wall.m4a', 10),
      () => Sfx('player_bullet_strong_wall.m4a', 10),
      () => Sfx('bullet_strong_tank.m4a', 10),
    ];
    sound.init(sfxList);
  }

  Future<Player> restorePlayer() async {
    var spawn = await Spawn.waitFree(true);
    final object = Player(position: spawn.position.clone());
    await spawn.createTank(object, true);
    camera.followComponent(object);
    return object;
  }

  Future<Enemy> spawnEnemy() async {
    var spawn = await Spawn.waitFree();
    final object = Enemy(position: spawn.position.clone());
    await spawn.createTank(object, true);
    return object;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // if (debugMode) {
    fpsTextPaint.render(canvas, fps(120).toString(), Vector2(10, 2));
    // }

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
    if (isPlayerHiddenFromEnemy) {
      hudTextPaintGood.render(canvas, 'HIDDEN', Vector2(70, 2));
    } else {
      hudTextPaintNormal.render(canvas, 'VISIBLE', Vector2(70, 2));
    }
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
