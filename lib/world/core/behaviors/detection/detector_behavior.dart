import 'package:flame/components.dart';
import 'package:flame/experimental.dart';
import 'package:flame/extensions.dart';
import 'package:flutter/painting.dart';
import 'package:tank_game/game.dart';
import 'package:tank_game/world/core/actor.dart';
import 'package:tank_game/world/core/behaviors/core_behavior.dart';
import 'package:tank_game/world/core/behaviors/detection/detectable_behavior.dart';
import 'package:tank_game/world/core/behaviors/distance_callback_mixin.dart';
import 'package:tank_game/world/core/faction.dart';

enum DetectionType {
  visual,
  audial,
  spawn,
}

typedef DetectionCallback = void Function(
    ActorMixin other, double distanceX, double distanceY);

class DetectorBehavior extends CoreBehavior<ActorMixin>
    with DistanceCallbackMixin, HasGameReference<MyGame> {
  DetectorBehavior({
    required this.distance,
    required this.detectionType,
    required this.factionsToDetect,
    this.pauseBetweenChecks = 0,
    this.onDetection,
    this.onNothingDetected,
    this.maxMomentum = 0,
  }) {
    _momentum = maxMomentum;
  }

  final double distance;
  final DetectionType detectionType;
  final double maxMomentum;

  // @override
  // bool get debugMode => true;

  double _momentum = 0;

  bool get isMomentum => _momentum < maxMomentum;

  final double pauseBetweenChecks;
  double _dtBetweenChecks = 0;

  bool detected = false;
  final List<Faction> factionsToDetect;

  DetectionCallback? onDetection;
  Function(bool isMomentum)? onNothingDetected;

  final _checkedComponents = <Component>{};
  ActorMixin? _lastOther;
  double? _lastDistanceX, _lastDistanceY;

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
        _checkedComponents.add(other);
        final finalDistance = distance * detectable.distanceModifier;
        if (distanceX < finalDistance && distanceY < finalDistance) {
          detected = true;
          onDetection?.call(other, distanceX, distanceY);
          _lastDistanceX = distanceX;
          _lastDistanceY = distanceY;
          _lastOther = other;
          return;
        }
      }
    } catch (_) {}
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
    debugMode = true;
    if (pauseBetweenChecks > 0) {
      _dtBetweenChecks += dt;
      if (_dtBetweenChecks < pauseBetweenChecks) {
        return;
      } else {
        _dtBetweenChecks = 0;
      }
    }

    final activeCollisions =
        game.collisionDetection.broadphase.activeCollisions;
    for (final hitbox in activeCollisions) {
      final component = hitbox.hitboxParent;
      if (_checkedComponents.contains(component)) {
        continue;
      }
      if (!_canProcessComponent(component)) {
        continue;
      }

      final (distanceX, distanceY) =
          _getComponentDistance(component as ActorMixin);
      _processComponentDistance(component, distanceX, distanceY);
    }

    _checkedComponents.clear();

    if (!detected) {
      if (isMomentum &&
          onDetection != null &&
          _lastOther != null &&
          _lastDistanceX != null &&
          _lastDistanceY != null) {
        onDetection!.call(_lastOther!, _lastDistanceX!, _lastDistanceY!);
      }
      if (_momentum < maxMomentum) {
        _momentum += dt;
      }
      onNothingDetected?.call(isMomentum);
    } else {
      _momentum = 0;
    }
    detected = false;
  }

  @override
  void renderDebugMode(Canvas canvas) {
    final rect = Rect.fromCenter(
        center: Vector2.zero().toOffset(),
        width: distance * 2,
        height: distance * 2);

    canvas.drawRect(
        rect,
        Paint()
          ..color = (Color.fromRGBO(255, 0, 144, 1.0))
          ..strokeWidth = 4
          ..style = PaintingStyle.stroke);
  }
}
