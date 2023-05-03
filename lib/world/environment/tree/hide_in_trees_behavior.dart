import 'package:tank_game/game.dart';
import 'package:tank_game/world/core/behaviors/collision_behavior.dart';
import 'package:tank_game/world/core/behaviors/detection/detectable_behavior.dart';
import 'package:tank_game/world/core/behaviors/detection/detector_behavior.dart';

class HideInTreesBehavior extends CollisionBehavior {
  final minimumTrees = 3;

  bool _hiddenInTrees = false;
  bool _last = false;
  int _collisionsWithTrees = 0;

  int get collisionsWithTrees => _collisionsWithTrees;

  set collisionsWithTrees(int value) {
    _collisionsWithTrees = value;
    if (collisionsWithTrees >= minimumTrees) {
      _hiddenInTrees = true;
    } else {
      _hiddenInTrees = false;
    }
  }

  bool get isHiddenInTrees => _hiddenInTrees;

  @override
  void update(double dt) {
    if (isHiddenInTrees != _last) {
      try {
        final detectables = parent.findBehaviors<DetectableBehavior>();
        if (isHiddenInTrees) {
          for (final detectable in detectables) {
            switch (detectable.detectionType) {
              case DetectionType.visual:
                detectable.distanceModifier = 0.2;
                break;
              case DetectionType.audial:
                detectable.distanceModifier = 0.5;
                break;
            }
          }
        } else {
          for (final detectable in detectables) {
            switch (detectable.detectionType) {
              case DetectionType.visual:
                detectable.distanceModifier = 1;
                break;
              case DetectionType.audial:
                detectable.distanceModifier = 1;
                break;
            }
          }
        }
      } catch (_) {}

      try {
        final game = (parent.sgGame as MyGame);
        game.hudVisibility.setVisibility(!isHiddenInTrees);
      } catch (_) {}

      _last = isHiddenInTrees;
    }
    super.update(dt);
  }
}
