part of tank;

class Player extends Tank {
  Player({super.position});

  double _dtAmbientEnemySoundCheck = 0;

  @override
  int health = 100000;

  @override
  int speed = 80;

  MyJoystick? joystick;

  Sfx? movePlayerSound;
  bool movePlayerSoundPaused = true;

  Sfx? _moveEnemiesAmbientSound;
  bool _moveEnemiesAmbientSoundPaused = true;

  @override
  void update(double dt) {
    super.update(dt);
    if (Platform.isAndroid || Platform.isIOS) {
      onJoystickEvent();
    }
    _dtAmbientEnemySoundCheck += dt;
    if (_dtAmbientEnemySoundCheck > 2) {
      _dtAmbientEnemySoundCheck = 0;
      var minDistance = distanceOfSilence;
      for (final enemy in game.enemies) {
        final distance = enemy.position.distanceTo(position);
        if (distance < minDistance) {
          minDistance = distance;
        }
      }
      if (minDistance >= distanceOfSilence) {
        if (!_moveEnemiesAmbientSoundPaused) {
          _moveEnemiesAmbientSound?.pause();
          _moveEnemiesAmbientSoundPaused = true;
        }
      } else {
        _moveEnemiesAmbientSound?.controller
            ?.setVolume(1 - (minDistance / distanceOfSilence));
        if (_moveEnemiesAmbientSoundPaused) {
          _moveEnemiesAmbientSound?.play();
          _moveEnemiesAmbientSoundPaused = false;
        }
      }
    }
  }

  @override
  Future<void> onLoad() async {
    animationRun = await SpriteSheetRegistry().tankBasic.animationRun;
    animationIdle = await SpriteSheetRegistry().tankBasic.animationIdle;
    await super.onLoad();
    joystick = game.joystick;
    movePlayerSound = Sound().movePlayer;
    _moveEnemiesAmbientSound = Sound().moveEnemies;
  }

  @override
  onHiddenChange(bool hidden) {
    if (hidden == true && dead == true) {
      game.restorePlayer();
    }
  }

  @override
  takeDamage(int damage) {
    game.colorFilter?.animateTo(material.Colors.red,
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
    bool directionButtonPressed = false;
    bool updateAngle = false;
    // return false;

    final angleDegrees = joystick?.knobAngleDegrees;

    if (angleDegrees == null) {
      return false;
    }

    directionButtonPressed = true;
    if (angleDegrees == 0) {
      directionButtonPressed = false;
    } else if (angleDegrees >= 315 || angleDegrees <= 45) {
      //Up
      if (lookDirection != Direction.up) {
        lookDirection = Direction.up;
        updateAngle = true;
      }
    } else if (angleDegrees > 45 && angleDegrees < 135) {
      //Right
      if (lookDirection != Direction.right) {
        lookDirection = Direction.right;
        updateAngle = true;
      }
    } else if (angleDegrees >= 135 && angleDegrees <= 225) {
      //Bottom
      if (lookDirection != Direction.down) {
        lookDirection = Direction.down;
        updateAngle = true;
      }
    } else if (angleDegrees > 225 && angleDegrees < 315) {
      //Left
      if (lookDirection != Direction.left) {
        lookDirection = Direction.left;
        updateAngle = true;
      }
    } else {
      directionButtonPressed = false;
      throw "Unexpected Joystick direction error. Angle is& $angleDegrees";
    }

    if (directionButtonPressed && canMoveForward) {
      current = MovementState.run;
      if (_movementHitbox.collisionType != CollisionType.active) {
        changeCollisionType(_movementHitbox, CollisionType.active);
      }
      if (movePlayerSoundPaused) {
        movePlayerSound?.controller?.setVolume(0.5);
        movePlayerSound?.play();
        movePlayerSoundPaused = false;
      }
    } else {
      if (!dead) {
        current = MovementState.idle;
        changeCollisionType(_movementHitbox, CollisionType.active);
      }
      if (!movePlayerSoundPaused) {
        movePlayerSound?.pause();
        movePlayerSoundPaused = true;
      }
    }

    if (updateAngle) {
      angle = lookDirection.angle;
    }
    return false;
  }

  // @override
  // bool onKeyEvent(RawKeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
  //   if (dead) return false;
  //   bool directionButtonPressed = false;
  //   bool updateAngle = false;
  //   for (final key in keysPressed) {
  //     // if (key == LogicalKeyboardKey.keyK) {
  //     //   takeDamage(1);
  //     // }
  //
  //     if (key == LogicalKeyboardKey.keyW) {
  //       directionButtonPressed = true;
  //       if (lookDirection != Direction.up) {
  //         lookDirection = Direction.up;
  //         updateAngle = true;
  //       }
  //     }
  //     if (key == LogicalKeyboardKey.keyA) {
  //       directionButtonPressed = true;
  //       if (lookDirection != Direction.left) {
  //         lookDirection = Direction.left;
  //         updateAngle = true;
  //       }
  //     }
  //     if (key == LogicalKeyboardKey.keyS) {
  //       directionButtonPressed = true;
  //       if (lookDirection != Direction.down) {
  //         lookDirection = Direction.down;
  //         updateAngle = true;
  //       }
  //     }
  //     if (key == LogicalKeyboardKey.keyD) {
  //       directionButtonPressed = true;
  //       if (lookDirection != Direction.right) {
  //         lookDirection = Direction.right;
  //         updateAngle = true;
  //       }
  //     }
  //
  //     if (key == LogicalKeyboardKey.space) {
  //       onFire();
  //     }
  //   }
  //
  //   if (directionButtonPressed && canMoveForward) {
  //     current = MovementState.run;
  //     if (movePlayerSoundPaused) {
  //       movePlayerSound?.controller?.setVolume(0.5);
  //       movePlayerSound?.play();
  //       movePlayerSoundPaused = false;
  //     }
  //   } else {
  //     if (!dead) {
  //       current = MovementState.idle;
  //     }
  //     if (!movePlayerSoundPaused) {
  //       movePlayerSound?.pause();
  //       movePlayerSoundPaused = true;
  //     }
  //   }
  //
  //   if (updateAngle) {
  //     angle = lookDirection.angle;
  //   }
  //
  //   return false;
  // }

  @override
  onHiddenFromEnemyChanged(bool isHidden) {
    game.isPlayerHiddenFromEnemy = isHidden;
  }
}
