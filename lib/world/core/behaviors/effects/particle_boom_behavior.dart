import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'package:flame/particles.dart';
import 'package:flutter/material.dart';
import 'package:tank_game/world/core/actor.dart';
import 'package:tank_game/world/core/behaviors/core_behavior.dart';

class ParticleBoomBehavior extends CoreBehavior<ActorMixin> {
  ParticleBoomBehavior(this.rootComponent, this.position);

  Component rootComponent;
  final Vector2 position;
  bool isEnabled = false;

  int particlesPerBoom = 3;
  double _nextBoomParticle = 0;
  static const _nextBoomParticleMax = 0.4;

  @override
  void update(double dt) {
    if (isEnabled) {
      if (_nextBoomParticle <= 0) {
        for (int i = 0; i < particlesPerBoom; i++) {
          final r = Random();
          final w = parent.size.x.ceil();
          final h = parent.size.y.ceil();
          final newPos = position.clone()
            ..translate(
                w - r.nextInt(w).toDouble(), h - r.nextInt(h).toDouble());
          rootComponent.add(ParticleSystemComponent(
              position: newPos,
              particle: ComputedParticle(
                  lifespan: 0.4,
                  renderer: (Canvas c, Particle particle) {
                    final paint = Paint()
                      ..color = Colors.red.withOpacity(1 - particle.progress);
                    c.drawCircle(Offset.zero, particle.progress * w, paint);
                  })));
        }
        _nextBoomParticle = _nextBoomParticleMax;
      } else {
        _nextBoomParticle -= dt;
      }
    }
    super.update(dt);
  }
}
