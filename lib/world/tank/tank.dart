library tank;

import 'dart:io';
import 'dart:math';
import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'package:flame_tiled/flame_tiled.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter/services.dart';
import 'package:tank_game/extensions.dart';
import 'package:tank_game/game.dart';
import 'package:tank_game/packages/collision_quad_tree/lib/collision_quad_tree.dart';
import 'package:tank_game/packages/sound/lib/sound.dart';
import 'package:tank_game/services/spritesheet/spritesheet.dart';
import 'package:tank_game/world/environment/brick.dart';
import 'package:tank_game/world/environment/heavy_brick.dart';
import 'package:tank_game/world/environment/spawn.dart';
import 'package:tank_game/world/environment/water.dart';

import '../world.dart';

part 'src/behaviors/available_directions.dart';
part 'src/behaviors/random_movement.dart';
part 'src/bullet.dart';
part 'src/core/base_tank.dart';
part 'src/core/direction.dart';
part 'src/core/hitbox_map_bounds.dart';
part 'src/core/hitbox_movement.dart';
part 'src/core/hitbox_movement_side.dart';
part 'src/core/trail.dart';
part 'src/enemy.dart';
part 'src/player.dart';
