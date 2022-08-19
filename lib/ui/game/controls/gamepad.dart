import 'package:flutter/services.dart';
import 'package:tank_game/game.dart';
import 'package:win32/win32.dart';
import 'package:xinput_gamepad/xinput_gamepad.dart';

mixin XInputGamePad on MyGameFeatures {
  late final Controller xinputController;
  var spaceHold = false;

  static const _raw = RawKeyUpEvent(data: RawKeyEventDataWindows());
  final _keysPressed = <LogicalKeyboardKey>{};

  initXInputGamePad() {
    XInputManager.enableXInput();
    xinputController = Controller(
        index: 0,
        onRawButtonEvent: onRawButtonEvent,
        leftVibrationSpeed: 65535,
        rightVibrationSpeed: 65535);
    xinputController.listen();
  }

  @override
  void update(double dt) {
    if (spaceHold) {
      _keysPressed.add(LogicalKeyboardKey.space);
      onKeyEvent(_raw, _keysPressed);
    }
    super.update(dt);
  }

  onRawButtonEvent(int bitmask) {
    _keysPressed.clear();
    if (bitmask & XINPUT_GAMEPAD_DPAD_UP > 0) {
      _keysPressed.add(LogicalKeyboardKey.keyW);
    } else if (bitmask & XINPUT_GAMEPAD_DPAD_DOWN > 0) {
      _keysPressed.add(LogicalKeyboardKey.keyS);
    } else if (bitmask & XINPUT_GAMEPAD_DPAD_LEFT > 0) {
      _keysPressed.add(LogicalKeyboardKey.keyA);
    } else if (bitmask & XINPUT_GAMEPAD_DPAD_RIGHT > 0) {
      _keysPressed.add(LogicalKeyboardKey.keyD);
    }

    if (bitmask & (XINPUT_GAMEPAD_X | XINPUT_GAMEPAD_RIGHT_SHOULDER) > 0) {
      _keysPressed.add(LogicalKeyboardKey.space);
      spaceHold = true;
    } else {
      spaceHold = false;
    }
    if (bitmask & XINPUT_GAMEPAD_BACK > 0) {
      _keysPressed.add(LogicalKeyboardKey.escape);
    }
    if (bitmask & XINPUT_GAMEPAD_START > 0) {
      _keysPressed.add(LogicalKeyboardKey.backquote);
    }
    onKeyEvent(_raw, _keysPressed);
  }
}
