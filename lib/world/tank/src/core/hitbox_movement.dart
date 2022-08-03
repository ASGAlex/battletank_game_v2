part of tank;

class _MovementHitbox extends _HitboxMapBounds
    with DebugRender, CollisionQuadTreeController<MyGame> {
  _MovementHitbox({super.angle, super.anchor, super.priority})
      : super(position: Vector2(13, 1));

  Tank get tank {
    if (parent == null) throw 'no parent!';
    return parent as Tank;
  }

  int _otherCollisions = 0;

  @override
  Future? onLoad() {
    // debug = true;
    position = Vector2(1, -1);
    size = Vector2(tank.size.x - 2, 8);
    priority = 100;
    super.onLoad();
  }

  @override
  bool broadPhaseCheck(PositionComponent other) {
    final success = super.broadPhaseCheck(other);
    if (other is _MovementSideHitbox ||
        other is _MovementHitbox ||
        other.parent is Spawn ||
        other.parent is Bullet) {
      return false;
    }
    return success;
  }

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, ShapeHitbox other) {
    try {
      _otherCollisions++;
      if (!_outOfBounds) {
        tank.canMoveForward = false;
      }
    } catch (e) {
      print(e);
    }
    super.onCollisionStart(intersectionPoints, other);
  }

  @override
  void onCollisionEnd(ShapeHitbox other) {
    try {
      _otherCollisions--;
      if (_otherCollisions == 0 && !_outOfBounds) {
        tank.canMoveForward = true;
      }
    } catch (e) {
      print(e);
    }
    super.onCollisionEnd(other);
  }

  @override
  update(dt) {
    super.update(dt);
    if (tank.canMoveForward) {
      tank.canMoveForward = !_outOfBounds;
    }

    if (!_outOfBounds && _otherCollisions == 0) {
      tank.canMoveForward = true;
    }
  }
}
