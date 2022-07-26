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
