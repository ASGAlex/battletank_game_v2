import 'package:tank_game/world/environment/buildings/brick.dart';

class HeavyBrickEntity extends BrickEntity {
  HeavyBrickEntity({super.sprite, super.position, super.size})
      : super(resizeOnHit: false) {
    data.health = 10000;
  }
}
