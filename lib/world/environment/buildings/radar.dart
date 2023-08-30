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
import 'package:tank_game/world/core/behaviors/attacks/killable_behavior.dart';
import 'package:tank_game/world/core/behaviors/effects/shadow_behavior.dart';
import 'package:tank_game/world/world.dart';

class RadarEntity extends PositionComponent
    with
        HasPaint,
        CollisionCallbacks,
        HasGameReference<MyGame>,
        EntityMixin,
        HasGridSupport,
        ComponentWithUpdate,
        ActorMixin,
        ActorWithBoundingBody {
  RadarEntity({
    super.position,
  }) : super(priority: RenderPriority.player.priority) {
    paint.filterQuality = FilterQuality.none;
    noVisibleChildren = true;
    paint.isAntiAlias = false;
    priority = RenderPriority.player.priority;
    noVisibleChildren = false;
  }

  @override
  FutureOr<void> onLoad() {
    final ground = game.tilesetManager.getTile('radar_head', 'radar_ground');

    if (ground?.sprite == null) {
      throw 'Ground sprite not found';
    }

    add(SpriteComponent(sprite: ground!.sprite, priority: 0));
    add(RadarHeadComponent());

    add(KillableBehavior());
    super.onLoad();
    boundingBox.collisionType =
        boundingBox.defaultCollisionType = CollisionType.passive;
    boundingBox.isSolid = true;
  }

  bool applyAttack(ActorMixin attackedBy, ActorMixin killable) {
    if (attackedBy.data.coreState == ActorCoreState.move) {
      data.health -= attackedBy.data.health;
      attackedBy.data.health = 0;

      removeFromParent();
    }
    return true;
  }
}

class RadarHeadComponent extends PositionComponent
    with HasGameReference<MyGame> {
  late final SpriteAnimationComponent headAnimation;
  late final ShadowPictureComponent shadow;

  @override
  FutureOr<void> onLoad() {
    final head = game.tilesetManager.getTile('radar_head', 'radar_head');
    if (head?.spriteAnimation == null) {
      throw 'Head animation not found';
    }
    headAnimation = SpriteAnimationComponent(
      animation: head!.spriteAnimation,
      anchor: Anchor.center,
      priority: 1,
      position: (parent as PositionComponent).position + Vector2(8, 8),
    )..add(RotateEffect.by(
        6.283, InfiniteEffectController(LinearEffectController(10))));

    shadow = ShadowPictureComponent(
      'radar',
      targetEntity: headAnimation,
      manuallyPositioned: true,
    );
    shadow.position = (parent as PositionComponent).position + Vector2(6, 10);
    game.world.skyLayer.add(headAnimation);
    game.world.skyLayer.add(shadow);

    return super.onLoad();
  }

  @override
  void onRemove() {
    headAnimation.removeFromParent();
    shadow.removeFromParent();
    super.onRemove();
  }
}
