import 'package:flame/game.dart';
import 'package:flutter/widgets.dart';
import 'package:tank_game/game.dart';
import 'package:tank_game/mission/repository.dart';
import 'package:tank_game/services/settings/controller.dart';
import 'package:tank_game/ui/game/gameover_screen.dart';
import 'package:tank_game/ui/widgets/console_messages.dart';

import 'ingame_menu.dart';
import 'mission_objectives.dart';

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
          return SettingsController()
              .startGameWithMission(selectedMission, context);
        },
        overlayBuilderMap: {
          'console': (BuildContext context, MyGame game) {
            return ConsoleMessages(
              controller: game.consoleMessages,
            );
          },
          'menu': (BuildContext context, MyGame game) {
            return InGameMenu(game: game);
          },
          'mission_objectives': (BuildContext context, MyGame game) {
            return MissionObjectives(game: game);
          },
          'game_over_success': (BuildContext context, MyGame game) {
            return GameOver(game: game, success: true);
          },
          'game_over_fail': (BuildContext context, MyGame game) {
            return GameOver(game: game, success: false);
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
