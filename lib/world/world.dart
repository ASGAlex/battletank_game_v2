import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/experimental.dart';
import 'package:flame/extensions.dart';
import 'package:flame_spatial_grid/flame_spatial_grid.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' as material;
import 'package:tank_game/game.dart';
import 'package:tank_game/world/tank/player.dart';

enum RenderPriority {
  sky(25),
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

const distanceOfSuspendingSquared = 250.0 * 250;
const distanceOfSilenceSquared = 300.0 * 300;
const distanceOfViewSquared = 200.0 * 200;
const distanceOfRevealSquared = 30 * 30;

class GameWorld extends World with HasGameRef<MyGame> {
  final skyLayer = Component(priority: RenderPriority.sky.priority);
  final tankLayer = Component(priority: RenderPriority.player.priority);
  final bulletLayer = Component(priority: RenderPriority.bullet.priority);
  final spawnLayer = Component(priority: RenderPriority.spawn.priority);

  final fadeOutConfig = FadeOutConfig(
      transparencyPerStep: 0.05, fadeOutTimeout: const Duration(seconds: 2));
  final shadowsOpacity = 0.6;

  final shadowOffset = Vector2(-1.5, 1.5);

  addSky(Component component) {
    skyLayer.add(component);
  }

  addTank(Component component) {
    tankLayer.add(component);
    if (component is Player) {
      game.cameraComponent.follow(component, maxSpeed: 60);
    }
  }

  addBullet(Component component) {
    bulletLayer.add(component);
  }

  addSpawn(Component component) {
    spawnLayer.add(component);
  }

  @override
  Future<void>? onLoad() {
    final root = game.layersManager.layersRootComponent;
    add(skyLayer);
    root.add(tankLayer);
    root.add(bulletLayer);
    root.add(spawnLayer);
    return null;
  }

  @override
  void onTapDown(TapDownEvent event) {
    final tapPosition = event.localPosition;
    final cellsUnderCursor = <Cell>[];
    try {
      gameRef.spatialGrid.cells.forEach((rect, cell) {
        if (cell.rect.containsPoint(tapPosition)) {
          cellsUnderCursor.add(cell);
          print('State:  + ${cell.state}');
          print('Rect: $rect');
          final animations =
              cell.components.whereType<CellStaticAnimationLayer>();
          // animations.forEach((element) {
          //   element.compileToSingleLayer(element.children);
          // });
          // print('Components count: ${cell.components.length}');
        }
      });
    } catch (e) {}

    final list = componentsAtPoint(tapPosition).toList(growable: false);
    for (final component in list) {
      if (component is! HasGridSupport) continue;
      print(component.runtimeType);
    }

    // game.player?.position.setFrom(tapPosition);
    // addTank(
    //     Enemy(position: tapPosition)..currentCell = cellsUnderCursor.single);
  }

  Image createShadow(Vector2 size, void Function(Canvas) draw) {
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);
    final shadowPaint = Paint()
      ..isAntiAlias = false
      ..filterQuality = FilterQuality.none
      ..colorFilter = ColorFilter.mode(
          material.Colors.black.withOpacity(shadowsOpacity), BlendMode.srcIn);
    canvas.saveLayer(Rect.largest, shadowPaint);
    draw(canvas);
    return recorder.endRecording().toImageSync(size.x.toInt(), size.y.toInt());
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
  double health = 0;
  bool dead = false;

  @mustCallSuper
  takeDamage(double damage, Component from) {
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
