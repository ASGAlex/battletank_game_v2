import 'dart:async';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame_tiled/flame_tiled.dart';
import 'package:tank_game/packages/flame_clusterizer/lib/clusterized_component.dart';
import 'package:tiled/tiled.dart';

class ImageBatchCompiler {
  Future<ImageComponent> compileMapLayer(
      {required RenderableTiledMap tileMap, List<String>? layerNames}) async {
    layerNames ??= [];
    _unlistedLayers(tileMap, layerNames).forEach((element) {
      element.visible = false;
    });
    for (var rl in tileMap.renderableLayers) {
      rl.refreshCache();
    }

    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);
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

    return ImageComponent(image, position: Vector2(0, 0));
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

class ImageComponent extends PositionComponent with ClusterizedComponent {
  ImageComponent(this.image, {required super.position});

  final Image image;

  @override
  void render(Canvas canvas) {
    canvas.drawImage(image, const Offset(0, 0), Paint());
  }
}
