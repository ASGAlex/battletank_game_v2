import 'dart:io';
import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart' as material;
import 'package:tank_game/controls/joystick.dart';
import 'package:tank_game/services/settings/controller.dart';

import 'core/base_tank.dart';
import 'core/direction.dart';

class Player extends Tank {
  Player({super.position});

  double _dtAmbientEnemySoundCheck = 0;

  static int respawnCount = 3000;

  MyJoystick? joystick;

  // final _movePlayerSound = SoundLibrary.createMusicPlayer('move_player.m4a',
  //         playerId: 'firstPlayerSelf')
  //     .then((value) {
  //   value.setReleaseMode(ReleaseMode.loop);
  //   return value;
  // });

  // AudioPlayer? movePlayerSound;

  // final _moveEnemiesAmbientSound = SoundLibrary.createMusicPlayer(
  //         'move_enemies.m4a',
  //         playerId: 'firstPlayerEnemies')
  //     .then((value) {
  //   value.setReleaseMode(ReleaseMode.loop);
  //   return value;
  // });

  // AudioPlayer? moveEnemiesAmbientSound;

  @override
  void update(double dt) {
    super.update(dt);
    if (!dead) {
      if (Platform.isAndroid || Platform.isIOS) {
        onJoystickEvent();
      }
      _dtAmbientEnemySoundCheck += dt;
      // if (_dtAmbientEnemySoundCheck > 0.6) {
      //   _dtAmbientEnemySoundCheck = 0;
      //   var minDistance = distanceOfSilenceSquared;
      //   for (final enemy in gameRef.enemies) {
      //     final distance = enemy.position.distanceToSquared(position);
      //     if (distance < minDistance) {
      //       minDistance = distance;
      //     }
      //   }
      //   if (minDistance >= distanceOfSilenceSquared) {
      //     if (moveEnemiesAmbientSound?.state == PlayerState.playing) {
      //       moveEnemiesAmbientSound?.pause();
      //     }
      //   } else {
      //     moveEnemiesAmbientSound
      //         ?.setVolume(1 - (minDistance / distanceOfSilenceSquared));
      //     if ([PlayerState.paused, PlayerState.stopped]
      //         .contains(moveEnemiesAmbientSound?.state)) {
      //       moveEnemiesAmbientSound?.resume();
      //     }
      //   }
      // }
    }
  }

  @override
  Future<void>? onLoad() async {
    // _movePlayerSound.then((value) {
    //   movePlayerSound = value;
    // });
    // _moveEnemiesAmbientSound.then((value) {
    //   moveEnemiesAmbientSound = value;
    // });
    await super.onLoad();
    joystick = gameRef.joystick;
  }

  // @override
  // onHiddenChange(bool hidden) {
  //   if (hidden == true && dead == true) {
  //     gameRef.restorePlayer();
  //   }
  // }

  @override
  takeDamage(double damage, Component from) {
    if (!dead) {
      gameRef.colorFilter?.animateTo(material.Colors.red,
          blendMode: BlendMode.colorBurn,
          duration: const Duration(milliseconds: 250), onFinish: () {
        gameRef.colorFilter?.config.color = null;
      });
      final xinput = SettingsController().xInputGamePadController;
      if (Platform.isWindows && xinput.useController) {
        xinput.xinputController.vibrate(const Duration(milliseconds: 250));
      }
    }

    super.takeDamage(damage, from);
  }

  @override
  onDeath(Component killedBy) {
    if (!dead) {
      // moveEnemiesAmbientSound?.pause();
      // movePlayerSound?.pause();
      // gameRef.restorePlayer();
    }
    super.onDeath(killedBy);
  }

  bool onJoystickEvent() {
    if (dead) return false;
    bool directionButtonPressed = false;
    bool updateAngle = false;

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

    if (directionButtonPressed && movementHitbox.isMovementAllowed) {
      current = TankState.run;
      if (movementHitbox.collisionType != CollisionType.active) {
        movementHitbox.collisionType = CollisionType.active;
      }
      // if ([PlayerState.paused, PlayerState.stopped]
      //     .contains(movePlayerSound?.state)) {
      //   movePlayerSound?.setVolume(0.5);
      //   movePlayerSound?.resume();
      // }
    } else {
      if (!dead) {
        current = TankState.idle;
        movementHitbox.collisionType = CollisionType.active;
      }
      // if (movePlayerSound?.state == PlayerState.playing) {
      //   movePlayerSound?.pause();
      // }
    }

    if (updateAngle) {
      angle = lookDirection.angle;
      skipUpdateOnAngleChange = true;
    }
    return false;
  }

  @override
  onHiddenFromEnemyChanged(bool isHidden) {
    gameRef.hudVisibility.setVisibility(!isHidden);
  }

  @override
  onRemove() {
    // movePlayerSound?.pause();
    // moveEnemiesAmbientSound?.pause();
  }
}
