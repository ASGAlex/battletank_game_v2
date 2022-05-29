part of tank;

enum _MovementMode { random, target }

class Enemy extends Tank {
  Enemy({super.position});

  @override
  int health = 1;

  var _movementMode = _MovementMode.random;

  var _lastAvailableDirections = <Direction>[];

  var _directionDistance = 0.0;

  bool _shouldFireAfterReload = false;

  final _movementSideHitboxes = <_MovementSideHitbox>[
    _MovementSideHitbox(direction: Direction.left),
    _MovementSideHitbox(direction: Direction.up),
    _MovementSideHitbox(direction: Direction.down)
  ];

  @override
  Future<void> onLoad() async {
    animationRun = await SpriteSheetRegistry().tankBasic.animationRun;
    animationIdle = await SpriteSheetRegistry().tankBasic.animationIdle;
    addAll(_movementSideHitboxes);

    await super.onLoad();

    _movementMode = _MovementMode.random;
    current = MovementState.run;
  }

  @override
  void update(double dt) {
    if (current != MovementState.die) {
      switch (_movementMode) {
        case _MovementMode.random:
          _moveRandom(dt);
          break;
        case _MovementMode.target:
          print('not implemented');
          break;
      }
    }
    super.update(dt);
  }

  void _moveRandom(double dt) {
    final availableDirections = <Direction>[];
    for (final hitbox in _movementSideHitboxes) {
      if (hitbox.canMoveToDirection) {
        availableDirections.add(hitbox.direction);
      }
    }

    final innerSpeed = speed * dt;
    _directionDistance -= innerSpeed;

    if (_lastAvailableDirections.length < availableDirections.length) {
      final random = Random();
      final changeDirection = random.nextBool();
      if (changeDirection) {
        _findNewDirection(availableDirections);
      }
    } else if (_directionDistance <= 0) {
      _findNewDirection(availableDirections);
    } else if (!canMoveForward) {
      _findNewDirection(availableDirections);
    }
    current = MovementState.run;
  }

  void _findNewDirection(List<Direction> availableDirections) {
    _lastAvailableDirections = availableDirections;
    if (availableDirections.isEmpty) return;
    final random = Random();
    final i = random.nextInt(availableDirections.length);
    var newDirection = availableDirections[i];
    if (lookDirection.value == 0) {
      lookDirection = newDirection;
    } else {
      for (var i = 0; i < lookDirection.value; i++) {
        newDirection = newDirection.rotateCCW();
      }
      lookDirection = newDirection;
    }
    _directionDistance = random.nextInt((size.x * 25).toInt()) + size.x * 10;
    angle = lookDirection.angle;
    _shouldFireAfterReload = !onFire();
  }

  @override
  onWeaponReloaded() {
    if (_shouldFireAfterReload) {
      _shouldFireAfterReload = !onFire();
    }
  }

  @override
  onDeath() {
    super.onDeath();
    findParent<MyGame>()?.spawnEnemy();
  }
}
