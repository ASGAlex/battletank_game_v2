import 'dart:math';
import 'dart:ui';

import '../../core/direction.dart';
import '../core/base_tank.dart';
import 'available_directions.dart';

class RandomMovementController {
  RandomMovementController(
      {required this.parent, required this.directionsChecker});

  Direction _plannedDirection = Direction.up;
  double _plannedDistance = 0.0;
  double _remainingDistance = 0.0;

  double _plannedMinDistanceForChange = 0.0;
  double _plannedDefaultMin = 10.0;
  double _plannedDefaultMax = 25.0;
  bool _directionFreqCheck = true;

  bool _hasPlan = false;

  bool get _canChangePlan =>
      ((_plannedDistance - _remainingDistance) >
          _plannedMinDistanceForChange) ||
      _remainingDistance <= 0 ||
      _plannedDistance <= 0 ||
      parent.movementHitbox.isMovementBlocked;

  final AvailableDirectionsChecker directionsChecker;
  final Tank parent;

  final _directionFreq = <Direction, int>{};

  VoidCallback? onDirectionChanged;

  bool _createMovementPlan() {
    final availableDirections = directionsChecker.getAvailableDirections();
    _hasPlan = _setRandomDirection(availableDirections);
    if (_hasPlan) {
      directionsChecker.disableSideHitboxes();
      _setNewDirection();
    }
    return _hasPlan;
  }

  runRandomMovement(double dt,
      [bool directionFreqCheck = true, List<Direction> except = const []]) {
    _directionFreqCheck = directionFreqCheck;
    bool planChanged = false;
    if (!_hasPlan) {
      planChanged = _createMovementPlan();
    }

    final innerSpeed = parent.speed * dt;
    _remainingDistance -= innerSpeed;
    if (!planChanged && _canChangePlan) {
      _hasPlan = false;
      directionsChecker.enableSideHitboxes();
    }
  }

  _setNewDirection() {
    parent.lookDirection = _plannedDirection;
    parent.angle = _plannedDirection.angle;
    parent.skipUpdateOnAngleChange = true;
    parent.current = TankState.run;
    var count = _directionFreq[_plannedDirection] ?? 0;
    count++;
    _directionFreq[_plannedDirection] = count;
    onDirectionChanged?.call();
  }

  bool _setRandomDirection(List<Direction> availableDirections) {
    if (availableDirections.isEmpty) return false;

    var total = 0;
    for (final direction in availableDirections) {
      total += _directionFreq[direction] ?? 0;
    }

    final random = Random();
    if (_directionFreqCheck && total > 0 && availableDirections.length > 1) {
      final range = <Direction, List<int>>{};
      var value = 0;
      for (final direction in availableDirections) {
        final list = <int>[value];
        value += ((1 - (_directionFreq[direction] ?? 0) / total) * 100).toInt();
        list.add(value);
        range[direction] = list;
      }

      value = random.nextInt(total);

      for (final entry in range.entries) {
        final min = entry.value.first;
        final max = entry.value.last;
        if (value >= min && value < max) {
          _plannedDirection = entry.key;
          break;
        }
      }
    } else {
      final i = random.nextInt(availableDirections.length);
      _plannedDirection = availableDirections[i];
    }

    _plannedDistance = _remainingDistance =
        random.nextInt((parent.size.x * _plannedDefaultMax).toInt()) +
            parent.size.x * _plannedDefaultMin;
    _plannedMinDistanceForChange = _plannedDistance * 0.3;
    if (_plannedMinDistanceForChange < _plannedDefaultMin) {
      _plannedMinDistanceForChange = _plannedDefaultMin;
    }

    return true;
  }
}
