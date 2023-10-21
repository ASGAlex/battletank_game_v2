import 'package:tank_game/packages/behaviors/lib/flame_behaviors.dart';

abstract class CoreBehavior<Parent extends EntityMixin>
    extends Behavior<Parent> {
  CoreBehavior({
    super.children,
  });

  @override
  void updateTree(double dt) {
    if (isRemoving || isRemoved) return;
    super.updateTree(dt);
  }
}
