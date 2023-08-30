import 'dart:async';
import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/experimental.dart';
import 'package:flame_behaviors/flame_behaviors.dart';
import 'package:flame_spatial_grid/flame_spatial_grid.dart';
import 'package:tank_game/game.dart';
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
  late final SpriteComponent ground;
  late final ShadowPictureComponent groundShadow;
  late final ShadowPictureComponent headShadow;

  late final SmokeBehavior smoke;

  @override
  FutureOr<void> onLoad() {
    add(AnimationGroupBehavior<ActorCoreState>(animationConfigs: {
      ActorCoreState.idle: const AnimationConfig(
          tileset: _tileset, tileType: 'radar_head_disabled', loop: true),
      ActorCoreState.move: const AnimationConfig(
          tileset: _tileset, tileType: 'radar_head', loop: true),
      ActorCoreState.dying: AnimationConfig(
          tileset: _tileset,
          tileType: 'radar_head_disabled',
          onComplete: () {
            coreState = ActorCoreState.wreck;
            smoke.isEnabled = true;
          }),
      ActorCoreState.wreck: const AnimationConfig(
          tileset: _tileset, tileType: 'radar_head_wreck', loop: true),
      ActorCoreState.removing: const AnimationConfig(
          tileset: _tileset, tileType: 'radar_head_wreck', loop: true),
    }));
    current = ActorCoreState.move;

    smoke = SmokeBehavior(game.world.skyLayer);
    add(smoke);

    final groundSprite =
        game.tilesetManager.getTile('radar_head', 'radar_ground')?.sprite;

    if (groundSprite == null) {
      throw 'Ground sprite not found';
    }
    ground = SpriteComponent(sprite: groundSprite, priority: 0);
    ground.position = position.translated(-8, -8);
    ground.priority = 2;
    parent?.add(ground);

    groundShadow = ShadowPictureComponent('radar_ground',
        targetEntity: ground, manuallyPositioned: true);
    groundShadow.position = ground.position.translated(-2, 2);
    groundShadow.priority = 1;
    parent?.add(groundShadow);

    headShadow = ShadowPictureComponent('radar_head',
        targetEntity: this, manuallyPositioned: true);
    headShadow.anchor = Anchor.center;
    headShadow.position = position.translated(-2, 2);
    headShadow.priority = 3;
    parent?.add(headShadow);

    add(KillableBehavior());
    add(RotateEffect.by(
      6.283,
      InfiniteEffectController(LinearEffectController(10)),
    ));
    super.onLoad();
    boundingBox.collisionType =
        boundingBox.defaultCollisionType = CollisionType.passive;
    boundingBox.isSolid = true;
  }
}
