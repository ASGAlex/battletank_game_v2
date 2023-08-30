import 'dart:async';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/experimental.dart';
import 'package:flame_spatial_grid/flame_spatial_grid.dart';
import 'package:flutter/material.dart' show Colors;
import 'package:tank_game/game.dart';
import 'package:tank_game/world/core/actor.dart';
import 'package:tank_game/world/core/behaviors/animation/animation_behavior.dart';
import 'package:tank_game/world/core/behaviors/animation/animation_group_behavior.dart';
import 'package:tank_game/world/core/behaviors/core_behavior.dart';
import 'package:tank_game/world/core/direction.dart';
import 'package:tank_game/world/world.dart';

mixin ShadowOfAnimationGroup on ActorMixin {}
mixin ShadowOfAnimation on ActorMixin {}

class ShadowBehavior extends CoreBehavior<ActorMixin>
    with HasGameReference<MyGame> {
  ShadowBehavior({required this.shadowKey});

  final String shadowKey;

  final animationStateToKey = <dynamic, String>{};
  ShadowPictureComponent? shadowPictureComponent;

  @override
  FutureOr<void> onLoad() {
    shadowPictureComponent =
        ShadowPictureComponent(shadowKey, shadowBehavior: this);

    shadowPictureComponent!.priority = parent.priority - 1;

    if (parent.parent is CellLayer) {
      game.layersManager.addComponent(
          component: shadowPictureComponent!,
          layerType: MapLayerType.static,
          layerName: 'Shadows',
          currentCell: parent.currentCell,
          componentsStorageMode: LayerComponentsStorageMode.internalLayerSet,
          renderMode: LayerRenderMode.image,
          priority: RenderPriority.shadows.priority);
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
}

class ShadowPictureComponent extends PositionComponent
    with HasPaint, LayerChildComponent, HasGameReference<MyGame> {
  static final generatedShadows = <String, Map<Image, Vector2>>{};

  ShadowPictureComponent(this.shadowKey,
      {this.shadowBehavior,
      this.targetEntity,
      this.manuallyPositioned = false}) {
    if (targetEntity == null && shadowBehavior?.parent != null) {
      targetEntity = shadowBehavior!.parent;
    }
    if (targetEntity != null) {
      anchor = targetEntity!.anchor;
      scale = targetEntity!.scale;
    }
    paint.isAntiAlias = false;
    paint.filterQuality = FilterQuality.none;
    _updateTransform();
  }

  final String shadowKey;
  final ShadowBehavior? shadowBehavior;
  PositionComponent? targetEntity;
  late final Image image;
  final Vector2 offset = Vector2.zero();

  final bool manuallyPositioned;

  ActorMixin? get targetAsActor {
    if (targetEntity is ActorMixin) {
      return targetEntity as ActorMixin;
    }
    return null;
  }

  @override
  FutureOr<void>? onLoad() {
    if ((parent is! CellLayer && parent != null) ||
        (parent is CellLayer &&
            (parent as CellLayer).componentsStorageMode ==
                LayerComponentsStorageMode.defaultComponentTree)) {
      targetAsActor?.data.lookDirectionNotifier
          .addListener(_onTargetLookDirectionUpdate);
    }
    targetEntity?.transform.addListener(_updateTransform);
    // anchor = targetEntity?.anchor ?? Anchor.topLeft;
    _updateTransform();
    _onTargetLookDirectionUpdate();

    if (targetEntity is ShadowOfAnimationGroup) {
      _loadForAnimationGroup();
    } else if (targetEntity is ShadowOfAnimation) {
      _loadForAnimation();
    } else {
      _loadForStatic();
    }

    Vector2? spriteSize;
    if (targetEntity is SpriteAnimationGroupComponent) {
      final state = (targetEntity as SpriteAnimationGroupComponent).current;
      final key = shadowBehavior?.animationStateToKey[state];
      if (key != null) {
        spriteSize = generatedShadows[key]?.values.first;
      } else {
        spriteSize = generatedShadows[shadowKey]?.values.first;
      }
    } else {
      spriteSize = generatedShadows[shadowKey]?.values.first;
    }

    if (spriteSize != null) {
      size.setFrom(spriteSize);
    }
    if (targetEntity is SpriteAnimationGroupComponent) {
      final state = (targetEntity as SpriteAnimationGroupComponent).current;
      final key = shadowBehavior?.animationStateToKey[state];
      if (key != null) {
        image = generatedShadows[key]!.keys.first;
      } else {
        image = generatedShadows[shadowKey]!.keys.first;
      }
    } else {
      image = generatedShadows[shadowKey]!.keys.first;
    }
    // image = picture.toImageSync(size.x.ceil(), size.y.ceil());
    return super.onLoad();
  }

  void _loadForAnimationGroup() {
    try {
      final animationGroup =
          targetAsActor?.findBehavior<AnimationGroupBehavior>();
      if (animationGroup == null) {
        throw 'Target is not actor';
      }
      for (final configEntry in animationGroup.animationConfigs.entries) {
        if (configEntry.value.needShadow) {
          final key =
              '${configEntry.value.tileset}_${configEntry.value.tileType}';
          shadowBehavior?.animationStateToKey[configEntry.key] = key;

          _processAnimation(configEntry.value, key.toString());
        }
      }
    } catch (groupException) {
      _loadForAnimation();
    }
  }

  void _loadForAnimation() {
    try {
      final animation = targetAsActor?.findBehavior<AnimationBehavior>();
      if (animation == null) {
        throw 'Target is not actor';
      }
      if (animation.config.needShadow) {
        final key = '${animation.config.tileset}_${animation.config.tileType}';

        _processAnimation(animation.config, key);
      }
    } catch (animationException) {
      _loadForStatic();
    }
  }

  void _loadForStatic() {
    if (targetEntity is SpriteComponent) {
      _renderSprite((targetEntity as SpriteComponent).sprite!, shadowKey);
    } else if (targetEntity is SpriteAnimationGroupComponent) {
      final firstFrameSprite = (targetEntity as SpriteAnimationGroupComponent)
          .animations!
          .values
          .first
          .frames
          .first
          .sprite;
      _renderSprite(firstFrameSprite, shadowKey);
    } else if (targetEntity is SpriteAnimationComponent) {
      _renderSprite(
          (targetEntity as SpriteAnimationComponent)
              .animation!
              .frames
              .first
              .sprite,
          shadowKey);
    }
  }

  void _onTargetLookDirectionUpdate() {
    final shadowOffset = game.world.shadowOffset;
    final actor = targetAsActor;
    if (actor == null) {
      offset.setValues(shadowOffset.x, shadowOffset.y);
    } else {
      switch (actor.data.lookDirection) {
        case DirectionExtended.up:
          offset.setValues(shadowOffset.x, shadowOffset.y);
          break;
        case DirectionExtended.left:
          offset.setValues(shadowOffset.x, -shadowOffset.y);
          break;
        case DirectionExtended.down:
          offset.setValues(-shadowOffset.x, -shadowOffset.y);
          break;
        case DirectionExtended.right:
          offset.setValues(-shadowOffset.x, shadowOffset.y);
          break;
      }
    }
  }

  void _updateTransform() {
    if (targetEntity != null) {
      if (!manuallyPositioned) {
        position.setFrom(targetEntity!.position);
      }
      size.setFrom(targetEntity!.size);
      angle = targetEntity!.angle;
    }
    if (parent is CellLayer) {
      (parent as CellLayer).isUpdateNeeded = true;
    } else if (parentLayer != null) {
      parentLayer!.isUpdateNeeded = true;
    }
  }

  @override
  void onRemove() {
    targetEntity?.transform.removeListener(_updateTransform);
    if (parent is CellLayer) {
      (parent as CellLayer).isUpdateNeeded = true;
    }
    targetAsActor?.data.lookDirectionNotifier
        .removeListener(_onTargetLookDirectionUpdate);
    super.onRemove();
  }

  @override
  void render(Canvas canvas) {
    final renderOffset = manuallyPositioned ? Offset.zero : offset.toOffset();
    canvas.drawImage(image, renderOffset, paint);
  }

  void _processAnimation(AnimationConfig config, String key) {
    if (generatedShadows[key] != null) return;

    final animation = AnimationBehavior.loadAnimation(
      config: config,
      tilesetManager: game.tilesetManager,
    );

    _renderSprite(animation.createTicker().getSprite(), key);
  }

  void _renderSprite(Sprite sprite, String key) {
    if (generatedShadows[key] != null) return;

    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);

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
    final image = recorder.endRecording().toImageSync(
          sprite.srcSize.x.ceil(),
          sprite.srcSize.y.ceil(),
        );
    generatedShadows[key] = {image: sprite.srcSize};
  }
}
