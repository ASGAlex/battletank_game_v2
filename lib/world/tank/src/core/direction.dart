import 'dart:math';

const PI_180 = (180 / pi);

enum Direction {
  up(0),
  left(1),
  down(2),
  right(3);

  const Direction(this.value);

  factory Direction.fromValue(int value) {
    if (value == 0) return Direction.up;
    if (value == 1) return Direction.left;
    if (value == 2) return Direction.down;
    if (value == 3) return Direction.right;

    throw 'invalid value: $value';
  }

  final int value;

  Direction rotateCCW() {
    int newVal = value + 1;
    if (newVal > 3) {
      newVal = 0;
    }
    return Direction.fromValue(newVal);
  }

  Direction rotateCW() {
    int newVal = value - 1;
    if (newVal < 0) {
      newVal = 3;
    }
    return Direction.fromValue(newVal);
  }

  double get angle {
    switch (this) {
      case Direction.down:
        return 180 / PI_180;
      case Direction.up:
        // we can't use 0 here because then no movement happens
        // we're just going as close to 0.0 without being exactly 0.0
        // if you have a better idea. Please be my guest
        return 0.0000001 / PI_180;
      case Direction.left:
        return -90 / PI_180;
      case Direction.right:
        return 90 / PI_180;
      default:
        return 0;
    }
  }
}
