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
  Direction? _failedDirection;
  final Set<Direction> _failedAlternatives = {};
  List<Direction>? _availableDirections;
  bool _needAlternativeDirection = false;
  double _randomMovementTicks = -1;
  static const double _randomMovementTicksMax = 30;

  double diffX = 0;
  double diffY = 0;

  bool runAttackMovement(double dt) {
    if (_randomMovementTicks > 0) {
      randomMovementController.runRandomMovement(dt);
      _randomMovementTicks--;
      return true;
    } else {
      final target = parent.game.player;
      if (target == null || target.dead) return false;
      diffX = target.x - parent.x;
      diffY = target.y - parent.y;

      Direction? direction;
      if (_needAlternativeDirection) {
        _availableDirections = directionsChecker.getAvailableDirections();
        direction = _findAlternativeDirection();
        final canMoveNormal = _availableDirections!.contains(_failedDirection);
        if (canMoveNormal) {
          _failedDirection = null;
          _needAlternativeDirection = false;
          _failedAlternatives.clear();
        }
      } else {
        direction = _findShortestDirection();
      }
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
        if (_failedDirection != null) {
          _failedDirection = direction;
        } else {
          _failedAlternatives.add(direction);
        }
        directionsChecker.enableSideHitboxes();
        _needAlternativeDirection = true;
      }
      return true;
    }
  }

  Direction? _findAlternativeDirection() {
    if (_failedAlternatives.length >= 2) {
      _randomMovementTicks = _randomMovementTicksMax;
      _failedDirection = null;
      _needAlternativeDirection = false;
      _failedAlternatives.clear();
    }

    if ([Direction.left, Direction.right].contains(_failedDirection)) {
      final direction = _upOrDown(diffY);
      if (_availableDirections!.contains(direction) &&
          !_failedAlternatives.contains(direction)) {
        return direction;
      } else {
        _failedAlternatives.add(direction);
        return direction.opposite;
      }
    } else {
      final direction = _leftOrRight(diffX);
      if (_availableDirections!.contains(direction) &&
          !_failedAlternatives.contains(direction)) {
        return direction;
      } else {
        _failedAlternatives.add(direction);
        return direction.opposite;
      }
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
