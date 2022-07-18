import 'package:flame/collisions.dart';
import 'package:flame/extensions.dart';
import 'package:flame_tiled/flame_tiled.dart';
import 'package:tank_game/services/collision_optimized/broadphase.dart';

class OptimizedCollisionDetection extends StandardCollisionDetection {
  OptimizedCollisionDetection({super.broadphase});

  factory OptimizedCollisionDetection.fromMap(RenderableTiledMap map) {
    final broadphase = QuadTreeBroadphase<ShapeHitbox>();
    broadphase.tree.bounds = Rect.fromLTWH(
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
    final index = items.indexOf(item);
    quadBf.tree.add(item, index);
  }

  @override
  void addAll(Iterable<ShapeHitbox> items) {
    for (final item in items) {
      add(item);
    }
  }

  @override
  void remove(ShapeHitbox item) {
    final index = quadBf.items.indexOf(item);
    quadBf.tree.remove(index);
    super.remove(item);
  }

  @override
  void removeAll(Iterable<ShapeHitbox> items) {
    quadBf.tree.clear();
    super.removeAll(items);
  }

  List<BoxesDbgInfo> get collisionQuadBoxes => _getBoxes(quadBf.tree);

  List<BoxesDbgInfo> _getBoxes(QuadTree tree) {
    final boxes = <BoxesDbgInfo>[];
    boxes.add(BoxesDbgInfo(
        tree.bounds, tree.hitboxes as List<ShapeHitbox>, tree.count));
    if (tree.children.isNotEmpty) {
      for (final child in tree.children) {
        boxes.addAll(_getBoxes(child));
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
