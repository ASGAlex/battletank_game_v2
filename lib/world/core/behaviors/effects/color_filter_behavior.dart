import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame_behaviors/flame_behaviors.dart';
import 'package:tank_game/world/core/actor.dart';

class ColorFilterBehavior extends Behavior<ActorMixin> {
  static final colorFilters = <ColorFilter>[
    //red
    const ColorFilter.matrix(<double>[
      1.000,
      0.000,
      1.000,
      0.000,
      0.000,
      0.000,
      0.200,
      1.000,
      0.000,
      0.000,
      1.000,
      3.000,
      1.000,
      0.000,
      0.000,
      0.000,
      0.000,
      0.000,
      1.000,
      0.000,
    ]),

    //green
    const ColorFilter.matrix(<double>[
      0.000,
      0.000,
      1.000,
      0.000,
      0.000,
      0.000,
      1.000,
      2.000,
      0.000,
      0.000,
      0.000,
      0.000,
      1.000,
      0.000,
      0.000,
      0.000,
      0.000,
      0.000,
      1.000,
      0.000,
    ]),
    // white
    const ColorFilter.matrix(<double>[
      1.000,
      0.000,
      0.000,
      0.000,
      0.000,
      0.500,
      1.000,
      0.000,
      0.000,
      0.000,
      0.500,
      1.000,
      1.000,
      0.000,
      0.000,
      0.000,
      0.000,
      0.000,
      1.000,
      0.000
    ]),
  ];

  ColorFilterBehavior();

  ColorFilter? _original;

  var _previous = -1;

  ColorFilter get randomColorFilter {
    var i = _previous;
    while (i == _previous) {
      i = Random().nextInt(colorFilters.length);
    }
    _previous = i;
    return colorFilters[i];
  }

  void applyNext() {
    (parent as HasPaint).getPaint().colorFilter = randomColorFilter;
  }

  @override
  FutureOr<void> onLoad() {
    assert(parent is HasPaint);
    _original = (parent as HasPaint).getPaint().colorFilter;
    applyNext();
    return super.onLoad();
  }

  @override
  void onRemove() {
    (parent as HasPaint).getPaint().colorFilter = _original;
    super.onRemove();
  }
}
