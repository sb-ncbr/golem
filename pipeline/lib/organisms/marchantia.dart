import 'package:pipeline/organisms/base_organism.dart';

class Marchantia extends BaseOrganism {
  Marchantia() : super(name: 'Marchantia polymorpha');

  @override
  String? stageNameFromTpmFilePath(String path) {
    final filename = path.split('/').last;
    final key = RegExp(r'^[0-9]+\.\s*Marchantia_([^.]*)').firstMatch(filename)?.group(1);
    return key;
  }
}
