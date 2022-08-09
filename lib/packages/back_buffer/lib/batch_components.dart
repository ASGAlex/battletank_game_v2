import 'dart:collection';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/sprite.dart';
import 'package:flutter/material.dart' as material;

mixin BatchRender on SpriteComponent {
  @override
  void renderTree(Canvas canvas) {}

  bool _treeInitiallyUpdated = false;

  @override
  void updateTree(double dt) {
    if (!_treeInitiallyUpdated) {
      super.updateTree(dt);
      _treeInitiallyUpdated = true;
    }
  }

  scheduleTreeUpdate() => _treeInitiallyUpdated = false;

  Rect get sourceRect => sprite!.src;

  Vector2 get offsetPosition => position;
}

class BatchComponentRenderer extends PositionComponent {
  BatchComponentRenderer(this.mapWidth, this.mapHeight,
      {this.offsetSteps = 0,
      this.offsetShadowSteps = 0,
      this.offsetDirection,
      this.drawShadow = false});

  Offset? offsetDirection;
  int offsetSteps;
  int offsetShadowSteps;
  bool drawShadow;
  int mapWidth;
  int mapHeight;
  final batchedComponents = HashSet<BatchRender>();

  bool imageChanged = true;
  Image? spriteSheetImg;
  Picture? _picture;

  bool get renderWithOffset => (offsetSteps > 0 && offsetDirection != null);

  @override
  render(Canvas canvas) async {
    if (_picture == null || (imageChanged)) {
      SpriteBatch? batch;
      for (final brick in batchedComponents) {
        spriteSheetImg ??= brick.sprite?.image;
        if (spriteSheetImg == null) throw 'SpriteSheet not loaded';
        batch ??= SpriteBatch(spriteSheetImg!);
        batch.add(source: brick.sourceRect, offset: brick.offsetPosition);
      }
      final component = SpriteBatchComponent(spriteBatch: batch);
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      if (renderWithOffset) {
        _renderWithOffset(canvas, component);
      } else {
        component.render(canvas);
      }
      _picture = recorder.endRecording();

      imageChanged = false;
    }

    if (_picture != null) {
      canvas.drawPicture(_picture!);
    }
  }

  _renderWithOffset(Canvas canvas, SpriteBatchComponent component) {
    if (offsetSteps > 0 && offsetDirection != null) {
      if (drawShadow) {
        final paintShadow = Paint();
        paintShadow.colorFilter = ColorFilter.mode(
            material.Colors.black.withOpacity(0.3), BlendMode.srcIn);
        var lastOffset = const Offset(0, 0);
        canvas.saveLayer(Rect.largest, paintShadow);
        for (var i = 0; i < offsetShadowSteps; i++) {
          lastOffset = lastOffset.translate(
              -(offsetDirection!.dx), -(offsetDirection!.dy));
          canvas.translate(-(offsetDirection!.dx), -(offsetDirection!.dy));
          component.render(canvas);
        }
        canvas.restore();
      }

      final paintWalls = Paint();
      paintWalls.colorFilter = ColorFilter.mode(
          material.Colors.black.withOpacity(0.4), BlendMode.srcATop);
      var lastOffset = const Offset(0, 0);
      canvas.saveLayer(Rect.largest, paintWalls);
      component.render(canvas);
      for (var i = 0; i < offsetSteps - 1; i++) {
        lastOffset =
            lastOffset.translate(offsetDirection!.dx, offsetDirection!.dy);
        canvas.translate(offsetDirection!.dx, offsetDirection!.dy);
        component.render(canvas);
      }

      canvas.restore();

      lastOffset =
          lastOffset.translate(offsetDirection!.dx, offsetDirection!.dy);
      canvas.saveLayer(Rect.largest, Paint());
      canvas.translate(lastOffset.dx, lastOffset.dy);
      component.render(canvas);
      canvas.restore();
    }
  }
}
