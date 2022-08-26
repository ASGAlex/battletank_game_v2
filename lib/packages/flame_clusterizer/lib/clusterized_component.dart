import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'package:tank_game/packages/flame_clusterizer/lib/clusterizer.dart';
import 'package:tank_game/packages/flame_clusterizer/lib/fragment.dart';

import 'clusterized_game.dart';

mixin ClusterizedComponent on PositionComponent {
  bool visible = true;

  Fragment? _currentFragment;
  Clusterizer? _clusterizer;

  Clusterizer? get clusterizer {
    if (_clusterizer != null) return _clusterizer;
    ClusterizedGame? game;
    if (this is HasGameRef) {
      game = (this as HasGameRef).gameRef as ClusterizedGame;
    } else {
      game = findParent<ClusterizedGame>();
    }
    if (game == null) {
      throw "Can't find parent of clusterized game";
    }

    if (game.clusterizer != null) {
      _clusterizer = game.clusterizer;
    }

    return _clusterizer;
  }

  @override
  void renderTree(Canvas canvas) {
    if (visible) {
      super.renderTree(canvas);
    }
  }

  @override
  void onMount() {
    super.onMount();
    _currentFragment = clusterizer?.findFragmentByPosition(position);
    _currentFragment?.components.add(this);
    position.addListener(_onPositionChanged);
  }

  void _onPositionChanged() {
    final keepOldFragment = _currentFragment?.rect.containsPoint(position);
    if (keepOldFragment == true) {
      return;
    }
    _currentFragment = clusterizer?.findFragmentByPosition(position);
  }

  @override
  void onRemove() {
    position.removeListener(_onPositionChanged);
    _currentFragment?.components.remove(this);
    super.onRemove();
  }
}
