import 'dart:math';

import 'package:flame/extensions.dart';
import 'package:flame_spatial_grid/flame_spatial_grid.dart';

import 'base_tank.dart';

enum TankType {
  simple(name: 'simple', order: 0),
  middle(name: 'middle', order: 1),
  advanced(name: 'advanced', order: 2),
  heavy(name: 'heavy', order: 3),
  fast(name: 'fast', order: 4);

  const TankType({required this.name, required this.order});

  final String name;
  final int order;

  static TankType getRandom() {
    final index = Random().nextInt(5);
    for (final value in TankType.values) {
      if (value.order == index) {
        return value;
      }
    }
    return TankType.simple;
  }

  static TankType fromString(String name) {
    switch (name) {
      case 'simple':
        return TankType.simple;
      case 'middle':
        return TankType.middle;
      case 'advanced':
        return TankType.advanced;
      case 'heavy':
        return TankType.heavy;
      case 'fast':
        return TankType.fast;
    }

    return TankType.getRandom();
  }
}

class TankTypeController {
  TankTypeController(this.parent);

  static final _shadowImageByType = <TankType, Image?>{};

  final Tank parent;
  TankType _type = TankType.simple;

  TankType get type => _type;

  set type(TankType value) {
    _type = value;
    _loadTypeData();

    if (value == TankType.heavy) {
      parent.boundingBox.collisionCheckFrequency = 0.5;
      parent.movementHitbox.collisionCheckFrequency = 0.5;
      parent.bodyHitbox.collisionCheckFrequency = 0.5;
    }
  }

  void _loadTypeData() {
    final tilesetManager = parent.game.tilesetManager;

    final tsxByType = {
      TankState.run: ['tank', type.name],
      TankState.idle: ['tank', '${type.name}_idle'],
      TankState.die: ['boom_big', 'boom_big'],
      TankState.wreck: ['tank', '${type.name}_wreck'],
    };

    for (final tsxEntry in tsxByType.entries) {
      final tileCache =
          tilesetManager.getTile(tsxEntry.value.first, tsxEntry.value.last);
      final animation =
          tileCache?.spriteAnimation ?? tileCache?.sprite?.toAnimation();

      if (animation == null) {
        throw "Can't find animation of type '${tsxEntry.key}' at tileset '${tsxEntry.value.first}' with name '${tsxEntry.value.last}'";
      }
      parent.animations ??= {};
      parent.animations![tsxEntry.key] = animation;
      if (tsxEntry.value.last == type.name) {
        _setProperties(tileCache!);
      }
    }
  }

  void _setProperties(TileCache tileCache) {
    parent.size = tileCache.sprite?.srcSize ?? Vector2(14, 16);
    parent.health = tileCache.properties.getValue<double>('health') ?? 1;
    parent.speed = tileCache.properties.getValue<int>('speed') ?? 50;
    parent.damage = tileCache.properties.getValue<double>('damage') ?? 1;
    final fireDelayMs = tileCache.properties.getValue<int>('fireDelay') ?? 1500;
    parent.fireDelay = Duration(milliseconds: fireDelayMs);
  }
}
