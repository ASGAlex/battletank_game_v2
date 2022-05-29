part of tank;

class _TrackTrail extends RectangleComponent {
  _TrackTrail({super.position, super.angle})
      : super(
          paint: Paint()..color = Colors.black.withOpacity(0.5),
          size: Vector2(1, 4),
          anchor: Anchor.topLeft,
        ) {
    if (_precompiledColors.isEmpty) {
      for (var opacity = 0.5; opacity >= 0; opacity -= 0.01) {
        _precompiledColors[opacity] = Colors.black.withOpacity(opacity);
      }
    }
  }

  double opacity = 0.5;
  double dtSum = 0;

  static final Map<double, Color> _precompiledColors = {};

  @override
  void update(double dt) {
    dtSum += dt;
    if (dtSum >= 1) {
      dtSum = 0;
      opacity -= 0.01;
      if (opacity <= 0) {
        renderShape = false;
        removeFromParent();
      } else {
        final newColor = _precompiledColors[opacity];
        if (newColor != null) {
          paint.color = newColor;
        }
      }
    }
    super.update(dt);
  }
}
