import 'package:args/args.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:tank_game/ui/widgets/console_messages.dart';

import 'game.dart';

void main(List<String> args) {
  var parser = ArgParser();
  parser.addOption('map',
      defaultsTo:
          const String.fromEnvironment("map", defaultValue: 'water.tmx'));
  final results = parser.parse(args);
  final map = results['map'];

  final myGame = MyGame(map);
  runApp(
    GameWidget(
      game: myGame,
      loadingBuilder: (BuildContext ctx) {
        return StreamBuilder(
            stream: myGame.consoleMessages.stream,
            builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
              return ConsoleMessages(game: myGame);
            });
      },
    ),
  );
}
