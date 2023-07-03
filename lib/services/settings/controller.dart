import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tank_game/controls/gamepad.dart';
import 'package:tank_game/game.dart';
import 'package:tank_game/ui/widgets/console_messages.dart';
import 'package:tank_game/world/core/scenario/repository/repository.dart';
import 'package:tank_game/world/core/scenario/scenario_description.dart';

enum ProcessorSpeed {
  web(0),
  office(1),
  middle(2),
  powerful(3);

  final int qualityValue;

  const ProcessorSpeed(this.qualityValue);

  static ProcessorSpeed fromInt(int value) {
    switch (value) {
      case 0:
        return ProcessorSpeed.web;
      case 1:
        return ProcessorSpeed.office;
      case 2:
        return ProcessorSpeed.middle;
      case 3:
        return ProcessorSpeed.powerful;
      default:
        return ProcessorSpeed.web;
    }
  }
}

class SettingsController with ChangeNotifier {
  static final SettingsController _instance = SettingsController._();

  factory SettingsController() => _instance;

  SettingsController._();

  Future<SharedPreferences> get prefs => SharedPreferences.getInstance();
  String mapFile = '';
  var xInputGamePadController = XInputGamePadController();

  final consoleMessages = ConsoleMessagesController();

  final _missionRepository = ScenarioRepository();

  List<Scenario> get scenarios => _missionRepository.scenarios;

  MyGame startGameWithMission(Scenario scenario, BuildContext context) {
    return MyGame(scenario, context);
  }

  loadSettings() async {
    _missionRepository.initMissionList();
    _processor = await prefs.then((value) =>
        ProcessorSpeed.fromInt(value.getInt('processor_speed') ?? 0));
    _soundEnabled =
        await prefs.then((value) => value.getBool('sound_enabled') ?? true);
  }

  ProcessorSpeed _processor = ProcessorSpeed.web;

  ProcessorSpeed get processor => _processor;

  bool _soundEnabled = true;

  bool get soundEnabled => _soundEnabled;

  set soundEnabled(bool value) {
    _soundEnabled = value;
    prefs.then((value) {
      value.setBool('sound_enabled', soundEnabled);
      notifyListeners();
    });
  }

  set processor(ProcessorSpeed quality) {
    _processor = quality;
    prefs.then((value) {
      value.setInt('processor_speed', quality.qualityValue);
      notifyListeners();
    });
  }
}
