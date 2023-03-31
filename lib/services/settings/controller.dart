import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tank_game/controls/gamepad.dart';
import 'package:tank_game/game.dart';
import 'package:tank_game/mission/repository.dart';
import 'package:tank_game/ui/widgets/console_messages.dart';

enum GraphicsQuality {
  low(0),
  treeShadow(1),
  walls3D_low(2),
  walls3dShadows_low(3),
  walls3DShadows_medium(4),
  walls3dShadows_hight(5);

  final int qualityValue;

  const GraphicsQuality(this.qualityValue);

  static GraphicsQuality fromInt(int value) {
    switch (value) {
      case 0:
        return GraphicsQuality.low;
      case 1:
        return GraphicsQuality.treeShadow;
      case 2:
        return GraphicsQuality.walls3D_low;
      case 3:
        return GraphicsQuality.walls3dShadows_low;
      case 4:
        return GraphicsQuality.walls3DShadows_medium;
      case 5:
        return GraphicsQuality.walls3dShadows_hight;
      default:
        return GraphicsQuality.low;
    }
  }
}

class SettingsController with ChangeNotifier {
  static final SettingsController _instance = SettingsController._();

  factory SettingsController() => _instance;

  SettingsController._();

  Future<SharedPreferences> get prefs => SharedPreferences.getInstance();
  MyGame? gameInstance;
  String mapFile = '';
  var xInputGamePadController = XInputGamePadController();

  final consoleMessages = ConsoleMessagesController();

  final _missionRepository = MissionRepository();

  List<MissionDescription> get missions => _missionRepository.missions;

  MissionDescription? _currentMission;

  MissionDescription get currentMission {
    if (_currentMission == null) {
      throw 'Mission not set!';
    }
    return _currentMission!;
  }

  MyGame startGameWithMission(
      MissionDescription mission, BuildContext context) {
    _currentMission = mission;
    mapFile = mission.mapFile;
    final game = MyGame(mapFile, context);
    gameInstance = game;
    return game;
  }

  loadSettings() async {
    _missionRepository.initMissionList();
    _graphicsQuality = await prefs.then((value) =>
        GraphicsQuality.fromInt(value.getInt('graphics_quality') ?? 0));
  }

  GraphicsQuality _graphicsQuality = GraphicsQuality.low;

  GraphicsQuality get graphicsQuality => _graphicsQuality;

  set graphicsQuality(GraphicsQuality quality) {
    _graphicsQuality = quality;
    prefs.then((value) {
      value.setInt('graphics_quality', quality.qualityValue);
      notifyListeners();
    });
  }
}
