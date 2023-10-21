import 'dart:async';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flame_fast_touch/flame_fast_touch.dart';
import 'package:flame_message_stream/flame_message_stream.dart';
import 'package:flame_spatial_grid/flame_spatial_grid.dart';
import 'package:flutter/material.dart' hide Image;
import 'package:tank_game/controls/gamepad.dart';
import 'package:tank_game/controls/input_events_handler.dart';
import 'package:tank_game/controls/joystick.dart';
import 'package:tank_game/controls/keyboard.dart';
import 'package:tank_game/packages/color_filter/lib/color_filter.dart';
import 'package:tank_game/services/settings/controller.dart';
import 'package:tank_game/ui/widgets/console_messages.dart';
import 'package:tank_game/world/actors/human/human.dart';
import 'package:tank_game/world/core/actor.dart';
import 'package:tank_game/world/core/behaviors/attacks/bullet.dart';
import 'package:tank_game/world/core/behaviors/detection/detectable_behavior.dart';
import 'package:tank_game/world/core/behaviors/detection/detector_behavior.dart';
import 'package:tank_game/world/core/behaviors/detection/enemy_ambient_volume.dart';
import 'package:tank_game/world/core/behaviors/player_controlled_behavior.dart';
import 'package:tank_game/world/core/faction.dart';
import 'package:tank_game/world/core/scenario/components/area_collision_high_precision.dart';
import 'package:tank_game/world/core/scenario/components/area_init_script.dart';
import 'package:tank_game/world/core/scenario/components/area_message.dart';
import 'package:tank_game/world/core/scenario/components/area_moving_path.dart';
import 'package:tank_game/world/core/scenario/scenario_component.dart';
import 'package:tank_game/world/core/scenario/scripts/event.dart';
import 'package:tank_game/world/environment/spawn/spawn_core_entity.dart';
import 'package:tank_game/world/environment/spawn/spawn_manager.dart';
import 'package:tank_game/world/environment/tree/tree.dart';
import 'package:tank_game/world/environment/water/water.dart';
import 'package:tank_game/world/map_loader.dart';
import 'package:tank_game/world/world.dart';
import 'package:wakelock/wakelock.dart';

import 'world/core/scenario/scenario_description.dart';

abstract class MyGameFeatures extends FlameGame<GameWorld>
    with
        ColorFilterMix,
        KeyboardEvents,
        HasSpatialGridFramework<GameWorld>,
        SingleGameInstance,
        ColorFilterMix<GameWorld>,
        ScrollDetector {
  MyGameFeatures()
      : super(
          world: GameWorld(),
        );

  final inputEventsHandler = InputEventsHandler();

  @override
  FutureOr<void> onLoad() {
    rootComponent = world;
    inputEventsHandler.game = this as MyGame;
    return super.onLoad();
  }
}

class MyGame extends MyGameFeatures
    with
        GameHardwareKeyboard,
        MyJoystickMix,
        XInputGamePad,
        FastTouch<GameWorld>,
        MessageListenerMixin<List<PlayerAction>>,
        HasMessageProviders {
  MyGame(this.scenario, this.context);

  static const zoomPerScrollUnit = 0.22;
  static final fpsTextPaint = TextPaint(
    style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
  );

  final Scenario scenario;
  final BuildContext context;

  ActorMixin? currentPlayer;

  ConsoleMessagesController get consoleMessages =>
      SettingsController().consoleMessages;

  final initialPlayerPosition = Vector2(0, 0);
  final spawnManager = SpawnManager();
  final enemyAmbientVolume = EnemyAmbientVolume();

  late final MessageStreamProvider<bool> hudHideInTreesProvider;
  late final MessageStreamProvider<ScenarioEvent> scenarioEventProvider;

  Widget Function(BuildContext context, MyGame game)
      scenarioCurrentWidgetBuilder = (_, __) => Container();

  bool isActiveScenarioMessage() => overlays.isActive('scenario');

  Widget? currentScenarioMessageContent;

  void showScenarioMessage(Widget content) {
    scenarioCurrentWidgetBuilder = (ctx, game) => content;
    if (overlays.isActive('scenario')) {
      overlays.remove('scenario');
    }
    overlays.add('scenario');
    currentScenarioMessageContent = content;
  }

  void hideScenarioMessage() {
    overlays.remove('scenario');
    currentScenarioMessageContent = null;
  }

  @override
  void onScroll(PointerScrollInfo info) {
    var zoom = camera.viewfinder.zoom;
    zoom += info.scrollDelta.global.y.sign * zoomPerScrollUnit;
    camera.viewfinder.zoom = zoom.clamp(0.1, 8.0);
    onAfterZoom();
  }

  @override
  Future<void> onLoad() async {
    Wakelock.enable();

    initColorFilter<MyGame>();
    consoleMessages.sendMessage('Start loading scenario ${scenario.name}');
    super.onLoad();
    initColorFilter<MyGame>();

    hudHideInTreesProvider =
        messageProvidersManager.getMessageProvider<bool>('hideInTrees');
    scenarioEventProvider = messageProvidersManager
        .getMessageProvider<ScenarioEvent>('scenarioEvent');

    // consoleMessages.sendMessage('loading sounds...');
    // SoundLibrary().init();
    // consoleMessages.sendMessage('done.');

    camera.viewfinder.zoom = 5;
    camera.priority = 999;

    final settings = SettingsController();
    Size activeRadius;
    Size unloadRadius;
    Size preloadRadius;
    int processCellsLimitToPauseEngine;
    Duration suspendedCellLifetime;

    switch (settings.processor) {
      case ProcessorSpeed.web:
        activeRadius = const Size(1, 1);
        unloadRadius = const Size(1, 1);
        preloadRadius = const Size(1, 1);
        processCellsLimitToPauseEngine = 30;
        suspendedCellLifetime = const Duration(seconds: 200);
        break;

      case ProcessorSpeed.office:
        activeRadius = const Size(1, 1);
        unloadRadius = const Size(2, 2);
        preloadRadius = const Size(6, 6);
        processCellsLimitToPauseEngine = 30;
        suspendedCellLifetime = const Duration(seconds: 200);
        break;

      case ProcessorSpeed.middle:
        activeRadius = const Size(1, 1);
        unloadRadius = const Size(3, 3);
        preloadRadius = const Size(8, 8);
        processCellsLimitToPauseEngine = 30;
        suspendedCellLifetime = const Duration(seconds: 300);
        break;

      case ProcessorSpeed.powerful:
        activeRadius = const Size(1, 1);
        unloadRadius = const Size(5, 5);
        preloadRadius = const Size(12, 12);
        processCellsLimitToPauseEngine = 50;
        suspendedCellLifetime = const Duration(seconds: 500);
        break;
    }

    WorldLoader? worldLoader;
    if (scenario.worldFile != null) {
      worldLoader = WorldLoader(
        fileName: scenario.worldFile!,
        mapLoader: {'all': GameMapLoader.new},
        // loadWholeMap: false,
      );
    }

    final listOfMaps = <GameMapLoader>[];
    if (worldLoader == null) {
      if (scenario.mapFile == null) {
        throw 'Cant load scenario!';
      }
      listOfMaps.add(GameMapLoader(scenario.mapFile!));
    }

    await initializeSpatialGrid(
      cellSize: 128,
      // debug: true,
      activeRadius: activeRadius,
      unloadRadius: unloadRadius,
      preloadRadius: preloadRadius,
      buildCellsPerUpdate: 1,
      cleanupCellsPerUpdate: 1,
      processCellsLimitToPauseEngine: processCellsLimitToPauseEngine,
      // maxCells: 200,
      rootComponent: world,
      trackWindowSize: true,
      trackedComponent: SpatialGridCameraWrapper(camera),
      initialPositionChecker: (layer, object, mapOffset, worldName) {
        if (object.name == 'spawn_human_player') {
          initialPlayerPosition.setValues(object.x, object.y);
          camera.viewfinder.position = mapOffset + Vector2(object.x, object.y);
          return camera.viewfinder.position;
        }
        return null;
      },
      suspendedCellLifetime: suspendedCellLifetime,
      suspendCellPrecision: const Duration(seconds: 10),
      cellBuilderNoMap:
          (Cell cell, Component rootComponent, Iterable<Rect> mapRects) =>
              GameMapLoader.noMapBuilder(this, cell, rootComponent, mapRects),
      // onAfterCellBuild: (cell, rootComponent) async {
      //   final trailLayer = CellTrailLayer(cell, name: 'trail');
      //   trailLayer.priority = RenderPriority.trackTrail.priority;
      //   trailLayer.optimizeCollisions = false;
      //   trailLayer.fadeOutConfig = world.fadeOutConfig;
      //   layersManager.addLayer(trailLayer);
      // },
      maps: listOfMaps,
      worldLoader: worldLoader,
    );

    scenario.onLoad();
    consoleMessages.sendMessage('done.');
    consoleMessages.sendMessage('Loading additional tilesets...');
    await _loadExternalTileSets();
    consoleMessages.sendMessage('Done...');

    // consoleMessages.sendMessage('Starting UI');
    // if (Platform.isAndroid || Platform.isIOS) {
    // initJoystick(inputEventsHandler.handleFireEvent);
    // inputEventsHandler.getCurrentAngle = () => joystick!.knobAngleDegrees;
    // }
    // consoleMessages.sendMessage('done.');

    componentsAtPointRoot = camera.viewport;

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
        'sfx/move_enemies.m4a',
        'music/intro.m4a',
      ]);
      add(enemyAmbientVolume);
    }

    initJoystick(camera.viewport);
    add(inputEventsHandler);

    // if (kIsWeb) {
    // } else {
    //   if (Platform.isAndroid) {
    //     initJoystick(camera.viewport);
    //   }
    // }

    consoleMessages.sendMessage('Start building game cells...');

    // Spawn.waitFree(true).then((playerSpawn) async {
    //   if (player == null || player?.dead == true) {
    //     // spatialGrid.trackedComponent = playerSpawn;
    //     camera.follow(playerSpawn, maxSpeed: 60);
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
    futures.add(tilesetManager.loadTileset('radar_head.tsx'));
    futures.add(tilesetManager.loadTileset('fire.tsx'));
    return Future.wait(futures);
  }

  bool _initialized = false;

  @override
  void onInitializationDone() {
    hideLoadingComponent();
    if (_initialized) return;

    listenProvider(inputEventsHandler.messageProvider);
    camera.viewfinder.zoom = 5;
    overlays.add('hud');

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
        ..add(DetectableBehavior(detectionType: DetectionType.visual))
        ..position = camera.viewfinder.position
        ..data.factions.add(Faction(name: 'Player'));

      spawnManager.spawnNewActor(
          actor: currentPlayer!,
          faction: Faction(name: 'Player'),
          onSpawnComplete: (objectToSpawn) {
            currentPlayer!.add(PlayerControlledBehavior());
            camera.follow(currentPlayer!);
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
    // super.onLoadingProgress(message);
  }

  @override
  bool pureTypeCheck(Type activeItemType, Type potentialItemType) {
    if (activeItemType == BulletEntity) {
      if (potentialItemType == WaterEntity ||
          potentialItemType == TreeEntity ||
          potentialItemType == SpawnCoreEntity ||
          potentialItemType == ScenarioComponent ||
          potentialItemType == AreaInitScriptComponent ||
          potentialItemType == AreaMessageComponent ||
          potentialItemType == AreaMovingPathComponent ||
          potentialItemType == AreaCollisionHighPrecisionComponent) {
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
          if (overlays.isActive('menu')) {
            overlays.remove('menu');
            resumeEngine();
          } else {
            pauseEngine();
            overlays.add('menu');
          }
          break;

        default:
          break;
      }
    }
  }

  @override
  void onRemove() {
    // if (!kDebugMode) {
    //   disposeListener();
    //   spawnManager.dispose();
    //   hudHideInTreesProvider.dispose();
    //   FlameAudio.audioCache.clearAll();
    //   removeAll(children);
    //   processLifecycleEvents();
    //   Flame.images.clearCache();
    //   Flame.assets.clearCache();
    //   SettingsController().endGame();
    //   super.onRemove();
    //
    //   Wakelock.disable();
    // }
  }
}
