import 'package:tank_game/world/core/actor.dart';

class AttackerData extends ActorData {
  double secondsBetweenFire = 1;
  double secondsElapsedBetweenFire = 1;

  /// -1 means infinity
  int ammo = -1;
  double ammoHealth = 1;
  double ammoSpeed = 100;

  /// -1 means infinity
  double ammoRange = -1;
}
