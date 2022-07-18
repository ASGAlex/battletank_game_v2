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
      if ((_hearPlayer() || _seePlayer()) &&
          _movementMode != _MovementMode.target) {
        _movementMode = _MovementMode.toPlayerBlind;
      } else {
        _movementMode = _MovementMode.random;
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
    final player = game?.player;
    if (player == null || player.current == MovementState.idle || player.dead) {
      return false;
    }
    final distance = player.position.distanceTo(position);
    return distance < distanceOfSilence;
  }

  bool _seePlayer() {
    final game = findParent<MyGame>();
    final player = game?.player;
    if (player == null || player.isHiddenFromEnemy || player.dead) {
      return false;
    }
    final distance = player.position.distanceTo(position);
    return distance < distanceOfView;
  }

  bool _moveRandom(double dt,
      {Direction? preferred, int min = 10, int max = 25}) {
    var directionChanged = false;
    final innerSpeed = speed * dt;
    _directionDistance -= innerSpeed;

    final availableDirections = _getAvailableDirections();
    final enoughDistanceRunned = ((_initialDirectionDistance -
                (_directionDistance < 0 ? 0 : _directionDistance))) /
            _initialDirectionDistance >=
        0.3;
    if (isCollisionLandscapeChanged(availableDirections) &&
        enoughDistanceRunned) {
      final random = Random();
      final changeDirection = random.nextBool();
      if (changeDirection) {
        if (preferred != null && availableDirections.contains(preferred)) {
          lookDirection = preferred;
          angle = preferred.angle;
        } else {
          _setRandomDirection(availableDirections, min: min, max: max);
        }
        directionChanged = true;
      }
    } else if (_directionDistance <= 0) {
      if (preferred != null && availableDirections.contains(preferred)) {
        lookDirection = preferred;
        angle = preferred.angle;
      } else {
        _setRandomDirection(availableDirections, min: min, max: max);
      }
      directionChanged = true;
    } else if (!canMoveForward) {
      if (preferred != null && availableDirections.contains(preferred)) {
        lookDirection = preferred;
        angle = preferred.angle;
      } else {
        _setRandomDirection(availableDirections, min: min, max: max);
      }
      directionChanged = true;
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

  bool _temporaryRandom = false;
  bool _inverseDirection = false;

  void _moveToPlayer(double dt) {
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
    Direction? secondaryDirection;
    Direction? directionHorizontal;
    Direction? directionVertical;
    bool attack = false;
    double attackDistance = 0;

    if (xDiff > 7) {
      directionHorizontal = Direction.left;
    } else if (xDiff < -7) {
      directionHorizontal = Direction.right;
    }

    if (yDiff > 7) {
      directionVertical = Direction.up;
    } else if (yDiff < -7) {
      directionVertical = Direction.down;
    }

    if (directionHorizontal != null && directionVertical != null) {
      preferredDirection =
          (xDiff.abs() < yDiff.abs() ? directionHorizontal : directionVertical);
      secondaryDirection =
          (xDiff.abs() < yDiff.abs() ? directionVertical : directionHorizontal);
    } else if (directionHorizontal == null) {
      _inverseDirection = false;
      preferredDirection = directionVertical;
      secondaryDirection = directionHorizontal;
      attack = true;
      attackDistance = yDiff.abs();
    } else if (directionVertical == null) {
      _inverseDirection = false;
      preferredDirection = directionHorizontal;
      secondaryDirection = directionVertical;
      attack = true;
      attackDistance = xDiff.abs();
    }

    if (attack && !_seePlayer()) {
      attack = false;
    }

    if (_inverseDirection) {
      final _tmp = secondaryDirection;
      secondaryDirection = preferredDirection;
      preferredDirection = _tmp;
    }

    if (preferredDirection == null) {
      current = MovementState.idle;
      return;
    }

    if (_temporaryRandom) {
      print(secondaryDirection);
      _temporaryRandom = !_moveRandom(dt, preferred: secondaryDirection);
      if (_temporaryRandom) return;
      if (secondaryDirection != null) {
        preferredDirection = secondaryDirection;
      }
      _inverseDirection = true;
      print('end random: $lookDirection, $preferredDirection');
    }

    final availableDirections = _getAvailableDirections();
    if (canMoveForward) {
      availableDirections.add(lookDirection);
    }

    if (availableDirections.contains(preferredDirection)) {
      _directionDistance = 0;
      lookDirection = preferredDirection;
      angle = preferredDirection.angle;
      if (_inverseDirection) {
        print('start random after stop');
        print(availableDirections);
        print(preferredDirection);
        print(secondaryDirection);
        print(lookDirection);
        print('===');
      }
      if (attack && attackDistance < 100) {
        current = MovementState.idle;
      } else {
        current = MovementState.run;
      }
    } else {
      _temporaryRandom = true;
      _moveRandom(dt, min: 2, max: 5);
    }

    if (attack) {
      _shouldFireAfterReload = !onFire();
    }
  }

  void _setRandomDirection(List<Direction> availableDirections,
      {int min = 10, int max = 25}) {
    _lastAvailableDirections = availableDirections;
    if (availableDirections.isEmpty) return;

    final random = Random();
    final i = random.nextInt(availableDirections.length);
    lookDirection = availableDirections[i];
    angle = lookDirection.angle;
    _initialDirectionDistance = _directionDistance =
        random.nextInt((size.x * max).toInt()) + size.x * min;
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
