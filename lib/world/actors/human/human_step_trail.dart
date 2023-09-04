import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame_spatial_grid/flame_spatial_grid.dart';
import 'package:flutter/material.dart';
import 'package:tank_game/game.dart';
import 'package:tank_game/world/core/behaviors/movement/movement_trail_behavior.dart';

class HumanStepTrailBehavior extends MovementTrailBehavior {
  HumanStepTrailBehavior() : super(stepSize: 4);

  @override
  void updateTrail(double innerSpeed) {
    final step = HumanStep(parent.position);
    try {
      final game = parent.sgGame;
      final layer = game.layersManager.addComponent(
        component: step,
        layerType: MapLayerType.trail,
        layerName: 'trail',
        optimizeCollisions: false,
        currentCell: parent.currentCell!,
        priority: 1,
      );

      if (layer is CellTrailLayer && game is MyGame) {
        layer.fadeOutConfig = game.world.fadeOutConfig;
      }
    } catch (e) {}
  }
}

class HumanStep extends PositionComponent with HasPaint {
  HumanStep(Vector2 parentPosition) {
    paint.color = Colors.black54;
    paint.strokeWidth = 1;
    paint.isAntiAlias = false;
    // final cell = human.currentCell;
    // if (cell != null) {
    position = parentPosition;
    size = Vector2(5, 5);
    // currentCell = cell;
    // }
  }

  @override
  void render(Canvas canvas) {
    canvas.drawPoints(
      PointMode.points,
      [
        const Offset(0, 0),
      ],
      paint,
    );
  }
}
