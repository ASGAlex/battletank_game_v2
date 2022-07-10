part of tiled_utils;

class PictureBatchCompiler {
  PositionComponent compileMapLayer(
      {required RenderableTiledMap tileMap, List<String>? layerNames}) {
    layerNames ??= [];
    _unlistedLayers(tileMap, layerNames).forEach((element) {
      element.visible = false;
    });
    tileMap.refreshCache();

    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);
    tileMap.render(canvas);
    final picture = recorder.endRecording();

    _unlistedLayers(tileMap, layerNames).forEach((element) {
      element.visible = true;
    });
    tileMap.refreshCache();

    return _PictureComponent(picture);
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

class _PictureComponent extends PositionComponent {
  _PictureComponent(this.picture);

  final Picture picture;

  @override
  void render(Canvas canvas) {
    canvas.drawPicture(picture);
  }
}
