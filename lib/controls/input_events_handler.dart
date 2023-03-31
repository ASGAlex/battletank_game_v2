import 'package:flame_message_stream/flame_message_stream.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:tank_game/world/tank/core/direction.dart';

enum PlayerAction { moveUp, moveDown, moveLeft, moveRight, fire }

class InputEventsHandler {
  final messageProvider = MessageStreamProvider<PlayerAction>();

  KeyEventResult onKeyEvent(
    RawKeyEvent event,
    Set<LogicalKeyboardKey> keysPressed,
  ) {
    for (final key in keysPressed) {
      if (key == LogicalKeyboardKey.keyW) {
        messageProvider.sendMessage(PlayerAction.moveUp);
      }
      if (key == LogicalKeyboardKey.keyA) {
        messageProvider.sendMessage(PlayerAction.moveLeft);
      }
      if (key == LogicalKeyboardKey.keyS) {
        messageProvider.sendMessage(PlayerAction.moveDown);
      }
      if (key == LogicalKeyboardKey.keyD) {
        messageProvider.sendMessage(PlayerAction.moveRight);
      }

      if (key == LogicalKeyboardKey.space) {
        handleFireEvent();
      }
    }
    return KeyEventResult.handled;
  }

  double Function()? getCurrentAngle;

  Direction Function()? getCurrentDirection;

  void handleFireEvent() {
    messageProvider.sendMessage(PlayerAction.fire);
  }

  bool onJoystickEvent() {
    final angleDegrees = getCurrentAngle?.call();
    if (angleDegrees == null) {
      return false;
    }

    if (angleDegrees == 0) {
      return false;
    }
    if (angleDegrees >= 315 || angleDegrees <= 45) {
      //Up
      messageProvider.sendMessage(PlayerAction.moveUp);
    } else if (angleDegrees > 45 && angleDegrees < 135) {
      //Right
      messageProvider.sendMessage(PlayerAction.moveRight);
    } else if (angleDegrees >= 135 && angleDegrees <= 225) {
      //Bottom
      messageProvider.sendMessage(PlayerAction.moveDown);
    } else if (angleDegrees > 225 && angleDegrees < 315) {
      //Left
      messageProvider.sendMessage(PlayerAction.moveLeft);
    }
    return true;
  }
}
