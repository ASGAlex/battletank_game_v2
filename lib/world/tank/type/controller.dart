import 'dart:ui';

import 'package:flame/extensions.dart';
import 'package:tank_game/world/tank/core/base_tank.dart';
import 'package:tank_game/world/tank/type/types.dart';

class TankTypeController {
  TankTypeController(this.tank);

  static final _shadowImageByType = <TankType, Image>{};

  Tank tank;
  TankType _type = TankType0();

  TankType get type => _type;

  set type(TankType type) {
    _type = type;
    _type.onLoad().then((_) {
      _setParentValues();
    });
  }

  _setParentValues() {
    tank.health = _type.health;
    tank.speed = _type.speed;
    tank.size = _type.size;
    tank.damage = _type.damage;
    tank.fireDelay = _type.fireDelay;

    tank.animations = {
      TankState.run: _type.animationRun,
      TankState.idle: _type.animationIdle,
      TankState.die: _type.animationDie,
      TankState.wreck: _type.animationWreck
    };
  }

  Future<void> onLoad() => _type.onLoad().then((value) {
        _setParentValues();
      });

  Future<Image> getShadow() async {
    var image = _shadowImageByType[type];
    if (image == null) {
      image =
          await tank.game.world.createShadowOfComponent(tank, tank.superRender);
      _shadowImageByType[type] = image;
    }
    return image;
  }
}
