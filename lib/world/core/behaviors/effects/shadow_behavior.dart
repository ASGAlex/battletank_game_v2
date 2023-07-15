import 'dart:async';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/experimental.dart';
import 'package:flame/rendering.dart';
import 'package:flame_spatial_grid/flame_spatial_grid.dart';
import 'package:flutter/material.dart' show Colors;
import 'package:tank_game/game.dart';
import 'package:tank_game/world/core/actor.dart';
import 'package:tank_game/world/core/behaviors/animation/animation_behavior.dart';
import 'package:tank_game/world/core/behaviors/animation/animation_group_behavior.dart';
import 'package:tank_game/world/core/behaviors/core_behavior.dart';
import 'package:tank_game/world/core/direction.dart';
import 'package:tank_game/world/world.dart';

class ShadowBehavior extends CoreBehavior<ActorMixin>
    with HasGameReference<MyGame> {
  ShadowBehavior({this.shadowKey});

  final String? shadowKey;

  static final generatedShadows = <String, Map<Picture, Vector2>>{};
  final animationStateToKey = <dynamic, String>{};
  ShadowPictureComponent? shadowPictureComponent;

  @override
  FutureOr<void> onLoad() {
    try {
      final animationGroup = parent.findBehavior<AnimationGroupBehavior>();
      for (final configEntry in animationGroup.animationConfigs.entries) {
        if (configEntry.value.needShadow) {
          final key = shadowKey ??
              '${configEntry.value.tileset}_${configEntry.value.tileType}';
          animationStateToKey[configEntry.key] = key;

          _processAnimation(configEntry.value, key.toString());
        }
      }
    } catch (groupException) {
      try {
        final animation = parent.findBehavior<AnimationBehavior>();
        if (animation.config.needShadow) {
          final key = shadowKey ??
              '${animation.config.tileset}_${animation.config.tileType}';

          _processAnimation(animation.config, key);
        }
      } catch (animationException) {
        if (parent is SpriteComponent && shadowKey != null) {
          _renderSprite((parent as SpriteComponent).sprite!, shadowKey!);
        }
      }
    }
    shadowPictureComponent = ShadowPictureComponent(shadowKey, this);

    shadowPictureComponent!.priority = parent.priority - 1;

    if (parent.parent is CellLayer) {
      final layer = game.layersManager.addComponent(
          component: shadowPictureComponent!,
          layerType: MapLayerType.static,
          layerName: 'Shadows',
          priority: RenderPriority.shadows.priority);
      (layer as CellStaticLayer).renderAsImage = true;
    } else {
      parent.parent!.add(shadowPictureComponent!);
    }
    return super.onLoad();
  }

  @override
  void onRemove() {
    if (shadowPictureComponent != null) {
      shadowPictureComponent!.removeFromParent();
    }
    super.onRemove();
  }

  void _processAnimation(AnimationConfig config, String key) {
    if (generatedShadows[key] != null) return;

    final game = parent.findGame() as HasSpatialGridFramework;
    final animation = AnimationBehavior.loadAnimation(
      config: config,
      tilesetManager: game.tilesetManager,
    );

    _renderSprite(animation.ticker().getSprite(), key);
  }

  void _renderSprite(Sprite sprite, String key) {
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);

    final game = parent.findGame() as MyGame;
    final shadowPaint = Paint()
      ..isAntiAlias = false
      ..filterQuality = FilterQuality.none
      ..colorFilter = ColorFilter.mode(
        Colors.black.withOpacity(game.world.shadowsOpacity),
        BlendMode.srcIn,
      );

    sprite.render(
      canvas,
      position: Vector2.zero(),
      overridePaint: shadowPaint,
    );
    final picture = recorder.endRecording();
    generatedShadows[key] = {picture: sprite.srcSize};
  }
}

class ShadowPictureComponent extends PositionComponent
    with HasGridSupport, HasPaint {
  ShadowPictureComponent(this.shadowKey, this.shadowBehavior) {
    targetEntity = shadowBehavior.parent;
    anchor = targetEntity.anchor;
    currentCell = targetEntity.currentCell;
    scale = targetEntity.scale;
    _updateTransform();
  }

  final String? shadowKey;
  final ShadowBehavior shadowBehavior;
  late final ActorMixin targetEntity;

  @override
  FutureOr<void>? onLoad() {
    targetEntity.transform.addListener(_updateTransform);
    _updateTransform();

    Vector2? spriteSize;
    if (targetEntity is SpriteAnimationGroupComponent) {
      final state = (targetEntity as SpriteAnimationGroupComponent).current;
      final key = shadowBehavior.animationStateToKey[state];
      spriteSize = ShadowBehavior.generatedShadows[key]?.values.first;
    } else {
      spriteSize = ShadowBehavior.generatedShadows[shadowKey]?.values.first;
    }

    if (spriteSize != null) {
      size.setFrom(spriteSize);
    }
    return super.onLoad();
  }

  void _updateTransform() {
    position.setFrom(targetEntity.position);
    size.setFrom(targetEntity.size);
    angle = targetEntity.angle;

    if (parent is CellLayer) {
      (parent as CellLayer).isUpdateNeeded = true;
    }
  }

  @override
  void onRemove() {
    targetEntity.transform.removeListener(_updateTransform);
    if (parent is CellLayer) {
      (parent as CellLayer).isUpdateNeeded = true;
    }
    super.onRemove();
  }

  @override
  void render(Canvas canvas) {
    Picture? picture;
    if (targetEntity is SpriteAnimationGroupComponent) {
      final state = (targetEntity as SpriteAnimationGroupComponent).current;
      final key = shadowBehavior.animationStateToKey[state];
      picture = ShadowBehavior.generatedShadows[key]?.keys.first;
    } else {
      picture = ShadowBehavior.generatedShadows[shadowKey]?.keys.first;
    }

    if (picture != null && parent != null) {
      final game = targetEntity.findGame() as MyGame;
      final decorator = Transform2DDecorator();
      Vector2? offset;
      final shadowOffset = game.world.shadowOffset;
      switch (targetEntity.data.lookDirection) {
        case DirectionExtended.up:
          offset = Vector2(shadowOffset.x, shadowOffset.y);
          break;
        case DirectionExtended.left:
          offset = Vector2(shadowOffset.x, -shadowOffset.y);
          break;
        case DirectionExtended.down:
          offset = Vector2(-shadowOffset.x, -shadowOffset.y);
          break;
        case DirectionExtended.right:
          offset = Vector2(-shadowOffset.x, shadowOffset.y);
          break;
      }
      decorator.transform2d.position.setFrom(offset);
      decorator.apply((p0) {
        p0.drawPicture(picture!);
      }, canvas);
    }
  }
}
