import 'dart:ui';

import 'package:flame/game.dart';

import 'renderer.dart';

mixin HasBatchRenderer on FlameGame {
  BatchComponentRenderer? batchRenderer;

  initBatchRenderer(int mapWidth, int mapHeight,
      {int offsetSteps = 0,
      int offsetShadowSteps = 0,
      Offset? offsetDirection,
      bool drawShadow = false}) {
    batchRenderer = BatchComponentRenderer(mapWidth.toInt(), mapHeight.toInt(),
        offsetSteps: offsetSteps,
        drawShadow: drawShadow,
        offsetShadowSteps: offsetShadowSteps,
        offsetDirection: offsetDirection);
    add(batchRenderer!);
  }
}
