import 'dart:async';

import 'package:tank_game/game.dart';
import 'package:tank_game/world/core/actor.dart';
import 'package:tank_game/world/core/behaviors/collision_behavior.dart';
import 'package:tank_game/world/core/behaviors/detection/detectable_behavior.dart';
import 'package:tank_game/world/core/behaviors/detection/detector_behavior.dart';

mixin HideInTreesOptimizedCheckerMixin on ActorMixin {
  bool canHideInTrees = false;
  HideInTreesBehavior? hideInTreesBehavior;
}

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
  FutureOr<void> onLoad() {
    if (parent is HideInTreesOptimizedCheckerMixin) {
      (parent as HideInTreesOptimizedCheckerMixin).canHideInTrees = true;
      (parent as HideInTreesOptimizedCheckerMixin).hideInTreesBehavior = this;
    }
    return super.onLoad();
  }

  @override
  void onRemove() {
    if (parent is HideInTreesOptimizedCheckerMixin) {
      (parent as HideInTreesOptimizedCheckerMixin).canHideInTrees = false;
      (parent as HideInTreesOptimizedCheckerMixin).hideInTreesBehavior = null;
    }
    super.onRemove();
  }

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
              default:
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
              default:
                break;
            }
          }
        }
      } catch (_) {}

      try {
        final game = (parent.sgGame as MyGame);
        game.hudHideInTreesProvider.sendMessage(isHiddenInTrees);
      } catch (_) {}

      _last = isHiddenInTrees;
    }
    super.update(dt);
  }
}
