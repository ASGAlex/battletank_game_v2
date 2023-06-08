import 'package:flame/camera.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flame_spatial_grid/flame_spatial_grid.dart';
import 'package:flutter/material.dart' hide Image;
import 'package:tank_game/controls/gamepad.dart';
import 'package:tank_game/controls/keyboard.dart';
import 'package:tank_game/packages/color_filter/lib/color_filter.dart';
import 'package:tank_game/services/settings/controller.dart';
import 'package:tank_game/ui/game/flash_message.dart';
import 'package:tank_game/ui/game/visibility_indicator.dart';
import 'package:tank_game/ui/widgets/console_messages.dart';
import 'package:tank_game/world/actors/human/human.dart';
import 'package:tank_game/world/core/actor.dart';
import 'package:tank_game/world/core/behaviors/attacks/bullet.dart';
import 'package:tank_game/world/core/behaviors/player_controlled_behavior.dart';
import 'package:tank_game/world/core/faction.dart';
import 'package:tank_game/world/environment/spawn/spawn_entity.dart';
import 'package:tank_game/world/environment/spawn/spawn_manager.dart';
import 'package:tank_game/world/environment/spawn/trigger_spawn_behavior.dart';
import 'package:tank_game/world/environment/tree/tree.dart';
import 'package:tank_game/world/environment/water/water.dart';
import 'package:tank_game/world/map_loader.dart';
import 'package:tank_game/world/world.dart';

abstract class MyGameFeatures extends FlameGame
    with
        ColorFilterMix,
        KeyboardEvents,
        SingleGameInstance,
        HasSpatialGridFramework,
        ScrollDetector {
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

  final initialPlayerPosition = Vector2(0, 0);

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

    cameraComponent = CameraComponent(
        world: gameWorld,
        viewport: FixedAspectRatioViewport(aspectRatio: 400 / 250));
    cameraComponent.viewfinder.zoom = 5;

    await initializeSpatialGrid(
        blockSize: 100,
        debug: false,
        activeRadius: const Size(1, 1),
        unloadRadius: const Size(2, 2),
        preloadRadius: const Size(2, 2),
        buildCellsPerUpdate: 1,
        cleanupCellsPerUpdate: 2,
        processCellsLimitToPauseEngine: 2,
        rootComponent: gameWorld,
        trackWindowSize: true,
        trackedComponent: SpatialGridCameraWrapper(cameraComponent),
        initialPositionChecker: (layer, object, mapOffset, worldName) {
          if (object.name == 'spawn_player') {
            initialPlayerPosition.setValues(object.x, object.y);
            return cameraComponent.viewfinder.position =
                mapOffset + Vector2(object.x, object.y);
          }
        },
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
    await _loadExternalTileSets();

    consoleMessages.sendMessage('done.');

    consoleMessages.sendMessage('Starting UI');
    // if (Platform.isAndroid || Platform.isIOS) {
    // initJoystick(inputEventsHandler.handleFireEvent);
    // inputEventsHandler.getCurrentAngle = () => joystick!.knobAngleDegrees;
    // }
    hudVisibility = VisibilityIndicator(this);
    hudVisibility.setVisibility(true);
    hudVisibility.x = 2;
    hudVisibility.y = 2;

    hudFlashMessage = FlashMessage(
        position: hudVisibility.position.clone()..translate(100, 0));

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

  bool _initialized = false;

  @override
  void onInitializationDone() {
    if (_initialized) return;
    cameraComponent.viewfinder.zoom = 5;

    onAfterZoom();
    if (!(currentPlayer?.isMounted ?? false)) {
      restorePlayer();
    }
    _initialized = true;
  }

  void restorePlayer() {
    if (true) {
      currentPlayer = HumanEntity()
        ..isInteractionEnabled = true
        ..add(TriggerSpawnBehavior())
        ..position = cameraComponent.viewfinder.position
        ..data.factions.add(Faction(name: 'Player'));

      SpawnManager().spawnNewActor(
          actor: currentPlayer!,
          faction: Faction(name: 'Player'),
          onSpawnComplete: () {
            currentPlayer!.add(PlayerControlledBehavior());
            cameraComponent.follow(currentPlayer!);
          });
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
    // player?.onRemove();
  }

  @override
  bool pureTypeCheck(Type activeItemType, Type potentialItemType) {
    if (activeItemType == BulletEntity) {
      if (potentialItemType == WaterEntity ||
          potentialItemType == TreeEntity ||
          potentialItemType == SpawnEntity) {
        return false;
      }
    }

    return true;
  }
}
