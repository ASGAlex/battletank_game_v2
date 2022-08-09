import 'package:flame/components.dart';
import 'package:flutter/rendering.dart';
import 'package:tank_game/ui/hud_text_styles.dart';
import 'package:tank_game/world/world.dart';

class VisibilityIndicator extends TextBoxComponent {
  VisibilityIndicator()
      : super(
            boxConfig: TextBoxConfig(
                growingBox: false, margins: const EdgeInsets.all(5))) {
    anchor = Anchor.topLeft;
    priority = RenderPriority.ui.priority;
    positionType = PositionType.viewport;
  }

  setVisibility(bool visible) {
    if (visible) {
      text = 'VISIBLE';
      textRenderer = hudTextPaintNormal;
    } else {
      text = 'HIDDEN';
      textRenderer = hudTextPaintGood;
    }
  }
}
