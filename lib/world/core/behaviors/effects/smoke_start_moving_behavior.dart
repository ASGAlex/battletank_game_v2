import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'package:flame/particles.dart';
import 'package:flutter/material.dart';
import 'package:tank_game/world/core/actor.dart';
import 'package:tank_game/world/core/behaviors/core_behavior.dart';
import 'package:tank_game/world/core/direction.dart';

class SmokeStartMovingBehavior extends CoreBehavior<ActorMixin> {
  SmokeStartMovingBehavior(this.rootComponent);

  Component rootComponent;
  bool isEnabled = false;

  double _elapsed = 0;
  final _particlesPerTick = 4;
  static const _duration = 0.3;
  static const _speed = 1.0;
  static const _acceleration = 15.0;

  @override
  void update(double dt) {
    if (isEnabled) {
      if (_elapsed <= _duration) {
        final direction = parent.lookDirection.opposite;

        final r = Random();
        final w = parent.size.x.ceil();
        final h = parent.size.y.ceil();

        final positionLeft = parent.position.clone();
        final positionRight = parent.position.clone();
        final acceleration = Vector2.zero();
        final speed = Vector2.zero();
        final secondarySpeed = r.nextDouble() * 5 * (r.nextBool() ? -1 : 1);
        final secondaryAcceleration =
            r.nextDouble() * 15 * (r.nextBool() ? -1 : 1);
        switch (direction) {
          case DirectionExtended.left:
            positionLeft.translate(-w / 2, -w / 4);
            positionRight.translate(-w / 2, w / 4);
            acceleration.setValues(-_acceleration, secondaryAcceleration);
            speed.setValues(-r.nextDouble() * _speed, secondarySpeed);
            break;
          case DirectionExtended.right:
            positionLeft.translate(w / 2, -w / 4);
            positionRight.translate(w / 2, w / 4);
            acceleration.setValues(_acceleration, secondaryAcceleration);
            speed.setValues(r.nextDouble() * _speed, secondarySpeed);

            break;
          case DirectionExtended.up:
            positionLeft.translate(-w / 4, -w / 2);
            positionRight.translate(w / 4, -w / 2);
            acceleration.setValues(secondaryAcceleration, -_acceleration);
            speed.setValues(secondarySpeed, -r.nextDouble() * _speed);
            break;
          case DirectionExtended.down:
            positionLeft.translate(-w / 4, w / 2);
            positionRight.translate(w / 4, w / 2);
            acceleration.setValues(secondaryAcceleration, _acceleration);
            speed.setValues(secondarySpeed, r.nextDouble() * _speed);
            break;
        }

        for (var i = 0; i < _particlesPerTick; i++) {
          rootComponent.add(ParticleSystemComponent(
              position: positionLeft,
              particle: AcceleratedParticle(
                  acceleration: acceleration,
                  speed: speed,
                  child: ComputedParticle(
                      lifespan: 2,
                      renderer: (Canvas c, Particle particle) {
                        final paint = Paint()
                          ..color =
                              Color.fromRGBO(82, 82, 82, 1 - particle.progress);
                        c.drawCircle(
                            Offset.zero, particle.progress * w / 4, paint);
                      }))));

          rootComponent.add(ParticleSystemComponent(
              position: positionRight,
              particle: AcceleratedParticle(
                  acceleration: acceleration,
                  speed: speed,
                  child: ComputedParticle(
                      lifespan: 2,
                      renderer: (Canvas c, Particle particle) {
                        final paint = Paint()
                          ..color =
                              Color.fromRGBO(82, 82, 82, 1 - particle.progress);
                        c.drawCircle(
                            Offset.zero, particle.progress * w / 4, paint);
                      }))));
        }

        _elapsed += dt;
      } else {
        isEnabled = false;
        _elapsed = 0;
      }
    }
    super.update(dt);
  }
}
