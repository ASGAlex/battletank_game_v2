import 'dart:async';

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/image_composition.dart';

import 'tile_processor.dart';

typedef AnimatedLayerPreprocessFunction = Component Function(
    SpriteAnimationClusterized image);

class AnimationBatchCompiler {
  AnimationBatchCompiler(this.game);

  final FlameGame game;

  SpriteAnimation? animation;
  bool _loading = false;

  List<Vector2> positions = [];
  final Completer _completer = Completer();

  Future addTile(TileProcessor tileProcessor) async {
    if (animation == null && _loading == false) {
      _loading = true;
      animation = await tileProcessor.getSpriteAnimation();
      if (animation == null) {
        _loading = false;
      } else {
        _completer.complete();
      }
    }
    positions.add(tileProcessor.position);
  }

  Future<SpriteAnimationClusterized> compileToSingleLayer() async {
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
      var composedImage = await composition.compose();
      newSprites.add(Sprite(composedImage));
      anim.currentIndex++;
    }
    final spriteAnimation = SpriteAnimation.variableSpriteList(newSprites,
        stepTimes: anim.getVariableStepTimes());
    return SpriteAnimationClusterized(
        animation: spriteAnimation,
        position: Vector2.all(0),
        size: newSprites.first.image.size);
  }

  Future addCollectedTiles(
      {int? priority,
      AnimatedLayerPreprocessFunction? preprocessFunction}) async {
    final singleComponent = await compileToSingleLayer();
    if (priority != null) {
      singleComponent.priority = priority;
    }
    if (preprocessFunction != null) {
      final preprocessed = preprocessFunction(singleComponent);
      game.add(preprocessed);
    } else {
      game.add(singleComponent);
    }
  }

  clear() {
    positions.clear();
    _loading = false;
    animation = null;
  }
}

class SpriteAnimationClusterized extends SpriteAnimationComponent {
  SpriteAnimationClusterized({
    this.runUpdate = true,
    super.animation,
    super.removeOnFinish,
    super.playing,
    super.paint,
    super.position,
    super.size,
    super.scale,
    super.angle,
    super.anchor,
    super.children,
    super.priority,
  });

  final bool runUpdate;

  @override
  void update(double dt) {
    if (runUpdate) {
      super.update(dt);
    }
  }
}

extension _VariableStepTimes on SpriteAnimation {
  List<double> getVariableStepTimes() {
    final times = <double>[];
    for (final frame in frames) {
      times.add(frame.stepTime);
    }
    return times;
  }
}
