import 'package:tank_game/world/core/actor.dart';
import 'package:tank_game/world/core/faction.dart';
import 'package:tank_game/world/environment/spawn/spawn_core_entity.dart';

enum SpawnState { idle, spawning, timeout }

typedef SpawnTriggerCallback = void Function(SpawnCoreEntity spawn);

class SpawnData extends ActorData {
  var state = SpawnState.idle;
  final allowedFactions = <Faction>[];
  final triggerFactions = <Faction>[];

  double secondsBetweenSpawns = 60;
  double timeoutBetweenSpawnsElapsed = 0;

  double secondsDuringSpawn = 0;
  double timeoutDuringSpawnsElapsed = 0;

  /// How many entities it contains. -1 means infinity
  int capacity = -1;

  /// squared distance to player to trigger spawn process. -1 means that spawn
  /// does not react on player
  double triggerDistanceSquared = 0;
  SpawnTriggerCallback? triggerCallback;

  String typeOfTank = '';

  bool removeWhenEmpty = false;

  SpawnData() {
    coreState = ActorCoreState.idle;
    health = -1;
  }
}
