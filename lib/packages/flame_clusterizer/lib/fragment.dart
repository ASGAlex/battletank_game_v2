import 'dart:collection';

import 'package:flame/components.dart';
import 'package:flame/extensions.dart';

import 'clusterized_component.dart';

class Fragment {
  Fragment(this.rect);

  Fragment? left;
  Fragment? right;
  Fragment? top;
  Fragment? bottom;

  final Rect rect;
  final components = HashSet<PositionComponent>();

  List<Fragment> get neighbours {
    final list = <Fragment>[];
    if (left != null) {
      list.add(left!);
      final leftTop = left!.top;
      if (leftTop != null) {
        list.add(leftTop);
      }
      final leftBottom = left!.bottom;
      if (leftBottom != null) {
        list.add(leftBottom);
      }
    }
    if (right != null) {
      list.add(right!);

      final rightTop = right!.top;
      if (rightTop != null) {
        list.add(rightTop);
      }
      final rightBottom = right!.bottom;
      if (rightBottom != null) {
        list.add(rightBottom);
      }
    }
    if (top != null) {
      list.add(top!);
    }
    if (bottom != null) {
      list.add(bottom!);
    }
    return list;
  }

  List<Fragment> get neighboursAndMe => neighbours..add(this);

  hide() => _setVisibility(false);

  show() => _setVisibility(true);

  _setVisibility(bool visible) {
    for (final c in components) {
      try {
        (c as ClusterizedComponent).visible = visible;
      } catch (e) {}
    }
  }
}
