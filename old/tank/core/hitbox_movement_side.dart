import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'package:flame_spatial_grid/flame_spatial_grid.dart';
import 'package:tank_game/world/environment/tree.dart';
import 'package:tank_game/world/tank/bullet.dart';

import '../../core/direction.dart';
import '../../environment/spawn.dart';
import 'base_tank.dart';
import 'hitbox_movement.dart';

class MovementSideHitbox extends BoundingHitbox {
  MovementSideHitbox({required this.direction})
      : super(position: Vector2(0, 0));

  Tank get tank => parent as Tank;

  final Direction direction;

  bool get isMovementBlocked => activeCollisions.isNotEmpty;

  bool get isMovementAllowed => activeCollisions.isEmpty;

  Direction get globalMapDirection {
    var globalValue = direction.value + tank.lookDirection.value;
    if (globalValue > 3) {
      return Direction.fromValue(globalValue - 4);
    }
    return Direction.fromValue(globalValue);
  }

  @override
  Future? onLoad() {
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
