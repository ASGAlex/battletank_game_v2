import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tank_game/game.dart';
import 'package:tank_game/services/settings/controller.dart';
import 'package:win32/win32.dart';
import 'package:xinput_gamepad/xinput_gamepad.dart';

class XInputGamePadController extends ChangeNotifier {
  XInputGamePadController() {
    initXInputGamePad();
  }

  late final Controller xinputController;
  var spaceHold = false;
  final keysPressed = <LogicalKeyboardKey>{};

  initXInputGamePad() {
    if (Platform.isWindows) {
      XInputManager.enableXInput();
      xinputController = Controller(
          index: 0,
          onRawButtonEvent: onRawButtonEvent,
          leftVibrationSpeed: 65535,
          rightVibrationSpeed: 65535);
      xinputController.listen();
    }
  }

  onRawButtonEvent(int bitmask) {
    keysPressed.clear();
    if (bitmask & XINPUT_GAMEPAD_DPAD_UP > 0) {
      keysPressed.add(LogicalKeyboardKey.keyW);
    } else if (bitmask & XINPUT_GAMEPAD_DPAD_DOWN > 0) {
      keysPressed.add(LogicalKeyboardKey.keyS);
    } else if (bitmask & XINPUT_GAMEPAD_DPAD_LEFT > 0) {
      keysPressed.add(LogicalKeyboardKey.keyA);
    } else if (bitmask & XINPUT_GAMEPAD_DPAD_RIGHT > 0) {
      keysPressed.add(LogicalKeyboardKey.keyD);
    }

    if (bitmask & (XINPUT_GAMEPAD_X | XINPUT_GAMEPAD_RIGHT_SHOULDER) > 0) {
      keysPressed.add(LogicalKeyboardKey.space);
      spaceHold = true;
    } else {
      spaceHold = false;
    }
    if (bitmask & XINPUT_GAMEPAD_BACK > 0) {
      keysPressed.add(LogicalKeyboardKey.escape);
    }
    if (bitmask & XINPUT_GAMEPAD_START > 0) {
      keysPressed.add(LogicalKeyboardKey.backquote);
    }
    if (keysPressed.isNotEmpty) {
      notifyListeners();
    }
  }
}

mixin XInputGamePad on MyGameFeatures {
  static const _raw = RawKeyUpEvent(data: RawKeyEventDataWindows());

  @override
  void update(double dt) {
    final controller = SettingsController().xInputGamePadController;
    if (controller.spaceHold) {
      controller.keysPressed.add(LogicalKeyboardKey.space);
    }
    onKeyEvent(_raw, controller.keysPressed);
    super.update(dt);
  }
}
