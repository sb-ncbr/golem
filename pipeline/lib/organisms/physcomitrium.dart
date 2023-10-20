import 'package:pipeline/organisms/base_organism.dart';

class Physcomitrium extends BaseOrganism {
  Physcomitrium() : super(name: 'Physcomitrella patens');

  @override
  String? stageNameFromTpmFilePath(String path) {
    final filename = path.split('/').last;
    final key = RegExp(r'^[0-9]+\.\s*Physcomitrium_([^.]*)').firstMatch(filename)?.group(1);
    return key;
  }
}
