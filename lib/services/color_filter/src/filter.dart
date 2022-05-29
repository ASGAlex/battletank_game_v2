part of color_filter;

mixin ColorFilterMix on FlameGame {
  initColorFilter<T extends ColorFilterMix>([ColorFilterConfig? config]) {
    config ??= ColorFilterConfig();
    colorFilter = _ColorFilterComponent<T>(config);
    add(colorFilter!);
  }

  _ColorFilterComponent? colorFilter;

  _ValueGeneratorComponent getValueGenerator(
    Duration duration, {
    double begin = 0.0,
    double end = 1.0,
    Curve curve = Curves.decelerate,
    VoidCallback? onFinish,
    ValueChanged<double>? onChange,
  }) {
    final valueGenerator = _ValueGeneratorComponent(
      duration,
      end: end,
      begin: begin,
      curve: curve,
      onFinish: onFinish,
      onChange: onChange,
    );
    add(valueGenerator);
    return valueGenerator;
  }
}

class ColorFilterConfig {
  Color? color;
  BlendMode blendMode;

  ColorFilterConfig({this.color, this.blendMode = BlendMode.color});

  bool get enable => color != null;
}

class _ColorFilterComponent<T extends ColorFilterMix> extends Component {
  ColorTween? _tween;

  ColorFilterConfig config;

  _ColorFilterComponent(this.config) : super(priority: int64MaxValue);

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    if (config.enable == true) {
      // canvas.save();
      canvas.drawColor(
        config.color!,
        config.blendMode,
      );
      // canvas.restore();
    }
  }

  void animateTo(
    Color color, {
    BlendMode? blendMode,
    Duration duration = const Duration(milliseconds: 500),
    curve = Curves.decelerate,
    VoidCallback? onFinish,
  }) {
    if (blendMode != null) {
      config.blendMode = blendMode;
    }
    _tween = ColorTween(
      begin: config.color ?? const Color(0x00000000),
      end: color,
    );

    final game = findParent<T>();

    game?.getValueGenerator(
      duration,
      onChange: (value) {
        config.color = _tween?.transform(value);
      },
      onFinish: () {
        config.color = color;
        onFinish?.call();
      },
      curve: curve,
    ).start();
  }
}
