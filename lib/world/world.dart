import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';

enum RenderPriority {
  tree(12),
  bullet(11),
  player(10),
  water(9),
  trackTrail(5),
  spawn(1),
  ground(0);

  final int priority;

  const RenderPriority(this.priority);
}

const distantOfSilence = 700.0;

mixin ObjectLayers on FlameGame {
  final _tankLayer = Component(priority: RenderPriority.player.priority);
  final _bulletLayer = Component(priority: RenderPriority.bullet.priority);
  final _spawnLayer = Component(priority: RenderPriority.spawn.priority);
  final _trackLayer = Component(priority: RenderPriority.trackTrail.priority);

  addTank(Component component) {
    _tankLayer.add(component);
  }

  addBullet(Component component) {
    _bulletLayer.add(component);
  }

  addSpawn(Component component) {
    _spawnLayer.add(component);
  }

  addTrack(Component component) {
    _trackLayer.add(component);
  }

  @override
  Future<void>? onLoad() {
    add(_tankLayer);
    add(_bulletLayer);
    add(_spawnLayer);
    add(_trackLayer);
    return null;
  }
}

mixin DebugRender on Component {
  bool debug = false;

  @override
  void render(Canvas canvas) {
    if (debug) {
      renderDebugMode(canvas);
    }
    super.render(canvas);
  }
}

mixin HideableComponent on Component {
  bool _hidden = false;

  bool get hidden => _hidden;
  set hidden(bool value) {
    _hidden = value;
    onHiddenChange(hidden);
  }

  void onHiddenChange(bool hidden) {}

  @override
  void render(Canvas canvas) {
    if (!hidden) {
      super.render(canvas);
    }
  }
}

mixin DestroyableComponent on PositionComponent {
  int health = 0;
  bool dead = false;

  @mustCallSuper
  takeDamage(int damage) {
    health -= damage;
    if (health <= 0) {
      onDeath();
    }
  }

  @mustCallSuper
  onDeath() {
    dead = true;
  }
}
