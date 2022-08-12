import 'package:flame/components.dart';
import 'package:flutter/rendering.dart';
import 'package:tank_game/ui/game/hud_text_styles.dart';
import 'package:tank_game/world/world.dart';

enum FlashMessageType { neutral, good, danger }

class FlashMessage extends TextBoxComponent with HideableComponent {
  FlashMessage({required super.position})
      : super(
            boxConfig: TextBoxConfig(
                maxWidth: 400,
                growingBox: false,
                margins: const EdgeInsets.all(5))) {
    anchor = Anchor.topLeft;
    priority = RenderPriority.ui.priority;
    positionType = PositionType.viewport;
  }

  showMessage(String message, FlashMessageType type) {
    text = message;
    switch (type) {
      case FlashMessageType.neutral:
        textRenderer = hudTextPaintNormal;
        break;
      case FlashMessageType.good:
        textRenderer = hudTextPaintNormal;
        break;
      case FlashMessageType.danger:
        textRenderer = hudTextPaintDanger;
        break;
    }
    hidden = false;
    Future.delayed(const Duration(seconds: 10)).then((value) {
      hidden = true;
    });
  }
}
