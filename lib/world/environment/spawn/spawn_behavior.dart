import 'dart:async';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/experimental.dart';
import 'package:tank_game/game.dart';
import 'package:tank_game/world/core/actor.dart';
import 'package:tank_game/world/core/behaviors/collision_behavior.dart';
import 'package:tank_game/world/core/behaviors/distance_callback_mixin.dart';
import 'package:tank_game/world/core/scenario/scripts/event.dart';
import 'package:tank_game/world/core/visibility_mixin.dart';
import 'package:tank_game/world/environment/spawn/spawn_entity.dart';

import 'spawn_data.dart';

class SpawnBehavior extends CollisionBehavior
    with DistanceCallbackMixin, HasGameReference<MyGame> {
  final _trackedObjectsDistances = <Component, List<double>>{};
  ActorMixin? objectToSpawn;
  Function(ActorMixin objectToSpawn)? onSpawnComplete;

  SpawnData get spawnData {
    final spawnData = parent.data;
    if (spawnData is! SpawnData) {
      throw 'Spawn data property must be a SpawnData\'s subtype!';
    }
    return spawnData;
  }

  @override
  FutureOr<void> onLoad() {
    assert(parent is SpawnEntity);
    super.onLoad();
    game.spawnManager.add(parent as SpawnEntity);
    parent.boundingBox.collisionType = CollisionType.passive;
    parent.boundingBox.isDistanceCallbackEnabled = true;
  }

  @override
  void onRemove() {
    game.spawnManager.remove(parent as SpawnEntity);
    parent.boundingBox.isDistanceCallbackEnabled = false;
    super.onRemove();
  }

  bool _spawnOnNextTick = false;

  @override
  void update(double dt) {
    if (_spawnOnNextTick) {
      _doSpawnOnNextTick();
      return;
    }

    switch (spawnData.state) {
      case SpawnState.idle:
        if (parent is VisibilityMixin) {
          (parent as VisibilityMixin).hide();
        }
        _trySpawnByTrigger();
        break;
      case SpawnState.spawning:
        if (parent is VisibilityMixin) {
          (parent as VisibilityMixin).show();
        }
        spawnData.timeoutSecondsElapsed += dt;
        if (parent is CollisionCallbacks &&
            (parent as CollisionCallbacks).isColliding) {
          break;
        }
        _spawnOnNextTick = true;
        break;
      case SpawnState.timeout:
        if (parent is VisibilityMixin) {
          (parent as VisibilityMixin).hide();
        }
        spawnData.timeoutSecondsElapsed += dt;
        if (spawnData.secondsBetweenSpawns <= spawnData.timeoutSecondsElapsed) {
          spawnData.timeoutSecondsElapsed = 0;
          spawnData.state = SpawnState.idle;
        }
        break;
    }
  }

  void _doSpawnOnNextTick() {
    _spawnOnNextTick = false;
    if (parent is CollisionCallbacks &&
        (parent as CollisionCallbacks).isColliding) {
      return;
    }
    if (spawnData.secondsDuringSpawn <= spawnData.timeoutSecondsElapsed) {
      spawnData.timeoutSecondsElapsed = 0;
      spawnData.state = SpawnState.timeout;
      final newObject = objectToSpawn;
      if (newObject != null) {
        newObject.position.setFrom(spawnData.positionCenter);
        newObject.currentCell = parent.currentCell;
        (parent as SpawnEntity).rootComponent.add(newObject);
        objectToSpawn = null;
        onSpawnComplete?.call(newObject);
        if (spawnData.capacity == 0) {
          parent.removeFromParent();
        }
      }
    }
  }

  @override
  void onCalculateDistance(
      Component other, double distanceX, double distanceY) {
    _trackedObjectsDistances[other] = [distanceX, distanceY];
  }

  void _trySpawnByTrigger() {
    if (spawnData.capacity <= 0 && spawnData.capacity != -1) {
      return;
    }
    for (final entry in _trackedObjectsDistances.entries) {
      final dx = entry.value.first;
      final dy = entry.value.last;
      final squared = dx * dx + dy * dy;
      if (spawnData.triggerDistanceSquared == 0 ||
          squared < spawnData.triggerDistanceSquared) {
        spawnData.triggerCallback?.call(parent as SpawnEntity);
        if (spawnData.capacity != -1) {
          spawnData.capacity--;
        }
        break;
      }
    }
    _trackedObjectsDistances.clear();
  }
}

class EventSpawned extends ScenarioEvent<ActorMixin> {
  const EventSpawned({required super.emitter, required super.name, super.data});
}
