// import 'dart:math';
//
// import 'package:flame/components.dart';
// import 'package:flame/effects.dart';
// import 'package:flame/input.dart';
// import 'package:flame/sprite.dart';
// import 'package:flutter/painting.dart';
//
// import '../../../game.dart';
// import '../../../world/world.dart';
//

import 'dart:async';
import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/events.dart';
import 'package:flame/input.dart';
import 'package:flame/sprite.dart';
import 'package:flutter/material.dart';
import 'package:tank_game/game.dart';
import 'package:tank_game/world/world.dart';

mixin MyJoystickMix on MyGameFeatures {
  MyJoystick? joystick;
  HudButtonComponent? hudButton;

  initJoystick(Component rootComponent) async {
    final image = await images.load('joystick.png');
    final sheet = SpriteSheet.fromColumnsAndRows(
      image: image,
      columns: 6,
      rows: 1,
    );
    joystick = MyJoystick(
      onUpdate: inputEventsHandler.onJoystickEvent,
      priority: RenderPriority.ui.priority,
      knob: SpriteComponent(
        sprite: sheet.getSpriteById(1),
        size: Vector2.all(40),
      ),
      background: SpriteComponent(
        sprite: sheet.getSpriteById(0),
        size: Vector2.all(90),
      ),
      margin: const EdgeInsets.only(left: 20, bottom: 40),
    );
    hudButton = HudButtonComponent(
        button: SpriteComponent(
            sprite: sheet.getSpriteById(3), size: Vector2.all(60))
          ..add(OpacityEffect.to(0.5, EffectController(duration: 0))),
        buttonDown: SpriteComponent(
            sprite: sheet.getSpriteById(5), size: Vector2.all(60)),
        onPressed: inputEventsHandler.onFireEvent,
        priority: RenderPriority.ui.priority,
        margin: const EdgeInsets.only(bottom: 40, right: 20));

    rootComponent.add(joystick!);
    rootComponent.add(hudButton!);

    joystick?.background
        ?.add(OpacityEffect.to(0.5, EffectController(duration: 0)));
    joystick?.knob?.add(OpacityEffect.to(0.8, EffectController(duration: 0)));
  }
}

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
    required this.onUpdate,
  });

  var _knobAngleDegrees = 0.0;

  double get knobAngleDegrees => _knobAngleDegrees;

  /// The total amount the knob is dragged from the center of the joystick.
  final Vector2 _unscaledDelta = Vector2.zero();

  /// The position where the knob rests.
  late Vector2 _baseKnobPosition;

  late final knobRadius2;

  final Function(double angle) onUpdate;

  @override
  void onMount() {
    super.onMount();
    _baseKnobPosition = knob!.position.clone();
  }

  @override
  FutureOr<void> onLoad() {
    knobRadius2 = knobRadius * knobRadius;
    return super.onLoad();
  }

  @override
  void update(double dt) {
    super.update(dt);
    var sa = delta.screenAngle();
    sa = sa < 0 ? 2 * pi + sa : sa;
    _knobAngleDegrees = sa * (180 / pi);
    onUpdate(_knobAngleDegrees);
  }

  @override
  bool onDragCancel(DragCancelEvent event) {
    super.onDragCancel(event);
    knob!.position = _baseKnobPosition;
    return false;
  }
}
