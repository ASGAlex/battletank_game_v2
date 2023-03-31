import 'package:flame_behaviors/flame_behaviors.dart';
import 'package:tank_game/world/core/actor.dart';

abstract class AttackBehavior extends Behavior<ActorMixin> {
  void attack();
}
