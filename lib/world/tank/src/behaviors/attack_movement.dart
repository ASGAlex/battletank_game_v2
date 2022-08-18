import 'dart:math';

import '../core/base_tank.dart';
import '../core/direction.dart';
import 'available_directions.dart';
import 'random_movement.dart';

class AttackMovementController {
  AttackMovementController(
      {required this.parent,
      required this.directionsChecker,
      required this.randomMovementController});

  final AvailableDirectionsChecker directionsChecker;
  final RandomMovementController randomMovementController;
  final Tank parent;

  bool shouldFire = false;
  Direction? _prevDirection;

  bool get _randomMovement => _randomMovementTimer > 0;
  double _randomMovementTimer = 0;

  double diffX = 0;
  double diffY = 0;

  _startRandomMovement() {
    _randomMovementTimer = 5;
  }

  bool runAttackMovement(double dt) {
    if (_randomMovement) {
      randomMovementController.runRandomMovement(dt, false);
      _randomMovementTimer -= dt;
      return true;
    } else {
      final target = parent.game.player;
      if (target == null || target.dead) return false;
      diffX = target.x - parent.x;
      diffY = target.y - parent.y;

      final direction = _findShortestDirection();

      if (direction == null) {
        return false;
      }

      if (shouldFire && (diffY.abs() < 80 && diffX.abs() < 80)) {
        parent.current = TankState.idle;
      } else {
        parent.current = TankState.run;
      }

      if (direction != _prevDirection) {
        _prevDirection = direction;
        parent.lookDirection = direction;
        parent.angle = direction.angle;
        parent.skipUpdateOnAngleChange = true;
      } else if (!parent.canMoveForward) {
        _startRandomMovement();
      }
      return true;
    }
  }

  Direction? _findShortestDirection() {
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
