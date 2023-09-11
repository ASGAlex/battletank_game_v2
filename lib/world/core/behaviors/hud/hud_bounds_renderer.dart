import 'dart:async';

import 'package:flame/components.dart';
import 'package:flame/experimental.dart';
import 'package:flutter/material.dart';
import 'package:tank_game/game.dart';
import 'package:tank_game/world/core/actor.dart';

abstract interface class BoundsRenderController extends Component {
  bool get showBounds;
}

class HudBoundsRenderer extends PositionComponent
    with HasGameReference<MyGame>, HasPaint<String> {
  HudBoundsRenderer(this.owner) {
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 2;

    final playerPaint = Paint();
    playerPaint.style = PaintingStyle.stroke;
    playerPaint.strokeWidth = 2;
    setPaint('player', playerPaint);
    setColor(Colors.amberAccent, paintId: 'player');
    setOpacity(0.5, paintId: 'player');
  }

  ActorMixin owner;

  BoundsRenderController? controller;

  late final Rect _ownerRect;

  @override
  void update(double dt) {
    if (owner is ActorWithSeparateBody) {
      position.setFrom((owner as ActorWithSeparateBody).bodyHitbox.aabb.min);
    } else {
      position.setFrom(owner.boundingBox.aabb.min);
    }
    if (parent == game.currentPlayer) {
      owner.noVisibleChildren = false;
      owner.boundingBox.debugMode = true;
    }
    super.update(dt);
  }

  @override
  FutureOr<void> onLoad() {
    if (owner is ActorWithSeparateBody) {
      final longest =
          (owner as ActorWithSeparateBody).bodyHitbox.toRect().longestSide;
      _ownerRect = Rect.fromLTWH(0, 0, longest, longest);
    } else {
      final longest = owner.boundingBox.toRect().longestSide;
      _ownerRect = Rect.fromLTWH(0, 0, longest, longest);
    }
    final player = game.currentPlayer;
    if (player != null) {
      final controllers = player.children.query<BoundsRenderController>();
      if (controllers.isNotEmpty) {
        controller = controllers.first;
      }
    }
    return super.onLoad();
  }

  @override
  void render(Canvas canvas) {
    if (controller?.showBounds == true) {
      if (owner == game.currentPlayer) {
        canvas.drawRect(_ownerRect, getPaint('player'));
      } else {
        canvas.drawRect(_ownerRect, paint);
      }
    }
  }
}
