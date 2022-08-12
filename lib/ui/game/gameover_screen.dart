import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:tank_game/game.dart';
import 'package:tank_game/ui/intl.dart';
import 'package:tank_game/ui/route_builder.dart';
import 'package:tank_game/ui/widgets/button.dart';

class GameOver extends StatelessWidget {
  const GameOver({Key? key, required this.game, required this.success})
      : super(key: key);
  final MyGame game;
  final bool success;

  @override
  Widget build(BuildContext context) {
    var message = '';
    var color = Colors.white;
    if (success) {
      message = context.loc().victory;
      color = Colors.red;
    } else {
      message = context.loc().defeat;
      color = Colors.brown;
    }

    return DefaultTextStyle(
      style: TextStyle(decoration: null, color: color),
      child: Container(
        alignment: Alignment.center,
        color: Colors.black26.withOpacity(0.5),
        padding: const EdgeInsets.all(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: 5.0,
            sigmaY: 5.0,
          ),
          child: Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.only(top: 100),
            child: ListView(children: [
              Center(
                  child: Text(
                message,
                style:
                    const TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
              )),
              Padding(
                padding: const EdgeInsets.only(top: 50),
                child: SizedBox(
                  width: 100,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      MenuButton(
                        onPressed: () {
                          RouteBuilder.gotoMainMenu(context);
                        },
                        text: context.loc().ok,
                      ),
                    ],
                  ),
                ),
              )
            ]),
          ),
        ),
      ),
    );
  }
}
