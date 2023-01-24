import 'dart:async';
import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/experimental.dart';
import 'package:flame_spatial_grid/flame_spatial_grid.dart';
import 'package:flutter/foundation.dart';
import 'package:tank_game/game.dart';

mixin HasShadow on SpriteComponent {
  late TileDataProvider tileDataProvider;

  final _removeShadow = ValueNotifier<bool>(false);

  @override
  void onRemove() {
    _removeShadow.value = true;
  }
}

class ShadowComponent extends SpriteComponent
    with HasGridSupport, HasGameReference<MyGame> {
  ShadowComponent(HasShadow component, [this.offsetMultiplier = 1])
      : _component = component {
    if (component is HasGridSupport) {
      currentCell = (component as HasGridSupport).currentCell;
    }

    position.setFrom(component.position);
    position.add(game.world.shadowOffset * offsetMultiplier);

    size.setFrom(component.size);

    _component.size.addListener(onTrackedComponentSizeChange);
    _component._removeShadow.addListener(onComponentRemove);

    _component.paint.blendMode = BlendMode.src;

    boundingBox.collisionType =
        boundingBox.defaultCollisionType = CollisionType.inactive;
  }

  final HasShadow _component;

  static final _globalImage = <Type, Image>{};
  Image? _shadowImage;

  double offsetMultiplier = 1;

  @override
  //ignore: must_call_super
  void render(Canvas canvas) {
    if (_shadowImage != null) {
      canvas.drawImage(_shadowImage!, Offset.zero, paint);
    } else {
      final image = _globalImage[_component.runtimeType];
      if (image != null) {
        canvas.drawImage(image, Offset.zero, paint);
      }
    }
  }

  void onComponentRemove() {
    _component.transform.removeListener(onTrackedComponentSizeChange);
    _component._removeShadow.removeListener(onComponentRemove);
    removeFromParent();
  }

  Future onTrackedComponentSizeChange() async {
    size.setFrom(_component.size);

    _shadowImage =
        await game.world.createShadowOfComponent(this, _component.render);
  }

  @override
  FutureOr<void> onLoad() async {
    sprite = _component.sprite = await _component.tileDataProvider.getSprite();
    _globalImage[_component.runtimeType] =
        await game.world.createShadowOfComponent(this, _component.render);

    super.onLoad();
  }

  @override
  void onRemove() {
    _component.transform.removeListener(onTrackedComponentSizeChange);
    _component._removeShadow.removeListener(onComponentRemove);
    _shadowImage?.dispose();
    _shadowImage = null;
    super.onRemove();
  }
}
