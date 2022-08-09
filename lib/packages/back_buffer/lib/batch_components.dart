import 'dart:collection';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/sprite.dart';

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
}

class BatchComponentRenderer extends PositionComponent {
  BatchComponentRenderer(this.mapWidth, this.mapHeight);

  int mapWidth;
  int mapHeight;
  final batchedComponents = HashSet<BatchRender>();

  bool imageChanged = true;
  Image? spriteSheetImg;
  Picture? _picture;

  @override
  render(Canvas canvas) async {
    if (_picture == null || (imageChanged)) {
      SpriteBatch? batch;
      for (final brick in batchedComponents) {
        spriteSheetImg ??= brick.sprite?.image;
        if (spriteSheetImg == null) throw 'SpriteSheet not loaded';
        batch ??= SpriteBatch(spriteSheetImg!);

        var source = brick.sprite!.src;
        if (brick.size.x < 8) {
          source = Rect.fromLTWH(
              source.left, source.top, brick.size.x, source.height);
        }
        if (brick.size.y < 8) {
          source = Rect.fromLTWH(
              source.left, source.top, source.width, brick.size.y);
        }
        batch.add(source: source, offset: brick.position);
      }
      final component = SpriteBatchComponent(spriteBatch: batch);
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      component.render(canvas);
      _picture = recorder.endRecording();

      imageChanged = false;
    }

    if (_picture != null) {
      canvas.drawPicture(_picture!);
    }
  }
}
