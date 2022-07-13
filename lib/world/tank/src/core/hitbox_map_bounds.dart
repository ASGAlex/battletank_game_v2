part of tank;

mixin _HitboxMapBounds on RectangleHitbox {
  bool _outOfBounds = false;

  @override
  update(dt) {
    final game = findParent<MyGame>();
    final width = (game?.currentMap?.map.width ?? 0) *
        (game?.currentMap?.map.tileWidth ?? 0);
    final height = (game?.currentMap?.map.height ?? 0) *
        (game?.currentMap?.map.tileHeight ?? 0);

    final posParent = parent as PositionComponent;
    final globalPos = posParent.transform.localToGlobal(position);
    final globalPosSize = posParent.transform
        .localToGlobal(Vector2(position.x + size.x, position.y + size.y));
    final hbRect =
        Rect.fromPoints(globalPos.toOffset(), globalPosSize.toOffset())
            .toMathRectangle();

    final mapRect = Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble())
        .toMathRectangle();

    if (mapRect.containsRectangle(hbRect)) {
      _outOfBounds = false;
    } else {
      _outOfBounds = true;
    }
    super.update(dt);
  }
}
