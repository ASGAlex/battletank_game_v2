import 'dart:async';

import 'package:flame/components.dart';
import 'package:flame/experimental.dart';
import 'package:flame_behaviors/flame_behaviors.dart';
import 'package:flame_spatial_grid/flame_spatial_grid.dart';
import 'package:flutter/foundation.dart';
import 'package:tank_game/world/core/actor.dart';
import 'package:tank_game/world/core/behaviors/animation/animation_behavior.dart';

class AnimationGroupBehavior<T> extends Behavior<ActorMixin>
    with HasGameReference<HasSpatialGridFramework> {
  AnimationGroupBehavior(
      {required this.animationConfigs, this.keepAnimations = true});

  final Map<T, AnimationConfig> animationConfigs;
  final bool keepAnimations;

  @override
  void update(double dt) {
    final animationGroup = (parent as SpriteAnimationGroupComponent<T>);

    final spriteSize = animationGroup.animation?.getSprite().srcSize;
    if (spriteSize != null && animationGroup.size != spriteSize) {
      animationGroup.size.setFrom(spriteSize);
    }
    super.update(dt);
  }

  @override
  FutureOr<void> onLoad() {
    assert(parent is SpriteAnimationGroupComponent<T>);
    assert((parent as SpriteAnimationGroupComponent<T>).animations == null);

    (parent as SpriteAnimationGroupComponent<T>).autoResize = false;
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
    if (!keepAnimations) {
      (parent as SpriteAnimationGroupComponent<T>).animations = null;
    }
  }
}

mixin AnimationGroupCoreStateListenerMixin
    on SpriteAnimationGroupComponent<ActorCoreState> implements ActorMixin {
  @mustCallSuper
  @override
  void onCoreStateChanged() {
    current = data.coreState;
  }
}
