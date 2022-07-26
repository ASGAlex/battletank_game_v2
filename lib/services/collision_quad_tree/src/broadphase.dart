part of collision_quad_tree;

class _QuadTreeBroadphase<T extends Hitbox<T>> extends Broadphase<T> {
  _QuadTreeBroadphase({super.items});

  final tree = _QuadTree<T>();
  final List<T> _active = [];

  final Set<CollisionProspect<T>> _potentials = {};

  @override
  Set<CollisionProspect<T>> query() {
    final sw = Stopwatch()..start();
    _potentials.clear();

    for (var item in items) {
      if (item.collisionType != CollisionType.active) {
        continue;
      }

      final asShapeItem = (item as ShapeHitbox);

      if (asShapeItem.isRemoving || asShapeItem.parent == null) {
        tree.remove(item);
        continue;
      }

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
        } else if (asShapePotential.parent == asShapeItem.parent &&
            asShapeItem.parent != null) {
          continue;
        }

        if (asShapeItem is CollisionQuadTreeController) {
          final success = (asShapeItem as CollisionQuadTreeController)
              .broadPhaseCheck(asShapePotential);
          if (!success) continue;
        }

        final itemParent = asShapeItem.parent;
        if (itemParent is Bullet) {
          if (asShapePotential.parent is WaterCollide) continue;
          if (itemParent.firedFrom == asShapePotential.parent) continue;
        }

        final itemCenter = item.aabb.center;
        final potentialCenter = potential.aabb.center;
        if ((itemCenter.x - potentialCenter.x).abs() > 25 ||
            (itemCenter.y - potentialCenter.y).abs() > 25) {
          continue;
        }

        _potentials.add(CollisionProspect<T>(item, potential));
      }
      for (final i in markRemove) {
        tree.remove(i);
      }
    }

    print("S: ${sw.elapsedMicroseconds}  p: ${_potentials.length} ");
    return _potentials;
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
    _potentials.clear();
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
            _potentials.add(CollisionProspect<T>(item, activeItem));
          }
        } else {
          _active.remove(activeItem);
        }
      }
      _active.add(item);
    }

    print("S: ${sw.elapsedMicroseconds}  p: ${_potentials.length} ");
    return _potentials;
  }
}
