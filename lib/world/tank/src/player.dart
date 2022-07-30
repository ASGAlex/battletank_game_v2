part of tank;

class Player extends Tank {
  Player({super.position});

  double _dtAmbientEnemySoundCheck = 0;

  @override
  int health = 100000;

  @override
  int speed = 80;

  JoystickComponent? joystick;

  @override
  void update(double dt) {
    super.update(dt);
    if (Platform.isAndroid || Platform.isIOS) {
      onJoystickEvent();
    }
    _dtAmbientEnemySoundCheck += dt;
    if (_dtAmbientEnemySoundCheck > 2) {
      _dtAmbientEnemySoundCheck = 0;
      final game = findParent<MyGame>();
      if (game != null) {
        var minDistance = distanceOfSilence;
        for (final enemy in game.enemies) {
          final distance = enemy.position.distanceTo(position);
          if (distance < minDistance) {
            minDistance = distance;
          }
        }
        final sfx = Sound().moveEnemies;
        if (minDistance >= distanceOfSilence) {
          sfx.pause();
        } else {
          sfx.controller?.setVolume(1 - (minDistance / distanceOfSilence));
          sfx.play();
        }
      }
    }
  }

  @override
  Future<void> onLoad() async {
    animationRun = await SpriteSheetRegistry().tankBasic.animationRun;
    animationIdle = await SpriteSheetRegistry().tankBasic.animationIdle;
    joystick = findParent<MyGame>()?.joystick;
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
    game?.colorFilter?.animateTo(material.Colors.red,
        blendMode: BlendMode.colorBurn,
        duration: const Duration(milliseconds: 250), onFinish: () {
      game.colorFilter?.config.color = null;
    });

    super.takeDamage(damage);
  }

  @override
  onDeath() {
    Sound().movePlayer.pause();
    super.onDeath();
  }

  bool onJoystickEvent() {
    if (dead) return false;
    final direction = joystick?.direction;
    bool directionButtonPressed = false;
    bool updateAngle = false;

    if (direction == null) {
      return false;
    }
    final angleDegrees = (joystick?.delta.screenAngle() ?? 0) * (180 / pi);

    switch (direction) {
      case JoystickDirection.up:
        directionButtonPressed = true;
        if (lookDirection != Direction.up) {
          lookDirection = Direction.up;
          updateAngle = true;
        }
        break;
      case JoystickDirection.upLeft:
        if (angleDegrees < -45) {
          directionButtonPressed = true;
          if (lookDirection != Direction.left) {
            lookDirection = Direction.left;
            updateAngle = true;
          }
        } else {
          directionButtonPressed = true;
          if (lookDirection != Direction.up) {
            lookDirection = Direction.up;
            updateAngle = true;
          }
        }
        break;
      case JoystickDirection.upRight:
        if (angleDegrees > 45) {
          directionButtonPressed = true;
          if (lookDirection != Direction.right) {
            lookDirection = Direction.right;
            updateAngle = true;
          }
        } else {
          directionButtonPressed = true;
          if (lookDirection != Direction.up) {
            lookDirection = Direction.up;
            updateAngle = true;
          }
        }
        break;
      case JoystickDirection.right:
        directionButtonPressed = true;
        if (lookDirection != Direction.right) {
          lookDirection = Direction.right;
          updateAngle = true;
        }
        break;
      case JoystickDirection.down:
        directionButtonPressed = true;
        if (lookDirection != Direction.down) {
          lookDirection = Direction.down;
          updateAngle = true;
        }
        break;
      case JoystickDirection.downRight:
        if (angleDegrees > 135) {
          directionButtonPressed = true;
          if (lookDirection != Direction.down) {
            lookDirection = Direction.down;
            updateAngle = true;
          }
        } else {
          directionButtonPressed = true;
          if (lookDirection != Direction.right) {
            lookDirection = Direction.right;
            updateAngle = true;
          }
        }
        break;
      case JoystickDirection.downLeft:
        if (angleDegrees < -135) {
          directionButtonPressed = true;
          if (lookDirection != Direction.left) {
            lookDirection = Direction.left;
            updateAngle = true;
          }
        } else {
          directionButtonPressed = true;
          if (lookDirection != Direction.down) {
            lookDirection = Direction.down;
            updateAngle = true;
          }
        }
        break;
      case JoystickDirection.left:
        directionButtonPressed = true;
        if (lookDirection != Direction.left) {
          lookDirection = Direction.left;
          updateAngle = true;
        }
        break;
      case JoystickDirection.idle:
        // TODO: Handle this case.
        break;
    }
    if (directionButtonPressed && canMoveForward) {
      current = MovementState.run;
      final sfx = Sound().movePlayer;
      // sfx.controller?.setVolume(0.5);
      sfx.play();
    } else {
      if (!dead) {
        current = MovementState.idle;
      }
      Sound().movePlayer.pause();
    }

    if (updateAngle) {
      angle = lookDirection.angle;
    }
    return false;
  }

  @override
  bool onKeyEvent(RawKeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    if (dead) return false;
    bool directionButtonPressed = false;
    bool updateAngle = false;
    for (final key in keysPressed) {
      // if (key == LogicalKeyboardKey.keyK) {
      //   takeDamage(1);
      // }

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
      final sfx = Sound().movePlayer;
      // sfx.controller?.setVolume(0.5);
      sfx.play();
    } else {
      if (!dead) {
        current = MovementState.idle;
      }
      Sound().movePlayer.pause();
    }

    if (updateAngle) {
      angle = lookDirection.angle;
    }

    return false;
  }

  @override
  onHiddenFromEnemyChanged(bool isHidden) {
    final game = findParent<MyGame>();
    game?.isPlayerHiddenFromEnemy = isHidden;
  }
}
