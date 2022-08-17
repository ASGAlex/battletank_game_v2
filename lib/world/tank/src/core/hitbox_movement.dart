import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'package:tank_game/game.dart';
import 'package:tank_game/packages/collision_quad_tree/lib/collision_quad_tree.dart';
import 'package:tank_game/world/environment/spawn.dart';

import '../bullet.dart';
import 'base_tank.dart';
import 'hitbox_map_bounds.dart';
import 'hitbox_movement_side.dart';

class MovementHitbox extends HitboxMapBounds
    with CollisionQuadTreeController<MyGame> {
  MovementHitbox({super.angle, super.anchor, super.priority})
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
    if (other is MovementSideHitbox ||
        other is MovementHitbox ||
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
      if (!outOfBounds) {
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
      if (_otherCollisions == 0 && !outOfBounds) {
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
      tank.canMoveForward = !outOfBounds;
    }

    if (!outOfBounds && _otherCollisions == 0) {
      tank.canMoveForward = true;
    }
  }
}
