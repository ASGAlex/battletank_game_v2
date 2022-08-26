import 'dart:async';

import 'package:flame/components.dart';
import 'package:flame/image_composition.dart';
import 'package:tank_game/packages/flame_clusterizer/lib/clusterized_component.dart';

import 'tile_processor.dart';

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

  Future<SpriteAnimationComponentVis> compile() async {
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
    return SpriteAnimationComponentVis(
        animation: spriteAnimation,
        position: Vector2.all(0),
        size: newSprites.first.image.size);
  }
}

class SpriteAnimationComponentVis extends SpriteAnimationComponent
    with ClusterizedComponent {
  SpriteAnimationComponentVis({
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
