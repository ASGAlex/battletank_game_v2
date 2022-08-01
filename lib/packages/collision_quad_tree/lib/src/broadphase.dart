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

  final activeCollisions = HashSet<T>();

  ExternalBroadphaseCheck? broadphaseCheck;
  final _broadphaseCheckCache = <T, Map<T, bool>>{};

  @override
  HashSet<CollisionProspect<T>> query() {
    final potentials = HashSet<CollisionProspect<T>>();
    final potentialsTmp = <List<T>>[];

    for (var activeItem in activeCollisions) {
      final asShapeItem = (activeItem as ShapeHitbox);

      if (asShapeItem.isRemoving || asShapeItem.parent == null) {
        tree.remove(activeItem);
        continue;
      }

      final itemCenter = activeItem.aabb.center;
      final markRemove = <T>[];
      final potentiallyCollide = tree.query(activeItem);
      for (final potential in potentiallyCollide.entries.first.value) {
        if (potential.collisionType == CollisionType.inactive) {
          continue;
        }

        if (_broadphaseCheckCache[activeItem]?[potential] == false) {
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

        potentialsTmp.add([activeItem, potential]);
      }
      for (final i in markRemove) {
        tree.remove(i);
      }
    }

    if (potentialsTmp.isNotEmpty && broadphaseCheck != null) {
      for (var i = 0; i < potentialsTmp.length; i++) {
        final item0 = potentialsTmp[i].first as PositionComponent;
        final item1 = potentialsTmp[i].last as PositionComponent;
        var keep = broadphaseCheck!(item0, item1);
        if (keep) {
          keep = broadphaseCheck!(item1, item0);
        }
        if (keep) {
          potentials.add(CollisionProspect(item0 as T, item1 as T));
        } else {
          if (_broadphaseCheckCache[item0 as T] == null) {
            _broadphaseCheckCache[item0 as T] = {};
          }
          _broadphaseCheckCache[item0 as T]![item1 as T] = false;
        }
      }
    }
    print("P: ${potentials.length}");
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
