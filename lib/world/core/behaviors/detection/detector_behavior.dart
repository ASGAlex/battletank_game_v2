import 'package:flame/components.dart';
import 'package:flame/experimental.dart';
import 'package:tank_game/game.dart';
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
    with DistanceCallbackMixin, HasGameReference<MyGame> {
  DetectorBehavior({
    required this.distance,
    required this.detectionType,
    required this.factionsToDetect,
    this.onDetection,
    this.onNothingDetected,
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
  Function? onNothingDetected;

  final _checkedCOmponents = <Component>{};

  @override
  void onCalculateDistance(
      Component other, double distanceX, double distanceY) {
    if (!_canProcessComponent(other)) {
      return;
    }

    _processComponentDistance(other as ActorMixin, distanceX, distanceY);
  }

  bool _canProcessComponent(Component other) {
    if (other is! ActorMixin) {
      return false;
    }

    if (other.data.factions.isEmpty) {
      return false;
    }

    var hasFaction = false;
    for (final faction in other.data.factions) {
      if (factionsToDetect.contains(faction)) {
        hasFaction = true;
        break;
      }
    }
    if (!hasFaction) {
      return false;
    }
    return true;
  }

  void _processComponentDistance(
      ActorMixin other, double distanceX, double distanceY) {
    try {
      final detectables = other.findBehaviors<DetectableBehavior>();
      for (final detectable in detectables) {
        if (detectable.detectionType != detectionType) {
          continue;
        }
        _checkedCOmponents.add(other);
        final finalDistance = distance * detectable.distanceModifier;
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

  (double distanceX, double distanceY) _getComponentDistance(ActorMixin other) {
    final myCenter = parent.boundingBox.aabbCenter;
    final otherCenter = other.boundingBox.aabbCenter;

    final distanceX = (myCenter.x - otherCenter.x).abs();
    final distanceY = (myCenter.y - otherCenter.y).abs();
    return (distanceX, distanceY);
  }

  @override
  void update(double dt) {
    final activeCollisions =
        game.collisionDetection.broadphase.activeCollisions;
    for (final hitbox in activeCollisions) {
      final component = hitbox.hitboxParent;
      if (_checkedCOmponents.contains(component)) {
        continue;
      }
      if (!_canProcessComponent(component)) {
        continue;
      }

      final (distanceX, distanceY) =
          _getComponentDistance(component as ActorMixin);
      _processComponentDistance(component, distanceX, distanceY);
    }

    _checkedCOmponents.clear();

    if (!detected) {
      if (_momentum < maxMomentum) {
        _momentum += dt;
      }
      onNothingDetected?.call();
    } else {
      _momentum = 0;
    }
    detected = false;
  }
}
