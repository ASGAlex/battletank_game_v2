import 'package:flame/experimental.dart';
import 'package:flame/game.dart';
import 'package:flame/image_composition.dart';
import 'package:flame/input.dart';
import 'package:flame_spatial_grid/flame_spatial_grid.dart';
import 'package:flame_tiled/flame_tiled.dart';
import 'package:flutter/material.dart';
import 'package:tank_game/extensions.dart';
import 'package:tank_game/packages/color_filter/lib/color_filter.dart';
import 'package:tank_game/packages/tiled_utils/lib/tiled_utils.dart';
import 'package:tank_game/services/settings/controller.dart';
import 'package:tank_game/ui/game/controls/gamepad.dart';
import 'package:tank_game/ui/game/controls/joystick.dart';
import 'package:tank_game/ui/game/controls/keyboard.dart';
import 'package:tank_game/ui/game/flash_message.dart';
import 'package:tank_game/ui/game/visibility_indicator.dart';
import 'package:tank_game/ui/widgets/console_messages.dart';
import 'package:tank_game/world/environment/shadow.dart';
import 'package:tank_game/world/environment/spawn.dart';
import 'package:tank_game/world/environment/tree.dart';
import 'package:tank_game/world/world.dart';

import 'world/environment/brick.dart';
import 'world/environment/heavy_brick.dart';
import 'world/environment/target.dart';
import 'world/environment/water.dart';
import 'world/tank/core/tank_type_controller.dart';
import 'world/tank/enemy.dart';
import 'world/tank/player.dart';

abstract class MyGameFeatures extends FlameGame
    with
        ColorFilterMix,
        KeyboardEvents,
        SingleGameInstance,
        HasSpatialGridFramework,
        ScrollDetector,
        ScaleDetector,
        HasDraggables,
        HasTappables {
  GameWorld get world => rootComponent as GameWorld;
}

class MyGame extends MyGameFeatures
    with MyJoystickMix, GameHardwareKeyboard, XInputGamePad {
  MyGame(this.mapFile, this.context);

  static const zoomPerScrollUnit = 0.22;
  static final fpsTextPaint = TextPaint(
    style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
  );

  final String mapFile;
  final BuildContext context;

  List<Enemy> enemies = [];
  Player? player;

  ConsoleMessagesController get consoleMessages =>
      SettingsController().consoleMessages;

  late VisibilityIndicator hudVisibility;
  late FlashMessage hudFlashMessage;
  late final CameraComponent cameraComponent;

  late final GameMapLoader map;

  @override
  void onScroll(PointerScrollInfo info) {
    var zoom = cameraComponent.viewfinder.zoom;
    zoom += info.scrollDelta.game.y.sign * zoomPerScrollUnit;
    cameraComponent.viewfinder.zoom = zoom.clamp(0.1, 8.0);
    onAfterZoom();
  }

  @override
  void onScaleUpdate(ScaleUpdateInfo info) {
    var zoom = cameraComponent.viewfinder.zoom;
    zoom += info.delta.game.y.sign * zoomPerScrollUnit;
    cameraComponent.viewfinder.zoom = zoom.clamp(0.1, 8.0);
  }

  @override
  Future<void> onLoad() async {
    consoleMessages.sendMessage('Start loading!');
    super.onLoad();
    initColorFilter<MyGame>();

    consoleMessages.sendMessage('loading sounds...');
    // SoundLibrary().init();
    consoleMessages.sendMessage('done.');

    consoleMessages.sendMessage('loading map...');

    final gameWorld = GameWorld();
    map = GameMapLoader(mapFile);

    cameraComponent = CameraComponent.withFixedResolution(
        world: gameWorld, width: 400, height: 250);
    cameraComponent.moveTo(Vector2(378, 731));
    // cameraComponent.viewfinder.zoom = 22;

    await initializeSpatialGrid(
        blockSize: 100,
        debug: false,
        activeRadius: const Size(2, 2),
        unloadRadius: const Size(5, 5),
        preloadRadius: const Size(5, 5),
        maximumCells: 150,
        buildCellsPerUpdate: 5,
        removeCellsPerUpdate: 4,
        rootComponent: gameWorld,
        lazyLoad: true,
        trackedComponent: SpatialGridCameraWrapper(cameraComponent),
        trackWindowSize: true,
        // onAfterCellBuild: (cell, rootComponent) async {
        //   final trailLayer = CellTrailLayer(cell, name: 'trail');
        //   trailLayer.priority = RenderPriority.trackTrail.priority;
        //   trailLayer.optimizeCollisions = false;
        //   trailLayer.fadeOutConfig = world.fadeOutConfig;
        //   layersManager.addLayer(trailLayer);
        // },
        suspendedCellLifetime: const Duration(minutes: 1),
        maps: [map]);

    await _loadExternalTileSets();

    consoleMessages.sendMessage('done.');

    consoleMessages.sendMessage('Starting UI');
    initJoystick(() {
      player?.onFire();
    });
    hudVisibility = VisibilityIndicator(this);
    hudVisibility.setVisibility(true);
    hudVisibility.x = 2;
    hudVisibility.y = 2;

    hudFlashMessage =
        FlashMessage(position: hudVisibility.position.translate(100, 0));

    consoleMessages.sendMessage('done.');

    add(gameWorld);
    cameraComponent.viewport.add(hudVisibility);
    cameraComponent.viewport.add(hudFlashMessage);

    consoleMessages.sendMessage('Spawning the Player...');

    Spawn.waitFree(true).then((playerSpawn) async {
      // spatialGrid.trackedComponent = playerSpawn;
      cameraComponent.follow(playerSpawn, snap: true);
      await restorePlayer(playerSpawn);
      // SoundLibrary().playIntro();
      consoleMessages.sendMessage('done.');
      consoleMessages.sendMessage('All done, game started!');
    });
  }

  Future<void> _loadExternalTileSets() {
    final futures = <Future>[];
    futures.add(tilesetManager.loadTileset('tank.tsx'));
    futures.add(tilesetManager.loadTileset('boom.tsx'));
    futures.add(tilesetManager.loadTileset('boom_big.tsx'));
    futures.add(tilesetManager.loadTileset('spawn.tsx'));
    futures.add(tilesetManager.loadTileset('target.tsx'));
    futures.add(tilesetManager.loadTileset('bullet.tsx'));
    return Future.wait(futures);
  }

  onObjectivesStateChange(String message, FlashMessageType type,
      [bool finishGame = false]) {
    hudFlashMessage.showMessage(message, type);
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

      final object = Player(position: spawn.position.clone());
      await spawn.createTank(object, true);
      player = object;
      cameraComponent.follow(player!);
      // spatialGrid.trackedComponent = player;
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

  void onEndGame() {
    TileProcessor.clearCache();
    Spawn.clear();
    Target.clear();
    player?.onRemove();
    Player.respawnCount = 30;
  }
}

class GameMapLoader extends TiledMapLoader {
  GameMapLoader(String fileName) {
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
        'brick': onBuildBrick,
        'heavy_brick': onBuildHeavyBrick,
        'spawn': onBuildSpawn,
        'spawn_player': onBuildSpawnPlayer,
        'target': onBuildTarget,
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
    final tree = Tree(data, position: context.position, size: context.size);
    tree.currentCell = context.cell;
    final shadow0 = ShadowComponent(tree, game);
    final shadow1 = ShadowComponent(tree, game, 1.3);

    game.layersManager.addComponent(
        component: tree,
        layerType: MapLayerType.static,
        layerName: 'Tree',
        priority: RenderPriority.tree.priority);

    game.layersManager.addComponent(
        component: shadow0,
        layerType: MapLayerType.static,
        layerName: 'TreeShadow',
        isRenewable: false,
        optimizeCollisions: false,
        priority: RenderPriority.tree.priority - 1);

    game.layersManager.addComponent(
        component: shadow1,
        layerType: MapLayerType.static,
        layerName: 'TreeShadow',
        isRenewable: false,
        optimizeCollisions: false,
        priority: RenderPriority.tree.priority - 1);
  }

  Future onBuildWater(CellBuilderContext context) async {
    // return;
    final data = context.tileDataProvider;
    if (data == null) return;
    final water = Water(data, position: context.position, size: context.size);
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
    final brick = Brick(data, position: context.position, size: context.size);
    brick.currentCell = context.cell;
    final shadow0 = ShadowComponent(brick, game);
    final shadow1 = ShadowComponent(brick, game, 1.3);

    game.layersManager.addComponent(
        component: brick,
        layerType: MapLayerType.static,
        layerName: 'Brick',
        priority: RenderPriority.walls.priority);

    game.layersManager.addComponent(
        component: shadow0,
        layerType: MapLayerType.static,
        layerName: 'BrickShadow',
        optimizeCollisions: false,
        priority: RenderPriority.walls.priority - 1);

    game.layersManager.addComponent(
        component: shadow1,
        layerType: MapLayerType.static,
        layerName: 'BrickShadow',
        optimizeCollisions: false,
        priority: RenderPriority.walls.priority - 1);
  }

  Future onBuildHeavyBrick(CellBuilderContext context) async {
    // return;
    final data = context.tileDataProvider;
    if (data == null) return;
    final heavyBrick =
        HeavyBrick(data, position: context.position, size: context.size);

    heavyBrick.currentCell = context.cell;
    game.layersManager.addComponent(
        component: heavyBrick,
        layerType: MapLayerType.static,
        layerName: 'HeavyBrick',
        priority: RenderPriority.walls.priority);
  }

  Future onBuildSpawn(CellBuilderContext context) async {
    final properties = context.tiledObject?.properties;
    if (properties == null) return;
    final newSpawn = Spawn(
        position: Vector2(context.position.x + context.size.x / 2,
            context.position.y + context.size.y / 2),
        isForPlayer: false);

    newSpawn.currentCell = context.cell;
    _setupSpawnProperties(newSpawn, properties);

    game.world.addSpawn(newSpawn);
  }

  Future onBuildSpawnPlayer(CellBuilderContext context) async {
    final properties = context.tiledObject?.properties;
    if (properties == null) return;
    final newSpawn = Spawn(
        position: Vector2(context.position.x + context.size.x / 2,
            context.position.y + context.size.y / 2),
        isForPlayer: true);

    newSpawn.currentCell = context.cell;
    _setupSpawnProperties(newSpawn, properties);

    game.cameraComponent.follow(newSpawn);
    game.world.addSpawn(newSpawn);
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
        position: context.position,
        primary: primary,
        protectFromEnemies: protectFromEnemies);
    game.world.addSpawn(newTarget);
  }
}
