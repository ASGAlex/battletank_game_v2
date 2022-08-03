part of tank;

class _MovementSideHitbox extends _HitboxMapBounds
    with DebugRender, CollisionQuadTreeController<MyGame> {
  _MovementSideHitbox(
      {required this.direction, super.angle, super.anchor, super.priority})
      : super(position: Vector2(0, 0));

  Tank get tank => parent as Tank;

  final Direction direction;

  int _collisions = 0;

  bool get canMoveToDirection => !_outOfBounds && _collisions == 0;

  Direction get globalMapDirection {
    var globalValue = direction.value + tank.lookDirection.value;
    if (globalValue > 3) {
      return Direction.fromValue(globalValue - 4);
    }
    return Direction.fromValue(globalValue);
  }

  @override
  Future? onLoad() {
    // debug = true;

    switch (direction) {
      case Direction.left:
        position = Vector2(-8, 2);
        size = Vector2(8, tank.size.y - 3);
        break;
      case Direction.right:
        position = Vector2(tank.size.x, 2);
        size = Vector2(8, tank.size.y - 3);
        break;
      case Direction.up:
        position = Vector2(2, -8);
        size = Vector2(tank.size.x - 3, 8);
        break;
      case Direction.down:
        position = Vector2(2, tank.size.y);
        size = Vector2(tank.size.x - 3, 8);
        break;
    }
    super.onLoad();

    return null;
  }

  @override
  bool broadPhaseCheck(PositionComponent other) {
    final success = super.broadPhaseCheck(other);
    if (success && (other.parent is Spawn || other is _MovementHitbox)) {
      return false;
    }
    return success;
  }

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, ShapeHitbox other) {
    _collisions++;

    super.onCollisionStart(intersectionPoints, other);
  }

  @override
  void onCollisionEnd(ShapeHitbox other) {
    _collisions--;

    super.onCollisionEnd(other);
  }
}
