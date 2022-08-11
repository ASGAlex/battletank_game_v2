import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/rendering.dart';
import 'package:tank_game/game.dart';
import 'package:tank_game/world/tank/tank.dart';
import 'package:tank_game/world/world.dart';

import '../../services/spritesheet/spritesheet.dart';

class Spawn extends SpriteAnimationComponent with CollisionCallbacks {
  static final _instances = <Spawn>[];
  static const spawnDurationSec = 2;

  static Spawn? _getFree([bool forPlayer = false]) {
    for (var spawn in _instances) {
      if (spawn.canSpawnAnything &&
          !spawn.busy &&
          spawn.isForPlayer == forPlayer &&
          !spawn.isColliding) {
        spawn.busy = true;
        return spawn;
      }
    }
    return null;
  }

  static Future<Spawn> waitFree([bool forPlayer = false]) {
    var spawn = _getFree(forPlayer);
    if (spawn == null) {
      return Future.delayed(const Duration(seconds: spawnDurationSec))
          .then((value) => waitFree(forPlayer));
    }
    return Future.value(spawn);
  }

  bool busy = false;
  bool isForPlayer = false;
  PositionComponent? _currentObject;
  bool _canTryCreate = false;

  Duration cooldown = const Duration(seconds: 60);
  bool _inactive = false;
  int tanksInside = -1;
  double triggerDistance = -1;

  bool get canSpawnAnything => tanksInside == -1 && triggerDistance == -1;

  Spawn({required Vector2 position, this.isForPlayer = false})
      : super(
            position: position, size: Vector2.all(15), anchor: Anchor.center) {
    _instances.add(this);
  }

  static clear() {
    _instances.clear();
  }

  @override
  Future<void> onLoad() async {
    animation = await SpriteSheetRegistry().spawn.animation;
    animation?.onComplete = reverseAnimation;
    add(StaticCollision(
        RectangleHitbox()..collisionType = CollisionType.passive));
  }

  void reverseAnimation() {
    animation = animation?.reversed();
    animation?.onComplete = reverseAnimation;
  }

  Future createTank(PositionComponent object, [bool isPlayer = false]) {
    busy = true;
    animation?.reset();
    _currentObject = object;
    _canTryCreate = false;
    return Future.delayed(const Duration(seconds: spawnDurationSec))
        .then((value) {
      _currentObject?.position = position.clone();
      _canTryCreate = true;
      return null;
    });
  }

  void _createObject() {
    if (_currentObject == null) return;
    findParent<MyGame>()?.addTank(_currentObject!);
    _currentObject = null;
    Future.delayed(const Duration(seconds: spawnDurationSec)).then((value) {
      busy = false;
    });
  }

  @override
  void update(double dt) {
    _doCreateAttempt();
    _doCreateByTriggerAttempt();

    if (busy) {
      super.update(dt);
    }
  }

  _doCreateByTriggerAttempt() {
    // return;
    if (canSpawnAnything) return;

    if (_inactive) return;

    if (tanksInside <= 0) return;

    final game = findParent<MyGame>();
    if (game == null) return;

    final player = game.player;
    if (player == null || player.dead) return;

    final distance = position.distanceTo(player.position);
    if (distance > triggerDistance) return;

    _inactive = true;
    tanksInside--;
    final newEnemy = Enemy(position: position.clone());
    createTank(newEnemy).then((value) {
      game.enemies.add(newEnemy);
      Future.delayed(cooldown).then((value) {
        _inactive = false;
      });
    });
  }

  _doCreateAttempt() {
    if (_canTryCreate) {
      if (isColliding) {
        _canTryCreate = false;
        Future.delayed(const Duration(seconds: spawnDurationSec ~/ 2))
            .then((value) {
          _canTryCreate = true;
        });
      } else {
        _createObject();
        _canTryCreate = false;
      }
    }
  }

  @override
  void render(Canvas canvas) {
    if (busy) {
      super.render(canvas);
    }
  }
}
