import 'dart:collection';
import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/image_composition.dart';
import 'package:flame/sprite.dart';
import 'package:tank_game/game.dart';
import 'package:tank_game/packages/collision_quad_tree/lib/collision_quad_tree.dart';
import 'package:tank_game/packages/tiled_utils/lib/tiled_utils.dart';
import 'package:tank_game/world/tank/tank.dart';
import 'package:tank_game/world/world.dart';

class Brick extends PositionComponent
    with CollisionCallbacks, CollisionQuadTreeController<MyGame>, MyGameRef {
  Brick(this.tileProcessor, {super.position, super.size})
      : super(priority: RenderPriority.player.priority);

  TileProcessor tileProcessor;

  int _hitsByBullet = 0;
  static const halfBrick = 4.0;
  static final brickSize = Vector2.all(halfBrick * 2);

  late StaticCollision _hitbox;

  @override
  Future<void> onLoad() async {
    // sprite = await tileProcessor.getSprite();
    final collision = tileProcessor.getCollisionRect();
    if (collision != null) {
      collision.collisionType = CollisionType.passive;
      _hitbox = StaticCollision(collision);
      add(_hitbox);
    }
    super.onLoad();
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    if (other is Bullet) {
      _collideWithBullet(other);
    }

    super.onCollision(intersectionPoints, other);
  }

  void _collideWithBullet(Bullet bullet) {
    game.brickRenderer.imageChanged = true;
    if (_hitsByBullet >= 1) {
      _die();
    } else {
      switch (bullet.direction) {
        case Direction.right:
          size.x -= halfBrick;
          position.x += halfBrick;
          break;
        case Direction.up:
          size.y -= halfBrick;
          break;
        case Direction.left:
          size.x -= halfBrick;
          break;
        case Direction.down:
          size.y -= halfBrick;
          position.y += halfBrick;
          break;
      }
      _hitbox.size = size;
      updateQuadTreeCollision(_hitbox);
    }
    _hitsByBullet++;
  }

  _die() {
    if (isRemoving) return;
    removeFromParent();
    game.brickRenderer.bricks.remove(this);
  }

  @override
  void renderTree(Canvas canvas) {
    // TODO: implement renderTree
    // super.renderTree(canvas);
  }
}

class BrickRenderController extends PositionComponent {
  final bricks = HashSet<Brick>();

  bool imageChanged = true;
  Sprite? sprite;
  Image? _image;

  @override
  render(Canvas canvas) async {
    if (_image == null || (imageChanged && sprite != null)) {
      final batch = SpriteBatch(sprite!.image);
      for (final brick in bricks) {
        var source = sprite!.src;
        if (brick.size.x < 8) {
          source = Rect.fromLTWH(
              source.left, source.top, brick.size.x, source.height);
        }
        if (brick.size.y < 8) {
          source = Rect.fromLTWH(
              source.left, source.top, source.width, brick.size.y);
        }
        batch.add(source: source, offset: brick.position);
      }
      final component = SpriteBatchComponent(spriteBatch: batch);
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      component.render(canvas);
      final picture = recorder.endRecording();
      picture.toImage(1000, 1000).then((value) => _image = value);

      imageChanged = false;
    }

    canvas.drawImage(_image!, Offset.zero, Paint());
  }
}
