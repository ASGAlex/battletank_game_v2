import 'package:flame/game.dart';
import 'package:flutter/widgets.dart';
import 'package:tank_game/game.dart';
import 'package:tank_game/services/settings/controller.dart';
import 'package:tank_game/ui/widgets/console_messages.dart';

import '../menu/ingame_menu.dart';

class GameScreen extends StatelessWidget {
  const GameScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        SettingsController().gameInstance?.overlays.add('menu');
        return false;
      },
      child: GameWidget.controlled(
        gameFactory: () {
          final game = MyGame(SettingsController().mapName);
          SettingsController().gameInstance = game;
          return game;
        },
        overlayBuilderMap: {
          'console': (BuildContext context, MyGame game) {
            return ConsoleMessages(
              controller: game.consoleMessages,
            );
          },
          'menu': (BuildContext context, MyGame game) {
            return InGameMenu(game: game);
          }
        },
        loadingBuilder: (BuildContext ctx) {
          final game = SettingsController().gameInstance;
          if (game == null) throw 'game not created';
          return StreamBuilder(
              stream: game.consoleMessages.stream,
              builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
                return ConsoleMessages(controller: game.consoleMessages);
              });
        },
      ),
    );
  }
}
