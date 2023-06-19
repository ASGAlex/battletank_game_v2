import 'package:flutter/material.dart';
import 'package:nes_ui/nes_ui.dart';
import 'package:tank_game/services/settings/controller.dart';
import 'package:tank_game/ui/intl.dart';
import 'package:tank_game/ui/route_builder.dart';

class SettingsMenu extends StatelessWidget {
  const SettingsMenu({Key? key}) : super(key: key);

  SettingsController get controller => SettingsController();

  @override
  Widget build(BuildContext context) {
    return Material(
      child: NesContainer(
        backgroundColor: Colors.blueGrey,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: AnimatedBuilder(
            animation: controller,
            builder: (BuildContext context, Widget? child) => ListView(
              children: [
                Text(context.loc().processor_speed, textAlign: TextAlign.left),
                Padding(
                  padding: const EdgeInsets.only(left: 16, right: 10),
                  child: DropdownButton<ProcessorSpeed>(
                    isExpanded: true,
                    value: controller.processor,
                    onChanged: (ProcessorSpeed? quality) {
                      if (quality != null) {
                        controller.processor = quality;
                      }
                    },
                    items: [
                      DropdownMenuItem(
                        value: ProcessorSpeed.web,
                        child: Text(context.loc().processor_speed_web),
                      ),
                      DropdownMenuItem(
                        value: ProcessorSpeed.office,
                        child: Text(context.loc().processor_speed_office),
                      ),
                      DropdownMenuItem(
                        value: ProcessorSpeed.middle,
                        child: Text(context.loc().processor_speed_middle),
                      ),
                      DropdownMenuItem(
                        value: ProcessorSpeed.powerful,
                        child: Text(context.loc().processor_speed_powerful),
                      ),
                    ],
                  ),
                ),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 200,
                      child: NesButton(
                          type: NesButtonType.success,
                          child: Center(child: Text(context.loc().back)),
                          onPressed: () {
                            RouteBuilder.gotoMainMenu(context);
                          }),
                    ),
                  ],
                )

                // Text(context.loc().settingsCollectionTitle,
                //     textAlign: TextAlign.left),
                // CollectionWidget(settings: controller),
                // const Divider(),
                // CheckboxListTile(
                //     title: Text(context.loc().settingsWithMagic),
                //     value: controller.withMagic,
                //     onChanged: controller.updateWithMagic),
                // CheckboxListTile(
                //     title: Text(context.loc().settingsVibrationOn),
                //     value: controller.vibrationOn,
                //     onChanged: controller.updateVibrationOn),
                // CheckboxListTile(
                //     title: Text(context.loc().settingsSoundOn),
                //     value: controller.soundOn,
                //     onChanged: controller.updateSoundOn),
                // const Divider(),
                // CheckboxListTile(
                //     title: Text(context.loc().gameTitleDocAllShow),
                //     value: controller.showDocAllScreen,
                //     onChanged: controller.updateShowDocAllScreen),
                // CheckboxListTile(
                //     title: Text(context.loc().gameTitleDocTrainingShow),
                //     value: controller.showDocTrainingScreen,
                //     onChanged: controller.updateShowDocTrainingScreen),
                // CheckboxListTile(
                //     title: Text(context.loc().gameTitleDocGameShow),
                //     value: controller.showDocGameScreen,
                //     onChanged: controller.updateShowDocGameScreen),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
