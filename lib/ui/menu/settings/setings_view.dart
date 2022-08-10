import 'package:flutter/material.dart';
import 'package:tank_game/services/settings/controller.dart';
import 'package:tank_game/ui/intl.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({Key? key}) : super(key: key);

  SettingsController get controller => SettingsController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blueGrey,
        title: Text(context.loc().settings),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: AnimatedBuilder(
          animation: controller,
          builder: (BuildContext context, Widget? child) => ListView(
            children: [
              Text(context.loc().graphics_quality, textAlign: TextAlign.left),
              Padding(
                padding: const EdgeInsets.only(left: 16, right: 10),
                child: DropdownButton<GraphicsQuality>(
                  isExpanded: true,
                  value: controller.graphicsQuality,
                  onChanged: (GraphicsQuality? quality) {
                    if (quality != null) {
                      controller.graphicsQuality = quality;
                    }
                  },
                  items: [
                    DropdownMenuItem(
                      value: GraphicsQuality.low,
                      child: Text(context.loc().graphics_low),
                    ),
                    DropdownMenuItem(
                      value: GraphicsQuality.treeShadow,
                      child: Text(context.loc().graphics_treeShadow),
                    ),
                    DropdownMenuItem(
                      value: GraphicsQuality.walls3D_low,
                      child: Text(context.loc().graphics_walls3D_low),
                    ),
                    DropdownMenuItem(
                      value: GraphicsQuality.walls3dShadows_low,
                      child: Text(context.loc().graphics_walls3dShadows_low),
                    ),
                    DropdownMenuItem(
                      value: GraphicsQuality.walls3DShadows_medium,
                      child: Text(context.loc().graphics_walls3DShadows_medium),
                    ),
                    DropdownMenuItem(
                      value: GraphicsQuality.walls3dShadows_hight,
                      child: Text(context.loc().graphics_walls3dShadows_high),
                    ),
                  ],
                ),
              ),
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
    );
  }
}
