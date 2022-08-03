part of tank;

class _HitboxMapBounds extends RectangleHitbox with MyGameRef {
  _HitboxMapBounds({super.angle, super.anchor, super.priority, super.position});

  bool _outOfBounds = false;
  num mapWidth = 0.0;
  num mapHeight = 0.0;

  @override
  onLoad() {
    mapWidth = (game.currentMap?.map.width ?? 0) *
        (game.currentMap?.map.tileWidth ?? 0);

    mapHeight = (game.currentMap?.map.height ?? 0) *
        (game.currentMap?.map.tileHeight ?? 0);
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
