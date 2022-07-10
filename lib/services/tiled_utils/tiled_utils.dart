library tiled_utils;

import 'dart:async';
import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/flame.dart';
import 'package:flame/image_composition.dart';
import 'package:flame_tiled/flame_tiled.dart';
import 'package:tiled/tiled.dart';

typedef ComponentBuilder = Component Function(
    TileProcessor tile, Vector2 position, Vector2 size);

typedef TileProcessorFunc = void Function(
    TileProcessor tile, Vector2 position, Vector2 size);

class TileProcessor {
  static final Map<String, Sprite> _spriteCache = {};
  static final Map<String, SpriteAnimation> _spriteAnimationCache = {};
  static final Map<String, Image> _imageCache = {};

  TileProcessor(this.tile, this.tileset);

  Tile tile;
  Tileset tileset;

  RectangleHitbox? getCollisionRect() {
    if (tile.objectGroup?.type == LayerType.objectGroup) {
      final grp = tile.objectGroup as ObjectGroup;
      if (grp.objects.isNotEmpty) {
        final obj = grp.objects.first;
        return RectangleHitbox(
            size: Vector2(obj.width, obj.height),
            position: Vector2(obj.x, obj.y));
      }
    }
    return null;
  }

  Future<Sprite> getSprite([int tileId = -1]) async {
    if (tileId == -1) {
      tileId = tile.localId;
    }
    final image = tileset.image;
    if (image == null) throw 'Cant load sprite without image';

    final src = image.source;
    if (src == null) throw 'Cant load sprite without image';

    final key = src + tileId.toString() + (tileset.name ?? '');
    var cachedSprite = _getSpriteCache(key);
    if (cachedSprite == null) {
      Image? spriteSheetImg = _getImageCache(src);
      if (spriteSheetImg == null) {
        spriteSheetImg = await Flame.images.load(src);
        _imageCache[src] = spriteSheetImg;
      }
      final maxColumns = _maxColumns(image);
      final row = ((tileId + 0.9) ~/ maxColumns) + 1;
      final column = (tileId + 1) - ((row - 1) * maxColumns);

      cachedSprite = Sprite(spriteSheetImg,
          srcPosition: Vector2(((column - 1) * tileset.tileWidth!).toDouble(),
              ((row - 1) * tileset.tileHeight!).toDouble()),
          srcSize: Vector2(
              tileset.tileWidth!.toDouble(), tileset.tileHeight!.toDouble()));
      _spriteCache[key] = cachedSprite;
    }
    return cachedSprite;
  }

  Future<SpriteAnimation?> getSpriteAnimation() async {
    final image = tileset.image;
    if (image == null) throw 'Cant load sprite without image';

    final src = image.source;
    if (src == null) throw 'Cant load sprite without image';

    final key = src + tile.localId.toString() + (tileset.name ?? '');
    var cachedAnimation = _getAnimationCache(key);
    if (cachedAnimation == null) {
      if (tile.animation.isEmpty) return null;
      final List<Sprite> spriteList = [];
      final List<double> stepTimes = [];
      for (final frame in tile.animation) {
        final sprite = await getSprite(frame.tileId);
        spriteList.add(sprite);
        stepTimes.add(frame.duration / 1000);
      }
      cachedAnimation =
          SpriteAnimation.variableSpriteList(spriteList, stepTimes: stepTimes);
      _spriteAnimationCache[key] = cachedAnimation;
    }
    return cachedAnimation;
  }

  int _maxColumns(TiledImage image) {
    final maxWidth = image.width;
    final tileWidth = tileset.tileWidth;
    if (maxWidth == null || tileWidth == null) throw 'No tile dimensions';

    return maxWidth ~/ tileWidth;
  }

  Image? _getImageCache(String image) {
    try {
      return _imageCache[image];
    } catch (e) {
      return null;
    }
  }

  Sprite? _getSpriteCache(String key) {
    try {
      return _spriteCache[key];
    } catch (e) {
      return null;
    }
  }

  SpriteAnimation? _getAnimationCache(String key) {
    try {
      return _spriteAnimationCache[key];
    } catch (e) {
      return null;
    }
  }

  static PictureComponent getPictureComponent(
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

    return PictureComponent(picture);
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

  static void processTileType(
      {required RenderableTiledMap tileMap,
      required Map<String, TileProcessorFunc> processorByType,
      required List<String> layersToLoad,
      bool clear = true}) {
    for (final layer in layersToLoad) {
      final tileLayer = tileMap.getLayer<TileLayer>(layer);
      final tileData = tileLayer?.data;
      if (tileData != null) {
        int xOffset = 0;
        int yOffset = 0;
        for (final tileId in tileData) {
          if (tileId != 0) {
            final tileset = tileMap.map.tilesetByTileGId(tileId);
            final tileData = tileset.tiles[tileId];
            final position = Vector2(xOffset.toDouble() * tileMap.map.tileWidth,
                yOffset.toDouble() * tileMap.map.tileWidth);
            final processor = processorByType[tileData.type];
            if (processor != null) {
              final tileProcessor = TileProcessor(tileData, tileset);
              processor(
                  tileProcessor,
                  position,
                  Vector2(tileMap.map.tileWidth.toDouble(),
                      tileMap.map.tileWidth.toDouble()));
            }
          }
          xOffset++;
          if (xOffset == tileLayer?.width) {
            xOffset = 0;
            yOffset++;
          }
        }
      }
    }

    if (clear) {
      tileMap.map.layers
          .removeWhere((element) => layersToLoad.contains(element.name));
      tileMap.refreshCache();
    }
  }

  static List<Component> createComponentsFromTiles(
      {required RenderableTiledMap tileMap,
      required Map<String, ComponentBuilder> componentByType,
      required List<String> layersToLoad,
      Component? game,
      bool clear = true}) {
    List<Component> newComponents = [];
    for (final layer in layersToLoad) {
      final tileLayer = tileMap.getLayer<TileLayer>(layer);
      final tileData = tileLayer?.data;
      if (tileData != null) {
        int xOffset = 0;
        int yOffset = 0;
        for (final tileId in tileData) {
          if (tileId != 0) {
            final tileset = tileMap.map.tilesetByTileGId(tileId);
            final tileData = tileset.tiles[tileId];
            final position = Vector2(xOffset.toDouble() * tileMap.map.tileWidth,
                yOffset.toDouble() * tileMap.map.tileWidth);
            final component = componentByType[tileData.type];
            if (component != null) {
              final tileProcessor = TileProcessor(tileData, tileset);
              final newComponent = component(
                  tileProcessor,
                  position,
                  Vector2(tileMap.map.tileWidth.toDouble(),
                      tileMap.map.tileWidth.toDouble()));
              if (game != null) {
                game.add(newComponent);
              }
              newComponents.add(newComponent);
            }
          }
          xOffset++;
          if (xOffset == tileLayer?.width) {
            xOffset = 0;
            yOffset++;
          }
        }
      }
    }

    if (clear) {
      tileMap.map.layers
          .removeWhere((element) => layersToLoad.contains(element.name));
      tileMap.refreshCache();
    }

    return newComponents;
  }
}

class PictureComponent extends PositionComponent {
  PictureComponent(this.picture);

  final Picture picture;

  @override
  void render(Canvas canvas) {
    canvas.drawPicture(picture);
  }
}

class AnimationBatchCompiler {
  SpriteAnimation? animation;
  bool _loading = false;

  List<Vector2> positions = [];
  final Completer _completer = Completer();

  Future addTile(Vector2 position, TileProcessor tileProcessor) async {
    if (animation == null && _loading == false) {
      _loading = true;
      animation = await tileProcessor.getSpriteAnimation();
      if (animation == null) {
        _loading = false;
      } else {
        _completer.complete();
      }
    }
    positions.add(position);
  }

  Future<SpriteAnimationComponent> compile() async {
    await _completer.future;
    final anim = animation;
    if (anim == null) {
      throw "Can't compile while animation is not loaded!";
    }

    List<Sprite> newSprites = [];

    while (anim.currentIndex < anim.frames.length) {
      final sprite = anim.getSprite();
      final composition = ImageComposition();
      for (final pos in positions) {
        composition.add(sprite.image, pos, source: sprite.src);
      }
      final composedImage = await composition.compose();
      newSprites.add(Sprite(composedImage));
      anim.currentIndex++;
    }
    final spriteAnimation = SpriteAnimation.variableSpriteList(newSprites,
        stepTimes: anim.getVariableStepTimes());
    return SpriteAnimationComponent(
        animation: spriteAnimation,
        position: Vector2.all(0),
        size: newSprites.first.image.size);
  }
}

extension VariableStepTimes on SpriteAnimation {
  List<double> getVariableStepTimes() {
    final times = <double>[];
    for (final frame in frames) {
      times.add(frame.stepTime);
    }
    return times;
  }
}
