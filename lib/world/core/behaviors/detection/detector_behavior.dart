import 'package:flame/components.dart';
import 'package:flame_behaviors/flame_behaviors.dart';
import 'package:tank_game/world/core/actor.dart';
import 'package:tank_game/world/core/behaviors/detection/detectable_behavior.dart';
import 'package:tank_game/world/core/behaviors/distance_callback_mixin.dart';
import 'package:tank_game/world/core/faction.dart';

enum DetectionType {
  visual,
  audial,
}

class DetectorBehavior extends Behavior<ActorMixin> with DistanceCallbackMixin {
  DetectorBehavior({
    required this.distance,
    required this.detectionType,
    required this.factionsToDetect,
  });

  final double distance;
  final DetectionType detectionType;

  bool detected = false;
  final List<Faction> factionsToDetect;

  @override
  void onCalculateDistance(
      Component other, double distanceX, double distanceY) {
    if (other is! ActorMixin) {
      return;
    }

    if (other.data.factions.isEmpty) {
      return;
    }

    var hasFaction = false;
    for (final faction in other.data.factions) {
      if (factionsToDetect.contains(faction)) {
        hasFaction = true;
        break;
      }
    }
    if (!hasFaction) {
      return;
    }

    try {
      final detectables = other.findBehaviors<DetectableBehavior>();
      for (final detectable in detectables) {
        if (detectable.detectionType != detectionType) {
          continue;
        }
        final finalDistance = distance + detectable.distanceModifier;
        if (distanceX < finalDistance && distanceY < finalDistance) {
          detected = true;
          return;
        }
      }
    } catch (_) {}
  }

  @override
  void update(double dt) {
    detected = false;
  }
}
