part of collision_quad_tree;

class _QuadTreeCollisionDetection extends StandardCollisionDetection {
  _QuadTreeCollisionDetection(Rect mapDimensions)
      : super(broadphase: _QuadTreeBroadphase<ShapeHitbox>()) {
    (broadphase as _QuadTreeBroadphase).tree.mainBoxSize = mapDimensions;
  }

  _QuadTreeBroadphase get quadBroadphase => broadphase as _QuadTreeBroadphase;

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

  List<BoxesDbgInfo> get collisionQuadBoxes =>
      _getBoxes(quadBroadphase.tree.rootNode, quadBroadphase.tree.mainBoxSize);

  List<BoxesDbgInfo> _getBoxes(_Node node, Rect rootBox) {
    final boxes = <BoxesDbgInfo>[];
    final hitboxes = node.values;
    boxes.add(
        BoxesDbgInfo(rootBox, hitboxes as List<ShapeHitbox>, hitboxes.length));
    if (node.children[0] != null) {
      for (var i = 0; i < node.children.length; i++) {
        boxes.addAll(_getBoxes(node.children[i] as _Node<ShapeHitbox>,
            quadBroadphase.tree.computeBox(rootBox, i)));
      }
    }
    return boxes;
  }
}

class BoxesDbgInfo {
  BoxesDbgInfo(this.rect, this.hitboxes, this.count);

  Rect rect;
  List<ShapeHitbox> hitboxes;
  int count;
}
