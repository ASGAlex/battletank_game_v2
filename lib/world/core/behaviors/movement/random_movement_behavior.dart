import 'dart:async';
import 'dart:math';

import 'package:tank_game/world/core/actor.dart';
import 'package:tank_game/world/core/behaviors/movement/available_direction_checker.dart';
import 'package:tank_game/world/core/direction.dart';

import 'movement_forward_collision.dart';

class RandomMovementBehavior extends AvailableDirectionChecker {
  RandomMovementBehavior({
    required this.maxDirectionDistance,
    required this.minDirectionDistance,
  }) {
    _maxActualDistanceAtCycle = maxDirectionDistance.toDouble();
  }

  bool pauseBehavior = false;
  final int maxDirectionDistance;
  final int minDirectionDistance;

  double _actualDistance = 0;
  double _plannedDistance = 0;

  double _maxActualDistanceAtCycle = -1;
  int _fullDistanceWithoutBlock = 0;

  bool get isDistanceEnd => _plannedDistance <= _actualDistance;

  late final MovementForwardCollisionBehavior _moveForwardBehavior;
  bool _chooseDirectionNextTick = false;

  DirectionExtended? _lastDirection;

  set trackCorners(bool value) {
    _trackCorners = value;
    if (_trackCorners) {
      provider.enableSideHitboxes();
    }
  }

  bool get trackCorners => _trackCorners;
  bool _trackCorners = false;

  final random = Random();
  final List<DirectionExtended> _lastAvailableDirections = [];

  @override
  void update(double dt) {
    if (pauseBehavior) {
      return;
    }
    if (_chooseDirectionNextTick) {
      _chooseDirectionNextTick = false;
      chooseNewDirection();
      if (!trackCorners) {
        provider.disableSideHitboxes();
      }

      if (_fullDistanceWithoutBlock > 4) {
        _fullDistanceWithoutBlock = 0;
        _maxActualDistanceAtCycle = maxDirectionDistance.toDouble();
      }
      return;
    }
    var distance = _moveForwardBehavior.lastDisplacement.x.abs();
    if (distance == 0) {
      distance = _moveForwardBehavior.lastDisplacement.y.abs();
    }
    _actualDistance += distance;
    if (movementHitbox.isMovementBlocked || isDistanceEnd) {
      if (movementHitbox.isMovementBlocked) {
        if (_maxActualDistanceAtCycle > _actualDistance) {
          _maxActualDistanceAtCycle =
              _maxActualDistanceAtCycle - _maxActualDistanceAtCycle / 5;
        }
      } else if (isDistanceEnd) {
        _fullDistanceWithoutBlock++;
      }
      provider.enableSideHitboxes();
      _chooseDirectionNextTick = true;
    } else if (trackCorners) {
      final availableDirections = getAvailableDirections();
      final directionsToTry = <DirectionExtended>[];
      for (final direction in availableDirections) {
        if (direction == _lastDirection ||
            _lastAvailableDirections.contains(direction)) continue;
        directionsToTry.add(direction);
      }
      if (directionsToTry.length > 1 && random.nextInt(100) > 20) {
        print('!!!!!!!!!!!!!!! CORNER !!!!!!!!!!!!!!!!');
        print(directionsToTry);
        final i = random.nextInt(directionsToTry.length);
        setNewDirection(directionsToTry[i]);
        _lastAvailableDirections
          ..clear()
          ..addAll(availableDirections);
      }
    }
  }

  void chooseNewDirection() {
    _lastAvailableDirections
      ..clear()
      ..addAll(getAvailableDirections());
    if (_lastAvailableDirections.isEmpty) return;

    if (_lastAvailableDirections.contains(parent.lookDirection) &&
        _lastAvailableDirections.length > 1) {
      _lastAvailableDirections.remove(parent.lookDirection);
    }
    if (_lastDirection != null && _lastAvailableDirections.length > 1) {
      _lastAvailableDirections.remove(_lastDirection!);
    }

    final i = random.nextInt(_lastAvailableDirections.length);

    setNewDirection(_lastAvailableDirections[i]);
  }

  void setNewDirection(DirectionExtended direction) {
    _lastDirection = parent.lookDirection;
    parent.lookDirection = direction;
    var distance = random.nextInt(maxDirectionDistance);
    if (_maxActualDistanceAtCycle < maxDirectionDistance) {
      distance = random.nextInt(_maxActualDistanceAtCycle.ceil());
    } else {
      if (distance < minDirectionDistance) {
        distance = minDirectionDistance +
            random.nextInt(maxDirectionDistance - minDirectionDistance);
      }
    }
    _plannedDistance = distance.toDouble();
    _actualDistance = 0;
    parent.coreState = ActorCoreState.move;
  }

  @override
  FutureOr onLoad() {
    _moveForwardBehavior =
        parent.findBehavior<MovementForwardCollisionBehavior>();
    return super.onLoad();
  }
}
