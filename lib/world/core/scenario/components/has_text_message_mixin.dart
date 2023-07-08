import 'package:intl/intl.dart';
import 'package:tank_game/world/core/scenario/scenario_component.dart';

mixin HasTextMessage<T extends ScenarioComponentCore> on ScenarioComponent<T> {
  late String text;

  @override
  void onLoad() {
    final properties = tiledObject?.properties;
    if (properties != null) {
      var text = properties.getValue<String>('text') ?? '';
      final locale = Intl.getCurrentLocale();
      text = properties.getValue<String>('text_$locale') ?? text;
      this.text = text;
    }
    super.onLoad();
  }
}
