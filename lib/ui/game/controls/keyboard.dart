import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:tank_game/game.dart';
import 'package:tank_game/world/tank/tank.dart';

mixin GameHardwareKeyboard on MyGameFeatures {
  KeyEventResult onKeyEvent(
    RawKeyEvent event,
    Set<LogicalKeyboardKey> keysPressed,
  ) {
    final player = (this as MyGame).player;
    if (player == null) return KeyEventResult.handled;
    if (player.dead == true) return KeyEventResult.handled;

    bool directionButtonPressed = false;
    bool updateAngle = false;
    for (final key in keysPressed) {
      if (key == LogicalKeyboardKey.tilde ||
          key == LogicalKeyboardKey.backquote) {
        if (overlays.isActive('console')) {
          overlays.remove('console');
        } else {
          overlays.add('console');
        }
      }

      if (key == LogicalKeyboardKey.keyW) {
        directionButtonPressed = true;
        if (player.lookDirection != Direction.up) {
          player.lookDirection = Direction.up;
          updateAngle = true;
        }
      }
      if (key == LogicalKeyboardKey.keyA) {
        directionButtonPressed = true;
        if (player.lookDirection != Direction.left) {
          player.lookDirection = Direction.left;
          updateAngle = true;
        }
      }
      if (key == LogicalKeyboardKey.keyS) {
        directionButtonPressed = true;
        if (player.lookDirection != Direction.down) {
          player.lookDirection = Direction.down;
          updateAngle = true;
        }
      }
      if (key == LogicalKeyboardKey.keyD) {
        directionButtonPressed = true;
        if (player.lookDirection != Direction.right) {
          player.lookDirection = Direction.right;
          updateAngle = true;
        }
      }

      if (key == LogicalKeyboardKey.space) {
        player.onFire();
      }
    }

    if (directionButtonPressed && player.canMoveForward) {
      player.current = MovementState.run;
      if (player.movePlayerSoundPaused) {
        player.movePlayerSound?.controller?.setVolume(0.5);
        player.movePlayerSound?.play();
        player.movePlayerSoundPaused = false;
      }
    } else {
      if (!player.dead) {
        player.current = MovementState.idle;
      }
      if (!player.movePlayerSoundPaused) {
        player.movePlayerSound?.pause();
        player.movePlayerSoundPaused = true;
      }
    }

    if (updateAngle) {
      player.angle = player.lookDirection.angle;
      player.skipUpdateOnAngleChange = true;
    }

    return KeyEventResult.handled;
  }
}
