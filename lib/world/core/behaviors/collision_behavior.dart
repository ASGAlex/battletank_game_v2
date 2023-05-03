import 'dart:async';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:tank_game/world/core/actor.dart';
import 'package:tank_game/world/core/behaviors/core_behavior.dart';

abstract class CollisionBehavior extends CoreBehavior<ActorMixin>
    with CollisionCallbacks {
  CollisionBehavior();

  final _onCollisionList = <CollisionCallback<PositionComponent>>{};
  final _onCollisionStartList = <CollisionCallback<PositionComponent>>{};
  final _onCollisionEndList = <CollisionEndCallback<PositionComponent>>{};

  bool _active = false;

  @override
  FutureOr<void> onLoad() {
    assert(parent is CollisionCallbacks);
    final _parent = (parent as CollisionCallbacks);
    if (_parent.onCollisionCallback == null) {
      _setupCallbacks(_parent);
    } else {
      try {
        final behaviors = parent.findBehaviors<CollisionBehavior>();
        for (final behavior in behaviors) {
          if (behavior._active) {
            behavior._onCollisionList.add(onCollision);
            behavior._onCollisionStartList.add(onCollisionStart);
            behavior._onCollisionEndList.add(onCollisionEnd);
            break;
          }
        }
      } catch (_) {
        _setupCallbacks(_parent);
      }
    }
  }

  void _setupCallbacks(CollisionCallbacks parent) {
    parent.onCollisionCallback = _onCollision;
    parent.onCollisionStartCallback = _onCollisionStart;
    parent.onCollisionEndCallback = _onCollisionEnd;
    _onCollisionList.add(onCollision);
    _onCollisionStartList.add(onCollisionStart);
    _onCollisionEndList.add(onCollisionEnd);
    _active = true;
  }

  @override
  void onRemove() {
    try {
      final behaviors = parent.findBehaviors<CollisionBehavior>();
      if (_active) {
        final _parent = (parent as CollisionCallbacks);
        _parent.onCollisionCallback = _parent.onCollisionStartCallback =
            _parent.onCollisionEndCallback = null;

        for (final behavior in behaviors) {
          if (behavior == this) continue;
          behavior._setupCallbacks(_parent);
          behavior._onCollisionList.addAll(_onCollisionList);
          behavior._onCollisionStartList.addAll(_onCollisionStartList);
          behavior._onCollisionEndList.addAll(_onCollisionEndList);
          break;
        }
      } else {
        for (final behavior in behaviors) {
          if (behavior == this) continue;
          if (behavior._active) {
            behavior._onCollisionList.remove(onCollision);
            behavior._onCollisionStartList.remove(_onCollisionStart);
            behavior._onCollisionEndList.remove(onCollisionEnd);
            break;
          }
        }
      }
    } catch (_) {}
    super.onRemove();
  }

  void _onCollision(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    for (final element in _onCollisionList) {
      element.call(intersectionPoints, other);
    }
  }

  void _onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    for (final element in _onCollisionStartList) {
      element.call(intersectionPoints, other);
    }
  }

  void _onCollisionEnd(
    PositionComponent other,
  ) {
    for (final element in _onCollisionEndList) {
      element.call(other);
    }
  }
}
