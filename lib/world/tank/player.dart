import 'dart:io';
import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart' as material;
import 'package:tank_game/packages/sound/lib/sfx.dart';
import 'package:tank_game/services/settings/controller.dart';
import 'package:tank_game/services/sound/library.dart';
import 'package:tank_game/ui/game/controls/joystick.dart';
import 'package:tank_game/world/world.dart';

import 'core/base_tank.dart';
import 'core/direction.dart';

class Player extends Tank {
  Player({super.position});

  double _dtAmbientEnemySoundCheck = 0;

  static int respawnCount = 3;

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
    await super.onLoad();
    joystick = game.joystick;
    movePlayerSound = SoundLibrary().movePlayer;
    _moveEnemiesAmbientSound = SoundLibrary().moveEnemies;
  }

  @override
  onHiddenChange(bool hidden) {
    if (hidden == true && dead == true) {
      game.restorePlayer();
    }
  }

  @override
  takeDamage(int damage, Component from) {
    if (!dead) {
      game.colorFilter?.animateTo(material.Colors.red,
          blendMode: BlendMode.colorBurn,
          duration: const Duration(milliseconds: 250), onFinish: () {
        game.colorFilter?.config.color = null;
      });
      if (Platform.isWindows) {
        SettingsController()
            .xInputGamePadController
            .xinputController
            .vibrate(const Duration(milliseconds: 250));
      }
    }

    super.takeDamage(damage, from);
  }

  @override
  onDeath(Component killedBy) {
    if (!dead) {
      SoundLibrary().movePlayer.pause();
      game.restorePlayer();
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
      if (movePlayerSoundPaused) {
        movePlayerSound?.controller?.setVolume(0.5);
        movePlayerSound?.play();
        movePlayerSoundPaused = false;
      }
    } else {
      if (!dead) {
        current = TankState.idle;
        changeCollisionType(movementHitbox, CollisionType.active);
      }
      if (!movePlayerSoundPaused) {
        movePlayerSound?.pause();
        movePlayerSoundPaused = true;
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
    game.hudVisibility?.setVisibility(!isHidden);
  }

  @override
  onRemove() {
    _moveEnemiesAmbientSound?.pause();
  }
}
