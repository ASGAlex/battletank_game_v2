import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'package:flame/particles.dart';
import 'package:flutter/material.dart';

class SmokeComponent extends PositionComponent {
  SmokeComponent(
    this.rootComponent, {
    this.parentSize,
    this.parentPosition,
    this.sizeAndPositionProvider,
    this.color,
    this.particlePriority = 0,
    this.nextParticleFrequency = 0.15,
  }) : assert((parentSize != null && parentPosition != null) ||
            sizeAndPositionProvider != null);

  Component rootComponent;
  bool isEnabled = false;
  final Vector2? parentSize;
  final Vector2? parentPosition;
  final PositionComponent? sizeAndPositionProvider;

  Color? color;
  int particlePriority;

  double _nextSmokeParticle = 0;
  double nextParticleFrequency;

  Vector2 get _parentSize {
    if (parentSize != null) {
      return parentSize!;
    } else if (sizeAndPositionProvider != null) {
      return sizeAndPositionProvider!.size;
    }
    throw 'Cant get parent size';
  }

  Vector2 get _parentPosition {
    if (parentPosition != null) {
      return parentPosition!;
    } else if (sizeAndPositionProvider != null) {
      return sizeAndPositionProvider!.position;
    }
    throw 'Cant get parent position';
  }

  @override
  void update(double dt) {
    if (isEnabled) {
      if (_nextSmokeParticle <= 0) {
        final r = Random();
        final w = _parentSize.x.ceil();
        final h = _parentSize.y.ceil();
        final newPos = _parentPosition.translated(
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
