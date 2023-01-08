import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame_spatial_grid/flame_spatial_grid.dart';

import 'hitbox_movement_side.dart';

class BodyHitbox extends BoundingHitbox {
  BodyHitbox({super.position, super.size}) {
    collisionType = CollisionType.active;
  }

  @override
  bool onComponentTypeCheck(PositionComponent other) {
    if (other is MovementSideHitbox) {
      return false;
    }
    return super.onComponentTypeCheck(other);
  }
}
