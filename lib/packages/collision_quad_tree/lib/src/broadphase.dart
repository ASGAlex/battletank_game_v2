import 'dart:collection';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/src/collisions/broadphase.dart';
import 'package:flame/src/collisions/collision_callbacks.dart';
import 'package:flame/src/collisions/hitboxes/hitbox.dart';

import 'quad_tree.dart';

typedef ExternalBroadphaseCheck = bool Function(
    PositionComponent one, PositionComponent another);

class QuadTreeBroadphase<T extends Hitbox<T>> extends Broadphase<T> {
  QuadTreeBroadphase({super.items});

  final tree = QuadTree<T>();
  final List<T> _active = [];
  ExternalBroadphaseCheck? broadphaseCheck;

  @override
  HashSet<CollisionProspect<T>> query() {
    // final sw = Stopwatch()..start();
    final potentials = HashSet<CollisionProspect<T>>();

    for (var item in items) {
      if (item.collisionType != CollisionType.active) {
        continue;
      }

      final asShapeItem = (item as ShapeHitbox);

      if (asShapeItem.isRemoving || asShapeItem.parent == null) {
        tree.remove(item);
        continue;
      }

      final itemCenter = item.aabb.center;
      final markRemove = <T>[];
      final potentiallyCollide = tree.query(item);
      for (final potential in potentiallyCollide) {
        if (potential.collisionType == CollisionType.inactive) {
          continue;
        }

        final asShapePotential = (potential as ShapeHitbox);

        if (asShapePotential.isRemoving || asShapePotential.parent == null) {
          markRemove.add(potential);
          continue;
        }
        if (asShapePotential.parent == asShapeItem.parent &&
            asShapeItem.parent != null) {
          continue;
        }

        final potentialCenter = potential.aabb.center;
        if ((itemCenter.x - potentialCenter.x).abs() > 20 ||
            (itemCenter.y - potentialCenter.y).abs() > 20) {
          continue;
        }

        potentials.add(CollisionProspect<T>(item, potential));
      }
      for (final i in markRemove) {
        tree.remove(i);
      }
    }

    if (broadphaseCheck != null) {
      final removePotentials = <CollisionProspect<T>>[];
      for (final item in potentials) {
        var keep = broadphaseCheck!(
            item.a as PositionComponent, item.b as PositionComponent);
        if (keep) {
          keep = broadphaseCheck!(
              item.b as PositionComponent, item.a as PositionComponent);
        }
        if (!keep) {
          removePotentials.add(item);
        }
      }

      potentials.removeAll(removePotentials);
    }

    // print("S: ${sw.elapsedMicroseconds}  p: ${potentials.length} ");
    return potentials;
  }

  updateItemSizeOrPosition(T item) {
    tree.remove(item, oldPosition: true);
    tree.add(item);
  }

  remove(T item) {
    tree.remove(item);
  }

  @override
  Set<CollisionProspect<T>> queryOld() {
    final sw = Stopwatch()..start();
    final Set<CollisionProspect<T>> potentials = {};
    items.sort((a, b) => (a.aabb.min.x - b.aabb.min.x).ceil());
    for (final item in items) {
      if (item.collisionType == CollisionType.inactive) {
        continue;
      }
      if (_active.isEmpty) {
        _active.add(item);
        continue;
      }
      final currentBox = item.aabb;
      final currentMin = currentBox.min.x;
      for (var i = _active.length - 1; i >= 0; i--) {
        final activeItem = _active[i];
        final activeBox = activeItem.aabb;
        if (activeBox.max.x >= currentMin) {
          if (item.collisionType == CollisionType.active ||
              activeItem.collisionType == CollisionType.active) {
            potentials.add(CollisionProspect<T>(item, activeItem));
          }
        } else {
          _active.remove(activeItem);
        }
      }
      _active.add(item);
    }

    print("S: ${sw.elapsedMicroseconds}  p: ${potentials.length} ");
    return potentials;
  }
}
