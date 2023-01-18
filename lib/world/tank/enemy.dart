import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:tank_game/game.dart';
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

  final colorFilters = <ColorFilter>[
    //red
    const ColorFilter.matrix(<double>[
      1.000,
      0.000,
      1.000,
      0.000,
      0.000,
      0.000,
      0.200,
      1.000,
      0.000,
      0.000,
      1.000,
      3.000,
      1.000,
      0.000,
      0.000,
      0.000,
      0.000,
      0.000,
      1.000,
      0.000,
    ]),

    //green
    const ColorFilter.matrix(<double>[
      0.000,
      0.000,
      1.000,
      0.000,
      0.000,
      0.000,
      1.000,
      2.000,
      0.000,
      0.000,
      0.000,
      0.000,
      1.000,
      0.000,
      0.000,
      0.000,
      0.000,
      0.000,
      1.000,
      0.000,
    ]),
    // white
    const ColorFilter.matrix(<double>[
      1.000,
      0.000,
      0.000,
      0.000,
      0.000,
      0.500,
      1.000,
      0.000,
      0.000,
      0.000,
      0.500,
      1.000,
      1.000,
      0.000,
      0.000,
      0.000,
      0.000,
      0.000,
      1.000,
      0.000
    ]),
  ];

  ColorFilter get randomColorFilter {
    final i = Random().nextInt(colorFilters.length);
    return colorFilters[i];
  }

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
    await super.onLoad();
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
        parent: this,
        directionsChecker: _directionsChecker,
        randomMovementController: _randomMovementController!);

    _movementMode = _MovementMode.random;
    current = TankState.run;

    getPaint().colorFilter = randomColorFilter;
  }

  @override
  void update(double dt) {
    if (current == TankState.wreck) {
      super.update(dt);
      return;
    }

    if (current != TankState.die) {
      hearPlayer = _hearPlayer();
      if (!hearPlayer) {
        seePlayer = false;
      } else {
        seePlayer = _seePlayer();
      }
      switch (_movementMode) {
        case _MovementMode.wait:
          movementHitbox.groupCollisionsTags.clear();
          if (hearPlayer) {
            _movementMode = _MovementMode.random;
          } else if (seePlayer) {
            _movementMode = _MovementMode.attack;
          }
          break;
        case _MovementMode.random:
          _randomMovementController?.runRandomMovement(dt);
          if (movementHitbox.groupCollisionsTags.isEmpty) {
            movementHitbox.groupCollisionsTags
              ..add('Brick')
              ..add('HeavyBrick')
              ..add('Water');
          }
          bool eventHappen = false;
          if (seePlayer) {
            _movementMode = _MovementMode.attack;
            _directionsChecker.disableSideHitboxes();
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
            current = TankState.idle;
            _directionsChecker.disableSideHitboxes();
            _noEventsTimer = 0;
          }
          break;
        case _MovementMode.attack:
          movementHitbox.groupCollisionsTags.clear();
          final foundDirection =
              _attackMovementController!.runAttackMovement(dt, seePlayer);
          if (!foundDirection) {
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
    final player = gameRef.player;
    if (player == null || player.current == TankState.idle || player.dead) {
      return false;
    }
    final distance = player.position.distanceToSquared(position);
    return distance < distanceOfSilenceSquared;
  }

  bool _seePlayer() {
    final player = gameRef.player;
    if (player == null || player.dead) {
      return false;
    }
    final distance = player.position.distanceToSquared(position);
    if (player.isHiddenFromEnemy) {
      return distance < distanceOfRevealSquared;
    }
    return distance < distanceOfViewSquared;
  }

  bool isCollisionLandscapeChanged(
          List<Direction> currentAvailableDirections) =>
      _lastAvailableDirections.length < currentAvailableDirections.length;

  @override
  takeDamage(double damage, Component from) {
    getPaint().colorFilter = randomColorFilter;
    super.takeDamage(damage, from);
  }

  @override
  onDeath(Component killedBy) {
    getPaint().colorFilter = null;
    super.onDeath(killedBy);
    final game = findParent<MyGame>();
    if (game != null) {
      game.enemies.remove(this);
      game.spawnEnemy();
    }
  }
}
