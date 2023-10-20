import 'package:pipeline/organisms/base_organism.dart';

class Oryza extends BaseOrganism {
  Oryza() : super(name: 'Oryza sativa');

  @override
  String? stageNameFromTpmFilePath(String path) {
    final filename = path.split('/').last;
    final key = RegExp(r'^[0-9]+\.\s*Oryza_([^.]*)').firstMatch(filename)?.group(1);
    return key;
  }
}
