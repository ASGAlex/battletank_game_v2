import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:tank_game/game.dart';

enum RenderPriority {
  walls(20),
  tree(15),
  bullet(12),
  player(10),
  water(9),
  spawn(5),
  trackTrail(1),
  ground(0),
  ui(100);

  final int priority;

  const RenderPriority(this.priority);
}

const distanceOfSilence = 300.0;
const distanceOfView = 200.0;
const distanceOfReveal = 30;

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

mixin MyGameRef on Component {
  MyGame? _gameRef;

  MyGame get game => _gameRef!;

  @override
  Future<void>? onLoad() {
    _gameRef = findParent<MyGame>();
    return super.onLoad();
  }
}

mixin DestroyableComponent on PositionComponent {
  int health = 0;
  bool dead = false;

  @mustCallSuper
  takeDamage(int damage, Component from) {
    health -= damage;
    if (health <= 0) {
      onDeath(from);
    }
  }

  @mustCallSuper
  onDeath(Component killedBy) {
    dead = true;
  }
}

class StaticCollision extends RectangleHitbox {
  StaticCollision(RectangleHitbox collision) {
    position = collision.position;
    size = collision.size;
    angle = collision.angle;
    anchor = collision.anchor;
    priority = collision.priority;
    shouldFillParent = collision.shouldFillParent;
    collisionType = collision.collisionType;
  }

  Vector2? _cachedCenter;

  Vector2 get collisionCenter {
    _cachedCenter ??= aabb.center;
    return _cachedCenter!;
  }
}
