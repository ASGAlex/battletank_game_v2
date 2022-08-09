import 'package:flame/components.dart';
import 'package:flame/extensions.dart';

extension Vector2Ext on Vector2 {
  Vector2 translate(double x, double y) {
    return Vector2(this.x + x, this.y + y);
  }

  Vector2 copyWith({double? x, double? y}) {
    return Vector2(x ?? this.x, y ?? this.y);
  }
}

extension StepTime on SpriteAnimation {
  Duration get duration {
    double durationMicroseconds = 0;
    for (final frame in frames) {
      durationMicroseconds += (frame.stepTime * 1000000);
    }
    return Duration(microseconds: durationMicroseconds.toInt());
  }
}
