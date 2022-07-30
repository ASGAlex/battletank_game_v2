part of tank;

class _AvailableDirectionsChecker {
  bool _sideHitboxesEnabled = true;

  bool get hitboxesEnabled => _sideHitboxesEnabled;
  late final Tank parent;

  onLoad(Tank parent) {
    this.parent = parent;
    parent.addAll(_movementSideHitboxes);
  }

  final _movementSideHitboxes = <_MovementSideHitbox>[
    _MovementSideHitbox(direction: Direction.left),
    _MovementSideHitbox(direction: Direction.right),
    _MovementSideHitbox(direction: Direction.down)
  ];

  List<Direction> getAvailableDirections() {
    final availableDirections = <Direction>[];
    for (final hitbox in _movementSideHitboxes) {
      if (hitbox.canMoveToDirection) {
        availableDirections.add(hitbox.globalMapDirection);
      }
    }
    if (parent.canMoveForward) {
      availableDirections.add(parent.lookDirection);
    }
    return availableDirections;
  }

  enableSideHitboxes([bool enable = true]) {
    for (var hb in _movementSideHitboxes) {
      if (enable) {
        parent.changeCollisionType(hb, CollisionType.active);
      } else {
        parent.changeCollisionType(hb, CollisionType.inactive);
      }
    }
    _sideHitboxesEnabled = enable;
  }

  disableSideHitboxes() {
    enableSideHitboxes(false);
  }
}
