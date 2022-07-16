part of tank;

enum _MovementMode { random, randomWithFire, toPlayerBlind, target }

class Enemy extends Tank {
  Enemy({super.position});

  @override
  int health = 1;

  @override
  bool get trackTreeCollisions => false;

  var _movementMode = _MovementMode.random;

  var _lastAvailableDirections = <Direction>[];

  var _directionDistance = 0.0;
  var _initialDirectionDistance = 0.0;

  bool _shouldFireAfterReload = false;

  final _movementSideHitboxes = <_MovementSideHitbox>[
    _MovementSideHitbox(direction: Direction.left),
    _MovementSideHitbox(direction: Direction.right),
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
      if (_hearPlayer() && _movementMode != _MovementMode.target) {
        _movementMode = _MovementMode.toPlayerBlind;
      }
      switch (_movementMode) {
        case _MovementMode.random:
        case _MovementMode.randomWithFire:
          _moveRandom(dt);
          break;
        case _MovementMode.toPlayerBlind:
          _moveToPlayer(dt);
          break;
        case _MovementMode.target:
          print('not implemented');
          break;
      }
    }
    super.update(dt);
  }

  bool _hearPlayer() {
    final game = findParent<MyGame>();
    final distance =
        game?.player?.position.distanceTo(position) ?? distanceOfSilence + 1;
    return distance < distanceOfSilence;
  }

  bool _moveRandom(double dt) {
    var directionChanged = false;
    final innerSpeed = speed * dt;
    _directionDistance -= innerSpeed;

    final availableDirections = _getAvailableDirections();
    final enouthDistanceRunned = ((_initialDirectionDistance -
                (_directionDistance < 0 ? 0 : _directionDistance))) /
            _initialDirectionDistance >=
        0.4;
    if (isCollisionLandscapeChanged(availableDirections) &&
        enouthDistanceRunned) {
      final random = Random();
      final changeDirection = random.nextBool();
      if (changeDirection) {
        _setRandomDirection(availableDirections);
        directionChanged = true;
        print(
            'collision changed $_directionDistance of $_initialDirectionDistance');
      }
    } else if (_directionDistance <= 0) {
      _setRandomDirection(availableDirections);
      directionChanged = true;

      print('distance end');
    } else if (!canMoveForward) {
      _setRandomDirection(availableDirections);
      directionChanged = true;

      print('cant move forward');
    }
    current = MovementState.run;
    if (_movementMode == _MovementMode.randomWithFire) {
      _shouldFireAfterReload = !onFire();
    }
    return directionChanged;
  }

  List<Direction> _getAvailableDirections() {
    final availableDirections = <Direction>[];
    for (final hitbox in _movementSideHitboxes) {
      if (hitbox.canMoveToDirection) {
        availableDirections.add(hitbox.globalMapDirection);
      }
    }
    return availableDirections;
  }

  bool isCollisionLandscapeChanged(
          List<Direction> currentAvailableDirections) =>
      _lastAvailableDirections.length < currentAvailableDirections.length;

  Direction? _lastPreferredDirection;

  bool _temporaryRandom = false;

  void _moveToPlayer(double dt) {
    if (_temporaryRandom) {
      _temporaryRandom = !_moveRandom(dt);
      if (_temporaryRandom) return;
    }

    final game = findParent<MyGame>();
    final playerPosition = game?.player?.position;
    final isPlayerDead = game?.player?.dead ?? true;
    if (playerPosition == null || isPlayerDead) {
      _movementMode = _MovementMode.random;
      return;
    }

    final xDiff = position.x - playerPosition.x;
    final yDiff = position.y - playerPosition.y;
    Direction? preferredDirection;
    bool attack = false;
    double attackDistance = 0;
    if (xDiff.abs() < yDiff.abs()) {
      if (xDiff > 7) {
        preferredDirection = Direction.left;
      } else if (xDiff < -7) {
        preferredDirection = Direction.right;
      } else {
        preferredDirection = (yDiff > 0 ? Direction.up : Direction.down);
        attack = true;
        attackDistance = yDiff.abs();
      }
    } else {
      if (yDiff > 7) {
        preferredDirection = Direction.up;
      } else if (yDiff < -7) {
        preferredDirection = Direction.down;
      } else {
        preferredDirection = (xDiff > 0 ? Direction.left : Direction.right);
        attack = true;
        attackDistance = xDiff.abs();
      }
    }

    _lastPreferredDirection = preferredDirection;

    // print(preferredDirection);

    final availableDirections = _getAvailableDirections();
    if (canMoveForward) {
      availableDirections.add(lookDirection);
    }

    if (availableDirections.contains(preferredDirection)) {
      _directionDistance = 0;
      lookDirection = preferredDirection;
      angle = preferredDirection.angle;
      if (attack && attackDistance < 100) {
        current = MovementState.idle;
      } else {
        current = MovementState.run;
      }
    } else {
      _temporaryRandom = true;
      _moveRandom(dt);
    }

    if (attack) {
      _shouldFireAfterReload = !onFire();
    }
  }

  void _setRandomDirection(List<Direction> availableDirections) {
    _lastAvailableDirections = availableDirections;
    if (availableDirections.isEmpty) return;

    final random = Random();
    final i = random.nextInt(availableDirections.length);
    lookDirection = availableDirections[i];
    angle = lookDirection.angle;
    _initialDirectionDistance = _directionDistance =
        random.nextInt((size.x * 25).toInt()) + size.x * 10;
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
    final game = findParent<MyGame>();
    if (game != null) {
      game.enemies.remove(this);
      game.spawnEnemy();
    }
  }
}
