import 'dart:async';

import 'package:flame/components.dart';
import 'package:flame/experimental.dart';
import 'package:flame_behaviors/flame_behaviors.dart';
import 'package:flame_spatial_grid/flame_spatial_grid.dart';
import 'package:tank_game/world/core/actor.dart';
import 'package:tank_game/world/core/behaviors/animation/animation_behavior.dart';

class AnimationGroupBehavior<T> extends Behavior<ActorMixin>
    with HasGameReference<HasSpatialGridFramework> {
  AnimationGroupBehavior({required this.animationConfigs});

  final Map<T, AnimationConfig> animationConfigs;

  @override
  FutureOr<void> onLoad() {
    assert(parent is SpriteAnimationGroupComponent<T>);
    assert((parent as SpriteAnimationGroupComponent<T>).animations == null);

    final animations = <T, SpriteAnimation>{};

    for (final entry in animationConfigs.entries) {
      animations[entry.key] = AnimationBehavior.loadAnimation(
        config: entry.value,
        tilesetManager: game.tilesetManager,
      );
    }

    (parent as SpriteAnimationGroupComponent<T>).animations = animations;

    if (parent.size.isZero()) {
      final animation = animations.values.first;
      parent.size.setFrom(animation.frames.first.sprite.srcSize);
      parent.boundingBox.size.setFrom(parent.size);
    }
  }

  @override
  void onRemove() {
    (parent as SpriteAnimationGroupComponent<T>).animations = null;
  }
}
