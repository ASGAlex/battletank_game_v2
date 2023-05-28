import 'package:flame/components.dart';

extension Vector2Ext on Vector2 {
  Vector2 copyWith({double? x, double? y}) {
    return Vector2(x ?? this.x, y ?? this.y);
  }
}
