import 'package:flame/game.dart';
import 'package:flutter/widgets.dart';
import 'package:tank_game/game.dart';
import 'package:tank_game/mission/repository.dart';
import 'package:tank_game/services/settings/controller.dart';
import 'package:tank_game/ui/widgets/console_messages.dart';

import '../menu/ingame_menu.dart';

class GameScreen extends StatelessWidget {
  const GameScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final selectedMission =
        ModalRoute.of(context)?.settings.arguments as MissionDescription?;
    if (selectedMission == null) {
      throw "Mission was not selected!!";
    }

    return WillPopScope(
      onWillPop: () async {
        SettingsController().gameInstance?.overlays.add('menu');
        return false;
      },
      child: GameWidget.controlled(
        gameFactory: () {
          return SettingsController().startGameWithMission(selectedMission);
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
              key: GlobalKey(),
              stream: game.consoleMessages.stream,
              builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
                return ConsoleMessages(controller: game.consoleMessages);
              });
        },
      ),
    );
  }
}