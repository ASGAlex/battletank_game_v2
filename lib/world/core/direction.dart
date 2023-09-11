import 'dart:math';

const PI_180 = (180 / pi);

enum DirectionExtended {
  up(0),
  left(1),
  down(2),
  right(3);

  const DirectionExtended(this.value);

  factory DirectionExtended.fromValue(int value) {
    if (value == 0) return DirectionExtended.up;
    if (value == 1) return DirectionExtended.left;
    if (value == 2) return DirectionExtended.down;
    if (value == 3) return DirectionExtended.right;

    throw 'invalid value: $value';
  }

  final int value;

  DirectionExtended rotateCCW() {
    int newVal = value + 1;
    if (newVal > 3) {
      newVal = 0;
    }
    return DirectionExtended.fromValue(newVal);
  }

  DirectionExtended rotateCW() {
    int newVal = value - 1;
    if (newVal < 0) {
      newVal = 3;
    }
    return DirectionExtended.fromValue(newVal);
  }

  DirectionExtended get opposite {
    switch (this) {
      case DirectionExtended.up:
        return DirectionExtended.down;
      case DirectionExtended.left:
        return DirectionExtended.right;
      case DirectionExtended.down:
        return DirectionExtended.up;
      case DirectionExtended.right:
        return DirectionExtended.left;
    }
  }

  Iterable<DirectionExtended> get perpendicular {
    switch (this) {
      case DirectionExtended.up:
      case DirectionExtended.down:
        return const [DirectionExtended.right, DirectionExtended.left];
      case DirectionExtended.left:
      case DirectionExtended.right:
        return const [DirectionExtended.up, DirectionExtended.down];
    }
  }

  double get angle {
    switch (this) {
      case DirectionExtended.down:
        return 180 / PI_180;
      case DirectionExtended.up:
        // we can't use 0 here because then no movement happens
        // we're just going as close to 0.0 without being exactly 0.0
        // if you have a better idea. Please be my guest
        return 0.0000001 / PI_180;
      case DirectionExtended.left:
        return -90 / PI_180;
      case DirectionExtended.right:
        return 90 / PI_180;
      default:
        return 0;
    }
  }
}
