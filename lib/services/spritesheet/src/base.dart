part of spritesheet;

/// Basic class to perform animation caching. The purpose: to save resources and
/// frame rate while creating new animations instances.
///
abstract class SpriteSheetBase {
  SpriteSheetBase() {
    _spriteSheet = Flame.images
        .load(fileName)
        .then((value) => SpriteSheet(image: value, srcSize: spriteSize));
  }

  String get fileName;

  Vector2 get spriteSize;

  static bool _allLoaded = false;

  late Future<SpriteSheet> _spriteSheet;

  final Map<String, SpriteAnimation> _compiledAnimations = {};

  Future<SpriteSheet> get spriteSheet => _spriteSheet;

  final List<Future> _awaitList = [];

  /// Call in constructor to create new animation template from sprite sheet
  /// @see [SpriteSheet.createAnimation]
  Future<SpriteAnimation> compileAnimation({
    required String name,
    required double stepTime,
    int row = 0,
    bool loop = true,
    int from = 0,
    int? to,
  }) =>
      awaitAnimation(spriteSheet.then((value) {
        final animation = value.createAnimation(
            row: row, stepTime: stepTime, loop: loop, from: from, to: to);
        _compiledAnimations[name] = animation;
        return animation;
      }));

  Future<SpriteAnimation> awaitAnimation(Future<SpriteAnimation> animation) {
    _awaitList.add(animation);
    return animation;
  }

  /// Call in animation getter to quickly create a new instance of "precompiled"
  /// animation
  Future<SpriteAnimation> getPrecompiledAnimation(String name) async {
    if (!_allLoaded) {
      await Future.wait(_awaitList);
      _allLoaded = true;
    }
    final template = _compiledAnimations[name];
    if (template == null) throw ArgumentError('Animation $name does not exist');
    return template.clone();
  }
}
