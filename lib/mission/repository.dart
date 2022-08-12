class MissionDescription {
  MissionDescription(
      {required this.name, required this.description, required this.mapFile});

  String name;
  String description;
  String mapFile;

  List<String> objectives = [];
}

class MissionRepository {
  final _missions = <MissionDescription>[];

  initMissionList() {
    const mapFiles = <String, String>{
      'collisiontest.tmx': 'Small to test collisions',
      'mission.tmx': 'Real mission on relatively big map',
      'huge.tmx': 'Boring but very big map for performance testing'
    };
    mapFiles.forEach((key, value) {
      _missions.add(MissionDescription(
          name: key.replaceAll('.tmx', ''), description: value, mapFile: key));
    });
  }

  List<MissionDescription> get missions => _missions;
}
