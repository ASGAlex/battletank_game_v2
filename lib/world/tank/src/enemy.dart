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

  bool _shouldFireAfterReload = false;

  final _directionsChecker = _AvailableDirectionsChecker();
  _RandomMovementController? _randomMovementController;

  @override
  Future<void> onLoad() async {
    animationRun = await SpriteSheetRegistry().tankBasic.animationRun;
    animationIdle = await SpriteSheetRegistry().tankBasic.animationIdle;
    _directionsChecker.onLoad(this);
    _randomMovementController = _RandomMovementController(
        directionsChecker: _directionsChecker, parent: this);

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
      _randomMovementController?.runRandomMovement(dt);

      switch (_movementMode) {
        case _MovementMode.random:
        case _MovementMode.randomWithFire:
          // _moveRandom(dt);
          break;
        case _MovementMode.toPlayerBlind:
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

  bool isCollisionLandscapeChanged(
          List<Direction> currentAvailableDirections) =>
      _lastAvailableDirections.length < currentAvailableDirections.length;

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
