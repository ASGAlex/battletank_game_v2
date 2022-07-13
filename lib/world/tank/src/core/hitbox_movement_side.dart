part of tank;

abstract class HitboxNoInteraction extends RectangleHitbox {}

class _MovementSideHitbox extends RectangleHitbox
    with _HitboxMapBounds
    implements HitboxNoInteraction {
  _MovementSideHitbox(
      {required this.direction, super.angle, super.anchor, super.priority})
      : super(position: Vector2(0, 0));

  Tank get tank => parent as Tank;

  final Direction direction;

  int _collisions = 0;

  bool get canMoveToDirection => !_outOfBounds && _collisions == 0;

  @override
  Future? onLoad() {
    switch (direction) {
      case Direction.left:
        position = Vector2(-tank.size.x, 2);
        size = Vector2(tank.size.x, tank.size.y - 3);
        break;
      case Direction.right:
        position = Vector2(tank.size.x, 2);
        size = Vector2(tank.size.x, tank.size.y - 3);
        break;
      case Direction.up:
        position = Vector2(2, -tank.size.y);
        size = Vector2(tank.size.x - 3, tank.size.y);
        break;
      case Direction.down:
        position = Vector2(2, tank.size.y);
        size = Vector2(tank.size.x - 3, tank.size.y);
        break;
    }
    return null;
  }

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, ShapeHitbox other) {
    if (other.parent is! Spawn) {
      _collisions++;
    }
    super.onCollisionStart(intersectionPoints, other);
  }

  @override
  void onCollisionEnd(ShapeHitbox other) {
    if (other.parent is! Spawn) {
      _collisions--;
    }
    super.onCollisionEnd(other);
  }
}
