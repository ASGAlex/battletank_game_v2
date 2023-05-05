import 'dart:io';

import 'package:flame/experimental.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flame_spatial_grid/flame_spatial_grid.dart';
import 'package:flutter/material.dart' hide Image;
import 'package:tank_game/controls/gamepad.dart';
import 'package:tank_game/controls/keyboard.dart';
import 'package:tank_game/extensions.dart';
import 'package:tank_game/packages/color_filter/lib/color_filter.dart';
import 'package:tank_game/packages/tiled_utils/lib/tiled_utils.dart';
import 'package:tank_game/services/settings/controller.dart';
import 'package:tank_game/ui/game/flash_message.dart';
import 'package:tank_game/ui/game/visibility_indicator.dart';
import 'package:tank_game/ui/widgets/console_messages.dart';
import 'package:tank_game/world/actors/human/human.dart';
import 'package:tank_game/world/core/actor.dart';
import 'package:tank_game/world/core/behaviors/player_controlled_behavior.dart';
import 'package:tank_game/world/core/faction.dart';
import 'package:tank_game/world/environment/spawn/spawn_manager.dart';
import 'package:tank_game/world/environment/spawn/trigger_spawn_behavior.dart';
import 'package:tank_game/world/map_loader.dart';
import 'package:tank_game/world/world.dart';

abstract class MyGameFeatures extends FlameGame
    with
        ColorFilterMix,
        KeyboardEvents,
        SingleGameInstance,
        HasSpatialGridFramework,
        ScrollDetector,
        HasDraggables,
        HasTappables {
  GameWorld get world => rootComponent as GameWorld;
}

class MyGame extends MyGameFeatures with GameHardwareKeyboard, XInputGamePad {
  MyGame(this.mapFile, this.context);

  static const zoomPerScrollUnit = 0.22;
  static final fpsTextPaint = TextPaint(
    style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
  );

  final String mapFile;
  final BuildContext context;

  ActorMixin? currentPlayer;

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
        blockSize: 200,
        debug: false,
        activeRadius: const Size(1, 1),
        unloadRadius: const Size(1, 1),
        preloadRadius: const Size(1, 1),
        buildCellsPerUpdate: 2,
        cleanupCellsPerUpdate: 2,
        processCellsLimitToPauseEngine: 15,
        rootComponent: gameWorld,
        trackedComponent: SpatialGridCameraWrapper(cameraComponent),
        suspendedCellLifetime: const Duration(seconds: 120),
        suspendCellPrecision: const Duration(seconds: 30),
        cellBuilderNoMap: map.noMapBuilder,
        // onAfterCellBuild: (cell, rootComponent) async {
        //   final trailLayer = CellTrailLayer(cell, name: 'trail');
        //   trailLayer.priority = RenderPriority.trackTrail.priority;
        //   trailLayer.optimizeCollisions = false;
        //   trailLayer.fadeOutConfig = world.fadeOutConfig;
        //   layersManager.addLayer(trailLayer);
        // },
        maps: [map]);

    // cameraComponent.moveTo(map.cameraInitialPosition);
    cameraComponent.viewfinder.position = map.cameraInitialPosition;

    await _loadExternalTileSets();

    consoleMessages.sendMessage('done.');

    consoleMessages.sendMessage('Starting UI');
    if (Platform.isAndroid || Platform.isIOS) {
      // initJoystick(inputEventsHandler.handleFireEvent);
      // inputEventsHandler.getCurrentAngle = () => joystick!.knobAngleDegrees;
    }
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

    // Spawn.waitFree(true).then((playerSpawn) async {
    //   if (player == null || player?.dead == true) {
    //     // spatialGrid.trackedComponent = playerSpawn;
    //     cameraComponent.follow(playerSpawn, maxSpeed: 60);
    //     await restorePlayer(playerSpawn);
    //     // SoundLibrary().playIntro();
    //     consoleMessages.sendMessage('done.');
    //     consoleMessages.sendMessage('All done, game started!');
    //   }
    // });
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

  @override
  void onInitializationDone() {
    if (!(currentPlayer?.isMounted ?? false)) {
      //cameraComponent.viewfinder.position = map.cameraInitialPosition;
      restorePlayer();
    }
  }

  void restorePlayer() {
    if (true) {
      currentPlayer = HumanEntity()
        ..isInteractionEnabled = true
        ..add(TriggerSpawnBehavior())
        ..add(PlayerControlledBehavior())
        ..data.factions.add(Faction(name: 'Player'));

      cameraComponent.follow(currentPlayer!);

      SpawnManager().spawnNewActor(
          actor: currentPlayer!, faction: Faction(name: 'Player'));
    } else {
      overlays.add('game_over_fail');
      onEndGame();
      return null;
    }
  }

  @override
  void onDetach() {
    onEndGame();
  }

  void onEndGame() {
    TileProcessor.clearCache();
    // player?.onRemove();
  }
}
