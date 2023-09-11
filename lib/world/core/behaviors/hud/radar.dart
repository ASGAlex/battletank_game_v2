import 'package:flame/experimental.dart';
import 'package:tank_game/game.dart';
import 'package:tank_game/world/actors/tank/tank.dart';
import 'package:tank_game/world/core/behaviors/core_behavior.dart';
import 'package:tank_game/world/core/behaviors/hud/hud_bounds_renderer.dart';

class RadarBehavior extends CoreBehavior
    with HasGameReference<MyGame>
    implements BoundsRenderController {
  bool keep = true;
  bool _showTanks = true;

  @override
  bool get showBounds => _showTanks;

  set showBounds(bool value) {
    if (_showTanks != value) {
      _showTanks = value;
    }
  }

  @override
  void onMount() {
    final tanks = game.world.tankLayer.children.query<TankEntity>();
    for (final tank in tanks) {
      tank.hudBoundsRenderer.controller = this;
    }
    super.onMount();
  }

  @override
  void onRemove() {
    final tanks = game.world.tankLayer.children.query<TankEntity>();
    for (final tank in tanks) {
      tank.hudBoundsRenderer.controller = null;
    }
    super.onRemove();
  }
}
