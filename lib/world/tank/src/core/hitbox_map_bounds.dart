part of tank;

class _HitboxMapBounds extends RectangleHitbox with MyGameRef {
  _HitboxMapBounds({super.angle, super.anchor, super.priority, super.position});

  bool _outOfBounds = false;
  num mapWidth = 0.0;
  num mapHeight = 0.0;

  onLoad() {
    mapWidth = (game.currentMap?.map.width ?? 0) *
        (game.currentMap?.map.tileWidth ?? 0);

    mapHeight = (game.currentMap?.map.height ?? 0) *
        (game.currentMap?.map.tileHeight ?? 0);
  }

  @override
  update(dt) {
    final hbRect = Rect.fromLTRB(aabb.min.x, aabb.min.y, aabb.max.x, aabb.max.y)
        .toMathRectangle();

    final mapRect =
        Rect.fromLTWH(0, 0, mapWidth.toDouble(), mapHeight.toDouble())
            .toMathRectangle();

    if (mapRect.containsRectangle(hbRect)) {
      _outOfBounds = false;
    } else {
      _outOfBounds = true;
    }
    super.update(dt);
  }
}
