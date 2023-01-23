import 'dart:async';
import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/experimental.dart';
import 'package:flame_spatial_grid/flame_spatial_grid.dart';
import 'package:tank_game/game.dart';
import 'package:tank_game/world/world.dart';

class Tree extends SpriteComponent
    with HasGridSupport, HasGameReference<MyGame> {
  Tree(this.tileDataProvider, {super.position, super.size})
      : super(priority: RenderPriority.tree.priority) {
    boundingBox.collisionType =
        boundingBox.defaultCollisionType = CollisionType.passive;
    boundingBox.isSolid = true;
    paint.filterQuality = FilterQuality.none;
    paint.isAntiAlias = false;
  }

  TileDataProvider tileDataProvider;

  @override
  FutureOr<void> onLoad() async {
    sprite = await tileDataProvider.getSprite();
    super.onLoad();
  }
}

class TreeShadow extends Tree {
  TreeShadow(Tree tree)
      : super(tree.tileDataProvider,
            position: tree.position.clone(), size: tree.size.clone()) {
    currentCell = tree.currentCell;
    position.add(game.world.shadowOffset*1.2);
    boundingBox.collisionType =
        boundingBox.defaultCollisionType = CollisionType.inactive;
  }

  static Image? _shadowImage;

  Future<Image> loadShadowImage() async {
    if (_shadowImage != null) {
      return _shadowImage!;
    }

    if (sprite != null) {
      _shadowImage =
          await game.world.createShadowOfComponent(this, super.render);
      return _shadowImage!;
    }

    throw "Can't generate shadow without sprite";
  }

  @override
  //ignore: must_call_super
  void render(Canvas canvas) {
    final image = _shadowImage;
    if (image != null) {
      canvas.drawImage(image, Offset.zero, paint);
    }
  }

  @override
  FutureOr<void> onLoad() async {
    sprite = await tileDataProvider.getSprite();
    await loadShadowImage();
    super.onLoad();
  }
}
