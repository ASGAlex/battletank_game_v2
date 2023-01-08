import 'package:tank_game/world/tank/core/base_tank.dart';
import 'package:tank_game/world/tank/type/types.dart';

class TankTypeController {
  TankTypeController(this.parent);

  Tank parent;
  TankType _type = TankType0();

  TankType get type => _type;

  set type(TankType type) {
    _type = type;
    _type.onLoad().then((_) {
      _setParentValues();
    });
  }

  _setParentValues() {
    parent.health = _type.health;
    parent.speed = _type.speed;
    parent.size = _type.size;
    parent.damage = _type.damage;
    parent.fireDelay = _type.fireDelay;

    parent.animations = {
      TankState.run: _type.animationRun,
      TankState.idle: _type.animationIdle,
      TankState.die: _type.animationDie,
      TankState.wreck: _type.animationWreck
    };
  }

  Future<void> onLoad() => _type.onLoad().then((value) {
        _setParentValues();
      });
}
