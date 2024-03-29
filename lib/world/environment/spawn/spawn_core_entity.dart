import 'dart:async';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame_spatial_grid/flame_spatial_grid.dart';
import 'package:tank_game/game.dart';
import 'package:tank_game/packages/behaviors/lib/flame_behaviors.dart';
import 'package:tank_game/world/core/actor.dart';
import 'package:tank_game/world/core/behaviors/animation/animation_behavior.dart';
import 'package:tank_game/world/core/behaviors/detection/detectable_behavior.dart';
import 'package:tank_game/world/core/behaviors/detection/detector_behavior.dart';
import 'package:tank_game/world/core/faction.dart';
import 'package:tank_game/world/core/scenario/components/scenario_event_emitter_mixin.dart';
import 'package:tank_game/world/core/scenario/scripts/event.dart';
import 'package:tank_game/world/core/visibility_mixin.dart';

import 'spawn_data.dart';

typedef SpawnComponentFactory = ActorMixin Function(
    List<Faction> allowedFactions);

class SpawnCoreEntity extends SpriteAnimationComponent
    with
        CollisionCallbacks,
        EntityMixin,
        HasGridSupport,
        VisibilityMixin,
        ActorMixin,
        RestorableStateMixin<SpawnData>,
        HasGameReference<MyGame>,
        ScenarioEventEmitter {
  SpawnCoreEntity({
    required this.rootComponent,
    required this.buildContext,
    required this.actorFactory,
    required this.animationConfig,
  }) {
    anchor = Anchor.center;
    data = SpawnData();

    final object = buildContext.tiledObject;
    if (object == null) {
      throw 'Spawn must to be an object!';
    }

    position = Vector2(
        buildContext.absolutePosition.x + buildContext.size.x / 2,
        buildContext.absolutePosition.y + buildContext.size.y / 2);
    currentCell = buildContext.cell;

    userData!.removeWhenEmpty =
        object.properties.getValue<bool>('removeWhenEmpty') ?? false;
    userData!.typeOfTank =
        object.properties.getValue<String>('tank_type') ?? 'any';
    userData!.capacity = object.properties.getValue<int>('tanks_inside') ??
        object.properties.getValue<int>('capacity') ??
        -1;

    final triggerDistance =
        object.properties.getValue<double>('trigger_distance') ?? 0;
    userData!.triggerDistanceSquared = triggerDistance * triggerDistance;

    userData!.secondsBetweenSpawns =
        object.properties.getValue<double>('cooldown_seconds') ?? 60;
    userData!.secondsDuringSpawn =
        object.properties.getValue<double>('spawn_seconds') ?? 0;

    var factionNames = <String>[];
    factionNames =
        object.properties.getValue<String>('triggerFactions')?.split(',') ??
            ['Player'];
    for (final name in factionNames) {
      if (name.isNotEmpty) {
        userData!.triggerFactions.add(Faction(name: name.trim()));
      }
    }

    factionNames =
        object.properties.getValue<String>('allowedFactions')?.split(',') ??
            ['Enemy'];
    for (final name in factionNames) {
      if (name.isNotEmpty) {
        userData!.allowedFactions.add(Faction(name: name.trim()));
      }
    }

    factionNames =
        object.properties.getValue<String>('factions')?.split(',') ?? ['Enemy'];
    for (final name in factionNames) {
      if (name.isNotEmpty) {
        userData!.allowedFactions.add(Faction(name: name.trim()));
      }
    }
  }

  final TileBuilderContext buildContext;
  final Component rootComponent;
  final SpawnComponentFactory actorFactory;
  final AnimationConfig animationConfig;
  ActorMixin? _scheduledActor;

  @override
  BoundingHitboxFactory get boundingHitboxFactory =>
      () => SpawnBoundingHitbox();

  @override
  SpawnData? get userData => data as SpawnData;

  @override
  void onLoad() {
    add(DetectorBehavior(
      distance: userData!.triggerDistanceSquared,
      detectionType: DetectionType.spawn,
      factionsToDetect: userData!.triggerFactions,
      pauseBetweenChecks: 1,
      onDetection: onTriggerDetected,
    ));
    add(AnimationBehavior(config: animationConfig));
    hide();
    super.onLoad();
  }

  void onTriggerDetected(ActorMixin other, double distanceX, double distanceY) {
    if (spawnState != SpawnState.idle) {
      return;
    }
    if (!_checkCapacity()) {
      return;
    }

    spawnState = SpawnState.spawning;
  }

  SpawnState get spawnState => userData!.state;

  set spawnState(SpawnState value) {
    if (userData!.state == value) {
      return;
    }
    userData!.state = value;
    switch (value) {
      case SpawnState.idle:
        hide();
        break;
      case SpawnState.timeout:
        hide();
        break;
      case SpawnState.spawning:
        if (_checkCapacity()) {
          show();
        }
        break;
    }
  }

  bool _checkCapacity() {
    if (userData!.capacity == -1) {
      return true;
    } else if (userData!.capacity >= 1) {
      return true;
    }

    return false;
  }

  @override
  void update(double dt) {
    if (!_checkCapacity()) {
      hide();
      return;
    }
    switch (userData!.state) {
      case SpawnState.idle:
        hide();
        break;
      case SpawnState.timeout:
        hide();
        if (userData!.timeoutBetweenSpawnsElapsed >=
            userData!.secondsBetweenSpawns) {
          userData!.timeoutBetweenSpawnsElapsed = 0;
          spawnState = SpawnState.idle;
        } else {
          userData!.timeoutBetweenSpawnsElapsed += dt;
        }
        break;
      case SpawnState.spawning:
        show();
        if (userData!.timeoutDuringSpawnsElapsed >=
            userData!.secondsDuringSpawn) {
          _trySpawn(_scheduledActor);
        } else {
          userData!.timeoutDuringSpawnsElapsed += dt;
        }
        break;
    }
    super.update(dt);
  }

  bool scheduleSpawn(ActorMixin actor) {
    if (spawnState != SpawnState.idle) {
      return false;
    }
    _scheduledActor = actor;
    spawnState = SpawnState.spawning;
    return true;
  }

  _trySpawn([ActorMixin? actor]) {
    if (isColliding) {
      return;
    }
    final newActor = actor ?? actorFactory.call(userData!.allowedFactions);
    newActor.position.setFrom(userData!.positionCenter);
    newActor.currentCell = currentCell;
    rootComponent.add(newActor);
    userData!.timeoutDuringSpawnsElapsed = 0;
    if (userData!.capacity != -1) {
      userData!.capacity--;
      if (userData!.capacity < 1 && userData!.removeWhenEmpty) {
        game.spawnManager.remove(this);
        removeFromParent();
      }
    }

    spawnState = SpawnState.timeout;
    _scheduledActor = null;
    scenarioEvent(
        EventSpawned(emitter: this, name: 'actorSpawned', data: newActor));
  }
}

class SpawnBoundingHitbox extends ActorDefaultHitbox {
  @override
  FutureOr<void> onLoad() {
    collisionType = defaultCollisionType = CollisionType.passive;
    isDistanceCallbackEnabled = true;
    return super.onLoad();
  }
}

class TriggerSpawnBehavior extends DetectableBehavior {
  TriggerSpawnBehavior({super.detectionType = DetectionType.spawn});
}

class EventSpawned extends ScenarioEvent<ActorMixin> {
  const EventSpawned({required super.emitter, required super.name, super.data});
}
