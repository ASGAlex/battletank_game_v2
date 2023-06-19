import 'package:flutter/material.dart';
import 'package:nes_ui/nes_ui.dart';
import 'package:tank_game/ui/intl.dart';
import 'package:tank_game/ui/route_builder.dart';

class MainMenu extends StatelessWidget {
  const MainMenu({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      child: NesContainer(
        backgroundColor: Colors.blueGrey,
        // padding: const EdgeInsets.only(top: 24, right: 100, left: 100),
        child: ListView(children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: SizedBox(
                  width: 250,
                  child: NesButton(
                    onPressed: () {
                      RouteBuilder.gotoMissions(context);
                    },
                    type: NesButtonType.success,
                    child: Center(
                      child: Text(
                        context.loc().start_new_game,
                        textScaleFactor: 1,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: SizedBox(
                  width: 250,
                  child: NesButton(
                    onPressed: () {
                      RouteBuilder.gotoSettings(context);
                    },
                    type: NesButtonType.primary,
                    child: Center(
                      child: Text(
                        context.loc().settings,
                        textScaleFactor: 1,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Center(
                child: Text(
              context.loc().controls_description_title,
              textScaleFactor: 1.3,
            )),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Center(
                child: Text(
              context.loc().controls_description,
              style: const TextStyle(
                height: 1.3,
              ),
            )),
          ),
        ]),
      ),
    );
  }
}
