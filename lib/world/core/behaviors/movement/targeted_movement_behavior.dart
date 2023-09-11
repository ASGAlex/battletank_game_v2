import 'dart:async';
import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/experimental.dart';
import 'package:flame/extensions.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:tank_game/game.dart';
import 'package:tank_game/world/core/actor.dart';
import 'package:tank_game/world/core/behaviors/movement/available_direction_checker.dart';
import 'package:tank_game/world/core/behaviors/movement/movement_factory_mixin.dart';
import 'package:tank_game/world/core/behaviors/movement/movement_forward_collision.dart';
import 'package:tank_game/world/core/behaviors/movement/random_movement_behavior.dart';
import 'package:tank_game/world/core/direction.dart';

class TargetedMovementBehavior extends AvailableDirectionChecker
    with HasGameReference<MyGame> {
  TargetedMovementBehavior({
    required Vector2 targetPosition,
    required this.targetSize,
    this.maxRandomMovementTime = 5,
    this.onShouldFire,
    this.stopAtTarget = true,
    this.precision = 1,
    this.maxDtFromLastDirectionChange = 0.1,
    this.onTargetReached,
    this.drawLineToTarget = false,
  }) {
    this.targetPosition.setFrom(targetPosition);
    minDiff = max(targetSize.x, targetSize.y) / 2;
  }

  bool stopAtTarget;
  Function(TargetedMovementBehavior behavior)? onTargetReached;

  Vector2 targetSize;
  double maxRandomMovementTime;
  double _randomMovementTimer = 0;
  final NotifyingVector2 targetPosition = NotifyingVector2.zero();
  late final double minDiff;
  final _diff = Vector2(0, 0);
  bool shouldFire = false;
  double precision;

  bool drawLineToTarget;
  _MovementLine? _movementLine;

  Function? onShouldFire;

  late final MovementForwardCollisionBehavior _moveForwardBehavior;

  double maxDtFromLastDirectionChange;
  double _dtFromLastDirectionChange = 0;

  bool forceIdle = false;
  final maxAttemptsToChangeDirection = 2;
  int _attemptsToChangeDirection = 0;

  DirectionExtended? _originalDirection;
  double? _fallbackToOriginalDistance;
  double? _blockAxisChangeDistance;
  bool _chooseLongestAxis = false;

  bool isTargetReached = false;
  bool pauseBehavior = false;

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
    _movementLine?.removeFromParent();
    super.onRemove();
  }

  @override
  void update(double dt) {
    if (pauseBehavior) return;

    if (drawLineToTarget && !isTargetReached) {
      if (_movementLine == null) {
        _movementLine = _MovementLine(parent.position, targetPosition);
        game.world.uiLayer.add(_movementLine!);
      }
      _movementLine!.position.setFrom(parent.position);
      _movementLine!.target.setFrom(targetPosition);
    }

    _diff.setFrom(targetPosition - parent.data.positionCenter);
    _dtFromLastDirectionChange += dt;

    if (_attemptsToChangeDirection >= maxAttemptsToChangeDirection) {
      if (!_chooseLongestAxis) {
        _chooseLongestAxis = true;
        _attemptsToChangeDirection = 0;
      } else {
        _startRandomMovement();
      }
    }

    if (!_randomMovementMode(dt)) {
      if (!_reachTargetCheck()) {
        if (_fallbackToOriginalDistance != null) {
          _fallbackToOriginalDistance = _fallbackToOriginalDistance! -
              _moveForwardBehavior.lastInnerSpeed;
          if (_fallbackToOriginalDistance! <= 0) {
            _fallbackToOriginalDistance = null;
            if (_originalDirection != null) {
              parent.lookDirection = _originalDirection!;
              _chooseLongestAxis = false;
              _attemptsToChangeDirection = 0;
            } else {
              _chooseShortestAxis();
            }
          } else {
            if (!_blockedMovementCheck()) {
              _chooseShortestAxis();
            }
          }
        } else {
          if (!_blockedMovementCheck()) {
            if (_blockAxisChangeDistance != null) {
              _blockAxisChangeDistance = _blockAxisChangeDistance! -
                  _moveForwardBehavior.lastInnerSpeed;
              if (_blockAxisChangeDistance! <= 0) {
                _blockAxisChangeDistance = null;
              }
            } else {
              _chooseShortestAxis();
            }
          }
        }
      }
    }

    if (shouldFire) {
      onShouldFire?.call();
    }
  }

  void _chooseShortestAxis() {
    if (_attemptsToChangeDirection < maxAttemptsToChangeDirection) {
      _changeDirectionTry();
    }
  }

  bool _randomMovementMode(double dt) {
    if (isRandomMovement) {
      if (_randomMovementTimer <= maxRandomMovementTime) {
        _randomMovementTimer += dt;
        return true;
      } else {
        _stopRandomMovement();
      }
    }
    return false;
  }

  bool _reachTargetCheck() {
    if ((_diff.x.abs() <= targetSize.x && _diff.y.abs() <= targetSize.y / 2) ||
        (_diff.x.abs() <= targetSize.x / 2 && _diff.y.abs() <= targetSize.y)) {
      if (stopAtTarget) {
        parent.coreState = ActorCoreState.idle;
        forceIdle = true;
      } else {
        _startRandomMovement();
        // removeFromParent();
      }
      if (drawLineToTarget && _movementLine != null) {
        _movementLine!.removeFromParent();
        _movementLine = null;
      }
      isTargetReached = true;
      onTargetReached?.call(this);
      _blockAxisChangeDistance = 0;
      _chooseLongestAxis = false;
      _attemptsToChangeDirection = 0;
      _fallbackToOriginalDistance = 0;
      return true;
    } else {
      if (stopAtTarget) {
        parent.coreState = ActorCoreState.move;
        forceIdle = false;
      }
    }
    return false;
  }

  bool _blockedMovementCheck() {
    if (_moveForwardBehavior.movementHitbox.isMovementBlocked) {
      if (forceIdle) {
        if (_dtFromLastDirectionChange >= maxDtFromLastDirectionChange) {
          forceIdle = false;
          _changeAlternativeDirectionWhenCollide();
        }
      } else {
        _changeAlternativeDirectionWhenCollide();
      }
      return true;
    }
    return false;
  }

  void _changeAlternativeDirectionWhenCollide() {
    _attemptsToChangeDirection++;
    if (_attemptsToChangeDirection >= maxAttemptsToChangeDirection) {
      if (!_chooseLongestAxis) {
        _chooseLongestAxis = true;
        _attemptsToChangeDirection = 0;
      }
    }

    final short =
        _moveForwardBehavior.movementHitbox.alternativeDirectionShortest;
    final long =
        _moveForwardBehavior.movementHitbox.alternativeDirectionLongest;
    var distance = 0.0;
    var secondaryDistance = 0.0;
    DirectionExtended direction;
    if (_chooseLongestAxis) {
      direction = long.keys.first;
      final longestSide =
          _moveForwardBehavior.movementHitbox.aabb.toRect().longestSide;
      distance = long.values.first + longestSide;
      secondaryDistance = short.values.first + longestSide;
    } else {
      direction = short.keys.first;
      final longestSide =
          _moveForwardBehavior.movementHitbox.aabb.toRect().longestSide;
      distance = short.values.first + longestSide;
      secondaryDistance = long.values.first + longestSide;
    }
    _changeDirectionTry(direction, distance, secondaryDistance);
  }

  void _changeDirectionTry([
    DirectionExtended? direction,
    double? distance,
    double? secondaryDistance,
  ]) {
    final newDirection = direction ?? _findShortestDirection();

    if (newDirection != null && newDirection != parent.lookDirection) {
      if (_dtFromLastDirectionChange >= maxDtFromLastDirectionChange) {
        if (distance != null && secondaryDistance != null) {
          _fallbackToOriginalDistance = distance;
          _blockAxisChangeDistance = secondaryDistance;
          _originalDirection = parent.lookDirection;
        }
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
        (parent as MovementFactoryMixin).createRandomMovement();
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
    _attemptsToChangeDirection = 0;
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

    if (diffBetweenAxis > 0 && !_chooseLongestAxis) {
      if (_diff.y > 0 && !_chooseLongestAxis) {
        if (_diff.y <= minDiff) {
          shouldFire = true;
          return _leftOrRight(_diff.x);
        } else {
          shouldFire = false;
        }
        return DirectionExtended.down;
      } else {
        if (_diff.y >= -minDiff && !_chooseLongestAxis) {
          shouldFire = true;
          return _leftOrRight(_diff.x);
        } else {
          shouldFire = false;
        }
        return DirectionExtended.up;
      }
    } else {
      if (_diff.x > 0 && !_chooseLongestAxis) {
        if (_diff.x <= minDiff) {
          shouldFire = true;
          return _upOrDown(_diff.y);
        } else {
          shouldFire = false;
        }
        return DirectionExtended.right;
      } else {
        if (_diff.x >= -minDiff && !_chooseLongestAxis) {
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
    if (diffX > 0 && !_chooseLongestAxis) {
      return DirectionExtended.right;
    } else {
      return DirectionExtended.left;
    }
  }

  DirectionExtended _upOrDown(double diffY) {
    if (diffY > 0 && !_chooseLongestAxis) {
      return DirectionExtended.down;
    } else {
      return DirectionExtended.up;
    }
  }
}

class _MovementLine extends Component with HasPaint {
  _MovementLine(this.position, this.target) {
    paint.color = Colors.pink;
  }

  Vector2 position;
  Vector2 target;

  @override
  void render(Canvas canvas) {
    canvas.drawLine(position.toOffset(), target.toOffset(), paint);
  }
}
