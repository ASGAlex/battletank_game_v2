import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame_spatial_grid/flame_spatial_grid.dart';
import 'package:tank_game/world/world.dart';

class Tree extends SpriteComponent with HasGridSupport {
  Tree(this.tileDataProvider, {super.position, super.size})
      : super(priority: RenderPriority.tree.priority) {
    boundingBox.collisionType =
        boundingBox.defaultCollisionType = CollisionType.passive;
    boundingBox.isSolid = true;
  }

  TileDataProvider tileDataProvider;

  @override
  Future<void> onLoad() async {
    sprite = await tileDataProvider.getSprite();
    super.onLoad();
  }
}
//
// class TreeLayer extends PositionComponent {
//   TreeLayer(this.trees) {
//     position = trees.position.clone();
//     trees.position = Vector2(0, 0);
//     priority = trees.priority;
//     Color color = material.Colors.black;
//     final shadowPaint = Paint()
//       ..colorFilter = ColorFilter.mode(color.withOpacity(0.4), BlendMode.srcIn);
//     shadowPaint.imageFilter = ImageFilter.blur(sigmaX: 1, sigmaY: 1);
//     final recorder = PictureRecorder();
//     final canvas = Canvas(recorder);
//     final settings = SettingsController();
//     if (settings.graphicsQuality != GraphicsQuality.low) {
//       canvas.saveLayer(Rect.largest, shadowPaint);
//       canvas.translate(-3, 3);
//       trees.render(canvas);
//       canvas.restore();
//     }
//     trees.render(canvas);
//     recorder
//         .endRecording()
//         .toImage(trees.image.width, trees.image.height)
//         .then((value) {
//       image = value;
//     });
//   }
//
//   Image? image;
//   final ImageComponent trees;
//
//   @override
//   void render(Canvas canvas) {
//     if (image == null) {
//       trees.render(canvas);
//     } else {
//       canvas.drawImage(image!, const Offset(0, 0), Paint());
//     }
//   }
// }
