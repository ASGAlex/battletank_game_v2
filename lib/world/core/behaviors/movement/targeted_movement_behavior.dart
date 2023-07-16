import 'dart:async';
import 'dart:math';

import 'package:flame/game.dart';
import 'package:tank_game/world/core/actor.dart';
import 'package:tank_game/world/core/behaviors/movement/available_direction_checker.dart';
import 'package:tank_game/world/core/behaviors/movement/movement_factory_mixin.dart';
import 'package:tank_game/world/core/behaviors/movement/movement_forward_collision.dart';
import 'package:tank_game/world/core/behaviors/movement/random_movement_behavior.dart';
import 'package:tank_game/world/core/direction.dart';

class TargetedMovementBehavior extends AvailableDirectionChecker {
  TargetedMovementBehavior({
    required Vector2 targetPosition,
    required Vector2 targetSize,
    this.stopMovementDistance = 0,
    this.maxRandomMovementTime = 5,
    this.onShouldFire,
    this.stopAtTarget = true,
    this.precision = 1,
    this.maxDtFromLastDirectionChange = 0.5,
  }) {
    this.targetPosition.setFrom(targetPosition);
    minDiff = max(targetSize.x, targetSize.y) / 2;
  }

  bool stopAtTarget;
  double stopMovementDistance;
  double maxRandomMovementTime;
  double _randomMovementTimer = 0;
  final NotifyingVector2 targetPosition = NotifyingVector2.zero();
  late final double minDiff;
  final _diff = Vector2(0, 0);
  bool shouldFire = false;
  double precision;

  Function? onShouldFire;

  late final MovementForwardCollisionBehavior _moveForwardBehavior;

  double maxDtFromLastDirectionChange;
  double _dtFromLastDirectionChange = 0;

  bool forceIdle = false;
  final maxAttemptsToChangeDirection = 2;
  int _attemptsToChangeDirection = 0;

  bool isTargetReached = false;

  @override
  FutureOr onLoad() {
    _moveForwardBehavior =
        parent.findBehavior<MovementForwardCollisionBehavior>();
    try {
      parent.findBehavior<RandomMovementBehavior>().pauseBehavior = true;
    } catch (_) {}

    targetPosition.addListener(() {
      isTargetReached = false;
    });
    return super.onLoad();
  }

  @override
  void onRemove() {
    targetPosition.dispose();
    super.onRemove();
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
    if ((_diff.x.abs() <= parent.size.x * precision &&
            _diff.y.abs() <= parent.size.y / 2) ||
        (_diff.x.abs() <= parent.size.x / 2 &&
            _diff.y.abs() <= parent.size.y * precision)) {
      if (stopAtTarget) {
        parent.coreState = ActorCoreState.idle;
        forceIdle = true;
        isTargetReached = true;
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
        if (parent.lookDirection == DirectionExtended.up ||
            parent.lookDirection == DirectionExtended.down) {
          _changeDirectionTry(_leftOrRight(_diff.x));
          directionChanged = true;
        } else if (parent.lookDirection == DirectionExtended.right ||
            parent.lookDirection == DirectionExtended.left) {
          _changeDirectionTry(_upOrDown(_diff.y));
          directionChanged = true;
        }
      } else {
        _attemptsToChangeDirection = 0;
        forceIdle = false;
        _startRandomMovement();
        return;
      }
    }

    if (directionChanged && !forceIdle) {
      _attemptsToChangeDirection++;
    } else {
      if (forceIdle) {
        if (_dtFromLastDirectionChange >= maxDtFromLastDirectionChange) {
          forceIdle = false;
          _changeDirectionTry();
        }
      } else if (!directionChanged) {
        _changeDirectionTry();
      }
    }

    if (shouldFire) {
      onShouldFire?.call();
    }
  }

  void _changeDirectionTry([DirectionExtended? direction]) {
    final newDirection = direction ?? _findShortestDirection();

    if (newDirection != null && newDirection != parent.lookDirection) {
      if (_dtFromLastDirectionChange >= maxDtFromLastDirectionChange) {
        parent.lookDirection = newDirection;
        _dtFromLastDirectionChange = 0;
      } else {
        forceIdle = true;
      }
    }
  }

  void _startRandomMovement() {
    if (parent is MovementFactoryMixin) {
      try {
        final randomMovementBehavior =
            parent.findBehavior<RandomMovementBehavior>();
        randomMovementBehavior.pauseBehavior = false;
      } catch (_) {
        final randomMovementBehavior =
            (parent as MovementFactoryMixin).createRandomMovement();
        parent.add(randomMovementBehavior);
      }
      _randomMovementTimer = 0;
      isRandomMovement = true;
    }
  }

  void _stopRandomMovement() {
    try {
      parent.findBehavior<RandomMovementBehavior>().pauseBehavior = true;
    } catch (_) {}
    isRandomMovement = false;
  }

  bool isRandomMovement = false;

  DirectionExtended? _findShortestDirection() {
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
        return DirectionExtended.down;
      } else {
        if (_diff.y >= -minDiff) {
          shouldFire = true;
          return _leftOrRight(_diff.x);
        } else {
          shouldFire = false;
        }
        return DirectionExtended.up;
      }
    } else {
      if (_diff.x > 0) {
        if (_diff.x <= minDiff) {
          shouldFire = true;
          return _upOrDown(_diff.y);
        } else {
          shouldFire = false;
        }
        return DirectionExtended.right;
      } else {
        if (_diff.x >= -minDiff) {
          shouldFire = true;
          return _upOrDown(_diff.y);
        } else {
          shouldFire = false;
        }
        return DirectionExtended.left;
      }
    }
  }

  DirectionExtended _leftOrRight(double diffX) {
    if (diffX > 0) {
      return DirectionExtended.right;
    } else {
      return DirectionExtended.left;
    }
  }

  DirectionExtended _upOrDown(double diffY) {
    if (diffY > 0) {
      return DirectionExtended.down;
    } else {
      return DirectionExtended.up;
    }
  }
}
