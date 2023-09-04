import 'dart:async';

import 'package:flame/components.dart';
import 'package:tank_game/world/core/actor.dart';
import 'package:tank_game/world/core/behaviors/movement/targeted_movement_behavior.dart';
import 'package:tank_game/world/core/scenario/scripts/event.dart';
import 'package:tank_game/world/core/scenario/scripts/script_core.dart';

class MovingPathScript extends ScriptCore with ChildrenChangeListenerMixin {
  static final namedLists = <String, List<Vector2>>{};

  MovingPathScript({
    this.points = const [],
    this.loop = false,
    this.highPriority = false,
  });

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
  bool highPriority;

  @override
  double get frequency => 0.5;

  TargetedMovementBehavior? _targetedMovementBehavior;
  final _pausedBehaviors = <TargetedMovementBehavior>[];

  final _trackedTargetedMovement = <TargetedMovementBehavior>{};

  @override
  void onStreamMessage(ScenarioEvent<dynamic> message) {
    // TODO: implement onStreamMessage
  }

  @override
  FutureOr<void> onLoad() {
    assert(parent is PositionComponent);
    super.onLoad();
    _iterator = points.iterator;
    _iterator.moveNext();
    _targetedMovementBehavior = TargetedMovementBehavior(
      targetPosition: _iterator.current,
      targetSize: (parent as PositionComponent).size,
      maxRandomMovementTime: 15,
      stopAtTarget: true,
      precision: 0.5,
      maxDtFromLastDirectionChange: 0.0001,
    );
    parent!.add(_targetedMovementBehavior!);
    (parent as ActorMixin).coreState = ActorCoreState.move;
  }

  @override
  void scriptUpdate(double dt) {
    try {
      for (final behavior in _trackedTargetedMovement) {
        if (!behavior.isTargetReached) {
          if (highPriority) {
            behavior.pauseBehavior = true;
            _pausedBehaviors.add(behavior);
          } else {
            _targetedMovementBehavior?.pauseBehavior = true;
            return;
          }
        }
      }
    } catch (_) {}
    _targetedMovementBehavior?.pauseBehavior = false;
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
          for (final behavior in _pausedBehaviors) {
            behavior.pauseBehavior = false;
          }
          _pausedBehaviors.clear();
        }
      } else {
        print(_iterator.current);
        _targetedMovementBehavior?.targetPosition.setFrom(_iterator.current);
      }
    }
  }

  @override
  void onParentChildrenChanged(ChildrenChangeMessage message) {
    if (message.child.runtimeType == TargetedMovementBehavior) {
      if (message.child == _targetedMovementBehavior) return;
      switch (message.type) {
        case ChildrenChangeType.added:
          _trackedTargetedMovement
              .add(message.child as TargetedMovementBehavior);
          break;
        case ChildrenChangeType.removed:
          _trackedTargetedMovement.remove(message.child);
          break;
      }
    }
  }
}
