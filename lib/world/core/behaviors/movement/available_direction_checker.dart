import 'dart:async';
import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame_spatial_grid/flame_spatial_grid.dart';
import 'package:tank_game/world/core/actor.dart';
import 'package:tank_game/world/core/behaviors/attacks/bullet.dart';
import 'package:tank_game/world/core/behaviors/core_behavior.dart';
import 'package:tank_game/world/core/behaviors/movement/movement_forward_collision.dart';
import 'package:tank_game/world/core/direction.dart';
import 'package:tank_game/world/environment/spawn/spawn_entity.dart';
import 'package:tank_game/world/environment/tree/tree.dart';

class AvailableDirectionChecker extends CoreBehavior<ActorMixin> {
  bool _sideHitboxesEnabled = true;

  bool get hitboxesEnabled => _sideHitboxesEnabled;
  late final MovementHitbox movementHitbox;

  @override
  FutureOr onLoad() {
    final moveForwardBehavior =
        parent.findBehavior<MovementForwardCollisionBehavior>();
    movementHitbox = moveForwardBehavior.movementHitbox;
    parent.addAll(_movementSideHitboxes);
  }

  @override
  void onRemove() {
    disableSideHitboxes();
    try {
      parent.removeAll(_movementSideHitboxes);
    } catch (_) {}
  }

  final _movementSideHitboxes = <MovementSideHitbox>[
    MovementSideHitbox(direction: Direction.left),
    MovementSideHitbox(direction: Direction.right),
    MovementSideHitbox(direction: Direction.down)
  ];

  List<Direction> getAvailableDirections() {
    final availableDirections = <Direction>[];
    for (final hitbox in _movementSideHitboxes) {
      if (hitbox.isMovementAllowed) {
        availableDirections.add(hitbox.globalMapDirection);
      }
    }
    if (movementHitbox.isMovementAllowed) {
      availableDirections.add(parent.data.lookDirection);
    }
    return availableDirections;
  }

  enableSideHitboxes([bool enable = true]) {
    for (var hb in _movementSideHitboxes) {
      if (enable) {
        hb.collisionType = CollisionType.active;
      } else {
        hb.collisionType = CollisionType.inactive;
      }
    }
    _sideHitboxesEnabled = enable;
  }

  disableSideHitboxes() {
    enableSideHitboxes(false);
  }
}

class MovementSideHitbox extends BoundingHitbox {
  MovementSideHitbox({required this.direction})
      : super(position: Vector2(0, 0)) {
    anchor = Anchor.topLeft;
  }

  final Direction direction;

  bool get isMovementBlocked => activeCollisions.isNotEmpty;

  bool get isMovementAllowed => activeCollisions.isEmpty;

  Direction get globalMapDirection {
    var globalValue =
        direction.value + (parent as ActorMixin).data.lookDirection.value;
    if (globalValue > 3) {
      return Direction.fromValue(globalValue - 4);
    }
    return Direction.fromValue(globalValue);
  }

  @override
  Future? onLoad() {
    assert(parent is ActorMixin);
    final parentSize = (parent as ActorMixin).size;
    final width = parentSize.x / 2;
    switch (direction) {
      case Direction.left:
        position = Vector2(-width, 0);
        size = Vector2(width, parentSize.y);
        break;
      case Direction.right:
        position = Vector2(parentSize.x, 0);
        size = Vector2(width, parentSize.y);
        break;
      case Direction.up:
        position = Vector2(2, -width);
        size = Vector2(parentSize.x - 3, width);
        break;
      case Direction.down:
        position = Vector2(0, parentSize.y);
        size = Vector2(parentSize.x, width);
        break;
    }
    super.onLoad();
    // debugMode = true;
    return null;
  }

  @override
  bool pureTypeCheck(Type other) {
    if (other == MovementHitbox || other == MovementSideHitbox) {
      return false;
    }
    return true;
  }

  @override
  bool onComponentTypeCheck(PositionComponent other) {
    if (other.parent is SpawnEntity ||
        other.parent is BulletEntity ||
        other.parent is TreeEntity) {
      return false;
    }
    return true;
  }

  @override
  void renderDebugMode(Canvas canvas) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.x, size.y),
      Paint()
        ..color = const Color.fromRGBO(188, 174, 238, 1.0)
        ..style = PaintingStyle.fill,
    );
  }
}
