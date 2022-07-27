part of collision_quad_tree;

class _QuadTreeBroadphase<T extends Hitbox<T>> extends Broadphase<T> {
  _QuadTreeBroadphase({super.items});

  final tree = _QuadTree<T>();
  final List<T> _active = [];
  final _skipPair = <T, HashSet<T>>{};

  @override
  HashSet<CollisionProspect<T>> query() {
    final sw = Stopwatch()..start();
    final potentials = HashSet<CollisionProspect<T>>();
    _skipPair.clear();

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

        if (_skipPair[potential]?.contains(item) != null) {
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
          if (success) {
            if (asShapePotential is CollisionQuadTreeController) {
              final success = (asShapePotential as CollisionQuadTreeController)
                  .broadPhaseCheck(asShapeItem);
              if (!success) {
                _skip(potential, item);
                continue;
              }
            }
          } else {
            _skip(potential, item);
            continue;
          }
        } else if (asShapeItem.parent is CollisionQuadTreeController) {
          final success = (asShapeItem.parent as CollisionQuadTreeController)
              .broadPhaseCheck(asShapePotential.parent as PositionComponent);
          if (success) {
            if (asShapePotential.parent is CollisionQuadTreeController) {
              final success =
                  (asShapePotential.parent as CollisionQuadTreeController)
                      .broadPhaseCheck(asShapeItem.parent as PositionComponent);
              if (!success) {
                _skip(potential, item);
                continue;
              }
            }
          } else {
            _skip(potential, item);
            continue;
          }
        }

        final itemCenter = item.aabb.center;
        final potentialCenter = potential.aabb.center;
        if ((itemCenter.x - potentialCenter.x).abs() > 25 ||
            (itemCenter.y - potentialCenter.y).abs() > 25) {
          continue;
        }

        potentials.add(CollisionProspect<T>(item, potential));
      }
      for (final i in markRemove) {
        tree.remove(i);
      }
    }

    print("S: ${sw.elapsedMicroseconds}  p: ${potentials.length} ");
    return potentials;
  }

  _skip(T item, T potential) {
    if (_skipPair[item] == null) {
      _skipPair[item] = HashSet<T>();
    }
    _skipPair[item]?.add(potential);
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
