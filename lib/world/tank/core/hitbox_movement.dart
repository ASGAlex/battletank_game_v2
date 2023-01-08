import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'package:flame_spatial_grid/flame_spatial_grid.dart';
import 'package:tank_game/world/environment/tree.dart';

import '../../environment/spawn.dart';
import '../bullet.dart';
import 'hitbox_movement_side.dart';

class MovementHitbox extends BoundingHitbox {
  MovementHitbox() : super(position: Vector2(1, -2), size: Vector2(12, 2)) {
    collisionType = CollisionType.active;
  }

  bool get isMovementBlocked => activeCollisions.isNotEmpty;

  bool get isMovementAllowed => activeCollisions.isEmpty;

  @override
  bool onComponentTypeCheck(PositionComponent other) {
    if (other is MovementHitbox ||
        other is MovementSideHitbox ||
        other.parent is Spawn ||
        other.parent is Bullet ||
        other.parent is Tree) {
      return false;
    }
    return super.onComponentTypeCheck(other);
  }
}
