import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:tank_game/controls/input_events_handler.dart';
import 'package:tank_game/game.dart';

mixin GameHardwareKeyboard on MyGameFeatures {
  final inputEventsHandler = InputEventsHandler();

  @override
  FutureOr<void> onLoad() {
    inputEventsHandler.game = this as MyGame;
    return super.onLoad();
  }

  @override
  KeyEventResult onKeyEvent(
    RawKeyEvent event,
    Set<LogicalKeyboardKey> keysPressed,
  ) {
    return inputEventsHandler.onKeyEvent(event, keysPressed);
  }
}
