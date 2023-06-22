import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:nes_ui/nes_ui.dart';
import 'package:tank_game/game.dart';
import 'package:tank_game/ui/intl.dart';
import 'package:tank_game/ui/route_builder.dart';

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
        child: NesContainer(
          width: 300,
          child: ListView(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 8, 0, 8),
              child: NesButton(
                onPressed: () {
                  game.overlays.remove('menu');
                  game.paused = false;
                },
                type: NesButtonType.primary,
                child: Text(context.loc().continue_play),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 8, 0, 8),
              child: NesButton(
                onPressed: () {
                  game.overlays.add('mission_objectives');
                },
                type: NesButtonType.primary,
                child: Text(context.loc().mission_objectives),
              ),
            ),
            const Divider(),
            NesButton(
              onPressed: () {
                NesConfirmDialog.show(
                        context: context,
                        message: context.loc().leave_game,
                        cancelLabel: context.loc().back,
                        confirmLabel: context.loc().ok)
                    .then((leave) {
                  if (leave == true) {
                    game.resumeEngine();
                    RouteBuilder.gotoMissions(context, false);
                  }
                });
              },
              type: NesButtonType.warning,
              child: Text(context.loc().exit),
            ),
          ]),
        ),
      ),
    );
  }
}
