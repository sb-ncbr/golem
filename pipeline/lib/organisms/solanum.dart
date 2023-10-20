import 'package:pipeline/organisms/base_organism.dart';

class Solanum extends BaseOrganism {
  Solanum() : super(name: 'Solanum lycopersicum');

  @override
  String? stageNameFromTpmFilePath(String path) {
    final filename = path.split('/').last;
    final key = RegExp(r'^[0-9]+\.\s*Solanum_([^.]*)').firstMatch(filename)?.group(1);
    return key;
  }
}
