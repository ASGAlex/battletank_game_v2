import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:tank_game/game.dart';

mixin GameHardwareKeyboard on MyGameFeatures {
  @override
  KeyEventResult onKeyEvent(
    RawKeyEvent event,
    Set<LogicalKeyboardKey> keysPressed,
  ) {
    return inputEventsHandler.onKeyEvent(event, keysPressed);
  }
}
