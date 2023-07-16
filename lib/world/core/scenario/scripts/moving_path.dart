import 'dart:async';

import 'package:flame/components.dart';
import 'package:tank_game/world/core/actor.dart';
import 'package:tank_game/world/core/behaviors/movement/targeted_movement_behavior.dart';
import 'package:tank_game/world/core/scenario/scripts/event.dart';
import 'package:tank_game/world/core/scenario/scripts/script_core.dart';

class MovingPathScript extends ScriptCore {
  static final namedLists = <String, List<Vector2>>{};

  MovingPathScript({this.points = const [], this.loop = false});

  factory MovingPathScript.fromNamed(String name) {
    final points = namedLists[name];
    if (points == null) {
      throw 'List with name $name is not registered';
    }

    final loop = name.contains('_loop');

    return MovingPathScript(points: points, loop: loop);
  }

  final List<Vector2> points;
  late Iterator<Vector2> _iterator;
  bool loop;

  TargetedMovementBehavior? _targetedMovementBehavior;

  @override
  void onStreamMessage(ScenarioEvent<dynamic> message) {
    // TODO: implement onStreamMessage
  }

  @override
  FutureOr<void> onLoad() {
    super.onLoad();
    _iterator = points.iterator;
    _iterator.moveNext();
    _targetedMovementBehavior = TargetedMovementBehavior(
      targetPosition: _iterator.current,
      targetSize: Vector2.all(8),
      maxRandomMovementTime: 15,
      stopAtTarget: true,
      precision: 0.5,
      maxDtFromLastDirectionChange: 0.01,
    );
    parent!.add(_targetedMovementBehavior!);
    (parent as ActorMixin).coreState = ActorCoreState.move;
  }

  @override
  void scriptUpdate(double dt) {
    final actor = parent as ActorMixin;
    try {
      final targetMovements = actor.findBehaviors<TargetedMovementBehavior>();
      for (final behavior in targetMovements) {
        if (behavior == _targetedMovementBehavior) continue;
        if (!behavior.forceIdle) {
          return;
        }
      }
    } catch (_) {}

    if (_targetedMovementBehavior?.isTargetReached == true) {
      final finished = !_iterator.moveNext();
      if (finished) {
        if (loop) {
          _iterator = points.iterator;
          _iterator.moveNext();
          _targetedMovementBehavior?.targetPosition.setFrom(_iterator.current);
        } else {
          removeFromParent();
          _targetedMovementBehavior?.removeFromParent();
        }
      } else {
        print(_iterator.current);
        _targetedMovementBehavior?.targetPosition.setFrom(_iterator.current);
      }
    }
  }
}
