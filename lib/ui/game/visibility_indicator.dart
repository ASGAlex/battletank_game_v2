import 'package:flame/components.dart';
import 'package:flutter/rendering.dart';
import 'package:tank_game/game.dart';
import 'package:tank_game/ui/game/hud_text_styles.dart';
import 'package:tank_game/ui/intl.dart';
import 'package:tank_game/world/world.dart';

class VisibilityIndicator extends TextBoxComponent {
  VisibilityIndicator(this.game)
      : super(
            boxConfig: TextBoxConfig(
                growingBox: false, margins: const EdgeInsets.all(5))) {
    anchor = Anchor.topLeft;
    priority = RenderPriority.ui.priority;
    positionType = PositionType.viewport;
  }

  final MyGame game;

  setVisibility(bool visible) {
    if (visible) {
      text = game.context.loc().visible;
      textRenderer = hudTextPaintNormal;
    } else {
      text = game.context.loc().hidden;
      textRenderer = hudTextPaintGood;
    }
  }
}
