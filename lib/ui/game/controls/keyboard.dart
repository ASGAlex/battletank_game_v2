import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:tank_game/game.dart';
import 'package:tank_game/services/settings/controller.dart';
import 'package:tank_game/world/tank/core/base_tank.dart';
import 'package:tank_game/world/tank/core/direction.dart';

mixin GameHardwareKeyboard on MyGameFeatures {
  @override
  KeyEventResult onKeyEvent(
    RawKeyEvent event,
    Set<LogicalKeyboardKey> keysPressed,
  ) {
    final player = (this as MyGame).player;

    if (player == null) return KeyEventResult.handled;
    if (player.dead == true) return KeyEventResult.handled;
    final isGamepad = (event.character == 'xinput');
    if (!isGamepad) {
      SettingsController().xInputGamePadController.useController = false;
    }

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
      } else if (key == LogicalKeyboardKey.escape) {
        if (overlays.isActive('menu')) {
          overlays.remove('menu');
          paused = false;
        } else {
          overlays.add('menu');
          paused = true;
        }
      }

      if (key == LogicalKeyboardKey.keyK) {
        player.onDeath(player);
      }

      if (key == LogicalKeyboardKey.keyM) {
        isSpatialGridDebugEnabled = !isSpatialGridDebugEnabled;
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

    if (directionButtonPressed && player.movementHitbox.isMovementAllowed) {
      player.current = TankState.run;
      // if ([PlayerState.paused, PlayerState.stopped]
      //     .contains(player.movePlayerSound?.state)) {
      //   player.movePlayerSound?.setVolume(0.5);
      //   player.movePlayerSound?.resume();
      // }
    } else {
      if (!player.dead) {
        player.current = TankState.idle;
      }
      // if (player.movePlayerSound?.state == PlayerState.playing) {
      //   player.movePlayerSound?.pause();
      // }
    }

    if (updateAngle) {
      player.angle = player.lookDirection.angle;
      player.skipUpdateOnAngleChange = true;
    }

    return KeyEventResult.handled;
  }
}
