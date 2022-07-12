import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/rendering.dart';
import 'package:tank_game/game.dart';

import '../../services/spritesheet/spritesheet.dart';

class Spawn extends SpriteAnimationComponent with CollisionCallbacks {
  static final _instances = <Spawn>[];
  static const spawnDurationSec = 2;

  static Spawn? _getFree([bool forPlayer = false]) {
    for (var spawn in _instances) {
      if (!spawn.busy && spawn.isForPlayer == forPlayer && !spawn.isColliding) {
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

  Spawn({required Vector2 position, this.isForPlayer = false})
      : super(
            position: position, size: Vector2.all(15), anchor: Anchor.center) {
    _instances.add(this);
  }

  @override
  Future<void> onLoad() async {
    animation = await SpriteSheetRegistry().spawn.animation;
    animation?.onComplete = reverseAnimation;
    add(RectangleHitbox()..collisionType = CollisionType.passive);
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
    super.update(dt);
  }

  @override
  void render(Canvas canvas) {
    if (busy) {
      super.render(canvas);
    }
  }
}
