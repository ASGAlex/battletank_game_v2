import 'package:flame_tiled/flame_tiled.dart';
import 'package:intl/intl.dart';
import 'package:tank_game/world/core/scenario/scenario_component.dart';

mixin HasTextMessage<T extends ScenarioComponentCore> on ScenarioComponent<T> {
  String getTextMessage(String name) {
    final properties = tiledObject?.properties;
    var text = '';
    if (properties != null) {
      text = properties.getValue<String>(name) ?? '';
      final locale = Intl.getCurrentLocale();
      text = properties.getValue<String>('${name}_${locale}') ?? text;
    }
    return text;
  }
}

extension PropertyLocalizedText on CustomProperties {
  String getLocalizedTextMessage(String name) {
    var text = '';
    text = getValue<String>(name) ?? '';
    final locale = Intl.getCurrentLocale();
    text = getValue<String>('${name}_${locale}') ?? text;
    return text;
  }
}
