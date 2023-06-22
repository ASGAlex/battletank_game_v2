import 'package:flame/game.dart';
import 'package:flutter/widgets.dart';
import 'package:tank_game/game.dart';
import 'package:tank_game/mission/repository.dart';
import 'package:tank_game/services/settings/controller.dart';
import 'package:tank_game/ui/game/gameover_screen.dart';
import 'package:tank_game/ui/game/hud.dart';
import 'package:tank_game/ui/menu/in_game_menu/ingame_menu.dart';
import 'package:tank_game/ui/menu/in_game_menu/mission_objectives.dart';
import 'package:tank_game/ui/widgets/console_messages.dart';

class GameScreen extends StatelessWidget {
  const GameScreen({Key? key, this.mission}) : super(key: key);

  final MissionDescription? mission;

  @override
  Widget build(BuildContext context) {
    final selectedMission = mission ??
        ModalRoute.of(context)?.settings.arguments as MissionDescription?;
    if (selectedMission == null) {
      throw "Mission was not selected!!";
    }
    final game =
        SettingsController().startGameWithMission(selectedMission, context);

    return WillPopScope(
      onWillPop: () async {
        game.overlays.add('menu');
        return false;
      },
      child: GameWidget(
        game: game,
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
          },
          'hud': (BuildContext context, MyGame game) {
            return HUDWidget(game: game);
          },
          'scenario': (BuildContext context, MyGame game) {
            return game.scenarioCurrentWidgetBuilder(context, game);
          },
        },
        loadingBuilder: (BuildContext ctx) {
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
