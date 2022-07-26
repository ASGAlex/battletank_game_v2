import 'package:flame/collisions.dart';
import 'package:flame/extensions.dart';
import 'package:flame_tiled/flame_tiled.dart';
import 'package:tank_game/services/collision_optimized/broadphase.dart';

class OptimizedCollisionDetection extends StandardCollisionDetection {
  OptimizedCollisionDetection({super.broadphase});

  factory OptimizedCollisionDetection.fromMap(RenderableTiledMap map) {
    final broadphase = QuadTreeBroadphase<ShapeHitbox>();

    broadphase.tree.mainBoxSize = Rect.fromLTWH(
        0,
        0,
        (map.map.width * map.map.tileWidth).toDouble(),
        (map.map.height * map.map.tileHeight).toDouble());
    final cd = OptimizedCollisionDetection(broadphase: broadphase);
    return cd;
  }

  QuadTreeBroadphase get quadBf => broadphase as QuadTreeBroadphase;

  @override
  void add(ShapeHitbox item) {
    super.add(item);
    quadBf.tree.add(item);
  }

  @override
  void addAll(Iterable<ShapeHitbox> items) {
    for (final item in items) {
      add(item);
    }
  }

  @override
  void remove(ShapeHitbox item) {
    quadBf.tree.remove(item);
    super.remove(item);
  }

  @override
  void removeAll(Iterable<ShapeHitbox> items) {
    quadBf.tree.clear();
    super.removeAll(items);
  }

  List<BoxesDbgInfo> get collisionQuadBoxes =>
      _getBoxes(quadBf.tree.rootNode, quadBf.tree.mainBoxSize);

  List<BoxesDbgInfo> _getBoxes(Node node, Rect rootBox) {
    final boxes = <BoxesDbgInfo>[];
    final hitboxes = node.values;
    boxes.add(
        BoxesDbgInfo(rootBox, hitboxes as List<ShapeHitbox>, hitboxes.length));
    if (node.children[0] != null) {
      for (var i = 0; i < node.children.length; i++) {
        boxes.addAll(_getBoxes(node.children[i] as Node<ShapeHitbox>,
            quadBf.tree.computeBox(rootBox, i)));
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
