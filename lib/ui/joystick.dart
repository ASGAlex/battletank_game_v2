import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/events.dart';

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

  /// The total amount the knob is dragged from the center of the joystick.
  final Vector2 _unscaledDelta = Vector2.zero();

  /// The position where the knob rests.
  late Vector2 _baseKnobPosition;

  late final knobRadius2;

  void onMount() {
    super.onMount();
    _baseKnobPosition = knob!.position.clone();
  }

  @override
  Future<void> onLoad() {
    knobRadius2 = knobRadius * knobRadius;
    return super.onLoad();
  }

  @override
  void update(double dt) {
    if (_unscaledDelta.isZero() && _baseKnobPosition != knob!.position) {
      knob!.position = _baseKnobPosition;
    } else {
      delta.setFrom(_unscaledDelta);
      if (delta.length2 > knobRadius2) {
        delta.scaleTo(knobRadius);
      }
      final newPos = _baseKnobPosition.clone();
      newPos.add(delta);
      if (newPos.distanceToSquared(knob!.position) > 100) {
        knob!.position = newPos;
      }
      intensity = delta.length2 / knobRadius2;
      var sa = delta.screenAngle();
      sa = sa < 0 ? 2 * pi + sa : sa;
      _knobAngleDegrees = sa * (180 / pi);
    }
  }

  @override
  bool onDragStart(DragStartInfo info) {
    return false;
  }

  @override
  bool onDragUpdate(DragUpdateInfo info) {
    _unscaledDelta.add(info.delta.global);
    return false;
  }

  @override
  bool onDragCancel() {
    _unscaledDelta.setZero();
    knob!.position = _baseKnobPosition;
    return false;
  }
}
