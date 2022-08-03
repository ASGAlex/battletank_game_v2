import 'dart:math';

import 'package:flame/components.dart';

class MyJoystick extends JoystickComponent {
  MyJoystick({
    super.knob,
    super.background,
    super.margin,
    super.position,
    super.size,
    super.knobRadius,
    super.anchor,
    super.children,
    super.priority,
  });

  var _knobAngleDegrees = 0.0;

  double get knobAngleDegrees => _knobAngleDegrees;

  @override
  void update(double dt) {
    super.update(dt);
    var sa = delta.screenAngle();
    sa = sa < 0 ? 2 * pi + sa : sa;
    _knobAngleDegrees = sa * (180 / pi);
  }
}
