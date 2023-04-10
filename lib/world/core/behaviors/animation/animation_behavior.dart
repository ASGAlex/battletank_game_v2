import 'dart:async';

import 'package:flame/components.dart';
import 'package:flame/experimental.dart';
import 'package:flame_behaviors/flame_behaviors.dart';
import 'package:flame_spatial_grid/flame_spatial_grid.dart';
import 'package:flutter/widgets.dart';
import 'package:tank_game/world/core/actor.dart';

@immutable
class AnimationConfig {
  const AnimationConfig({
    this.loop = false,
    this.reversed = false,
    this.reversedLoop = false,
    this.onComplete,
    required this.tileset,
    required this.tileType,
  });

  final bool loop;
  final bool reversed;
  final bool reversedLoop;
  final String tileset;
  final String tileType;
  final void Function()? onComplete;
}

class AnimationBehavior extends Behavior<ActorMixin>
    with HasGameReference<HasSpatialGridFramework> {
  AnimationBehavior({required this.config});

  final AnimationConfig config;

  static SpriteAnimation loadAnimation({
    required AnimationConfig config,
    required TilesetManager tilesetManager,
  }) {
    final animationTileCache =
        tilesetManager.getTile(config.tileset, config.tileType);
    var animation = animationTileCache?.spriteAnimation?.clone();
    if (animation == null) {
      final sprite = animationTileCache?.sprite;
      if (sprite == null) {
        throw 'Error loading animation for tile type "${config.tileType}" from tileset "${config.tileset}"';
      }
      animation =
          SpriteAnimation.spriteList([sprite], stepTime: 10000, loop: true);
    }

    if (config.reversedLoop) {
      final reversed = animation.reversed();
      animation.frames.addAll(reversed.frames);
      animation.loop = true;
    } else {
      if (config.loop) {
        animation.loop = true;
      }
      if (config.reversed) {
        animation = animation.reversed();
      }
    }

    if (config.onComplete != null) {
      animation.onComplete = config.onComplete;
      animation.loop = false;
    }

    return animation;
  }

  @override
  FutureOr<void> onLoad() {
    assert(parent is SpriteAnimationComponent);
    assert((parent as SpriteAnimationComponent).animation == null);

    final animation = loadAnimation(
      config: config,
      tilesetManager: game.tilesetManager,
    );

    (parent as SpriteAnimationComponent).animation = animation;

    if (parent.size.isZero()) {
      parent.size.setFrom(animation.frames.first.sprite.srcSize);
      parent.boundingBox.size.setFrom(parent.size);
    }
  }

  @override
  void onRemove() {
    (parent as SpriteAnimationComponent).animation = null;
  }
}
