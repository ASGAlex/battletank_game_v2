import 'package:flame/collisions.dart';
import 'package:flame/extensions.dart';
import 'package:flutter/widgets.dart';

import 'broadphase.dart';

class QuadTreeCollisionDetection extends StandardCollisionDetection {
  QuadTreeCollisionDetection(Rect mapDimensions)
      : super(broadphase: QuadTreeBroadphase<ShapeHitbox>()) {
    (broadphase as QuadTreeBroadphase).tree.mainBoxSize = mapDimensions;
  }

  QuadTreeBroadphase get quadBroadphase => broadphase as QuadTreeBroadphase;

  @override
  void add(ShapeHitbox item) {
    super.add(item);
    quadBroadphase.tree.add(item);
  }

  @override
  void addAll(Iterable<ShapeHitbox> items) {
    for (final item in items) {
      add(item);
    }
  }

  @override
  void remove(ShapeHitbox item) {
    quadBroadphase.tree.remove(item);
    super.remove(item);
  }

  @override
  void removeAll(Iterable<ShapeHitbox> items) {
    quadBroadphase.tree.clear();
    super.removeAll(items);
  }
}
