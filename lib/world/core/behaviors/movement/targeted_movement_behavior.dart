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
    this.stopMovementDistance = 0,
    this.maxRandomMovementTime = 5,
    this.onShouldFire,
    this.stopAtTarget = true,
  });

  bool stopAtTarget;
  double stopMovementDistance;
  double maxRandomMovementTime;
  double _randomMovementTimer = 0;
  final Vector2 targetPosition;
  final _diff = Vector2(0, 0);
  bool shouldFire = false;

  Function? onShouldFire;

  late final MovementForwardCollisionBehavior _moveForwardBehavior;
  RandomMovementBehavior? _randomMovementBehavior;

  double _dtFromLastDirectionChange = 0;

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

    if (_moveForwardBehavior.movementHitbox.isMovementBlocked) {
      _startRandomMovement();
      return;
    }

    _diff.setFrom(targetPosition - parent.data.positionCenter);
    if (_diff.x <= parent.size.x && _diff.y <= parent.size.y) {
      if (stopAtTarget) {
        parent.coreState = ActorCoreState.idle;
      } else {
        _startRandomMovement();
        removeFromParent();
        return;
      }
    }

    final direction = _findShortestDirection();

    if (direction != null &&
        direction != parent.lookDirection &&
        _dtFromLastDirectionChange >= 0.5) {
      parent.lookDirection = direction;
      _dtFromLastDirectionChange = 0;
    }

    if (shouldFire) {
      onShouldFire?.call();
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
    final minDiff = parent.size.x / 2;

    if (diffBetweenAxis.abs() <= minDiff) {
      if (Random().nextBool()) {
        diffBetweenAxis = -(minDiff + 1);
      } else {
        diffBetweenAxis = minDiff + 1;
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
