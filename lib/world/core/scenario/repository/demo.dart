import 'package:tank_game/world/core/scenario/scenario_description.dart';

class DemoScenario extends Scenario {
  DemoScenario({super.name = 'Demo', super.description = 'Not just test map!'});

  @override
  String? get worldFile => 'demo.world';
}
