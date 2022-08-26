import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/material.dart' as material;
import 'package:tank_game/packages/flame_clusterizer/lib/clusterized_component.dart';
import 'package:tank_game/services/settings/controller.dart';

class TreeLayer extends PositionComponent with ClusterizedComponent {
  TreeLayer(this.trees, int width, int height) {
    Color color = material.Colors.black;
    final shadowPaint = Paint()
      ..colorFilter = ColorFilter.mode(color.withOpacity(0.4), BlendMode.srcIn);
    shadowPaint.imageFilter = ImageFilter.blur(sigmaX: 1, sigmaY: 1);
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);
    final settings = SettingsController();
    if (settings.graphicsQuality != GraphicsQuality.low) {
      canvas.saveLayer(Rect.largest, shadowPaint);
      canvas.translate(-3, 3);
      trees.render(canvas);
      canvas.restore();
    }
    trees.render(canvas);
    recorder.endRecording().toImage(width, height).then((value) {
      image = value;
    });
  }

  Image? image;
  final PositionComponent trees;

  @override
  void render(Canvas canvas) {
    if (image == null) {
      trees.render(canvas);
    } else {
      canvas.drawImage(image!, const Offset(0, 0), Paint());
    }
  }
}
