import 'dart:async';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame_tiled/flame_tiled.dart';
import 'package:tiled/tiled.dart';

class ImageBatchCompiler {
  Future<List<ImageComponent>> compileMapLayer(
      {required RenderableTiledMap tileMap, List<String>? layerNames}) async {
    layerNames ??= [];
    _unlistedLayers(tileMap, layerNames).forEach((element) {
      element.visible = false;
    });
    for (var rl in tileMap.renderableLayers) {
      rl.refreshCache();
    }

    var recorder = PictureRecorder();
    var canvas = Canvas(recorder);
    tileMap.render(canvas);
    final picture = recorder.endRecording();

    _unlistedLayers(tileMap, layerNames).forEach((element) {
      element.visible = true;
    });
    for (var rl in tileMap.renderableLayers) {
      rl.refreshCache();
    }

    final image = await picture.toImage(
        tileMap.map.width * tileMap.map.tileWidth,
        tileMap.map.height * tileMap.map.tileHeight);

    double fragmentWidth = image.width.toDouble();
    double fragmentHeight = image.height.toDouble();
    while (fragmentWidth > 200) {
      fragmentWidth = fragmentWidth / 2;
    }
    while (fragmentHeight > 200) {
      fragmentHeight = fragmentHeight / 2;
    }

    final componentList = <ImageComponent>[];
    final totalColumns = image.width / fragmentWidth;
    final totalRows = image.height / fragmentHeight;
    var col = 0;
    var row = 0;
    final paint = Paint();
    while (row < totalRows) {
      while (col < totalColumns) {
        recorder = PictureRecorder();
        canvas = Canvas(recorder);
        canvas.drawImageRect(
            image,
            Rect.fromLTWH(col * fragmentWidth, row * fragmentHeight,
                fragmentWidth + 10, fragmentHeight + 10),
            Rect.fromLTWH(0, 0, fragmentWidth + 10, fragmentHeight + 10),
            paint);
        final picture = recorder.endRecording();
        final img = await picture.toImage(
            fragmentWidth.toInt(), fragmentHeight.toInt());
        componentList.add(ImageComponent(img,
            position: Vector2(col * fragmentWidth, row * fragmentHeight)));
        col++;
      }
      col = 0;
      row++;
    }

    return componentList;
  }

  static List<Layer> _unlistedLayers(
      RenderableTiledMap tileMap, List<String> layerNames) {
    final unlisted = <Layer>[];
    for (final layer in tileMap.map.layers) {
      if (!layerNames.contains(layer.name)) {
        unlisted.add(layer);
      }
    }
    return unlisted;
  }
}

class ImageComponent extends PositionComponent {
  ImageComponent(this.image, {required super.position});

  final Image image;

  @override
  void render(Canvas canvas) {
    canvas.drawImage(image, const Offset(0, 0), Paint());
  }
}
