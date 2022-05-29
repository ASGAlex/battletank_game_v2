part of tank;

class Player extends Tank {
  Player({super.position});

  @override
  Future<void> onLoad() async {
    animationRun = await SpriteSheetRegistry().tankBasic.animationRun;
    animationIdle = await SpriteSheetRegistry().tankBasic.animationIdle;
    super.onLoad();
  }

  @override
  onHiddenChange(bool hidden) {
    if (hidden == true && dead == true) {
      final game = findParent<MyGame>();
      game?.restorePlayer();
    }
  }

  @override
  takeDamage(int damage) {
    final game = findParent<MyGame>();
    game?.colorFilter?.animateTo(Colors.red,
        blendMode: BlendMode.colorBurn,
        duration: const Duration(milliseconds: 250), onFinish: () {
      game.colorFilter?.config.color = null;
    });

    super.takeDamage(damage);
  }

  @override
  bool onKeyEvent(RawKeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    bool directionButtonPressed = false;
    bool updateAngle = false;
    for (final key in keysPressed) {
      if (key == LogicalKeyboardKey.keyK) {
        takeDamage(1);
      }

      if (key == LogicalKeyboardKey.keyW) {
        directionButtonPressed = true;
        if (lookDirection != Direction.up) {
          lookDirection = Direction.up;
          updateAngle = true;
        }
      }
      if (key == LogicalKeyboardKey.keyA) {
        directionButtonPressed = true;
        if (lookDirection != Direction.left) {
          lookDirection = Direction.left;
          updateAngle = true;
        }
      }
      if (key == LogicalKeyboardKey.keyS) {
        directionButtonPressed = true;
        if (lookDirection != Direction.down) {
          lookDirection = Direction.down;
          updateAngle = true;
        }
      }
      if (key == LogicalKeyboardKey.keyD) {
        directionButtonPressed = true;
        if (lookDirection != Direction.right) {
          lookDirection = Direction.right;
          updateAngle = true;
        }
      }

      if (key == LogicalKeyboardKey.space) {
        onFire();
      }
    }

    if (directionButtonPressed && canMoveForward) {
      current = MovementState.run;
      Sound().movePlayer.play();
    } else {
      if (!dead) {
        current = MovementState.idle;
      }
      Sound().movePlayer.pause();
    }

    if (updateAngle) {
      angle = lookDirection.angle;
      collisionCheckedAfterAngleUpdate = false;
    }

    return false;
  }

  @override
  onHiddenFromEnemyChanged(bool isHidden) {
    final game = findParent<MyGame>();
    game?.isPlayerHiddenFromEnemy = isHidden;
  }
}
