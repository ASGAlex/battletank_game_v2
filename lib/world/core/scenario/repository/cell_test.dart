import 'package:tank_game/world/core/scenario/scenario_description.dart';

class CellTestScenario extends Scenario {
  CellTestScenario(
      {super.name = 'Cell Test', super.description = 'Not just test map!'});

  @override
  String? get mapFile => 'cell_test.tmx';
}
