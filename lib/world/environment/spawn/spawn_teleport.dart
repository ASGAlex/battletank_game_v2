import 'package:tank_game/world/core/behaviors/animation/animation_behavior.dart';
import 'package:tank_game/world/environment/spawn/spawn_core_entity.dart';

class SpawnTeleport extends SpawnCoreEntity {
  SpawnTeleport({
    required super.rootComponent,
    required super.buildContext,
    required super.actorFactory,
  }) : super(
          animationConfig: const AnimationConfig(
            tileset: 'spawn',
            tileType: 'spawn',
            reversedLoop: true,
          ),
        );
}
