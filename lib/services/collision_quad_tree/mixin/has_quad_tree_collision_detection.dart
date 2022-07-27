part of collision_quad_tree;

mixin HasQuadTreeCollisionDetection on FlameGame
    implements HasCollisionDetection {
  CollisionDetection<Hitbox>? _collisionDetection;

  @override
  CollisionDetection<Hitbox> get collisionDetection => _collisionDetection!;

  final _scheduledUpdate = <ShapeHitbox>{};

  @override
  set collisionDetection(CollisionDetection<Hitbox> cd) {
    if (cd is! _QuadTreeCollisionDetection) {
      throw 'Must be _QuadTreeCollisionDetection!';
    }
    _collisionDetection = cd;
  }

  initCollisionDetection(Rect mapDimensions) {
    _collisionDetection = _QuadTreeCollisionDetection(mapDimensions);
    (collisionDetection as _QuadTreeCollisionDetection)
        .quadBroadphase
        .broadphaseCheck = broadPhaseCheck;
  }

  bool broadPhaseCheck(PositionComponent one, PositionComponent another) {
    bool checkParent = false;
    if (one is CollisionQuadTreeController) {
      if (!(one).broadPhaseCheck(another)) {
        return false;
      }
    } else {
      checkParent = true;
    }

    if (another is CollisionQuadTreeController) {
      if (!(another).broadPhaseCheck(one)) {
        return false;
      }
    } else {
      checkParent = true;
    }

    if (checkParent &&
        one.parent is CollisionQuadTreeController &&
        another.parent is CollisionQuadTreeController) {
      return broadPhaseCheck(
          one.parent as PositionComponent, another.parent as PositionComponent);
    }
    return true;
  }

  scheduleHitboxUpdate(ShapeHitbox hitbox) {
    _scheduledUpdate.add(hitbox);
  }

  @override
  void update(double dt) {
    super.update(dt);
    for (final hb in _scheduledUpdate) {
      (collisionDetection as _QuadTreeCollisionDetection)
          .quadBroadphase
          .updateItemSizeOrPosition(hb);
    }
    _scheduledUpdate.clear();
    collisionDetection.run();
  }
}
