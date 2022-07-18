part of 'broadphase.dart';

class _QuadTree<T extends Hitbox<T>> {
  static const maxObjects = 20;
  static const maxLevels = 500;
  static const _exceptionMessage = 'Bounds not set';

  static final _cachedHitboxesTrees = <int, _QuadTree>{};

  _QuadTree();

  int _level = 0;
  final _hitboxes = <int, T>{};
  final _children = <_QuadTree<T>>[];

  var bounds = Rect.zero;

  _QuadTree.subtree(this._level, this.bounds);

  clear() {
    _hitboxes.clear();
    for (final node in _children) {
      node.clear();
    }
    _children.clear();
    _cachedHitboxesTrees.clear();
  }

  void split() {
    if (bounds == Rect.zero) throw _exceptionMessage;

    var subWidth = bounds.width / 2;
    var subHeight = bounds.height / 2;
    var x = bounds.left;
    var y = bounds.top;

    _children.add(_QuadTree<T>.subtree(
        _level + 1, Rect.fromLTWH(x + subWidth, y, subWidth, subHeight)));
    _children.add(_QuadTree<T>.subtree(
        _level + 1, Rect.fromLTWH(x, y, subWidth, subHeight)));
    _children.add(_QuadTree<T>.subtree(
        _level + 1, Rect.fromLTWH(x, y + subHeight, subWidth, subHeight)));
    _children.add(_QuadTree<T>.subtree(_level + 1,
        Rect.fromLTWH(x + subWidth, y + subHeight, subWidth, subHeight)));
  }

  /*
 * Determine which node the object belongs to. -1 means
 * object cannot completely fit within a child node and is part
 * of the parent node
 */
  int _calculateIndex(T hitbox) {
    if (bounds == Rect.zero) throw _exceptionMessage;

    var index = -1;
    var verticalMidpoint = bounds.left + (bounds.width / 2);
    var horizontalMidpoint = bounds.top + (bounds.height / 2);

    // Object can completely fit within the top quadrants
    final globalPosition = hitbox.aabb;
    final height = globalPosition.max.y - globalPosition.min.y;
    final width = globalPosition.max.x - globalPosition.min.x;
    final topQuadrant = (globalPosition.min.x < horizontalMidpoint &&
        globalPosition.min.y + height < horizontalMidpoint);
    // Object can completely fit within the bottom quadrants
    final bottomQuadrant = (globalPosition.min.y > horizontalMidpoint);

    // Object can completely fit within the left quadrants
    if (globalPosition.min.x < verticalMidpoint &&
        globalPosition.min.x + width < verticalMidpoint) {
      if (topQuadrant) {
        index = 1;
      } else if (bottomQuadrant) {
        index = 2;
      }
    }
    // Object can completely fit within the right quadrants
    else if (globalPosition.min.x > verticalMidpoint) {
      if (topQuadrant) {
        index = 0;
      } else if (bottomQuadrant) {
        index = 3;
      }
    }

    return index;
  }

  /*
  * Insert the object into the quadtree. If the node
  * exceeds the capacity, it will split and add all
  * objects to their corresponding nodes.
  */
  add(T hitbox, int globalIndex) {
    if (bounds == Rect.zero) throw _exceptionMessage;

    if (_children.isNotEmpty) {
      final index = _calculateIndex(hitbox);

      if (index != -1) {
        final tree = _children[index];
        tree.add(hitbox, globalIndex);
        return;
      }
    }

    _hitboxes[globalIndex] = hitbox;
    _cachedHitboxesTrees[globalIndex] = this;

    if (_hitboxes.length > maxObjects && _level < maxLevels) {
      if (_children.isEmpty) {
        split();
      }

      final toRemove = <int>[];
      for (final entry in _hitboxes.entries) {
        int index = _calculateIndex(entry.value);
        if (index != -1) {
          toRemove.add(entry.key);
          final tree = _children[index];
          tree._hitboxes[entry.key] = entry.value;
          _cachedHitboxesTrees[entry.key] = tree;
        }
      }
      _hitboxes.removeWhere((key, value) => toRemove.contains(key));
    }
  }

  remove(int globalIndex) {
    if (bounds == Rect.zero) throw _exceptionMessage;

    final tree = _cachedHitboxesTrees[globalIndex];
    if (tree != null) {
      tree._hitboxes.remove(globalIndex);
    }
  }

  /*
 * Return all objects that could collide with the given hitbox
 */
  Iterable<T> retrieve(int globalIndex) {
    if (bounds == Rect.zero) throw _exceptionMessage;

    final tree = _cachedHitboxesTrees[globalIndex];
    if (tree != null) {
      return tree._hitboxes.values as Iterable<T>;
    }
    return [];
  }
}
