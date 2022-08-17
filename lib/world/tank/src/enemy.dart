import 'package:flame/components.dart';
import 'package:tank_game/game.dart';
import 'package:tank_game/services/spritesheet/spritesheet.dart';
import 'package:tank_game/world/world.dart';

import 'behaviors/available_directions.dart';
import 'behaviors/fire.dart';
import 'behaviors/random_movement.dart';
import 'core/base_tank.dart';
import 'core/direction.dart';

enum _MovementMode { random, randomWithFire, toPlayerBlind, target }

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

    _movementMode = _MovementMode.random;
    current = MovementState.run;
  }

  @override
  void update(double dt) {
    if (current == MovementState.wreck) return;
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

  @override
  void onWeaponReloaded() {
    _fireController?.onWeaponReloaded();
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
