import 'dart:async';

import 'package:flame/components.dart';
import 'package:flame/experimental.dart';
import 'package:flame_message_stream/flame_message_stream.dart';
import 'package:tank_game/game.dart';
import 'package:tank_game/world/core/scenario/scripts/event.dart';

abstract class ScriptCore extends Component
    with MessageListenerMixin<ScenarioEvent>, HasGameReference<MyGame> {
  double _lifetimeMax = 0;

  double get lifetimeMax => _lifetimeMax;

  set lifetimeMax(double value) {
    _lifetimeMax = value;
    _timeOver = _lifetimeMax <= _lifeTimeDt;
  }

  double _lifeTimeDt = 0;
  bool _timeOver = false;

  void resetLifetime([double? newLifetime]) {
    _timeOver = false;
    _lifeTimeDt = 0;
    if (newLifetime != null) {
      lifetimeMax = newLifetime;
    }
  }

  void scriptUpdate(double dt);

  @override
  void update(double dt) {
    if (_lifetimeMax > 0 && !_timeOver) {
      if (_lifeTimeDt < _lifetimeMax) {
        scriptUpdate(dt);
        // super.update(dt);
      } else if (_lifeTimeDt >= _lifetimeMax) {
        _timeOver = true;
      }
      _lifeTimeDt += dt;
    } else {
      // super.update(dt);
    }
  }

  @override
  FutureOr<void> onLoad() {
    listenProvider(game.scenarioEventProvider);
    return super.onLoad();
  }

  @override
  void onRemove() {
    dispose();
    super.onRemove();
  }
}
