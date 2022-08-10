import 'dart:io';
import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flame/sprite.dart';
import 'package:flutter/painting.dart';

import '../../../game.dart';
import '../../../world/world.dart';

mixin MyJoystickMix on MyGameFeatures {
  MyJoystick? joystick;

  initJoystick([VoidCallback? playerFire]) async {
    final image = await images.load('joystick.png');
    final sheet = SpriteSheet.fromColumnsAndRows(
      image: image,
      columns: 6,
      rows: 1,
    );
    if (Platform.isAndroid || Platform.isIOS) {
      joystick = MyJoystick(
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
      add(HudButtonComponent(
          button: SpriteComponent(
              sprite: sheet.getSpriteById(3), size: Vector2.all(60))
            ..add(OpacityEffect.to(0.5, EffectController(duration: 0))),
          buttonDown: SpriteComponent(
              sprite: sheet.getSpriteById(5), size: Vector2.all(60)),
          onPressed: playerFire,
          priority: RenderPriority.ui.priority,
          margin: const EdgeInsets.only(bottom: 40, right: 20)));
      add(joystick!);

      joystick?.background
          ?.add(OpacityEffect.to(0.5, EffectController(duration: 0)));
      joystick?.knob?.add(OpacityEffect.to(0.8, EffectController(duration: 0)));
    }
  }

  @override
  void onDragStart(int pointerId, DragStartInfo info) {
    joystick?.handleDragStart(pointerId, info);
  }

  @override
  void onDragUpdate(int pointerId, DragUpdateInfo info) {
    joystick?.handleDragUpdated(pointerId, info);
  }

  @override
  void onDragEnd(int pointerId, DragEndInfo info) {
    joystick?.handleDragEnded(pointerId, info);
  }

  @override
  void onDragCancel(int pointerId) {
    joystick?.handleDragCanceled(pointerId);
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
  });

  var _knobAngleDegrees = 0.0;

  double get knobAngleDegrees => _knobAngleDegrees;

  /// The total amount the knob is dragged from the center of the joystick.
  final Vector2 _unscaledDelta = Vector2.zero();

  /// The position where the knob rests.
  late Vector2 _baseKnobPosition;

  late final knobRadius2;

  @override
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
