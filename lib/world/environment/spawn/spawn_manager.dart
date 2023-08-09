import 'dart:collection';

import 'package:tank_game/world/core/actor.dart';
import 'package:tank_game/world/core/faction.dart';
import 'package:tank_game/world/environment/spawn/spawn_core_entity.dart';
import 'package:tank_game/world/environment/spawn/spawn_data.dart';

class SpawnManager {
  final _spawns = HashSet<SpawnCoreEntity>();

  bool spawnNewActor({
    required ActorMixin actor,
    SpawnCoreEntity? preferredSpawn,
    Faction? faction,
    Duration retryInterval = const Duration(seconds: 10),
    int retryAttempts = 15,
    Function(ActorMixin objectToSpawn)? onSpawnComplete,
  }) {
    bool success;
    final spawn = preferredSpawn ?? findIdle(faction: faction);
    if (spawn == null) {
      success = false;
    } else {
      success = spawn.scheduleSpawn(actor);
    }

    if (!success) {
      if (retryAttempts != 0) {
        Future.delayed(retryInterval).then((value) {
          spawnNewActor(
            actor: actor,
            faction: faction,
            retryInterval: retryInterval,
            retryAttempts: retryAttempts - 1,
            onSpawnComplete: onSpawnComplete,
          );
        });
      }
      return false;
    }

    if (onSpawnComplete != null) {
      onSpawnComplete(actor);
    }

    return true;
  }

  SpawnCoreEntity? findIdle({Faction? faction}) {
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

  void add(SpawnCoreEntity spawn) {
    _spawns.add(spawn);
  }

  void remove(SpawnCoreEntity spawn) {
    _spawns.remove(spawn);
  }

  void dispose() {
    _spawns.clear();
  }
}
