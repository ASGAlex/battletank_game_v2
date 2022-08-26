import 'dart:collection';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'package:flame/game.dart';

import 'fragment.dart';

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
}

extension Crop on Image {
  Future<Image> crop(Rect rect) {
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawImageRect(
        this, rect, Rect.fromLTWH(0, 0, rect.width, rect.height), Paint());
    final picture = recorder.endRecording();
    return picture.toImage(rect.width.toInt(), rect.height.toInt());
  }
}
