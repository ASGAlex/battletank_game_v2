import 'dart:ui';

import 'package:flame/components.dart';

import 'batched_game.dart';

mixin BatchedComponent on SpriteComponent {
  @override
  void renderTree(Canvas canvas) {}

  bool _treeInitiallyUpdated = false;
  HasBatchRenderer? _batchedGame;

  bool _gameBatched = true;

  @override
  void updateTree(double dt) {
    if (!_treeInitiallyUpdated) {
      super.updateTree(dt);
      _treeInitiallyUpdated = true;
    }
  }

  scheduleTreeUpdate() => _treeInitiallyUpdated = false;

  Rect get sourceRect => sprite!.src;

  Vector2 get offsetPosition => position;

  @override
  void onMount() {
    final game = _findBatchedGame();
    if (game != null) {
      game.batchRenderer?.batchedComponents.add(this);
      position.addListener(_onPositionOrSizeUpdate);
      size.addListener(_onPositionOrSizeUpdate);
      game.batchRenderer?.imageChanged = true;
    }
    super.onMount();
  }

  _onPositionOrSizeUpdate() {
    _findBatchedGame()?.batchRenderer?.imageChanged = true;
  }

  @override
  onRemove() {
    final game = _findBatchedGame();
    if (game != null) {
      position.removeListener(_onPositionOrSizeUpdate);
      game.batchRenderer?.batchedComponents.remove(this);
      game.batchRenderer?.imageChanged = true;
    }
    super.onRemove();
  }

  HasBatchRenderer? _findBatchedGame() {
    if (_batchedGame != null) return _batchedGame;
    if (_gameBatched == false) return null;
    HasBatchRenderer? game;
    if (this is HasGameRef) {
      game = (this as HasGameRef).gameRef as HasBatchRenderer;
    } else {
      game = findParent<HasBatchRenderer>();
    }

    if (game == null) {
      _gameBatched = false;
    }
    _batchedGame = game;
    return _batchedGame;
  }
}
