import 'package:flame_behaviors/flame_behaviors.dart';
import 'package:tank_game/world/core/actor.dart';
import 'package:tank_game/world/core/behaviors/detection/detector_behavior.dart';
import 'package:tank_game/world/core/behaviors/distance_callback_mixin.dart';

class DetectableBehavior extends Behavior<ActorMixin>
    with DistanceCallbackMixin {
  DetectableBehavior({
    this.distanceModifier = 0,
    required this.detectionType,
  });

  double distanceModifier;
  final DetectionType detectionType;

  @override
  bool get registerDistanceFunction => false;
}
