import 'package:flame/components.dart';
import 'package:tank_game/game.dart';
import 'package:tank_game/services/spritesheet/spritesheet.dart';
import 'package:tank_game/world/world.dart';

import 'behaviors/attack_movement.dart';
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
  AttackMovementController? _attackMovementController;
  FireController? _fireController;
  double _noEventsTimer = 0;
  static const _noEventsMax = 60;

  bool hearPlayer = false;
  bool seePlayer = false;

  @override
  Future<void> onLoad() async {
    animationRun = await SpriteSheetRegistry().tankBasic.animationRun;
    animationIdle = await SpriteSheetRegistry().tankBasic.animationIdle;
    _directionsChecker.onLoad(this);
    _randomMovementController = RandomMovementController(
        directionsChecker: _directionsChecker, parent: this);
    _fireController = FireController(this);
    _randomMovementController?.onDirectionChanged = () {
      if (hearPlayer) {
        _fireController?.fireASAP();
      }
    };

    _attackMovementController = AttackMovementController(
        parent: this, directionsChecker: _directionsChecker);

    await super.onLoad();

    _movementMode = _MovementMode.random;
    current = TankState.run;
  }

  @override
  void update(double dt) {
    if (current == TankState.wreck) return;
    if (current != TankState.die) {
      hearPlayer = _hearPlayer();
      seePlayer = _seePlayer();
      switch (_movementMode) {
        case _MovementMode.wait:
          if (hearPlayer) {
            _movementMode = _MovementMode.random;
          } else if (seePlayer) {
            _movementMode = _MovementMode.attack;
          }
          break;
        case _MovementMode.random:
          _randomMovementController?.runRandomMovement(dt);
          bool eventHappen = false;
          if (seePlayer) {
            _movementMode = _MovementMode.attack;
            eventHappen = true;
          }
          if (hearPlayer) {
            eventHappen = true;
          }
          if (!eventHappen) {
            _noEventsTimer += dt;
          }
          if (_noEventsTimer >= _noEventsMax) {
            _movementMode = _MovementMode.wait;
            _noEventsTimer = 0;
          }
          break;
        case _MovementMode.attack:
          final foundDirection =
              _attackMovementController?.runAttackMovement(dt);
          if (foundDirection == null) {
            _movementMode = _MovementMode.random;
          } else if (_attackMovementController?.shouldFire == true) {
            _fireController?.fireASAP();
          }
          break;
      }
    }
    super.update(dt);
  }

  @override
  void onWeaponReloaded() {
    if (dead) return;
    _fireController?.onWeaponReloaded();
  }

  bool _hearPlayer() {
    final player = game.player;
    if (player == null || player.current == TankState.idle || player.dead) {
      return false;
    }
    final distance = player.position.distanceTo(position);
    return distance < distanceOfSilence;
  }

  bool _seePlayer() {
    final player = game.player;
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
