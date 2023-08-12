import 'dart:async';
import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame_spatial_grid/flame_spatial_grid.dart';
import 'package:flutter/material.dart';
import 'package:tank_game/game.dart';
import 'package:tank_game/world/core/behaviors/movement/movement_trail_behavior.dart';
import 'package:tank_game/world/core/direction.dart';

class TankStepTrailBehavior extends MovementTrailBehavior {
  TankStepTrailBehavior() : super(stepSize: 2);

  final topLeftRotated1 = <DirectionExtended, Vector2>{};
  final bottomRightRotated1 = <DirectionExtended, Vector2>{};

  final topLeftRotated2 = <DirectionExtended, Vector2>{};
  final bottomRightRotated2 = <DirectionExtended, Vector2>{};

  @override
  FutureOr<void> onLoad() {
    for (final possibleDirection in DirectionExtended.values) {
      final topLeft1 = TankStep.topLeftDefault.clone();
      final bottomRight1 = TankStep.bottomRightDefault.clone();

      final topLeft2 = TankStep.topLeftDefault.clone()
        ..translate(TankStep.distanceBetweenTracks, 0);
      final bottomRight2 = TankStep.bottomRightDefault.clone()
        ..translate(TankStep.distanceBetweenTracks, 0);

      switch (possibleDirection) {
        case DirectionExtended.up:
          break;
        case DirectionExtended.left:
          topLeft1.rotate(270 * pi / 180);
          bottomRight1.rotate(270 * pi / 180);

          topLeft2.rotate(270 * pi / 180);
          bottomRight2.rotate(270 * pi / 180);

          break;
        case DirectionExtended.down:
          topLeft1.rotate(180 * pi / 180);
          bottomRight1.rotate(180 * pi / 180);

          topLeft2.rotate(180 * pi / 180);
          bottomRight2.rotate(180 * pi / 180);

          break;
        case DirectionExtended.right:
          topLeft1.rotate(90 * pi / 180);
          bottomRight1.rotate(90 * pi / 180);

          topLeft2.rotate(90 * pi / 180);
          bottomRight2.rotate(90 * pi / 180);

          break;
      }
      topLeftRotated1[possibleDirection] = topLeft1;
      bottomRightRotated1[possibleDirection] = bottomRight1;

      topLeftRotated2[possibleDirection] = topLeft2;
      bottomRightRotated2[possibleDirection] = bottomRight2;
    }

    return super.onLoad();
  }

  @override
  void updateTrail(double innerSpeed) {
    final step = TankStep(this);
    try {
      final game = parent.sgGame;
      final layer = game.layersManager.addComponent(
        component: step,
        layerType: MapLayerType.trail,
        layerName: 'trail',
        optimizeCollisions: false,
        currentCell: parent.currentCell,
        priority: 1,
      );

      if (layer is CellTrailLayer && game is MyGame) {
        layer.fadeOutConfig = game.world.fadeOutConfig;
      }
    } catch (e) {}
  }
}

class TankStep extends PositionComponent with HasPaint {
  TankStep(this.behavior) {
    paint.color = Colors.black54;
    paint.strokeWidth = 1;
    paint.isAntiAlias = false;
    position.setFrom(behavior.parent.position);
    size = Vector2(16, 2);
  }

  static Vector2 topLeftDefault = Vector2(-6, 6);
  static Vector2 bottomRightDefault = Vector2(-1, 7);
  static double distanceBetweenTracks = 9 + bottomRightDefault.x;

  final TankStepTrailBehavior behavior;

  @override
  void render(Canvas canvas) {
    try {
      final trackTopLeft1 = behavior
          .topLeftRotated1[behavior.parent.data.lookDirection]!
          .toOffset();
      final trackBottomRight1 = behavior
          .bottomRightRotated1[behavior.parent.data.lookDirection]!
          .toOffset();
      final trackTopLeft2 = behavior
          .topLeftRotated2[behavior.parent.data.lookDirection]!
          .toOffset();
      final trackBottomRight2 = behavior
          .bottomRightRotated2[behavior.parent.data.lookDirection]!
          .toOffset();
      canvas.drawRect(Rect.fromPoints(trackTopLeft1, trackBottomRight1), paint);
      canvas.drawRect(Rect.fromPoints(trackTopLeft2, trackBottomRight2), paint);
    } catch (_) {}
  }
}
