part of tank;

class _MovementHitbox extends RectangleHitbox
    with DebugRender, _HitboxMapBounds
    implements HitboxNoInteraction {
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
    position = Vector2(1, -2);
    size = Vector2(tank.size.x - 3, 2);
    priority = 100;
  }

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, ShapeHitbox other) {
    try {
      if (other.parent is! Spawn && other is! HitboxNoInteraction) {
        _otherCollisions++;
        if (!_outOfBounds) {
          tank.canMoveForward = false;
        }
      }
    } catch (e) {
      print(e);
    }
    super.onCollisionStart(intersectionPoints, other);
  }

  @override
  void onCollisionEnd(ShapeHitbox other) {
    try {
      if (other.parent is! Spawn && other is! HitboxNoInteraction) {
        _otherCollisions--;
        if (_otherCollisions == 0 && !_outOfBounds) {
          tank.canMoveForward = true;
        }
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
