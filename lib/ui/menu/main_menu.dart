import 'package:flame/flame.dart';
import 'package:flutter/material.dart';
import 'package:tank_game/ui/intl.dart';
import 'package:tank_game/ui/route_builder.dart';
import 'package:tank_game/ui/widgets/button.dart';

class MainMenu extends StatelessWidget {
  const MainMenu({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Flame.device.setLandscape();
    Flame.device.fullScreen();

    return Container(
      padding: const EdgeInsets.only(top: 24, right: 100, left: 100),
      child: ListView(children: [
        MenuButton(
          onPressed: () {
            RouteBuilder.gotoGameProcess(context);
          },
          text: context.loc().start_new_game,
        ),
        MenuButton(
          onPressed: () {
            RouteBuilder.gotoSettings(context);
          },
          text: context.loc().settings,
        ),
      ]),
    );
  }
}
