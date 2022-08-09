import 'package:args/args.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

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
              final msgScrollController = ScrollController();
              WidgetsBinding.instance.addPostFrameCallback((_) {
                try {
                  msgScrollController
                      .jumpTo(msgScrollController.position.maxScrollExtent);
                } catch (e) {}
              });
              return Container(
                color: Colors.black,
                margin: const EdgeInsets.all(0),
                child: ListView.builder(
                  itemExtent: 24,
                  controller: msgScrollController,
                  itemCount: myGame.consoleMessages.gameMessages.length,
                  reverse: false,
                  itemBuilder: (BuildContext context, int index) {
                    return Row(
                      verticalDirection: VerticalDirection.up,
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          myGame.consoleMessages.gameMessages[index],
                          style: const TextStyle(
                              color: Colors.white,
                              fontFamily: 'MonospaceRU',
                              fontSize: 12),
                        ),
                      ],
                    );
                  },
                ),
              );
            });
      },
    ),
  );
}
