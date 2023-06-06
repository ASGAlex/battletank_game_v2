import 'dart:async';
import 'dart:math';

import 'package:tank_game/world/core/behaviors/movement/available_direction_checker.dart';

import 'movement_forward_collision.dart';

class RandomMovementBehavior extends AvailableDirectionChecker {
  RandomMovementBehavior({
    required this.maxDirectionDistance,
    required this.minDirectionDistance,
  });

  final int maxDirectionDistance;
  final int minDirectionDistance;

  double _actualDistance = 0;
  double _plannedDistance = 0;

  bool get isDistanceEnd => _plannedDistance <= _actualDistance;

  late final MovementForwardCollisionBehavior _moveForwardBehavior;
  bool _chooseDirectionNextTick = false;

  @override
  void update(double dt) {
    if (_chooseDirectionNextTick) {
      _chooseDirectionNextTick = false;
      chooseNewDirection();
      disableSideHitboxes();
      return;
    }
    var distance = _moveForwardBehavior.lastDisplacement.x;
    if (distance == 0) {
      distance = _moveForwardBehavior.lastDisplacement.y;
    }
    _actualDistance += distance;
    if (movementHitbox.isMovementBlocked || isDistanceEnd) {
      enableSideHitboxes();
      _chooseDirectionNextTick = true;
    }
  }

  void chooseNewDirection() {
    final availableDirections = getAvailableDirections();
    if (availableDirections.isEmpty) return;

    final random = Random();
    final i = random.nextInt(availableDirections.length);
    parent.lookDirection = availableDirections[i];
    var distance = random.nextInt(maxDirectionDistance);
    if (distance < minDirectionDistance) {
      distance = minDirectionDistance +
          random.nextInt(maxDirectionDistance - minDirectionDistance);
    }
    _plannedDistance = distance.toDouble();
    _actualDistance = 0;
  }

  @override
  FutureOr onLoad() {
    _moveForwardBehavior =
        parent.findBehavior<MovementForwardCollisionBehavior>();
    return super.onLoad();
  }
}
