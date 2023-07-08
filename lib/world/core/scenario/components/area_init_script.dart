import 'package:tank_game/game.dart';
import 'package:tank_game/world/core/actor.dart';
import 'package:tank_game/world/core/scenario/components/has_text_message_mixin.dart';
import 'package:tank_game/world/core/scenario/scenario_component.dart';
import 'package:tank_game/world/core/scenario/scripts/script_core.dart';

typedef ScriptTypeFactory = ScriptCore Function(
  double lifetimeMax,
  AreaInitScriptComponent creator,
);

enum AreaScriptTarget {
  global('global'),
  activator('activator'),
  player('player');

  final String name;

  const AreaScriptTarget(this.name);

  factory AreaScriptTarget.fromString(String name) {
    switch (name) {
      case 'global':
        return AreaScriptTarget.global;
      case 'activator':
        return AreaScriptTarget.activator;
      case 'player':
        return AreaScriptTarget.player;
      default:
        throw 'Invalid AreaScriptTarget $name';
    }
  }
}

class AreaInitScriptComponent extends ScenarioComponent<AreaInitScriptComponent>
    with HasTextMessage<AreaInitScriptComponent> {
  /// FIXME: скрипт только один, но в зоне действия может быть несколько объектов
  /// Нужно переделать, чтобы был только билдер скрипта для такого случая!
  /// Или отнаследовать класс, т.к. с билдером будет медленнее?.. Хмм...
  ScriptCore? script;
  ScriptTypeFactory? scriptFactory;
  late final AreaScriptTarget scriptTarget;
  late final double lifetimeMax;
  late final int activationTimes;
  int _activationCount = 0;
  late final bool limitedByArea;

  static final _availableTypes = <String, ScriptTypeFactory>{};

  static registerType(String name, ScriptTypeFactory factory) {
    _availableTypes[name] = factory;
  }

  static restoreDefaults() {
    _availableTypes.clear();
    _availableTypes.addAll({}); // TODO: default scripts here
  }

  AreaInitScriptComponent({
    ScriptTypeFactory? scriptFactory,
    ScriptCore? script,
    super.tiledObject,
    this.scriptTarget = AreaScriptTarget.global,
    this.lifetimeMax = 0,
    this.activationTimes = 1,
    this.limitedByArea = false,
  }) {
    if (script != null) {
      this.script = script;
    } else {
      final scriptName = tiledObject?.properties.getValue<String>('scriptName');
      if (scriptName == null) {
        throw 'scriptName must be specified!';
      }
      final scriptFactory = _availableTypes[scriptName];
      if (scriptFactory == null) {
        throw 'script with name $scriptName id not registered';
      }
      this.scriptFactory = scriptFactory;
    }
  }

  @override
  void onLoad() {
    final properties = tiledObject?.properties;
    if (properties != null) {
      try {
        final scriptTargetName =
            properties.getValue<String>('scriptTarget') ?? 'global';
        scriptTarget = AreaScriptTarget.fromString(scriptTargetName);
      } catch (_) {}
      try {
        lifetimeMax = properties.getValue<double>('scriptLifetimeSeconds') ?? 0;
      } catch (_) {}
      try {
        activationTimes = properties.getValue<int>('activationTimes') ?? 1;
      } catch (_) {}
      try {
        limitedByArea = properties.getValue<bool>('limitedByArea') ?? false;
      } catch (_) {}
    }
    super.onLoad();
  }

  @override
  void activatedBy(
      AreaInitScriptComponent scenario, ActorMixin other, MyGame game) {
    super.activatedBy(scenario, other, game);
    if (_activationCount >= activationTimes) {
      return;
    }
    final newScript = script ?? scriptFactory?.call(lifetimeMax, this);
    if (newScript != null) {
      switch (scriptTarget) {
        case AreaScriptTarget.global:
          game.world.scriptLayer.add(newScript);
          break;
        case AreaScriptTarget.player:
          game.currentPlayer?.add(newScript);
          break;
        case AreaScriptTarget.activator:
          other.add(newScript);
          break;
      }
      _activationCount++;
    }
  }

  @override
  void deactivatedBy(
      AreaInitScriptComponent scenario, ActorMixin other, MyGame game) {
    if (limitedByArea) {
      script?.removeFromParent();
    }
    super.deactivatedBy(scenario, other, game);
  }
}
