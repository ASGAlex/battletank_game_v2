import 'dart:math';

import 'package:flame_spatial_grid/flame_spatial_grid.dart';
import 'package:tank_game/game.dart';
import 'package:tank_game/world/actors/human/human.dart';
import 'package:tank_game/world/actors/tank/tank.dart';
import 'package:tank_game/world/core/actor.dart';
import 'package:tank_game/world/core/behaviors/movement/random_movement_behavior.dart';
import 'package:tank_game/world/core/faction.dart';

class SpawnActorFactory {
  SpawnActorFactory._(this._actorFactory);

  final ActorMixin Function() _actorFactory;

  static const _typeOfTank = {
    0: 'simple',
    1: 'middle',
    2: 'advanced',
    3: 'heavy',
    4: 'fast',
  };

  factory SpawnActorFactory.tankFromContext({
    required MyGame game,
    required TileBuilderContext spawnBuilderContext,
  }) {
    var tankType = spawnBuilderContext.tiledObject!.properties
            .getValue<String>('tank_type') ??
        '';

    return SpawnActorFactory._(() {
      if (!_typeOfTank.containsValue(tankType)) {
        tankType = _typeOfTank[Random().nextInt(4)] ?? 'simple';
      }
      return TankEntity(tankType, game.tilesetManager);
    });
  }

  factory SpawnActorFactory.human() {
    return SpawnActorFactory._(() => HumanEntity());
  }

  factory SpawnActorFactory.humanRandomCrowd() {
    return SpawnActorFactory._(() {
      final human = HumanEntity();
      human.loaded.then((_) {
        human.add(RandomMovementBehavior(
          maxDirectionDistance: 10,
          minDirectionDistance: 3,
          maxPauseBetweenDirectionChanges: 5,
          outerWidth: 4,
        ));
        human.data.speed = 5;
      });
      return human;
    });
  }

  ActorMixin call(List<Faction> allowedFactions) {
    final actor = _actorFactory();
    actor.data.factions.addAll(allowedFactions);
    return actor;
  }
}
