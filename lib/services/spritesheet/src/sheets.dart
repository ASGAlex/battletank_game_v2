part of spritesheet;

class _Boom extends SpriteSheetBase {
  _Boom() : super() {
    compileAnimation(
      name: 'boom',
      stepTime: 0.1,
      from: 0,
      to: 3,
    ).then((value) {
      value.loop = false;
    });

    compileAnimation(
      name: 'crate',
      stepTime: 0.1,
      from: 3,
      to: 4,
    ).then((value) {
      value.loop = false;
    });
  }

  @override
  String get fileName => 'spritesheets/boom.png';

  @override
  Vector2 get spriteSize => Vector2.all(16);

  Future<SpriteAnimation> get boom => getPrecompiledAnimation('boom');
  Future<SpriteAnimation> get crate => getPrecompiledAnimation('crate');
}

class _BoomBig extends SpriteSheetBase {
  _BoomBig() : super() {
    compileAnimation(
      name: 'boom',
      stepTime: 0.1,
    ).then((value) {
      value.loop = false;
    });
  }

  @override
  String get fileName => 'spritesheets/boom_big.png';

  @override
  Vector2 get spriteSize => Vector2.all(32);

  Future<SpriteAnimation> get animation => getPrecompiledAnimation('boom');
}

class _TankBasic extends SpriteSheetBase {
  _TankBasic() : super() {
    compileAnimation(
      name: 'run',
      from: 0,
      to: 2,
      stepTime: 0.2,
    );
    compileAnimation(
      name: 'idle',
      from: 0,
      to: 1,
      stepTime: 10,
    );
    compileAnimation(
      name: 'wreck',
      from: 2,
      to: 3,
      stepTime: 10,
    ).then((value) {
      _track = value.frames.first.sprite;
    });
  }

  late final Sprite _track;

  @override
  String get fileName => 'spritesheets/tank_basic2.png';

  @override
  Vector2 get spriteSize => Vector2(14, 14);

  Future<SpriteAnimation> get animationRun => getPrecompiledAnimation('run');

  Future<SpriteAnimation> get animationIdle => getPrecompiledAnimation('idle');

  Future<SpriteAnimation> get animationWreck =>
      getPrecompiledAnimation('wreck');

  Sprite get track => _track;
}

class _Bullet extends SpriteSheetBase {
  _Bullet() : super() {
    compileAnimation(
      name: 'basic',
      stepTime: 0.1,
    ).then((value) {
      _bullet = value;
    });
  }

  late SpriteAnimation _bullet;

  @override
  String get fileName => 'spritesheets/bullet.png';

  @override
  Vector2 get spriteSize => Vector2(3, 4);

  SpriteAnimation get animation => _bullet;
}

class _Ground extends SpriteSheetBase {
  _Ground() : super() {
    compileAnimation(name: 'grass', stepTime: 1, from: 0, to: 1).then((value) {
      _grass = value.frames.first.sprite;
    });
    compileAnimation(name: 'dirt', stepTime: 1, from: 1, to: 2).then((value) {
      _dirt = value.frames.first.sprite;
    });
    compileAnimation(name: 'ash', stepTime: 1, from: 2, to: 3).then((value) {
      _ash = value.frames.first.sprite;
    });
  }

  late Sprite _dirt;
  late Sprite _grass;
  late Sprite _ash;

  @override
  String get fileName => 'ground_tiles.png';

  @override
  Vector2 get spriteSize => Vector2.all(8);

  Sprite get dirt => _dirt;

  Sprite get grass => _grass;

  Sprite get ash => _ash;
}

class _Spawn extends SpriteSheetBase {
  _Spawn() : super() {
    compileAnimation(name: 'basic', stepTime: 0.09, loop: false);
  }

  @override
  String get fileName => 'spritesheets/spawn.png';

  @override
  Vector2 get spriteSize => Vector2(15, 15);

  Future<SpriteAnimation> get animation => getPrecompiledAnimation('basic');
}

class _Target extends SpriteSheetBase {
  _Target() : super() {
    compileAnimation(name: 'life', stepTime: 1, from: 0, to: 1);
    compileAnimation(name: 'dead', stepTime: 1, from: 1, to: 2);
  }

  @override
  String get fileName => 'spritesheets/target.png';

  @override
  Vector2 get spriteSize => Vector2(16, 16);

  Future<Sprite> get life => getPrecompiledAnimation('life')
      .then((value) => value.frames.first.sprite);

  Future<Sprite> get dead => getPrecompiledAnimation('dead')
      .then((value) => value.frames.first.sprite);
}
