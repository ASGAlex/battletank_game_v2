import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/material.dart' as material;

class TreeLayer extends PositionComponent {
  TreeLayer(this.trees, int width, int height) {
    Color color = material.Colors.black;
    final shadowPaint = Paint()
      ..colorFilter = ColorFilter.mode(color.withOpacity(0.4), BlendMode.srcIn);
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);

    canvas.saveLayer(Rect.largest, shadowPaint);
    canvas.translate(-3, 3);
    trees.render(canvas);
    canvas.restore();
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
