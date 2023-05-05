import 'dart:async';
import 'dart:math';

import 'package:flame/extensions.dart';
import 'package:tank_game/world/core/actor.dart';
import 'package:tank_game/world/core/behaviors/movement/available_direction_checker.dart';
import 'package:tank_game/world/core/behaviors/movement/movement_factory_mixin.dart';
import 'package:tank_game/world/core/behaviors/movement/movement_forward_collision.dart';
import 'package:tank_game/world/core/behaviors/movement/random_movement_behavior.dart';
import 'package:tank_game/world/core/direction.dart';

class TargetedMovementBehavior extends AvailableDirectionChecker {
  TargetedMovementBehavior({
    required this.targetPosition,
    required Vector2 targetSize,
    this.stopMovementDistance = 0,
    this.maxRandomMovementTime = 5,
    this.onShouldFire,
    this.stopAtTarget = true,
  }) {
    minDiff = max(targetSize.x, targetSize.y) / 2;
  }

  bool stopAtTarget;
  double stopMovementDistance;
  double maxRandomMovementTime;
  double _randomMovementTimer = 0;
  final Vector2 targetPosition;
  late final double minDiff;
  final _diff = Vector2(0, 0);
  bool shouldFire = false;

  Function? onShouldFire;

  late final MovementForwardCollisionBehavior _moveForwardBehavior;
  RandomMovementBehavior? _randomMovementBehavior;

  final maxDtFromLastDirectionChange = 0.25;
  double _dtFromLastDirectionChange = 0;

  bool forceIdle = false;
  final maxAttemptsToChangeDirection = 3;
  int _attemptsToChangeDirection = 0;

  @override
  FutureOr onLoad() {
    _moveForwardBehavior =
        parent.findBehavior<MovementForwardCollisionBehavior>();
    try {
      parent.findBehavior<RandomMovementBehavior>().removeFromParent();
    } catch (_) {}

    return super.onLoad();
  }

  @override
  void update(double dt) {
    _dtFromLastDirectionChange += dt;
    if (isRandomMovement) {
      if (_randomMovementTimer <= maxRandomMovementTime) {
        _randomMovementTimer += dt;
        return;
      } else {
        _stopRandomMovement();
      }
    }

    _diff.setFrom(targetPosition - parent.data.positionCenter);
    if (_diff.x.abs() <= parent.size.x + (parent.size.x / 2) &&
        _diff.y.abs() <= parent.size.y + (parent.size.y / 2)) {
      if (stopAtTarget) {
        parent.coreState = ActorCoreState.idle;
        forceIdle = true;
      } else {
        _startRandomMovement();
        // removeFromParent();
        return;
      }
    } else {
      if (stopAtTarget) {
        parent.coreState = ActorCoreState.move;
        forceIdle = false;
      }
    }

    bool directionChanged = false;
    if (_moveForwardBehavior.movementHitbox.isMovementBlocked && !forceIdle) {
      if (_attemptsToChangeDirection < maxAttemptsToChangeDirection) {
        if (parent.lookDirection == Direction.up ||
            parent.lookDirection == Direction.down) {
          _changeDirection(_leftOrRight(_diff.x));
          directionChanged = true;
        } else if (parent.lookDirection == Direction.right ||
            parent.lookDirection == Direction.left) {
          _changeDirection(_upOrDown(_diff.y));
          directionChanged = true;
        }
      } else {
        _attemptsToChangeDirection = 0;
        forceIdle = false;
        _startRandomMovement();
        return;
      }
    }

    if (directionChanged) {
      _attemptsToChangeDirection++;
    } else if (_dtFromLastDirectionChange >= maxDtFromLastDirectionChange) {
      final direction = _findShortestDirection();
      _changeDirection(direction);
    }

    if (shouldFire) {
      onShouldFire?.call();
    }
  }

  void _changeDirection(Direction? direction) {
    final newDirection = direction ?? _findShortestDirection();

    if (newDirection != null &&
        newDirection != parent.lookDirection &&
        _dtFromLastDirectionChange >= maxDtFromLastDirectionChange) {
      parent.lookDirection = newDirection;
      _dtFromLastDirectionChange = 0;
    }
  }

  void _startRandomMovement() {
    if (_randomMovementBehavior == null && parent is MovementFactoryMixin) {
      _randomMovementBehavior =
          (parent as MovementFactoryMixin).createRandomMovement();
      parent.add(_randomMovementBehavior!);
      _randomMovementTimer = 0;
    }
  }

  void _stopRandomMovement() {
    _randomMovementBehavior?.removeFromParent();
    _randomMovementBehavior = null;
  }

  bool get isRandomMovement => _randomMovementBehavior != null;

  Direction? _findShortestDirection() {
    var diffBetweenAxis = _diff.x.abs() - _diff.y.abs();

    if (diffBetweenAxis.abs() <= minDiff) {
      if (Random().nextBool()) {
        diffBetweenAxis = -1;
      } else {
        diffBetweenAxis = 1;
      }
    }

    if (diffBetweenAxis > 0) {
      if (_diff.y > 0) {
        if (_diff.y <= minDiff) {
          shouldFire = true;
          return _leftOrRight(_diff.x);
        } else {
          shouldFire = false;
        }
        return Direction.down;
      } else {
        if (_diff.y >= -minDiff) {
          shouldFire = true;
          return _leftOrRight(_diff.x);
        } else {
          shouldFire = false;
        }
        return Direction.up;
      }
    } else {
      if (_diff.x > 0) {
        if (_diff.x <= minDiff) {
          shouldFire = true;
          return _upOrDown(_diff.y);
        } else {
          shouldFire = false;
        }
        return Direction.right;
      } else {
        if (_diff.x >= -minDiff) {
          shouldFire = true;
          return _upOrDown(_diff.y);
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
