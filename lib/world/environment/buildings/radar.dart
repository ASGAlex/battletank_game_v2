import 'dart:async';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame_spatial_grid/flame_spatial_grid.dart';
import 'package:flutter/material.dart';
import 'package:tank_game/game.dart';
import 'package:tank_game/packages/behaviors/lib/flame_behaviors.dart';
import 'package:tank_game/world/core/actor.dart';
import 'package:tank_game/world/core/behaviors/animation/animation_behavior.dart';
import 'package:tank_game/world/core/behaviors/animation/animation_group_behavior.dart';
import 'package:tank_game/world/core/behaviors/attacks/killable_behavior.dart';
import 'package:tank_game/world/core/behaviors/effects/shadow_behavior.dart';
import 'package:tank_game/world/core/behaviors/effects/smoke_behavior.dart';
import 'package:tank_game/world/world.dart';

class RadarEntity extends SpriteAnimationGroupComponent<ActorCoreState>
    with
        CollisionCallbacks,
        HasGameReference<MyGame>,
        EntityMixin,
        HasGridSupport,
        ComponentWithUpdate,
        ActorMixin,
        AnimationGroupCoreStateListenerMixin,
        ActorWithBoundingBody {
  RadarEntity({
    super.position,
  }) : super(priority: RenderPriority.player.priority) {
    paint.filterQuality = FilterQuality.none;
    paint.isAntiAlias = false;
    priority = RenderPriority.player.priority;
    noVisibleChildren = false;
    boundingBox.collisionType =
        boundingBox.defaultCollisionType = CollisionType.passive;
    anchor = Anchor.center;
    position.translate(8, 8);
  }

  static const _tileset = 'radar_head';
  late SpriteComponent ground;
  late final ShadowPictureComponent groundShadow;
  late final ShadowPictureComponent groundShadow1;
  late final ShadowPictureComponent headShadow;
  late final RotateEffect rotateEffect;
  late final SpriteAnimationComponent boom;

  late final SmokeComponent smoke;

  @override
  FutureOr<void> onLoad() {
    add(AnimationGroupBehavior<ActorCoreState>(animationConfigs: {
      ActorCoreState.idle: const AnimationConfig(
          tileset: _tileset, tileType: 'radar_head_disabled', loop: true),
      ActorCoreState.move: const AnimationConfig(
          tileset: _tileset, tileType: 'radar_head', loop: true),
      ActorCoreState.dying: const AnimationConfig(
        tileset: _tileset,
        tileType: 'radar_head_disabled',
      ),
      ActorCoreState.wreck: const AnimationConfig(
          tileset: _tileset, tileType: 'radar_head_disabled', loop: true),
      ActorCoreState.removing: const AnimationConfig(
          tileset: _tileset, tileType: 'radar_head_disabled', loop: true),
    }));
    current = ActorCoreState.move;

    smoke = SmokeComponent(
      game.world.skyLayer,
      color: Colors.black38,
      particlePriority: 10,
      nextParticleFrequency: 0.1,
      sizeAndPositionProvider: this,
    );
    add(smoke);

    final groundSprite =
        game.tilesetManager.getTile('radar_head', 'radar_ground')?.sprite;

    final boomAnimation =
        game.tilesetManager.getTile('boom', 'boom')?.spriteAnimation;

    if (groundSprite == null) {
      throw 'Ground sprite not found';
    }
    if (boomAnimation == null) {
      throw 'Boom animation not found';
    }
    boomAnimation.loop = false;

    ground = SpriteComponent(sprite: groundSprite, priority: 0);
    ground.position = position.translated(-8, -8);
    ground.priority = 2;
    parent?.add(ground);

    groundShadow = ShadowPictureComponent('radar_ground',
        targetEntity: ground, manuallyPositioned: true);
    groundShadow.position = ground.position.translated(-1.5, 1.5);
    groundShadow.priority = 1;
    parent?.add(groundShadow);
    groundShadow1 = ShadowPictureComponent('radar_ground',
        targetEntity: ground, manuallyPositioned: true);
    groundShadow1.position = ground.position.translated(-2.5, 2.5);
    groundShadow1.priority = 1;
    parent?.add(groundShadow1);

    headShadow = ShadowPictureComponent('radar_head',
        targetEntity: this, manuallyPositioned: true);
    headShadow.anchor = Anchor.center;
    headShadow.position = position.translated(-2, 2);
    headShadow.priority = 3;
    parent?.add(headShadow);

    boom = SpriteAnimationComponent(
      animation: boomAnimation,
      anchor: Anchor.center,
      position: ground.position.translated(8, 8),
      scale: Vector2.all(1.5),
      priority: 3,
      removeOnFinish: true,
    );

    add(KillableBehavior(onBeingKilled: onBeingKilled));
    rotateEffect = RotateEffect.by(
      6.283,
      InfiniteEffectController(LinearEffectController(10)),
    );
    add(rotateEffect);
    super.onLoad();
    boundingBox.collisionType =
        boundingBox.defaultCollisionType = CollisionType.passive;
    boundingBox.isSolid = true;
  }

  void onBeingKilled(ActorMixin? attackedBy, ActorMixin killable) {
    if (coreState == ActorCoreState.removing) {
      coreState = ActorCoreState.wreck;
      return;
    }
    smoke.isEnabled = true;
    parent?.add(boom);
    rotateEffect.removeFromParent();
    ground.removeFromParent();
    final groundSprite =
        game.tilesetManager.getTile('radar_head', 'radar_head_wreck')?.sprite;

    if (groundSprite == null) {
      throw 'Wreck sprite not found';
    }
    ground = SpriteComponent(sprite: groundSprite, priority: 0);
    ground.position = position.translated(-8, -8);
    ground.priority = 2;
    parent?.add(ground);
    coreState = ActorCoreState.wreck;
  }
}
