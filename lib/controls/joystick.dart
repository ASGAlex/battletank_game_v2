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

import 'dart:math';

import 'package:flame/components.dart'
    hide JoystickComponent, JoystickDirection;
import 'package:flame/effects.dart';
import 'package:flame/events.dart';
import 'package:flame/sprite.dart';
import 'package:flutter/material.dart';
import 'package:tank_game/controls/input_events_handler.dart';
import 'package:tank_game/game.dart';
import 'package:tank_game/packages/flame_override/lib/flame_override.dart';
import 'package:tank_game/packages/flame_override/lib/src/extensoins.dart';
import 'package:tank_game/world/world.dart';

mixin MyJoystickMix on MyGameFeatures {
  initJoystick(Component rootComponent) async {
    final image = await images.load('joystick.png');
    final sheet = SpriteSheet.fromColumnsAndRows(
      image: image,
      columns: 6,
      rows: 1,
    );
    final joystick = MyJoystick(
      onUpdate: inputEventsHandler.onJoystickMoveEvent,
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

    joystick.background
        ?.add(OpacityEffect.to(0.5, EffectController(duration: 0)));
    joystick.knob?.add(OpacityEffect.to(0.8, EffectController(duration: 0)));

    final fireButton = HudButtonComponent(
        button: SpriteComponent(
            sprite: sheet.getSpriteById(3), size: Vector2.all(100))
          ..add(OpacityEffect.to(0.5, EffectController(duration: 0))),
        buttonDown: SpriteComponent(
            sprite: sheet.getSpriteById(5), size: Vector2.all(100)),
        onPressed: () =>
            inputEventsHandler.onJoystickButtonEvent(PlayerAction.fire),
        onReleased: () =>
            inputEventsHandler.onJoystickButtonReleaseEvent(PlayerAction.fire),
        priority: RenderPriority.ui.priority,
        margin: const EdgeInsets.only(bottom: 40, right: 20));

    final primaryActionButton = HudButtonComponent(
        button: SpriteComponent(
            sprite: sheet.getSpriteById(2), size: Vector2.all(50))
          ..add(OpacityEffect.to(0.5, EffectController(duration: 0))),
        buttonDown: SpriteComponent(
            sprite: sheet.getSpriteById(4), size: Vector2.all(50)),
        onPressed: () =>
            inputEventsHandler.onJoystickButtonEvent(PlayerAction.triggerE),
        onReleased: () => inputEventsHandler
            .onJoystickButtonReleaseEvent(PlayerAction.triggerE),
        priority: RenderPriority.ui.priority,
        margin: const EdgeInsets.only(bottom: 40, right: 120));

    final secondaryActionButton = HudButtonComponent(
        button: SpriteComponent(
            sprite: sheet.getSpriteById(2), size: Vector2.all(40))
          ..add(OpacityEffect.to(0.5, EffectController(duration: 0)))
          ..add(ColorEffect(
              const Color.fromRGBO(119, 0, 255, 1.0),
              const Offset(1, 1),
              InfiniteEffectController(EffectController(duration: 100)))),
        buttonDown: SpriteComponent(
            sprite: sheet.getSpriteById(4), size: Vector2.all(40)),
        onPressed: () =>
            inputEventsHandler.onJoystickButtonEvent(PlayerAction.triggerF),
        onReleased: () => inputEventsHandler
            .onJoystickButtonReleaseEvent(PlayerAction.triggerF),
        priority: RenderPriority.ui.priority,
        margin: const EdgeInsets.only(top: 40, right: 40));

    rootComponent.add(joystick);
    rootComponent.add(fireButton);
    rootComponent.add(primaryActionButton);
    rootComponent.add(secondaryActionButton);
  }
}

class MyJoystick extends JoystickComponent with ScreenPointOnComponentCached {
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

  /// The position where the knob rests.
  late Vector2 _baseKnobPosition;

  final Function(double angle) onUpdate;

  @override
  void onMount() {
    super.onMount();
    _baseKnobPosition = knob!.position.clone();
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
