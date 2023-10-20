import 'package:pipeline/organisms/base_organism.dart';

class Zea extends BaseOrganism {
  Zea() : super(name: 'Zea mays');

  @override
  String? stageNameFromTpmFilePath(String path) {
    final filename = path.split('/').last;
    final key = RegExp(r'^[0-9]+\.\s*Zea_([^.]*)').firstMatch(filename)?.group(1);
    return key;
  }

  @override
  String? transcriptParser(Map<String, String> attributes) {
    // We use transcript_id instead of Name
    return attributes['transcript_id'];
  }

  @override
  String sequenceIdentifier(List<String> line) {
    // We need to convert `Zm00001e000001_P001` to `Zm00001e000001_T001` used in GFF
    return line[0].replaceAll('_P', '_T');
  }
}
