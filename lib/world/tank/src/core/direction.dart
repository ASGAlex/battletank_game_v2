part of tank;

const PI_180 = (180 / pi);

enum Direction {
  right(0),
  up(1),
  left(2),
  down(3);

  const Direction(this.value);

  factory Direction._fromValue(int value) {
    if (value == 0) return Direction.right;
    if (value == 1) return Direction.up;
    if (value == 2) return Direction.left;
    if (value == 3) return Direction.down;

    throw 'invalid value: $value';
  }

  final int value;

  Direction rotateCCW() {
    int newVal = value + 1;
    if (newVal > 3) {
      newVal = 0;
    }
    return Direction._fromValue(newVal);
  }

  Direction rotateCW() {
    int newVal = value - 1;
    if (newVal < 0) {
      newVal = 3;
    }
    return Direction._fromValue(newVal);
  }

  double get angle {
    switch (this) {
      case Direction.left:
        return 180 / PI_180;
      case Direction.right:
        // we can't use 0 here because then no movement happens
        // we're just going as close to 0.0 without being exactly 0.0
        // if you have a better idea. Please be my guest
        return 0.0000001 / PI_180;
      case Direction.up:
        return -90 / PI_180;
      case Direction.down:
        return 90 / PI_180;
      default:
        return 0;
    }
  }
}
