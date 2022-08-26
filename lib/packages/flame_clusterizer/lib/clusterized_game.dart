import 'package:flame/extensions.dart';
import 'package:flame/game.dart';

import 'clusterizer.dart';
import 'fragment.dart';

mixin ClusterizedGame on FlameGame {
  Clusterizer? clusterizer;

  initClusterizer(double mapWidth, double mapHeight, double viewportWidth,
      double viewportHeight) {
    clusterizer = Clusterizer(Vector2(mapWidth, mapHeight),
        Vector2(viewportWidth, viewportHeight), this, isFragmentVisible);
  }

  bool isFragmentVisible(Fragment fragment) {
    final pos = camera.follow ?? camera.position;
    final center = Vector2(pos.x, pos.y);
    return fragment.rect.containsPoint(center);
  }

  @override
  void update(double dt) {
    super.update(dt);
    clusterizer?.findCurrentFragment();
  }
}
