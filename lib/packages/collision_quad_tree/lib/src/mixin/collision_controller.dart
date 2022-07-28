import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/widgets.dart';

import '../broadphase.dart';
import '../collision_detection.dart';
import 'has_quad_tree_collision_detection.dart';

mixin CollisionQuadTreeController<T extends HasQuadTreeCollisionDetection>
    on PositionComponent {
  final _listenerByComponent = <ShapeHitbox, VoidCallback>{};

  QuadTreeBroadphase get _quadBroadphase {
    final game = findParent<T>();
    final bf = game?.collisionDetection as QuadTreeCollisionDetection;
    return bf.quadBroadphase;
  }

  removeQuadTreeCollision(ShapeHitbox hitbox) {
    _quadBroadphase.remove(hitbox);
  }

  updateQuadTreeCollision(ShapeHitbox hitbox) {
    _quadBroadphase.updateItemSizeOrPosition(hitbox);
  }

  @override
  Future<void>? add(Component component) {
    final result = super.add(component);
    if (component is ShapeHitbox) {
      final listener = () {
        final game = findParent<T>();
        game?.scheduleHitboxUpdate(component);
      };
      position.addListener(listener);
      size.addListener(listener);

      _listenerByComponent[component] = listener;
    }
    return result;
  }

  @override
  void remove(Component component) {
    super.remove(component);

    final listener = _listenerByComponent[component];
    if (listener != null) {
      position.removeListener(listener);
      size.removeListener(listener);
    }
  }

  @mustCallSuper
  bool broadPhaseCheck(PositionComponent other) {
    final myParent = parent;
    final otherParent = other.parent;
    if (myParent is CollisionQuadTreeController &&
        otherParent is PositionComponent) {
      return (myParent).broadPhaseCheck(otherParent);
    }

    return true;
  }
}
