import 'package:flame/components.dart';
import 'package:tank_game/game.dart';
import 'package:tank_game/services/spritesheet/spritesheet.dart';
import 'package:tank_game/world/world.dart';

import 'behaviors/available_directions.dart';
import 'behaviors/fire.dart';
import 'behaviors/random_movement.dart';
import 'core/base_tank.dart';
import 'core/direction.dart';

enum _MovementMode { wait, random, attack }

class Enemy extends Tank {
  Enemy({super.position});

  @override
  int health = 1;

  @override
  bool get trackTreeCollisions => false;

  var _movementMode = _MovementMode.random;

  final _lastAvailableDirections = <Direction>[];

  final _directionsChecker = AvailableDirectionsChecker();
  RandomMovementController? _randomMovementController;
  FireController? _fireController;

  @override
  Future<void> onLoad() async {
    animationRun = await SpriteSheetRegistry().tankBasic.animationRun;
    animationIdle = await SpriteSheetRegistry().tankBasic.animationIdle;
    _directionsChecker.onLoad(this);
    _randomMovementController = RandomMovementController(
        directionsChecker: _directionsChecker, parent: this);
    _fireController = FireController(this);
    _randomMovementController?.onDirectionChanged = () {
      if (_hearPlayer()) {
        _fireController?.fireASAP();
      }
    };

    await super.onLoad();

    _movementMode = _MovementMode.wait;
    current = TankState.idle;
  }

  @override
  void update(double dt) {
    if (current == TankState.wreck) return;
    if (current != TankState.die) {
      switch (_movementMode) {
        case _MovementMode.wait:
          if (_hearPlayer()) {
            _movementMode = _MovementMode.random;
          } else if (_seePlayer()) {
            _movementMode = _MovementMode.attack;
          }
          break;
        case _MovementMode.random:
          _randomMovementController?.runRandomMovement(dt);
          if (_seePlayer()) {
            _movementMode = _MovementMode.attack;
          }
          break;
        case _MovementMode.attack:
          _randomMovementController?.runRandomMovement(dt);
          break;
      }
    }
    super.update(dt);
  }

  @override
  void onWeaponReloaded() {
    _fireController?.onWeaponReloaded();
  }

  bool _hearPlayer() {
    final game = findParent<MyGame>();
    final player = game?.player;
    if (player == null || player.current == TankState.idle || player.dead) {
      return false;
    }
    final distance = player.position.distanceTo(position);
    return distance < distanceOfSilence;
  }

  bool _seePlayer() {
    final game = findParent<MyGame>();
    final player = game?.player;
    if (player == null || player.dead) {
      return false;
    }
    final distance = player.position.distanceTo(position);
    if (player.isHiddenFromEnemy) {
      return distance < distanceOfReveal;
    }
    return distance < distanceOfView;
  }

  bool isCollisionLandscapeChanged(
          List<Direction> currentAvailableDirections) =>
      _lastAvailableDirections.length < currentAvailableDirections.length;

  @override
  onDeath(Component killedBy) {
    super.onDeath(killedBy);
    final game = findParent<MyGame>();
    if (game != null) {
      game.enemies.remove(this);
      game.spawnEnemy();
    }
  }
}
