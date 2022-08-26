import 'package:flame/game.dart';
import 'package:flame/image_composition.dart';
import 'package:flame/input.dart';
import 'package:flame_tiled/flame_tiled.dart';
import 'package:flutter/material.dart';
import 'package:tank_game/extensions.dart';
import 'package:tank_game/packages/back_buffer/lib/back_buffer.dart';
import 'package:tank_game/packages/back_buffer/lib/batch_components.dart';
import 'package:tank_game/packages/collision_quad_tree/lib/collision_quad_tree.dart';
import 'package:tank_game/packages/color_filter/lib/color_filter.dart';
import 'package:tank_game/packages/flame_clusterizer/lib/clusterizer.dart';
import 'package:tank_game/packages/lazy_collision/lib/lazy_collision.dart';
import 'package:tank_game/packages/tiled_utils/lib/tiled_utils.dart';
import 'package:tank_game/services/settings/controller.dart';
import 'package:tank_game/services/spritesheet/spritesheet.dart';
import 'package:tank_game/ui/game/controls/gamepad.dart';
import 'package:tank_game/ui/game/controls/joystick.dart';
import 'package:tank_game/ui/game/controls/keyboard.dart';
import 'package:tank_game/ui/game/flash_message.dart';
import 'package:tank_game/ui/game/visibility_indicator.dart';
import 'package:tank_game/ui/widgets/console_messages.dart';
import 'package:tank_game/world/environment/spawn.dart';
import 'package:tank_game/world/environment/tree.dart';
import 'package:tank_game/world/world.dart';
import 'package:tiled/tiled.dart';

import 'world/environment/brick.dart';
import 'world/environment/heavy_brick.dart';
import 'world/environment/target.dart';
import 'world/environment/water.dart';
import 'world/tank/enemy.dart';
import 'world/tank/player.dart';

abstract class MyGameFeatures extends FlameGame
    with
        ColorFilterMix,
        KeyboardEvents,
        SingleGameInstance,
        HasQuadTreeCollisionDetection,
        ScrollDetector,
        HasDraggables,
        HasTappables,
        ObjectLayers {
  static const zoomPerScrollUnit = 0.02;

  @override
  void onScroll(PointerScrollInfo info) {
    camera.zoom += info.scrollDelta.game.y.sign * zoomPerScrollUnit;
    clampZoom();
  }

  void clampZoom() {
    camera.zoom = camera.zoom.clamp(0.05, 5.0);
  }
}

class MyGame extends MyGameFeatures
    with MyJoystickMix, GameHardwareKeyboard, XInputGamePad {
  MyGame(this.mapFile, this.context);

  static final fpsTextPaint = TextPaint(
    style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
  );

  final String mapFile;
  final BuildContext context;

  final lazyCollisionService = LazyCollisionsService();

  List<Enemy> enemies = [];
  Player? player;

  BatchComponentRenderer? batchRenderer;

  RenderableTiledMap? currentMap;

  BackBuffer? backBuffer;

  ConsoleMessagesController get consoleMessages =>
      SettingsController().consoleMessages;

  VisibilityIndicator? hudVisibility;
  FlashMessage? hudFlashMessage;
  Clusterizer? clusterizer;

  @override
  Future<void> onLoad() async {
    consoleMessages.sendMessage('Start loading!');
    super.onLoad();
    initColorFilter<MyGame>();

    consoleMessages.sendMessage('loading sounds...');
    // SoundLibrary().init();
    consoleMessages.sendMessage('done.');

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

    clusterizer = Clusterizer(Vector2(mapWidth, mapHeight), Vector2(200, 200),
        this, isFragmentVisible);
    consoleMessages.sendMessage('Compiling ground layer...');
    final imageCompiler = ImageBatchCompiler();
    final ground = await imageCompiler.compileMapLayer(
        tileMap: tiledComponent.tileMap, layerNames: ['ground']);
    ground.priority = RenderPriority.ground.priority;
    final groundMap = await clusterizer?.splitImageComponent(ground);
    if (groundMap != null) {
      for (final g in groundMap.entries) {
        g.key.components.addAll(g.value);
        addAll(g.value);
      }
    }
    consoleMessages.sendMessage('done.');

    consoleMessages.sendMessage('Compiling tree layer...');
    final tree = await imageCompiler
        .compileMapLayer(tileMap: tiledComponent.tileMap, layerNames: ['tree']);
    final trees = await clusterizer?.splitImageComponent(tree);
    if (trees != null) {
      for (final entry in trees.entries) {
        for (final t in entry.value) {
          final treeWithShadow = TreeLayer(t, t.image.width, t.image.height);
          treeWithShadow.priority = RenderPriority.tree.priority;
          treeWithShadow.position = t.position;
          add(treeWithShadow);
          entry.key.components.add(treeWithShadow);
        }
      }
    }
    consoleMessages.sendMessage('done.');

    consoleMessages.sendMessage('Preparing back buffer...');
    backBuffer = BackBuffer(mapWidth.toInt(), mapHeight.toInt(), 2, 10, 0.98);
    add(backBuffer!);
    consoleMessages.sendMessage('done.');

    consoleMessages.sendMessage('Starting lazy collision service...');
    await lazyCollisionService.run({
      'tree': const Duration(milliseconds: 100),
    });
    consoleMessages.sendMessage('done.');

    consoleMessages.sendMessage('Creating trees and collision tiles...');
    final settings = SettingsController();
    switch (settings.graphicsQuality) {
      case GraphicsQuality.low:
      case GraphicsQuality.treeShadow:
        batchRenderer = BatchComponentRenderer(
            mapWidth.toInt(), mapHeight.toInt(),
            offsetSteps: 0,
            drawShadow: false,
            offsetShadowSteps: 0,
            offsetDirection: null);
        break;
      case GraphicsQuality.walls3D_low:
        batchRenderer = BatchComponentRenderer(
            mapWidth.toInt(), mapHeight.toInt(),
            offsetSteps: 2,
            drawShadow: false,
            offsetShadowSteps: 0,
            offsetDirection: const Offset(2, -2));
        break;
      case GraphicsQuality.walls3dShadows_low:
        batchRenderer = BatchComponentRenderer(
            mapWidth.toInt(), mapHeight.toInt(),
            offsetSteps: 2,
            drawShadow: true,
            offsetShadowSteps: 2,
            offsetDirection: const Offset(2, -2));
        break;
      case GraphicsQuality.walls3DShadows_medium:
        batchRenderer = BatchComponentRenderer(
            mapWidth.toInt(), mapHeight.toInt(),
            offsetSteps: 3,
            drawShadow: true,
            offsetShadowSteps: 2,
            offsetDirection: const Offset(1.3, -1.3));
        break;
      case GraphicsQuality.walls3dShadows_hight:
        batchRenderer = BatchComponentRenderer(
            mapWidth.toInt(), mapHeight.toInt(),
            offsetSteps: 4,
            drawShadow: true,
            offsetShadowSteps: 4,
            offsetDirection: const Offset(1.1, -1.1));
        break;
    }

    batchRenderer?.priority = RenderPriority.walls.priority;
    TileProcessor.processTileType(
        tileMap: tiledComponent.tileMap,
        processorByType: <String, TileProcessorFunc>{
          'tree': ((tile) {
            final collision = tile.getCollisionRect();
            if (collision != null) {
              collision.position = tile.position;
              lazyCollisionService.addHitbox(
                  position: tile.position, size: size, layer: 'tree');
            }
          }),
          'water': ((tile) {
            add(WaterCollide(tile, position: tile.position, size: size));
          }),
          'brick': ((tile) async {
            final brick = Brick(tile, position: tile.position, size: size);
            add(brick);
            batchRenderer?.batchedComponents.add(brick);
          }),
          'heavy_brick': ((tile) async {
            final brick =
                HeavyBrick(tile, position: tile.position, size: tile.size);
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
    final fragmentData = <Fragment, AnimationBatchCompiler>{};
    TileProcessor.processTileType(
        tileMap: tiledComponent.tileMap,
        processorByType: <String, TileProcessorFunc>{
          'water': ((tile) {
            final fragment = clusterizer?.findFragmentByPosition(tile.position);
            if (fragment != null) {
              if (fragmentData[fragment] == null) {
                fragmentData[fragment] = AnimationBatchCompiler();
              }
              fragmentData[fragment]!.addTile(tile.position, tile);
            }
          }),
        },
        layersToLoad: [
          'water',
        ]);
    consoleMessages.sendMessage('done.');

    consoleMessages.sendMessage('Compiling water animation...');
    for (final entry in fragmentData.entries) {
      final fragment = entry.key;
      final compiler = entry.value;
      final animatedWater = await compiler.compile();
      animatedWater.priority = RenderPriority.water.priority;
      add(animatedWater);
      fragment.components.add(animatedWater);
    }
    consoleMessages.sendMessage('done.');

    consoleMessages.sendMessage('Loading spawns...');
    loadSpawns(tiledComponent);
    loadTargets(tiledComponent);
    consoleMessages.sendMessage('done.');

    consoleMessages.sendMessage('Starting UI');
    initJoystick(() {
      player?.onFire();
    });
    hudVisibility = VisibilityIndicator(this);
    hudVisibility!.setVisibility(true);
    hudVisibility!.x = 2;
    hudVisibility!.y = 2;
    add(hudVisibility!);

    hudFlashMessage =
        FlashMessage(position: hudVisibility!.position.translate(100, 0));
    add(hudFlashMessage!);

    consoleMessages.sendMessage('done.');

    consoleMessages.sendMessage('Spawning the Player...');
    camera.viewport = FixedResolutionViewport(Vector2(400, 250));
    camera.worldBounds = Rect.fromLTWH(0, 0, mapWidth, mapHeight);
    camera.zoom = 0.3;

    final playerSpawn = await Spawn.waitFree(true);
    camera.followComponent(playerSpawn);
    restorePlayer(playerSpawn);
    // SoundLibrary().playIntro();
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
              final distance = double.parse(property.value);
              newSpawn.triggerDistanceSquared = distance * distance;
              break;
            case 'tank_type':
              newSpawn.tankTypeFactory.typeName = property.value;
              break;
          }
        }
        addSpawn(newSpawn);
      }
    }
  }

  loadTargets(TiledComponent tiledComponent) {
    final targets =
        tiledComponent.tileMap.getLayer<ObjectGroup>('target')?.objects;
    if (targets != null) {
      for (final targetObject in targets) {
        var primary = true;
        var protectFromEnemies = false;
        for (final property in targetObject.properties) {
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
            position: Vector2(targetObject.x, targetObject.y),
            primary: primary,
            protectFromEnemies: protectFromEnemies);
        addSpawn(newTarget);
      }
    }
  }

  onObjectivesStateChange(String message, FlashMessageType type,
      [bool finishGame = false]) {
    hudFlashMessage?.showMessage(message, type);
    if (finishGame) {
      Future.delayed(const Duration(seconds: 5)).then((value) {
        paused = true;
        if (type == FlashMessageType.good) {
          overlays.add('game_over_success');
        } else {
          overlays.add('game_over_fail');
        }
        onEndGame();
      });
    }
  }

  Future<Player?> restorePlayer([Spawn? spawn]) async {
    if (Player.respawnCount > 0) {
      spawn ??= await Spawn.waitFree(true);
      camera.followComponent(spawn);
      final object = Player(position: spawn.position.clone());
      await spawn.createTank(object, true);
      camera.followComponent(object);
      player = object;
      Player.respawnCount--;
      return object;
    } else {
      overlays.add('game_over_fail');
      onEndGame();
      return null;
    }
  }

  Future<Enemy> spawnEnemy() async {
    var spawn = await Spawn.waitFree();
    final object = Enemy(position: spawn.position.clone());
    await spawn.createTank(object, true);
    enemies.add(object);
    return object;
  }

  @override
  void onDetach() {
    onEndGame();
  }

  @override
  void update(double dt) {
    super.update(dt);
    clusterizer?.findCurrentFragment();
  }

  bool isFragmentVisible(Fragment fragment) {
    final pos = camera.follow ?? camera.position;
    final center = Vector2(pos.x, pos.y);
    return fragment.rect.containsPoint(center);
  }

  void onEndGame() {
    TileProcessor.clearCache();
    Spawn.clear();
    Target.clear();
    player?.onRemove();
    lazyCollisionService.stop();
    SpriteSheetBase.clearCaches();
    Player.respawnCount = 30;
  }
}
