import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/widgets.dart';

import 'value_generator.dart';

mixin ColorFilterMix on FlameGame {
  initColorFilter<T extends ColorFilterMix>([ColorFilterConfig? config]) {
    config ??= ColorFilterConfig();
    colorFilter = ColorFilterComponent<T>(config);
    add(colorFilter!);
  }

  ColorFilterComponent? colorFilter;

  ValueGeneratorComponent getValueGenerator(
    Duration duration, {
    double begin = 0.0,
    double end = 1.0,
    Curve curve = Curves.decelerate,
    VoidCallback? onFinish,
    ValueChanged<double>? onChange,
  }) {
    final valueGenerator = ValueGeneratorComponent(
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

class ColorFilterComponent<T extends ColorFilterMix> extends Component {
  ColorTween? _tween;

  ColorFilterConfig config;

  ColorFilterComponent(this.config) : super(priority: 999999999);

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    if (config.enable == true) {
      canvas.drawColor(
        config.color!,
        config.blendMode,
      );
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
