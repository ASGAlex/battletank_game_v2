import 'package:flame/collisions.dart';
import 'package:flame/extensions.dart';
import 'package:flame/src/collisions/broadphase.dart';
import 'package:flame/src/collisions/collision_callbacks.dart';
import 'package:flame/src/collisions/hitboxes/hitbox.dart';

part 'quad_tree.dart';

class QuadTreeBroadphase<T extends Hitbox<T>> extends Broadphase<T> {
  QuadTreeBroadphase({super.items});

  final tree = _QuadTree<T>();
  final List<T> _active = [];

  final Set<CollisionProspect<T>> _potentials = {};

  @override
  Set<CollisionProspect<T>> query() {
    // final sw = Stopwatch()..start();
    _potentials.clear();

    for (var globalIndex = 0; globalIndex < items.length; globalIndex++) {
      final item = items[globalIndex];
      if (item.collisionType != CollisionType.active) {
        continue;
      }

      if ((item as ShapeHitbox).isRemoving ||
          (item as ShapeHitbox).parent == null) {
        tree.remove(globalIndex);
        continue;
      }
      _updateItemPosition(item, globalIndex);

      final potentiallyCollide = tree.retrieve(globalIndex);
      for (final potential in potentiallyCollide) {
        if (potential.collisionType == CollisionType.inactive) {
          continue;
        }

        _potentials.add(CollisionProspect<T>(item, potential));
      }
      //
      // if (activeOnly.length > 50) {
      //   _sweep(activeOnly);
      // }
    }

    // if (_potentials.length > 50) {}

    // print("${sw.elapsedMicroseconds}, p: ${_potentials.length} ");
    return _potentials;
  }

  _updateItemPosition(T item, int globalIndex) {
    tree.remove(globalIndex);
    tree.add(item, items.indexOf(item));
  }

  @override
  Set<CollisionProspect<T>> query22() {
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

    print(sw.elapsedMicroseconds);
    return _potentials;
  }
}
