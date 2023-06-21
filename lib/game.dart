import 'package:flame/camera.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flame_message_stream/flame_message_stream.dart';
import 'package:flame_spatial_grid/flame_spatial_grid.dart';
import 'package:flutter/material.dart' hide Image;
import 'package:nes_ui/nes_ui.dart';
import 'package:tank_game/controls/gamepad.dart';
import 'package:tank_game/controls/input_events_handler.dart';
import 'package:tank_game/controls/keyboard.dart';
import 'package:tank_game/packages/color_filter/lib/color_filter.dart';
import 'package:tank_game/services/settings/controller.dart';
import 'package:tank_game/ui/game/flash_message.dart';
import 'package:tank_game/ui/game/visibility_indicator.dart';
import 'package:tank_game/ui/intl.dart';
import 'package:tank_game/ui/route_builder.dart';
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
        HasSpatialGridFramework,
        SingleGameInstance,
        ScrollDetector {
  GameWorld get world => rootComponent as GameWorld;
}

class MyGame extends MyGameFeatures
    with
        GameHardwareKeyboard,
        XInputGamePad,
        MessageListenerMixin<List<PlayerAction>> {
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
  final spawnManager = SpawnManager();

  @override
  void onScroll(PointerScrollInfo info) {
    var zoom = cameraComponent.viewfinder.zoom;
    zoom += info.scrollDelta.game.y.sign * zoomPerScrollUnit;
    cameraComponent.viewfinder.zoom = zoom.clamp(0.1, 8.0);
    onAfterZoom();
  }

  @override
  Future<void> onLoad() async {
    consoleMessages.sendMessage('Start loading map $mapFile');
    super.onLoad();
    initColorFilter<MyGame>();

    // consoleMessages.sendMessage('loading sounds...');
    // SoundLibrary().init();
    // consoleMessages.sendMessage('done.');

    final gameWorld = GameWorld();
    map = GameMapLoader(mapFile);

    cameraComponent = CameraComponent(
        world: gameWorld,
        viewport: FixedAspectRatioViewport(aspectRatio: 400 / 250));
    cameraComponent.viewfinder.zoom = 5;

    final settings = SettingsController();
    Size activeRadius;
    Size unloadRadius;
    Size preloadRadius;
    int processCellsLimitToPauseEngine;
    Duration suspendedCellLifetime;

    switch (settings.processor) {
      case ProcessorSpeed.web:
        activeRadius = const Size(1, 1);
        unloadRadius = const Size(2, 2);
        preloadRadius = const Size(4, 4);
        processCellsLimitToPauseEngine = 10;
        suspendedCellLifetime = const Duration(seconds: 120);
        break;

      case ProcessorSpeed.office:
        activeRadius = const Size(1, 1);
        unloadRadius = const Size(3, 3);
        preloadRadius = const Size(6, 6);
        processCellsLimitToPauseEngine = 10;
        suspendedCellLifetime = const Duration(seconds: 180);
        break;

      case ProcessorSpeed.middle:
        activeRadius = const Size(1, 1);
        unloadRadius = const Size(3, 3);
        preloadRadius = const Size(6, 6);
        processCellsLimitToPauseEngine = 15;
        suspendedCellLifetime = const Duration(seconds: 180);
        break;

      case ProcessorSpeed.powerful:
        activeRadius = const Size(1, 1);
        unloadRadius = const Size(3, 3);
        preloadRadius = const Size(6, 6);
        processCellsLimitToPauseEngine = 30;
        suspendedCellLifetime = const Duration(seconds: 240);
        break;
    }

    await initializeSpatialGrid(
        blockSize: 128,
        debug: false,
        activeRadius: activeRadius,
        unloadRadius: unloadRadius,
        preloadRadius: preloadRadius,
        buildCellsPerUpdate: 1,
        cleanupCellsPerUpdate: 1,
        processCellsLimitToPauseEngine: processCellsLimitToPauseEngine,
        // maxCells: 200,
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
        suspendedCellLifetime: suspendedCellLifetime,
        suspendCellPrecision: const Duration(seconds: 10),
        cellBuilderNoMap: map.noMapBuilder,
        // onAfterCellBuild: (cell, rootComponent) async {
        //   final trailLayer = CellTrailLayer(cell, name: 'trail');
        //   trailLayer.priority = RenderPriority.trackTrail.priority;
        //   trailLayer.optimizeCollisions = false;
        //   trailLayer.fadeOutConfig = world.fadeOutConfig;
        //   layersManager.addLayer(trailLayer);
        // },
        maps: [map]);
    consoleMessages.sendMessage('done.');
    consoleMessages.sendMessage('Loading additional tilesets...');
    await _loadExternalTileSets();
    consoleMessages.sendMessage('Done...');

    // consoleMessages.sendMessage('Starting UI');
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

    // consoleMessages.sendMessage('done.');

    add(gameWorld);
    cameraComponent.viewport.add(hudVisibility);
    cameraComponent.viewport.add(hudFlashMessage);

    if (SettingsController().soundEnabled) {
      consoleMessages.sendMessage('Loading audio...');
      await FlameAudio.audioCache.loadAll([
        'sfx/bullet_strong_tank.m4a',
        'sfx/explosion_enemy.m4a',
        'sfx/explosion_player.m4a',
        'sfx/player_bullet_strong_wall.m4a',
        'sfx/player_bullet_wall.m4a',
        'sfx/player_fire_bullet.m4a',
        'sfx/move_player.m4a',
        'sfx/human_step_grass.m4a',
        'sfx/human_shoot.m4a',
        'sfx/human_death.m4a',
        'music/intro.m4a',
        'music/move_enemies.m4a',
      ]);
    }
    consoleMessages.sendMessage('Start building game cells...');

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
    hideLoadingComponent();
    if (_initialized) return;

    listenProvider(inputEventsHandler.messageProvider);
    cameraComponent.viewfinder.zoom = 5;

    onAfterZoom();
    if (!(currentPlayer?.isMounted ?? false)) {
      restorePlayer();
    }

    if (SettingsController().soundEnabled) {
      FlameAudio.playLongAudio('music/intro.m4a');
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

      spawnManager.spawnNewActor(
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
  Future<void> showLoadingComponent() async {
    if (!_initialized) {
      overlays.add('console');
    }
  }

  @override
  Future<void> hideLoadingComponent() async {
    overlays.remove('console');
  }

  @override
  void onLoadingProgress<M>(LoadingProgressMessage<M> message) {
    if (message.data is String) {
      consoleMessages
          .sendMessage('${message.type} | progress: ${message.progress}% '
              '| ${message.data}');
    } else {
      consoleMessages
          .sendMessage('${message.type} | progress: ${message.progress}%');
    }
    refreshWidget();
    super.onLoadingProgress(message);
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

  @override
  void onStreamMessage(List<PlayerAction> message) {
    for (final msg in message) {
      switch (msg) {
        case PlayerAction.console:
          if (overlays.isActive('console')) {
            overlays.remove('console');
            resumeEngine();
          } else {
            pauseEngine();
            overlays.add('console');
          }

          break;
        case PlayerAction.escape:
          pauseEngine();
          NesConfirmDialog.show(
                  context: context,
                  message: context.loc().leave_game,
                  confirmLabel: context.loc().ok,
                  cancelLabel: context.loc().back)
              .then((run) {
            if (run == true) {
              resumeEngine();
              RouteBuilder.gotoMissions(context, false);
            } else {
              resumeEngine();
            }
          });
          break;

        default:
          break;
      }
    }
  }

  @override
  void onRemove() {
    dispose();
    spawnManager.dispose();
    FlameAudio.audioCache.clearAll().catchError((error) {
      consoleMessages.sendMessage(error.toString());
    });
    super.onRemove();
  }
}
