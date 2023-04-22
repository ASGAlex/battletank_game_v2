import 'package:flame/components.dart';
import 'package:tank_game/world/core/actor.dart';
import 'package:tank_game/world/core/behaviors/core_behavior.dart';
import 'package:tank_game/world/core/behaviors/detection/detectable_behavior.dart';
import 'package:tank_game/world/core/behaviors/distance_callback_mixin.dart';
import 'package:tank_game/world/core/faction.dart';

enum DetectionType {
  visual,
  audial,
}

typedef DetectionCallback = void Function(
    ActorMixin other, double distanceX, double distanceY);

class DetectorBehavior extends CoreBehavior<ActorMixin>
    with DistanceCallbackMixin {
  DetectorBehavior({
    required this.distance,
    required this.detectionType,
    required this.factionsToDetect,
    this.onDetection,
    this.maxMomentum = 0,
  }) {
    _momentum = maxMomentum;
  }

  final double distance;
  final DetectionType detectionType;
  final double maxMomentum;

  double _momentum = 0;

  bool detected = false;
  final List<Faction> factionsToDetect;

  DetectionCallback? onDetection;

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
          onDetection?.call(other, distanceX, distanceY);
          return;
        }
      }
    } catch (_) {}

    if (_momentum < maxMomentum && onDetection != null) {
      onDetection?.call(other, distanceX, distanceY);
    }
  }

  @override
  void update(double dt) {
    if (!detected) {
      if (_momentum < maxMomentum) {
        _momentum += dt;
      }
    } else {
      _momentum = 0;
    }
    detected = false;
  }
}
