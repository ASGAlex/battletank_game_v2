import 'dart:io';
import 'dart:ui';

import 'package:audioplayers/audioplayers.dart';
import 'package:flame/components.dart';
import 'package:flame/flame.dart';
import 'package:flame/game.dart';
import 'package:flame/image_composition.dart';
import 'package:flame/input.dart';
import 'package:flame/sprite.dart';
import 'package:flame_tiled/flame_tiled.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tank_game/packages/lazy_collision/lib/lazy_collision.dart';
import 'package:tank_game/packages/sound/lib/sound.dart';
import 'package:tank_game/packages/tiled_utils/lib/tiled_utils.dart';
import 'package:tank_game/ui/joystick.dart';
import 'package:tank_game/world/environment/spawn.dart';
import 'package:tank_game/world/tank/tank.dart';
import 'package:tank_game/world/world.dart';
import 'package:tiled/tiled.dart';

import 'packages/collision_quad_tree/lib/collision_quad_tree.dart';
import 'packages/collision_quad_tree/lib/src/collision_detection.dart';
import 'packages/color_filter/lib/color_filter.dart';
import 'world/environment/brick.dart';
import 'world/environment/water.dart';

class MyGame extends FlameGame
    with
        ColorFilterMix,
        KeyboardEvents,
        SingleGameInstance,
        HasQuadTreeCollisionDetection,
        ScrollDetector,
        HasDraggables,
        HasTappables,
        ObjectLayers {
  MyGame(this.mapFile);

  static final fpsTextPaint = TextPaint(
    style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
  );

  String mapFile;

  final lazyCollisionService = LazyCollisionsService();

  bool isPlayerHiddenFromEnemy = false;
  List<Enemy> enemies = [];
  Player? player;

  BrickRenderController? brickRenderer;

  RenderableTiledMap? currentMap;

  MyJoystick? joystick;

  final hudTextPaintNormal = TextPaint(
      style: const TextStyle(
    fontWeight: FontWeight.bold,
    color: Colors.black,
    backgroundColor: Colors.white,
  ));

  final hudTextPaintGood = TextPaint(
      style: const TextStyle(
    fontWeight: FontWeight.bold,
    color: Colors.green,
    backgroundColor: Colors.black12,
  ));

  final hudTextPaintDanger = TextPaint(
      style: const TextStyle(
    fontWeight: FontWeight.bold,
    color: Colors.red,
    fontSize: 24,
    backgroundColor: Colors.black12,
  ));

  @override
  Future<void> onLoad() async {
    print('Start loading!');
    super.onLoad();
    initColorFilter<MyGame>();

    print('loading sounds...');
    loadSounds();
    print('done.');

    print('loading map...');
    var tiledComponent = await TiledComponent.load(mapFile, Vector2.all(8));
    currentMap = tiledComponent.tileMap;
    initCollisionDetection(Rect.fromLTWH(
        0,
        0,
        (tiledComponent.tileMap.map.width *
                tiledComponent.tileMap.map.tileWidth)
            .toDouble(),
        (tiledComponent.tileMap.map.height *
                tiledComponent.tileMap.map.tileHeight)
            .toDouble()));
    print('done.');

    print('Compiling ground layer...');
    final imageCompiler = ImageBatchCompiler();
    final ground = await imageCompiler.compileMapLayer(
        tileMap: tiledComponent.tileMap, layerNames: ['ground']);
    ground.priority = RenderPriority.ground.priority;
    add(ground);
    print('done.');

    print('Compiling tree layer...');
    final tree = await imageCompiler
        .compileMapLayer(tileMap: tiledComponent.tileMap, layerNames: ['tree']);
    tree.priority = RenderPriority.tree.priority;
    add(tree);
    print('done.');

    print('Preparing back buffer...');
    final trackController = TrackTrailController();
    await trackController.init(tiledComponent.tileMap);
    add(trackController);
    print('done.');

    print('Starting lazy collision service...');
    await lazyCollisionService.run({
      'tree': const Duration(milliseconds: 100),
    });
    print('done.');

    print('Creating trees and collision tiles...');
    brickRenderer = BrickRenderController(
        ((currentMap?.map.width ?? 0) * (currentMap?.map.tileWidth ?? 0))
            .toInt(),
        ((currentMap?.map.height ?? 0) * (currentMap?.map.tileHeight ?? 0))
            .toInt());
    TileProcessor.processTileType(
        tileMap: tiledComponent.tileMap,
        processorByType: <String, TileProcessorFunc>{
          'tree': ((tile, position, size) {
            final collision = tile.getCollisionRect();
            if (collision != null) {
              collision.position = position;
              lazyCollisionService.addHitbox(
                  position: position, size: size, layer: 'tree');
            }
          }),
          'water': ((tile, position, size) {
            add(WaterCollide(tile, position: position, size: size));
          }),
          'brick': ((tile, position, size) async {
            final brick = Brick(tile, position: position, size: size);
            add(brick);
            brickRenderer?.sprite ??= await tile.getSprite();
            brickRenderer?.bricks.add(brick);
          }),
          'heavy_brick': ((tile, position, size) {
            // add(HeavyBrick(tile, position: position, size: size));
          }),
        },
        layersToLoad: [
          'tree',
          'collision'
        ]);
    add(brickRenderer!);
    print('done.');

    print('Creating water tiles...');
    final animationCompiler = AnimationBatchCompiler();
    TileProcessor.processTileType(
        tileMap: tiledComponent.tileMap,
        processorByType: <String, TileProcessorFunc>{
          'water': ((tile, position, size) {
            animationCompiler.addTile(position, tile);
          }),
        },
        layersToLoad: [
          'water',
        ]);
    print('done.');

    print('Compiling water animation...');
    final animatedWater = await animationCompiler.compile();
    animatedWater.priority = RenderPriority.water.priority;
    add(animatedWater);
    print('done.');

    print('Loading spawns...');
    loadSpawns(tiledComponent);
    print('done.');

    print('Spawning the Player...');
    camera.viewport = FixedResolutionViewport(Vector2(400, 250));
    // camera.zoom = 1;

    final image = await images.load('joystick.png');
    final sheet = SpriteSheet.fromColumnsAndRows(
      image: image,
      columns: 6,
      rows: 1,
    );
    if (Platform.isAndroid || Platform.isIOS) {
      joystick = MyJoystick(
        priority: RenderPriority.ui.priority,
        knob: SpriteComponent(
          sprite: sheet.getSpriteById(1),
          size: Vector2.all(30),
        ),
        background: SpriteComponent(
          sprite: sheet.getSpriteById(0),
          size: Vector2.all(60),
        ),
        margin: const EdgeInsets.only(left: 20, bottom: 40),
      );
      add(HudButtonComponent(
          button: SpriteComponent(
              sprite: sheet.getSpriteById(3),
              size: Vector2.all(
                  50)) /*..add(OpacityEffect.to(0.5, EffectController(duration: 0)))*/,
          buttonDown: SpriteComponent(
              sprite: sheet.getSpriteById(5), size: Vector2.all(50)),
          onPressed: playerFire,
          priority: RenderPriority.ui.priority,
          margin: const EdgeInsets.only(bottom: 40, right: 20)));
      add(joystick!);

      // joystick?.background
      //     ?.add(OpacityEffect.to(0.5, EffectController(duration: 0)));
      // joystick?.knob?.add(OpacityEffect.to(0.8, EffectController(duration: 0)));
    }

    restorePlayer();
    // camera.snapTo(Vector2.all(1110));
    print('done.');

    // Future.delayed(const Duration(seconds: 5)).then((value) {
    //   for (var i = 0; i < 1; i++) {
    //     spawnEnemy();
    //   }
    // });

    // print('Prepare UI...');
    // add(FpsTextComponent(textRenderer: hudTextPaintDanger)
    //   ..x = 0
    //   ..y = 0);
    // print('done.');

    print('All done, game started!');
    Flame.device.setLandscape();
    Flame.device.fullScreen();
  }

  playerFire() {
    player?.onFire();
  }

  loadSpawns(TiledComponent tiledComponent) {
    final spawns =
        tiledComponent.tileMap.getLayer<ObjectGroup>('spawn')?.objects;
    if (spawns != null) {
      for (final spawnObject in spawns) {
        final newSpawn = Spawn(
            position: Vector2(spawnObject.x + spawnObject.width / 2,
                spawnObject.y + spawnObject.height / 2),
            isForPlayer: spawnObject.name == 'spawn_player');
        for (final property in spawnObject.properties) {
          switch (property.name) {
            case 'cooldown_seconds':
              newSpawn.cooldown = Duration(seconds: int.parse(property.value));
              break;
            case 'tanks_inside':
              newSpawn.tanksInside = int.parse(property.value);
              break;
            case 'trigger_distance':
              newSpawn.triggerDistance = double.parse(property.value);
              break;
          }
        }
        addSpawn(newSpawn);
      }
    }
  }

  loadSounds() {
    AudioPlayer.global.changeLogLevel(LogLevel.info);
    final sound = Sound();
    sound.playMusic('intro.m4a');
    final sfxList = [
      () => SfxLongLoop('move_player.m4a'),
      () => SfxLongLoop('move_enemies.m4a'),
      () => SfxShort('explosion_player.m4a', 1),
      () => SfxShort('explosion_enemy.m4a', 1),
      () => SfxShort('player_fire_bullet.m4a', 1),
      () => SfxShort('player_bullet_wall.m4a', 1),
      () => SfxShort('player_bullet_strong_wall.m4a', 1),
      () => SfxShort('bullet_strong_tank.m4a', 1),
    ];
    sound.init(sfxList);
  }

  Future<Player> restorePlayer() async {
    var spawn = await Spawn.waitFree(true);
    final object = Player(position: spawn.position.clone());
    await spawn.createTank(object, true);
    camera.followComponent(object);
    player = object;
    return object;
  }

  Future<Enemy> spawnEnemy() async {
    var spawn = await Spawn.waitFree();
    final object = Enemy(position: spawn.position.clone());
    await spawn.createTank(object, true);
    enemies.add(object);
    return object;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    // brickRenderer.render(canvas);
    if (false) {
      final cd = collisionDetection as QuadTreeCollisionDetection;
      final boxes = cd.collisionQuadBoxes;
      final boxPaint = Paint();
      boxPaint.color = Colors.blue.withOpacity(0.5);
      boxPaint.strokeWidth = 2;
      boxPaint.style = PaintingStyle.stroke;

      final boxRootPaint = Paint();
      boxRootPaint.color = Colors.red.withOpacity(0.8);
      boxRootPaint.strokeWidth = 2;
      boxRootPaint.style = PaintingStyle.stroke;

      camera.viewport.apply(canvas);
      for (final rect in boxes) {
        canvas.drawRect(rect.rect, boxPaint);
        for (final hb in rect.hitboxes) {
          if (rect.hasChildren) {
            canvas.drawRect(
                Rect.fromLTRB(
                    hb.aabb.min.x, hb.aabb.min.y, hb.aabb.max.x, hb.aabb.max.y),
                boxRootPaint);
          } else {
            canvas.drawRect(
                Rect.fromLTRB(
                    hb.aabb.min.x, hb.aabb.min.y, hb.aabb.max.x, hb.aabb.max.y),
                boxPaint);
          }
        }
        hudTextPaintNormal.render(
            canvas, rect.count.toString(), rect.rect.topCenter.toVector2());
      }
      final playerPos = player?.absoluteTopLeftPosition.toOffset();
      if (playerPos != null) {
        canvas.drawCircle(playerPos, 3, boxPaint);
      }
    } else {
      // if (isPlayerHiddenFromEnemy) {
      //   hudTextPaintGood.render(canvas, 'HIDDEN', Vector2(70, 2));
      // } else {
      //   hudTextPaintNormal.render(canvas, 'VISIBLE', Vector2(70, 2));
      // }
    }
  }

  static const zoomPerScrollUnit = 0.02;
  late double startZoom;

  @override
  void onScroll(PointerScrollInfo info) {
    camera.zoom += info.scrollDelta.game.y.sign * zoomPerScrollUnit;
    clampZoom();
  }

  void clampZoom() {
    camera.zoom = camera.zoom.clamp(0.05, 5.0);
  }

  KeyEventResult onKeyEvent(
    RawKeyEvent event,
    Set<LogicalKeyboardKey> keysPressed,
  ) {
    final player = this.player;
    if (player == null) return KeyEventResult.handled;
    if (player.dead == true) return KeyEventResult.handled;

    bool directionButtonPressed = false;
    bool updateAngle = false;
    for (final key in keysPressed) {
      // if (key == LogicalKeyboardKey.keyK) {
      //   takeDamage(1);
      // }

      if (key == LogicalKeyboardKey.keyW) {
        directionButtonPressed = true;
        if (player.lookDirection != Direction.up) {
          player.lookDirection = Direction.up;
          updateAngle = true;
        }
      }
      if (key == LogicalKeyboardKey.keyA) {
        directionButtonPressed = true;
        if (player.lookDirection != Direction.left) {
          player.lookDirection = Direction.left;
          updateAngle = true;
        }
      }
      if (key == LogicalKeyboardKey.keyS) {
        directionButtonPressed = true;
        if (player.lookDirection != Direction.down) {
          player.lookDirection = Direction.down;
          updateAngle = true;
        }
      }
      if (key == LogicalKeyboardKey.keyD) {
        directionButtonPressed = true;
        if (player.lookDirection != Direction.right) {
          player.lookDirection = Direction.right;
          updateAngle = true;
        }
      }

      if (key == LogicalKeyboardKey.space) {
        player.onFire();
      }
    }

    if (directionButtonPressed && player.canMoveForward) {
      player.current = MovementState.run;
      if (player.movePlayerSoundPaused) {
        player.movePlayerSound?.controller?.setVolume(0.5);
        player.movePlayerSound?.play();
        player.movePlayerSoundPaused = false;
      }
    } else {
      if (!player.dead) {
        player.current = MovementState.idle;
      }
      if (!player.movePlayerSoundPaused) {
        player.movePlayerSound?.pause();
        player.movePlayerSoundPaused = true;
      }
    }

    if (updateAngle) {
      player.angle = player.lookDirection.angle;
    }

    return KeyEventResult.handled;
  }

  void onDragStart(int pointerId, DragStartInfo info) {
    joystick?.handleDragStart(pointerId, info);
  }

  void onDragUpdate(int pointerId, DragUpdateInfo info) {
    joystick?.handleDragUpdated(pointerId, info);
  }

  void onDragEnd(int pointerId, DragEndInfo info) {
    joystick?.handleDragEnded(pointerId, info);
  }

  void onDragCancel(int pointerId) {
    joystick?.handleDragCanceled(pointerId);
  }
}
