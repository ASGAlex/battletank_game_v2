import 'dart:collection';

import 'package:tank_game/world/core/actor.dart';
import 'package:tank_game/world/core/faction.dart';
import 'package:tank_game/world/environment/spawn/spawn_behavior.dart';
import 'package:tank_game/world/environment/spawn/spawn_data.dart';
import 'package:tank_game/world/environment/spawn/spawn_entity.dart';

class SpawnManager {
  static final SpawnManager _instance = SpawnManager._();

  SpawnManager._();

  final _spawns = HashSet<SpawnEntity>();

  factory SpawnManager() => _instance;

  bool spawnNewActor(
      {required ActorMixin actor,
      SpawnEntity? preferredSpawn,
      Faction? faction,
      Duration retryInterval = const Duration(seconds: 10),
      int retryAttempts = 15}) {
    bool success;
    final spawn = preferredSpawn ?? findIdle(faction: faction);
    if (spawn == null) return false;
    try {
      final behavior = spawn.findBehavior<SpawnBehavior>();
      if (behavior.objectToSpawn != null) {
        success = false;
      }
      behavior.objectToSpawn = actor;
      behavior.spawnData.state = SpawnState.spawning;
      success = true;
    } on StateError catch (_) {
      success = false;
    }

    if (success) {
      return success;
    } else {
      if (retryAttempts != 0) {
        Future.delayed(retryInterval).then((value) {
          spawnNewActor(
            actor: actor,
            faction: faction,
            retryInterval: retryInterval,
            retryAttempts: retryAttempts - 1,
          );
        });
      }
      return false;
    }
  }

  SpawnEntity? findIdle({Faction? faction}) {
    for (final spawn in _spawns) {
      final data = spawn.data as SpawnData;
      if (data.state != SpawnState.idle) {
        continue;
      }
      if (faction == null || data.allowedFactions.isEmpty) {
        return spawn;
      } else if (data.allowedFactions.contains(faction)) {
        return spawn;
      }
    }
    return null;
  }

  void add(SpawnEntity spawn) {
    _spawns.add(spawn);
  }

  void remove(SpawnEntity spawn) {
    _spawns.remove(spawn);
  }

  void dispose() {
    _spawns.clear();
  }
}
