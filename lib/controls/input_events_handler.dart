import 'package:flame_message_stream/flame_message_stream.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:tank_game/game.dart';

enum PlayerAction {
  moveUp,
  moveDown,
  moveLeft,
  moveRight,
  fire,
  triggerE,
  triggerF,
  triggerK,
  console,
  escape,
}

class InputEventsHandler {
  MyGame? game;
  final messageProvider = MessageStreamProvider<List<PlayerAction>>();

  KeyEventResult onKeyEvent(
    RawKeyEvent event,
    Set<LogicalKeyboardKey> keysPressed,
  ) {
    final actions = <PlayerAction>[];
    for (final key in keysPressed) {
      if (key == LogicalKeyboardKey.keyW) {
        actions.add(PlayerAction.moveUp);
      }
      if (key == LogicalKeyboardKey.keyA) {
        actions.add(PlayerAction.moveLeft);
      }
      if (key == LogicalKeyboardKey.keyS) {
        actions.add(PlayerAction.moveDown);
      }
      if (key == LogicalKeyboardKey.keyD) {
        actions.add(PlayerAction.moveRight);
      }
      if (key == LogicalKeyboardKey.keyE) {
        actions.add(PlayerAction.triggerE);
      }
      if (key == LogicalKeyboardKey.keyF) {
        actions.add(PlayerAction.triggerF);
      }
      if (key == LogicalKeyboardKey.keyK) {
        actions.add(PlayerAction.triggerK);
      }

      if (key == LogicalKeyboardKey.keyU) {
        game?.removeUnusedCells(forceCleanup: true);
      }
      if (key == LogicalKeyboardKey.keyO) {
        game?.isSpatialGridDebugEnabled =
            !(game?.isSpatialGridDebugEnabled ?? false);
      }

      if (key == LogicalKeyboardKey.escape) {
        actions.add(PlayerAction.escape);
      }
      if (key == LogicalKeyboardKey.tilde ||
          key == LogicalKeyboardKey.backquote) {
        actions.add(PlayerAction.console);
      }

      if (key == LogicalKeyboardKey.space) {
        actions.add(PlayerAction.fire);
      }
    }
    messageProvider.sendMessage(actions);
    return KeyEventResult.handled;
  }

  void onFireEvent() {
    messageProvider.sendMessage([PlayerAction.fire]);
  }

  PlayerAction? _joystickPreviousMovement;

  bool onJoystickEvent(double angleDegrees) {
    PlayerAction? movement;
    if (angleDegrees <= 0.05) {
      movement = null;
    } else if (angleDegrees >= 315 || angleDegrees <= 45) {
      //Up
      movement = PlayerAction.moveUp;
    } else if (angleDegrees > 45 && angleDegrees < 135) {
      //Right
      movement = PlayerAction.moveRight;
    } else if (angleDegrees >= 135 && angleDegrees <= 225) {
      //Bottom
      movement = PlayerAction.moveDown;
    } else if (angleDegrees > 225 && angleDegrees < 315) {
      //Left
      movement = PlayerAction.moveLeft;
    }
    if (_joystickPreviousMovement != movement) {
      if (movement == null) {
        messageProvider.sendMessage([]);
      } else {
        messageProvider.sendMessage([movement]);
      }
      _joystickPreviousMovement = movement;
    }
    return true;
  }
}
