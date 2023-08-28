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

mixin ShadowOfAnimationGroup on ActorMixin {}
mixin ShadowOfAnimation on ActorMixin {}

class ShadowBehavior extends CoreBehavior<ActorMixin>
    with HasGameReference<MyGame> {
  ShadowBehavior({this.shadowKey});

  final String? shadowKey;

  static final generatedShadows = <String, Map<Image, Vector2>>{};
  final animationStateToKey = <dynamic, String>{};
  ShadowPictureComponent? shadowPictureComponent;

  @override
  FutureOr<void> onLoad() {
    if (parent is ShadowOfAnimationGroup) {
      _loadForAnimationGroup();
    } else if (parent is ShadowOfAnimation) {
      _loadForAnimation();
    } else {
      _loadForStatic();
    }

    shadowPictureComponent = ShadowPictureComponent(shadowKey, this);

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

  void _loadForAnimationGroup() {
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
      _loadForAnimation();
    }
  }

  void _loadForAnimation() {
    try {
      final animation = parent.findBehavior<AnimationBehavior>();
      if (animation.config.needShadow) {
        final key = shadowKey ??
            '${animation.config.tileset}_${animation.config.tileType}';

        _processAnimation(animation.config, key);
      }
    } catch (animationException) {
      _loadForStatic();
    }
  }

  void _loadForStatic() {
    if (parent is SpriteComponent && shadowKey != null) {
      _renderSprite((parent as SpriteComponent).sprite!, shadowKey!);
    }
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

    _renderSprite(animation.createTicker().getSprite(), key);
  }

  void _renderSprite(Sprite sprite, String key) {
    if (generatedShadows[key] != null) return;

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
    final image = recorder.endRecording().toImageSync(
          sprite.srcSize.x.ceil(),
          sprite.srcSize.y.ceil(),
        );
    generatedShadows[key] = {image: sprite.srcSize};
  }
}

class ShadowPictureComponent extends PositionComponent
    with HasPaint, LayerChildComponent {
  ShadowPictureComponent(this.shadowKey, this.shadowBehavior) {
    targetEntity = shadowBehavior.parent;
    anchor = targetEntity.anchor;
    // currentCell = targetEntity.currentCell;
    scale = targetEntity.scale;
    paint.isAntiAlias = false;
    paint.filterQuality = FilterQuality.none;
    _updateTransform();
  }

  final String? shadowKey;
  final ShadowBehavior shadowBehavior;
  late final ActorMixin targetEntity;
  late final Image image;
  final Vector2 offset = Vector2.zero();
  final shadowOffsetDecorator = Transform2DDecorator();

  @override
  FutureOr<void>? onLoad() {
    if ((parent is! CellLayer && parent != null) ||
        (parent is CellLayer &&
            (parent as CellLayer).componentsStorageMode ==
                LayerComponentsStorageMode.defaultComponentTree)) {
      targetEntity.data.lookDirectionNotifier
          .addListener(_onTargetLookDirectionUpdate);
    }
    targetEntity.transform.addListener(_updateTransform);
    _updateTransform();
    _onTargetLookDirectionUpdate();

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
    if (targetEntity is SpriteAnimationGroupComponent) {
      final state = (targetEntity as SpriteAnimationGroupComponent).current;
      final key = shadowBehavior.animationStateToKey[state];
      image = ShadowBehavior.generatedShadows[key]!.keys.first;
    } else {
      image = ShadowBehavior.generatedShadows[shadowKey]!.keys.first;
    }
    // image = picture.toImageSync(size.x.ceil(), size.y.ceil());
    return super.onLoad();
  }

  void _onTargetLookDirectionUpdate() {
    final game = targetEntity.findGame() as MyGame;

    final shadowOffset = game.world.shadowOffset;
    switch (targetEntity.data.lookDirection) {
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
    shadowOffsetDecorator.transform2d.position.setFrom(offset);
  }

  void _updateTransform() {
    position.setFrom(targetEntity.position);
    size.setFrom(targetEntity.size);
    angle = targetEntity.angle;

    if (parent is CellLayer) {
      (parent as CellLayer).isUpdateNeeded = true;
    } else if (parentLayer != null) {
      parentLayer!.isUpdateNeeded = true;
    }
  }

  @override
  void onRemove() {
    targetEntity.transform.removeListener(_updateTransform);
    if (parent is CellLayer) {
      (parent as CellLayer).isUpdateNeeded = true;
    }
    targetEntity.data.lookDirectionNotifier
        .removeListener(_onTargetLookDirectionUpdate);
    super.onRemove();
  }

  @override
  void render(Canvas canvas) {
    canvas.drawImage(image, offset.toOffset(), paint);
  }
}
