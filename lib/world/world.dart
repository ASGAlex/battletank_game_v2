import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/extensions.dart';
import 'package:flame_spatial_grid/flame_spatial_grid.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' as material;
import 'package:tank_game/game.dart';

enum RenderPriority {
  sky(25),
  walls(20),
  tree(15),
  shadows(11),
  player(10),
  bullet(9),
  water(5),
  spawn(3),
  trackTrail(2),
  ground(0),
  ui(100);

  final int priority;

  const RenderPriority(this.priority);
}

class GameWorld extends World with HasGameRef<MyGame> {
  final skyLayer = Component(priority: RenderPriority.sky.priority);
  final tankLayer = Component(priority: RenderPriority.player.priority);
  final bulletLayer = Component(priority: RenderPriority.bullet.priority);
  final spawnLayer = Component(priority: RenderPriority.spawn.priority);
  final scenarioLayer = Component(priority: RenderPriority.sky.priority);
  final scriptLayer = Component(priority: RenderPriority.sky.priority);

  final fadeOutConfig = FadeOutConfig(
    transparencyPerStep: 0.2,
    fadeOutTimeout: const Duration(seconds: 8),
  );
  final shadowsOpacity = 0.6;

  final shadowOffset = Vector2(-1.5, 1.5);

  addSky(Component component) {
    skyLayer.add(component);
  }

  addTank(Component component) {
    tankLayer.add(component);
  }

  addBullet(Component component) {
    bulletLayer.add(component);
  }

  addSpawn(Component component) {
    spawnLayer.add(component);
  }

  addScenario(Component component) {
    scenarioLayer.add(component);
  }

  @override
  Future<void>? onLoad() {
    add(skyLayer);
    add(tankLayer);
    add(bulletLayer);
    add(spawnLayer);
    add(scenarioLayer);
    return null;
  }

  @override
  void onTapDown(TapDownEvent event) {
    final tapPosition = event.localPosition;
    final cellsUnderCursor = <Cell>[];
    try {
      print(gameRef.spatialGrid.cells.length);
      // gameRef.spatialGrid.cells.forEach((rect, cell) {
      //   if (cell.rect.containsPoint(tapPosition)) {
      //     cellsUnderCursor.add(cell);
      //     print('State:  + ${cell.state}');
      //     print('Rect: $rect');
      //     print('Out of bounds: ${cell.outOfBoundsCounter}');
      //
      //     final l = (game)
      //         .layersManager
      //         .getLayer(name: 'static-ground-procedural', cell: cell);
      //     print(l);
      //     // final animations =
      //     //     cell.components.whereType<CellStaticAnimationLayer>();
      //     // animations.forEach((element) {
      //     //   element.compileToSingleLayer(element.children);
      //     // });
      //     // print('Components count: ${cell.components.length}');
      //   }
      // });
    } catch (e) {
      print(e);
    }
    //
    final list = componentsAtPoint(tapPosition).toList(growable: false);
    for (final component in list) {
      if (component is! HasGridSupport) continue;
      if (component is CellLayer) {
        print(component.name);
      } else {
        print(component.runtimeType);
      }
    }

    event.handled = true;

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
