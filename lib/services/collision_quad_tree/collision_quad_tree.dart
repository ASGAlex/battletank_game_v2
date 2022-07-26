library collision_quad_tree;

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'package:flame/game.dart';
import 'package:flame/src/collisions/broadphase.dart';
import 'package:flame/src/collisions/collision_callbacks.dart';
import 'package:flame/src/collisions/hitboxes/hitbox.dart';
import 'package:flame_tiled/flame_tiled.dart';
import 'package:flutter/widgets.dart';
import 'package:tank_game/world/environment/water.dart';
import 'package:tank_game/world/tank/tank.dart';

part 'mixin/collision_controller.dart';
part 'mixin/has_quad_tree_collision_detection.dart';
part 'src/broadphase.dart';
part 'src/collision_detection.dart';
part 'src/quad_tree.dart';
