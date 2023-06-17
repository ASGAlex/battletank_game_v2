import 'package:tank_game/world/core/behaviors/collision_behavior.dart';

class SlowDownBySandBehavior extends CollisionBehavior {
  final minimumTiles = 2;

  bool _slowDown = false;
  bool _last = false;
  int _collisionsWithSand = 0;

  int get collisionsWithSand => _collisionsWithSand;

  set collisionsWithSand(int value) {
    _collisionsWithSand = value;
    if (collisionsWithSand >= minimumTiles) {
      _slowDown = true;
    } else {
      _slowDown = false;
    }
  }

  bool get isSlowedDown => _slowDown;
  double _originalSpeed = 0;

  @override
  void update(double dt) {
    if (isSlowedDown) {
      if (_originalSpeed == 0) {
        _originalSpeed = parent.data.speed;
      }
      parent.data.speed = _originalSpeed - 20;
      if (parent.data.speed < 0) {
        parent.data.speed = 0;
      }
    }

    if (isSlowedDown != _last) {
      if (!isSlowedDown) {
        parent.data.speed = _originalSpeed;
        _originalSpeed = 0;
      }
      _last = isSlowedDown;
    }
    super.update(dt);
  }
}
