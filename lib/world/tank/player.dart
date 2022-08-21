import 'dart:io';
import 'dart:ui';

import 'package:audioplayers/audioplayers.dart';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart' as material;
import 'package:tank_game/services/settings/controller.dart';
import 'package:tank_game/ui/game/controls/joystick.dart';
import 'package:tank_game/world/world.dart';

import '../sound.dart';
import 'core/base_tank.dart';
import 'core/direction.dart';

class Player extends Tank {
  Player({super.position});

  double _dtAmbientEnemySoundCheck = 0;

  static int respawnCount = 30;

  MyJoystick? joystick;

  final movePlayerSound = SoundLibrary.createMusicPlayer('move_player.m4a',
      playerId: 'firstPlayerSelf')
    ..setReleaseMode(ReleaseMode.loop);

  final _moveEnemiesAmbientSound = SoundLibrary.createMusicPlayer(
      'move_enemies.m4a',
      playerId: 'firstPlayerEnemies')
    ..setReleaseMode(ReleaseMode.loop);
  bool _moveEnemiesAmbientSoundPaused = true;

  @override
  void update(double dt) {
    super.update(dt);
    if (Platform.isAndroid || Platform.isIOS) {
      onJoystickEvent();
    }
    if (!dead) {
      _dtAmbientEnemySoundCheck += dt;
      if (_dtAmbientEnemySoundCheck > 0.6) {
        _dtAmbientEnemySoundCheck = 0;
        var minDistance = distanceOfSilenceSquared;
        for (final enemy in gameRef.enemies) {
          final distance = enemy.position.distanceToSquared(position);
          if (distance < minDistance) {
            minDistance = distance;
          }
        }
        if (minDistance >= distanceOfSilenceSquared) {
          if (!_moveEnemiesAmbientSoundPaused) {
            _moveEnemiesAmbientSound.pause();
            _moveEnemiesAmbientSoundPaused = true;
          }
        } else {
          _moveEnemiesAmbientSound
              .setVolume(1 - (minDistance / distanceOfSilenceSquared));
          if (_moveEnemiesAmbientSoundPaused) {
            _moveEnemiesAmbientSound.resume();
            _moveEnemiesAmbientSoundPaused = false;
          }
        }
      }
    }
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    joystick = gameRef.joystick;
  }

  @override
  onHiddenChange(bool hidden) {
    if (hidden == true && dead == true) {
      gameRef.restorePlayer();
    }
  }

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
      _moveEnemiesAmbientSound.pause();
      movePlayerSound.pause();
      gameRef.restorePlayer();
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

    if (directionButtonPressed && canMoveForward) {
      current = TankState.run;
      if (movementHitbox.collisionType != CollisionType.active) {
        changeCollisionType(movementHitbox, CollisionType.active);
      }
      if (movePlayerSound.state == PlayerState.paused) {
        movePlayerSound.setVolume(0.5);
        movePlayerSound.resume();
      }
    } else {
      if (!dead) {
        current = TankState.idle;
        changeCollisionType(movementHitbox, CollisionType.active);
      }
      if (movePlayerSound.state == PlayerState.playing) {
        movePlayerSound.pause();
      }
    }

    if (updateAngle) {
      angle = lookDirection.angle;
      skipUpdateOnAngleChange = true;
    }
    return false;
  }

  @override
  onHiddenFromEnemyChanged(bool isHidden) {
    gameRef.hudVisibility?.setVisibility(!isHidden);
  }

  @override
  onRemove() {
    movePlayerSound.pause();
    _moveEnemiesAmbientSound.pause();
  }
}
