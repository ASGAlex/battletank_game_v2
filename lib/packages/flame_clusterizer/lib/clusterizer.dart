import 'dart:collection';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'package:flame/game.dart';
import 'package:tank_game/packages/tiled_utils/lib/image_batch_compiler.dart';

typedef FragmentVisibilityChecker = bool Function(Fragment fragment);

class Clusterizer {
  Clusterizer(this.mapSize, this.viewportSize, this.game,
      this.fragmentVisibilityChecker) {
    _calculateFragments();
  }

  final FlameGame game;
  final Vector2 mapSize;
  final Vector2 viewportSize;
  final fragments = HashSet<Fragment>();
  Fragment? _currentFragment;
  Fragment? _prevFragment;
  final FragmentVisibilityChecker fragmentVisibilityChecker;

  Fragment? findCurrentFragment() {
    final current = _currentFragment;
    if (current != null) {
      var visible = fragmentVisibilityChecker(current);
      if (visible) return current;

      for (final n in current.neighbours) {
        if (fragmentVisibilityChecker(n)) {
          _prevFragment = _currentFragment;
          _currentFragment = n;
          _onCurrentChanged();
          return _currentFragment;
        }
      }
    }
    for (final f in fragments) {
      if (fragmentVisibilityChecker(f)) {
        _prevFragment = _currentFragment;
        _currentFragment = f;
        _onCurrentChanged();
        return _currentFragment;
      }
    }

    _prevFragment = _currentFragment;
    _currentFragment = null;
    _onCurrentChanged();
    return _currentFragment;
  }

  _onCurrentChanged() {
    if (_currentFragment == null) {
      for (var f in fragments) {
        f.hide();
      }
      return;
    }
    if (_prevFragment == null) {
      for (var f in fragments) {
        f.hide();
      }
    } else {
      _prevFragment?.neighboursAndMe.forEach((fragment) {
        fragment.hide();
      });
    }

    _currentFragment?.neighboursAndMe.forEach((fragment) {
      fragment.show();
    });
  }

  _calculateFragments() {
    final totalColumns = mapSize.x / viewportSize.x;
    final totalRows = mapSize.y / viewportSize.y;
    var col = 0;
    var row = 0;
    var upperLine = <Fragment>[];
    final currentLine = <Fragment>[];
    Fragment? previous;
    while (row < totalRows) {
      while (col < totalColumns) {
        final rect = Rect.fromLTWH(col * viewportSize.x, row * viewportSize.y,
            viewportSize.x, viewportSize.y);
        final newF = Fragment(rect);
        fragments.add(newF);
        if (previous != null) {
          newF.left = previous;
          previous.right = newF;
        }
        if (upperLine.isNotEmpty) {
          final upper = upperLine[col];
          newF.top = upper;
          upper.bottom = newF;
        }
        previous = newF;
        currentLine.add(newF);
        col++;
      }
      upperLine = List.from(currentLine);
      currentLine.clear();
      previous = null;
      col = 0;
      row++;
    }
  }

  Fragment? findFragmentByPosition(Vector2 position) {
    for (final f in fragments) {
      if (f.rect.containsPoint(position)) return f;
    }
    return null;
  }

  Future<Map<Fragment, List<ImageComponent>>> splitImageComponent(
      ImageComponent component) async {
    final paint = Paint();
    final componentMap = <Fragment, List<ImageComponent>>{};
    for (final fragment in fragments) {
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      canvas.drawImageRect(
          component.image,
          fragment.rect,
          Rect.fromLTWH(0, 0, fragment.rect.width, fragment.rect.height),
          paint);
      final picture = recorder.endRecording();
      final img = await picture.toImage(
          fragment.rect.width.toInt(), fragment.rect.height.toInt());
      final imgComp = ImageComponent(img,
          position: Vector2(fragment.rect.left, fragment.rect.top));
      imgComp.priority = component.priority;
      if (componentMap[fragment] == null) {
        componentMap[fragment] = [];
      }
      componentMap[fragment]!.add(imgComp);
    }
    return componentMap;
  }
}

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
        (c as HasVisibility).visible = visible;
      } catch (e) {}
    }
  }
}

mixin HasVisibility on PositionComponent {
  bool visible = true;

  @override
  void renderTree(Canvas canvas) {
    if (visible) {
      super.renderTree(canvas);
    }
  }
}
