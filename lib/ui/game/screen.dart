import 'package:flame/game.dart';
import 'package:flutter/widgets.dart';
import 'package:tank_game/game.dart';
import 'package:tank_game/services/settings/controller.dart';
import 'package:tank_game/ui/widgets/console_messages.dart';

class GameScreen extends StatelessWidget {
  const GameScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final game = SettingsController().gameInstance;
    if (game == null) throw 'no game!';
    return GameWidget(
      game: game,
      overlayBuilderMap: {
        'console': (BuildContext context, MyGame game) {
          return ConsoleMessages(
            game: game,
          );
        }
      },
      loadingBuilder: (BuildContext ctx) {
        return StreamBuilder(
            stream: game.consoleMessages.stream,
            builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
              return ConsoleMessages(game: game);
            });
      },
    );
  }
}
