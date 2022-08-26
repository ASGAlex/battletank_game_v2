import 'dart:async';

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/image_composition.dart';
import 'package:tank_game/packages/flame_clusterizer/lib/clusterized_component.dart';
import 'package:tank_game/packages/flame_clusterizer/lib/clusterized_game.dart';
import 'package:tank_game/packages/flame_clusterizer/lib/clusterizer.dart';
import 'package:tank_game/packages/flame_clusterizer/lib/fragment.dart';

import 'tile_processor.dart';

typedef AnimatedLayerPreprocessFunction = ClusterizedComponent Function(
    SpriteAnimationClusterized image);

class AnimationBatchCompiler {
  AnimationBatchCompiler(this.game) {
    if (game is ClusterizedGame) {
      _clusterizer = (game as ClusterizedGame).clusterizer;
    } else {
      _clusterizer = null;
    }
  }

  final FlameGame game;
  Clusterizer? _clusterizer;
  final _fragmentData = <Fragment, AnimationBatchCompiler>{};

  SpriteAnimation? animation;
  bool _loading = false;

  List<Vector2> positions = [];
  final Completer _completer = Completer();

  Future addTile(TileProcessor tileProcessor) async {
    final clusterizer = _clusterizer;
    if (clusterizer != null) {
      final fragment =
          clusterizer.findFragmentByPosition(tileProcessor.position);
      if (fragment != null) {
        if (_fragmentData[fragment] == null) {
          _fragmentData[fragment] = AnimationBatchCompiler(game);
        }
        return _fragmentData[fragment]!._addTile(tileProcessor);
      }
    } else {
      return _addTile(tileProcessor);
    }
  }

  Future _addTile(TileProcessor tileProcessor) async {
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

  Future<SpriteAnimationClusterized> compileToSingleLayer(
      [Fragment? fragment]) async {
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
      if (fragment != null) {
        composedImage = await composedImage.crop(fragment.rect);
      }
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
    final clusterizer = _clusterizer;

    if (clusterizer != null && _fragmentData.isNotEmpty) {
      final mainAnimationComponent =
          _RootAnimationUpdater(size: clusterizer.mapSize);
      for (final entry in _fragmentData.entries) {
        final fragment = entry.key;
        final compiler = entry.value;
        final animatedFragment = await compiler.compileToSingleLayer(fragment);
        mainAnimationComponent.animation ??= animatedFragment.animation;
        animatedFragment.position =
            Vector2(fragment.rect.left, fragment.rect.top);
        if (priority != null) {
          animatedFragment.priority = priority;
        }
        if (preprocessFunction != null) {
          final preprocessed = preprocessFunction(animatedFragment);
          game.add(preprocessed);
        } else {
          game.add(animatedFragment);
        }
      }
      game.add(mainAnimationComponent);
    } else {
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
  }

  clear() {
    _fragmentData.clear();
    positions.clear();
    _loading = false;
    animation = null;
  }
}

class _RootAnimationUpdater extends SpriteAnimationComponent
    with ClusterizedComponent {
  _RootAnimationUpdater({
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

  @override
  void renderTree(Canvas canvas) {}
}

class SpriteAnimationClusterized extends SpriteAnimationComponent
    with ClusterizedComponent {
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
