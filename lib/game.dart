import 'package:flame/experimental.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flame_spatial_grid/flame_spatial_grid.dart';
import 'package:flutter/material.dart' hide Image;
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
import 'package:tank_game/world/environment/spawn.dart';
import 'package:tank_game/world/map_loader.dart';
import 'package:tank_game/world/world.dart';

import 'world/environment/target.dart';
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
    // cameraComponent.viewfinder.zoom = 22;

    await initializeSpatialGrid(
        blockSize: 100,
        debug: false,
        activeRadius: const Size(2, 2),
        unloadRadius: const Size(3, 3),
        preloadRadius: const Size(5, 5),
        buildCellsPerUpdate: 1,
        processCellsLimitToPauseEngine: 25,
        rootComponent: gameWorld,
        trackedComponent: SpatialGridCameraWrapper(cameraComponent),
        // onAfterCellBuild: (cell, rootComponent) async {
        //   final trailLayer = CellTrailLayer(cell, name: 'trail');
        //   trailLayer.priority = RenderPriority.trackTrail.priority;
        //   trailLayer.optimizeCollisions = false;
        //   trailLayer.fadeOutConfig = world.fadeOutConfig;
        //   layersManager.addLayer(trailLayer);
        // },
        suspendedCellLifetime: const Duration(minutes: 2),
        maps: [map]);

    cameraComponent.moveTo(map.cameraInitialPosition);

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
      if (player == null || player?.dead == true) {
        // spatialGrid.trackedComponent = playerSpawn;
        cameraComponent.follow(playerSpawn, maxSpeed: 60);
        await restorePlayer(playerSpawn);
        // SoundLibrary().playIntro();
        consoleMessages.sendMessage('done.');
        consoleMessages.sendMessage('All done, game started!');
      }
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
      player!.health = 1000;
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
