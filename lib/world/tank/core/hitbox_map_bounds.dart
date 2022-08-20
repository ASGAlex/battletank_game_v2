import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:tank_game/game.dart';

class HitboxMapBounds extends RectangleHitbox with HasGameRef<MyGame> {
  HitboxMapBounds({super.angle, super.anchor, super.priority, super.position});

  bool _outOfBounds = false;

  bool get outOfBounds => _outOfBounds;

  num mapWidth = 0.0;
  num mapHeight = 0.0;

  @override
  onLoad() {
    mapWidth = (gameRef.currentMap?.map.width ?? 0) *
        (gameRef.currentMap?.map.tileWidth ?? 0);

    mapHeight = (gameRef.currentMap?.map.height ?? 0) *
        (gameRef.currentMap?.map.tileHeight ?? 0);
    return null;
  }

  @override
  update(dt) {
    bool tmp = false;
    if (aabb.min.x < 0 || aabb.max.x > mapWidth) {
      tmp = true;
    }
    if (aabb.min.y < 0 || aabb.max.y > mapHeight) {
      tmp = true;
    }
    _outOfBounds = tmp;

    super.update(dt);
  }
}
