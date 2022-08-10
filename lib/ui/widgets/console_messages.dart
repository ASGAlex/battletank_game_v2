import 'dart:async';

import 'package:flutter/material.dart';
import 'package:tank_game/game.dart';

class ConsoleMessagesController {
  final _streamController = StreamController<String>();

  Stream<String> get stream => _streamController.stream;

  final gameMessages = <String>[];

  sendMessage(String msg) {
    gameMessages.add(msg);
    _streamController.add(msg);
  }
}

class ConsoleMessages extends StatelessWidget {
  const ConsoleMessages({Key? key, required this.game}) : super(key: key);

  final MyGame game;

  @override
  Widget build(BuildContext context) {
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
        itemCount: game.consoleMessages.gameMessages.length,
        reverse: false,
        itemBuilder: (BuildContext context, int index) {
          return Row(
            verticalDirection: VerticalDirection.up,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                game.consoleMessages.gameMessages[index],
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
  }
}
