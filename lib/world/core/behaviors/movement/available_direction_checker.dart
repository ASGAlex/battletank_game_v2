import 'dart:async';
import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:tank_game/world/core/actor.dart';
import 'package:tank_game/world/core/behaviors/core_behavior.dart';
import 'package:tank_game/world/core/behaviors/movement/movement_forward_collision.dart';
import 'package:tank_game/world/core/direction.dart';

class AvailableDirectionChecker extends CoreBehavior<ActorMixin> {
  AvailableDirectionChecker({this.outerWidth = 0}) {
    _movementSideHitboxes = <MovementSideHitbox>[
      MovementSideHitbox(direction: Direction.left, outerWidth: outerWidth),
      MovementSideHitbox(direction: Direction.right, outerWidth: outerWidth),
      MovementSideHitbox(direction: Direction.down, outerWidth: outerWidth)
    ];
  }

  bool _sideHitboxesEnabled = true;
  final double outerWidth;

  bool get hitboxesEnabled => _sideHitboxesEnabled;
  late final MovementCheckerHitbox movementHitbox;

  @override
  FutureOr onLoad() {
    try {
      final moveForwardBehavior =
          parent.findBehavior<MovementForwardCollisionBehavior>();
      movementHitbox = moveForwardBehavior.movementHitbox;
    } catch (_) {
      movementHitbox = MovementSideHitbox(direction: Direction.up);
      parent.add(movementHitbox);
    }
    parent.addAll(_movementSideHitboxes);
  }

  @override
  void onRemove() {
    disableSideHitboxes();
    try {
      parent.removeAll(_movementSideHitboxes);
    } catch (_) {}
  }

  late final List<MovementSideHitbox> _movementSideHitboxes;

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

  Map<Direction, MovementCheckerHitbox> getAvailableDirectionsWithHitbox() {
    final availableDirections = <Direction, MovementCheckerHitbox>{};
    for (final hitbox in _movementSideHitboxes) {
      if (hitbox.isMovementAllowed) {
        availableDirections[hitbox.globalMapDirection] = hitbox;
      }
    }
    if (movementHitbox.isMovementAllowed) {
      availableDirections[parent.data.lookDirection] = movementHitbox;
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

class MovementSideHitbox extends MovementCheckerHitbox {
  MovementSideHitbox({required this.direction, this.outerWidth = 0})
      : super(position: Vector2(0, 0)) {
    anchor = Anchor.topLeft;
  }

  @override
  final Direction direction;
  final double outerWidth;

  @override
  Future? onLoad() {
    assert(parent is ActorMixin);
    final parentSize = (parent as ActorMixin).size;
    final width = outerWidth == 0 ? parentSize.x / 2 : outerWidth;
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
    defaultCollisionType = CollisionType.passive;
    collisionType = CollisionType.inactive;
    super.onLoad();
    return null;
  }

  @override
  bool pureTypeCheck(Type other) {
    if (other != BodyHitbox) {
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
