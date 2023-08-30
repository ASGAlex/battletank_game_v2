import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'package:flame/particles.dart';
import 'package:flutter/material.dart';
import 'package:tank_game/world/core/actor.dart';
import 'package:tank_game/world/core/behaviors/core_behavior.dart';

class SmokeBehavior extends CoreBehavior<ActorMixin> {
  SmokeBehavior(
    this.rootComponent, {
    this.color,
    this.particlePriority = 0,
    this.nextParticleFrequency = 0.15,
  });

  Component rootComponent;
  bool isEnabled = false;

  Color? color;
  int particlePriority;

  double _nextSmokeParticle = 0;
  double nextParticleFrequency;

  @override
  void update(double dt) {
    if (isEnabled) {
      if (_nextSmokeParticle <= 0) {
        final r = Random();
        final w = parent.size.x.ceil();
        final h = parent.size.y.ceil();
        final newPos = parent.position.clone()
          ..translate(
              w / 2 - r.nextInt(w).toDouble(), h / 2 - r.nextInt(h).toDouble());
        rootComponent.add(ParticleSystemComponent(
            priority: particlePriority,
            position: newPos,
            particle: AcceleratedParticle(
                acceleration:
                    Vector2(r.nextDouble() * 15, -r.nextDouble() * 15),
                speed: Vector2(r.nextDouble() * 30, -r.nextDouble() * 30),
                child: ComputedParticle(
                    lifespan: 5,
                    renderer: (Canvas c, Particle particle) {
                      final opacity = 1 - particle.progress;
                      final paint = Paint()
                        ..color = color?.withOpacity(opacity) ??
                            Colors.grey.withOpacity(opacity);
                      c.drawCircle(
                          Offset.zero, particle.progress * w / 2, paint);
                    }))));
        _nextSmokeParticle = nextParticleFrequency;
      } else {
        _nextSmokeParticle -= dt;
      }
    }
    super.update(dt);
  }
}
