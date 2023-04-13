import 'package:flame/collisions.dart';

import '../../core/direction.dart';
import '../core/base_tank.dart';
import '../core/hitbox_movement_side.dart';

class AvailableDirectionsChecker {
  bool _sideHitboxesEnabled = true;

  bool get hitboxesEnabled => _sideHitboxesEnabled;
  late final Tank parent;

  onLoad(Tank parent) {
    this.parent = parent;
    parent.addAll(_movementSideHitboxes);
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
    if (parent.movementHitbox.isMovementAllowed) {
      availableDirections.add(parent.lookDirection);
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
