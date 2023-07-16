import 'package:tank_game/world/core/scenario/components/area_init_script.dart';
import 'package:tank_game/world/core/scenario/scripts/moving_path.dart';
import 'package:tank_game/world/core/scenario/scripts/script_core.dart';

class AreaMovingPathComponent extends AreaInitScriptComponent {
  String pathName = '';

  AreaMovingPathComponent({super.tiledObject});

  @override
  void onLoad() {
    super.onLoad();

    final properties = tiledObject?.properties;
    if (properties != null) {
      pathName = properties.getValue<String>('pathName') ?? '';
    }
    if (pathName.isEmpty) {
      throw 'pathName must be specified!';
    }
    scriptTarget = AreaScriptTarget.activator;
    scriptFactory = _buildMovingScript;
  }

  ScriptCore _buildMovingScript(
      double lifetimeMax, AreaInitScriptComponent creator) {
    return MovingPathScript.fromNamed(pathName);
  }
}
