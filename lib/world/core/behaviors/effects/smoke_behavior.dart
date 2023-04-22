import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'package:flame/particles.dart';
import 'package:flutter/material.dart';
import 'package:tank_game/extensions.dart';
import 'package:tank_game/world/core/actor.dart';
import 'package:tank_game/world/core/behaviors/core_behavior.dart';

class SmokeBehavior extends CoreBehavior<ActorMixin> {
  SmokeBehavior(this.rootComponent);

  Component rootComponent;
  bool isEnabled = false;

  double _nextSmokeParticle = 0;
  static const _nextSmokeParticleMax = 0.15;

  @override
  void update(double dt) {
    if (isEnabled) {
      if (_nextSmokeParticle <= 0) {
        final r = Random();
        final w = parent.size.x.ceil();
        final h = parent.size.y.ceil();
        final newPos = parent.position.translate(
            w / 2 - r.nextInt(w).toDouble(), h / 2 - r.nextInt(h).toDouble());
        rootComponent.add(ParticleSystemComponent(
            position: newPos,
            particle: AcceleratedParticle(
                acceleration:
                    Vector2(r.nextDouble() * 15, -r.nextDouble() * 15),
                speed: Vector2(r.nextDouble() * 30, -r.nextDouble() * 30),
                child: ComputedParticle(
                    lifespan: 5,
                    renderer: (Canvas c, Particle particle) {
                      final paint = Paint()
                        ..color =
                            Colors.grey.withOpacity(1 - particle.progress);
                      c.drawCircle(
                          Offset.zero, particle.progress * w / 2, paint);
                    }))));
        _nextSmokeParticle = _nextSmokeParticleMax;
      } else {
        _nextSmokeParticle -= dt;
      }
    }
    super.update(dt);
  }
}
