import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:tank_game/game.dart';
import 'package:tank_game/ui/intl.dart';
import 'package:tank_game/ui/route_builder.dart';
import 'package:tank_game/ui/widgets/button.dart';

import '../../services/settings/controller.dart';

class InGameMenu extends StatelessWidget {
  const InGameMenu({Key? key, required this.game}) : super(key: key);

  final MyGame game;

  @override
  Widget build(BuildContext context) {
    return Container(
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
          width: 300,
          padding: const EdgeInsets.only(top: 50),
          child: ListView(children: [
            MenuButton(
              onPressed: () {
                game.overlays.remove('menu');
                game.paused = false;
              },
              text: context.loc().continue_play,
            ),
            MenuButton(
              onPressed: () {
                game.overlays.add('mission_objectives');
              },
              text: context.loc().mission_objectives,
            ),
            Padding(
              padding: const EdgeInsets.only(top: 40),
              child: MenuButton(
                onPressed: () {
                  game.paused = true;
                  SettingsController().gameInstance = null;
                  RouteBuilder.gotoMainMenu(context);
                },
                text: context.loc().exit,
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
