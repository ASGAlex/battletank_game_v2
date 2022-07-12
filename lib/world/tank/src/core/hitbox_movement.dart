part of tank;

class _MovementHitbox extends RectangleHitbox
    with DebugRender
    implements HitboxNoInteraction {
  _MovementHitbox({super.angle, super.anchor, super.priority})
      : super(position: Vector2(13, 1));

  Tank get tank {
    if (parent == null) throw 'no parent!';
    return parent as Tank;
  }

  int _lazyMovementHitboxId = -1;
  int get lazyId => _lazyMovementHitboxId;
  int _otherCollisions = 0;
  bool _collideWithWater = false;

  @override
  Future? onLoad() {
    // debug = true;
    position = Vector2(tank.size.x / 2, 1);
    size = Vector2(tank.size.x / 2 + 0.9, tank.size.y - 2);

    final game = findParent<MyGame>();

    game?.lazyCollisionService
        .addHitbox(
            position: absolutePosition,
            size: size,
            layer: 'water',
            type: CollisionType.active)
        .then((value) {
      _lazyMovementHitboxId = value;
    });
  }

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, ShapeHitbox other) {
    try {
      if (other.parent is! Spawn && other is! HitboxNoInteraction) {
        _otherCollisions++;
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
      if (other.parent is! Spawn && other is! HitboxNoInteraction) {
        _otherCollisions--;
        if (_otherCollisions == 0) {
          tank.canMoveForward = true;
        }
      }
    } catch (e) {
      print(e);
    }
    super.onCollisionEnd(other);
  }

  void onWaterCollisionStart() {
    tank.canMoveForward = false;
  }

  void onWaterCollisionEnd() {
    if (_otherCollisions == 0) tank.canMoveForward = true;
  }

  @override
  void update(double dt) {
    final game = findParent<MyGame>();

    final hbRelativePos = position.clone();
    final tankMatrix = tank.transformMatrix.clone();
    var rect = Rect.fromLTRB(hbRelativePos.x, hbRelativePos.y,
        hbRelativePos.x + size.x, hbRelativePos.y + size.y);
    rect = rect.transform(tankMatrix);

    game?.lazyCollisionService.updateHitbox(
        id: _lazyMovementHitboxId,
        position: rect.topLeft.toVector2(),
        size: rect.size.toVector2(),
        layer: 'water');

    super.update(dt);

    try {
      game?.lazyCollisionService
          .getCollisionsCount(_lazyMovementHitboxId, 'water')
          .then((value) {
        final isCollidingNew = (value > 1);
        if (!_collideWithWater && isCollidingNew) {
          _collideWithWater = isCollidingNew;
          onWaterCollisionStart();
        } else if (_collideWithWater && !isCollidingNew) {
          _collideWithWater = isCollidingNew;
          onWaterCollisionEnd();
        }
      });

      tank.collisionCheckedAfterAngleUpdate = true;
    } catch (e) {
      print(e);
    }
  }
}
