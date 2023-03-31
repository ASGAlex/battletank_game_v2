class Faction {
  Faction._({required this.name});

  static final _factions = <String, Faction>{};

  factory Faction({required String name}) {
    var faction = _factions[name];
    if (faction == null) {
      faction = Faction._(name: name);
      _factions[name] = faction;
    }
    return faction;
  }

  String name;

  static clear() {
    _factions.clear();
  }
}
