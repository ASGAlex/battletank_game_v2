import 'package:tank_game/services/audio/effect_loop/effect_loop.dart';
import 'package:tank_game/world/core/actor.dart';
import 'package:tank_game/world/core/behaviors/core_behavior.dart';

class MovementAudioEffectBehavior extends CoreBehavior<ActorMixin> {
  MovementAudioEffectBehavior({required AudioEffectLoop effect})
      : _audioEffectLoop = effect {
    priority = 99;
  }

  final AudioEffectLoop _audioEffectLoop;

  @override
  void update(double dt) {
    if (parent.coreState == ActorCoreState.move) {
      _audioEffectLoop.play();
    } else {
      _audioEffectLoop.stop();
    }
  }

  @override
  void onRemove() {
    _audioEffectLoop.dispose();
    super.onRemove();
  }
}
