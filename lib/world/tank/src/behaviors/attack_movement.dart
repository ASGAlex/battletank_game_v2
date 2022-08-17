import 'dart:math';

import '../core/base_tank.dart';
import '../core/direction.dart';
import 'available_directions.dart';

class AttackMovementController {
  AttackMovementController(
      {required this.parent, required this.directionsChecker});

  final AvailableDirectionsChecker directionsChecker;
  final Tank parent;

  bool shouldFire = false;
  Direction? _prevDirection;

  bool runAttackMovement(double dt) {
    final direction = findShortestDirection();
    if (direction == null) {
      return false;
    }
    if (direction != _prevDirection) {
      _prevDirection = direction;
      parent.lookDirection = direction;
      parent.angle = direction.angle;
      parent.skipUpdateOnAngleChange = true;
      parent.current = TankState.run;
    }
    return true;
  }

  Direction? findShortestDirection() {
    final target = parent.game.player;
    if (target == null || target.dead) return null;
    final diffX = target.x - parent.x;
    final diffY = target.y - parent.y;
    var diffBetweenAxis = diffX.abs() - diffY.abs();

    if (diffBetweenAxis.abs() <= 4) {
      if (Random().nextBool()) {
        diffBetweenAxis = -5;
      } else {
        diffBetweenAxis = 5;
      }
    }

    if (diffBetweenAxis > 0) {
      if (diffY > 0) {
        if (diffY <= 4) {
          shouldFire = true;
          return _leftOrRight(diffX);
        } else {
          shouldFire = false;
        }
        return Direction.down;
      } else {
        if (diffY >= -4) {
          shouldFire = true;
          return _leftOrRight(diffX);
        } else {
          shouldFire = false;
        }
        return Direction.up;
      }
    } else {
      if (diffX > 0) {
        if (diffX <= 4) {
          shouldFire = true;
          return _upOrDown(diffY);
        } else {
          shouldFire = false;
        }
        return Direction.right;
      } else {
        if (diffX >= -4) {
          shouldFire = true;
          return _upOrDown(diffY);
        } else {
          shouldFire = false;
        }
        return Direction.left;
      }
    }
  }

  Direction _leftOrRight(double diffX) {
    if (diffX > 0) {
      return Direction.right;
    } else {
      return Direction.left;
    }
  }

  Direction _upOrDown(double diffY) {
    if (diffY > 0) {
      return Direction.down;
    } else {
      return Direction.up;
    }
  }
}
