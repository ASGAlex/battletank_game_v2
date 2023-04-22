import 'dart:async';

import 'package:flame/components.dart';
import 'package:flame/experimental.dart';
import 'package:flame_spatial_grid/flame_spatial_grid.dart';
import 'package:flutter/foundation.dart';
import 'package:tank_game/world/core/actor.dart';
import 'package:tank_game/world/core/behaviors/animation/animation_behavior.dart';
import 'package:tank_game/world/core/behaviors/core_behavior.dart';

class AnimationGroupBehavior<T> extends CoreBehavior<ActorMixin>
    with HasGameReference<HasSpatialGridFramework> {
  AnimationGroupBehavior(
      {required this.animationConfigs, this.keepAnimations = true});

  final Map<T, AnimationConfig> animationConfigs;
  final bool keepAnimations;

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
    (parent as SpriteAnimationGroupComponent<T>).autoResize = true;
    parent.boundingBox.size.setFrom(parent.size);
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
