import 'package:flame/components.dart';
import 'package:flame/extensions.dart';

mixin VisibilityMixin on PositionComponent {
  bool visible = true;

  bool get isVisible => visible;

  bool get isHidden => !visible;

  void hide() => visible = false;

  void show() => visible = true;

  void toggleVisibility() => visible = !visible;

  @override
  void render(Canvas canvas) {
    if (visible) {
      super.render(canvas);
    }
  }
}
